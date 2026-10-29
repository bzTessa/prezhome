import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import 'add_recipe_screen.dart';
import 'cook_mode_screen.dart';
import 'services/recipe_photo_service.dart';
import 'services/recipe_share.dart';
import 'services/price_memory.dart';
import 'utils/approx_price.dart';
import 'utils/measure_format.dart';
import 'utils/practical_quantity.dart';
import 'models/ingredient.dart';
import 'models/inventory_item.dart';
import 'models/nutrition_profile.dart';
import 'models/recipe.dart';
import 'models/shopping_list_item.dart';
import 'models/supermarket.dart';
import 'theme/app_theme.dart';
import 'widgets/recipe_chip.dart';
import 'widgets/recipe_image.dart';
import 'utils/friendly_error.dart';
import 'utils/pantry_ideas.dart';
import 'utils/recipe_steps.dart';
import 'utils/shopping_categories.dart';
import 'widgets/list_skeleton.dart';

class RecipeDetailScreen extends StatefulWidget {
  final Recipe recipe;
  const RecipeDetailScreen({super.key, required this.recipe});

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  final SupabaseClient _client = Supabase.instance.client;
  final ImagePicker _picker = ImagePicker();
  late Recipe _recipe;

  /// Fotos automáticas ya mostradas en esta pantalla (para "Otra foto").
  final Set<String> _seenPhotoUrls = {};
  late Future<List<Ingredient>> _ingredientsFuture;
  bool _changingPhoto = false; // true mientras se regenera/sube una foto
  String? _homeSupermarketLabel; // etiqueta del súper del hogar (chip)
  RecipeCost? _cost; // coste estimado de la receta (precio real o aproximado)
  List<NutritionProfile> _profiles =
      []; // miembros del hogar con perfil visible
  NutritionProfile? _myProfile; // perfil del usuario logueado (para el modo)

  bool get _isMealPrep => _myProfile?.isMealPrep ?? false;

  // Raciones a preparar elegidas en el conversor (null = las de la receta).
  int? _servings;
  bool _changed = false; // para avisar a la lista si hubo cambios al volver

  // Sección visible: 0 ingredientes, 1 pasos, 2 nutrición.
  int _tab = 0;
  // Ingredientes ya preparados y pasos hechos (solo en esta pantalla).
  final Set<int> _checkedIngs = {};
  final Set<int> _doneSteps = {};
  // Nombres de la despensa, para marcar lo que ya hay en casa.
  List<String> _pantry = [];
  bool _addingMissing = false;

  int get _recipeServings => _recipe.servings < 1 ? 1 : _recipe.servings;
  int get _servingsNow => _servings ?? _recipeServings;

  /// Los ingredientes se guardan para las raciones de la receta: se escalan
  /// por raciones elegidas / raciones guardadas (×1 = tal cual se guardó).
  double get _servingsFactor => _servingsNow / _recipeServings;

  /// Raciones que come el hogar en una comida (por perfiles y peso), o null.
  double? _householdServings(Recipe r) {
    final mealGrams = _householdMealGrams(r);
    final perServing = r.gramsPerServing;
    if (mealGrams == null || perServing == null || perServing <= 0) return null;
    return mealGrams / perServing;
  }

  @override
  void initState() {
    super.initState();
    _recipe = widget.recipe;
    _ingredientsFuture = _fetchIngredients();
    _loadProfile();
    _loadHomeSupermarketLabel();
    _loadCost();
    _loadPantry();
  }

  /// Calcula el coste estimado de la receta: precio real de los tickets si lo
  /// hay, y aproximado por tipo de alimento si no. Best-effort.
  Future<void> _loadCost() async {
    try {
      final ings = await _ingredientsFuture;
      if (ings.isEmpty) return;
      final prices = await PriceMemory(_client).loadAll(_recipe.homeId);
      final cost = computeRecipeCost(
        ingredients: [
          for (final i in ings)
            (name: i.name, quantity: i.quantity, unit: i.unit),
        ],
        prices: prices,
        servings: _recipe.servings < 1 ? 1 : _recipe.servings,
        approxOf: ApproxPrice.estimate,
      );
      if (mounted) setState(() => _cost = cost);
    } catch (_) {
      // Sin coste si falla; no es crítico.
    }
  }

  /// Carga la etiqueta del primer súper del hogar para mostrarla como chip
  /// junto al resto (Comida/Cena/kcal). Best-effort.
  Future<void> _loadHomeSupermarketLabel() async {
    final key = await _firstHomeSupermarket();
    if (key.isEmpty || !mounted) return;
    setState(() => _homeSupermarketLabel = Supermarket.labelFor(key));
  }

  Future<void> _loadProfile() async {
    final user = _client.auth.currentUser;
    if (user == null) return;
    // Perfiles del hogar visibles: el propio siempre, y los de los miembros
    // que tengan el perfil compartido (RLS ya filtra: solo devuelve visibles).
    final rows = await _client
        .from('profiles')
        .select()
        .eq('home_id', _recipe.homeId);
    if (mounted) {
      setState(() {
        final all = (rows as List)
            .map((p) => NutritionProfile.fromMap(p))
            .toList();
        _profiles = all.where((p) => p.isComplete).toList();
        // Mi perfil (para saber el modo de cocina). Puede estar incompleto.
        for (final p in all) {
          if (p.id == user.id) _myProfile = p;
        }
      });
    }
  }

  Future<List<Ingredient>> _fetchIngredients() async {
    final res = await _client
        .from('recipe_ingredients')
        .select()
        .eq('recipe_id', _recipe.id)
        .order('position');
    return (res as List).map((m) => Ingredient.fromMap(m)).toList();
  }

  Future<void> _edit() async {
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => AddRecipeScreen(recipe: _recipe)),
    );
    if (updated == true) {
      _changed = true;
      // Recargar la receta y sus ingredientes tras editar.
      final r = await _client
          .from('recipes')
          .select()
          .eq('id', _recipe.id)
          .maybeSingle();
      if (r != null && mounted) {
        setState(() {
          _recipe = Recipe.fromMap(r);
          _servings = null;
          _ingredientsFuture = _fetchIngredients();
        });
      }
    }
  }

  /// Marca/desmarca la receta como favorita con un solo toque, sin abrir el
  /// formulario de edición. Actualiza is_favorite en la BD y refresca la UI.
  Future<void> _toggleFavorite() async {
    final newValue = !_recipe.isFavorite;
    try {
      await _client
          .from('recipes')
          .update({'is_favorite': newValue})
          .eq('id', _recipe.id);
      if (!mounted) return;
      setState(() {
        _recipe = _recipe.copyWithFavorite(newValue);
        _changed = true;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(friendlyError(e, 'No se pudo actualizar')),
          backgroundColor: AppColors.expired,
        ),
      );
    }
  }

  /// Menú de foto: regenerar automática (Unsplash) o elegir de la galería.
  Future<void> _openPhotoMenu() async {
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.cream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 4),
              child: Text(
                'Foto de la receta',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: AppColors.ink,
                ),
              ),
            ),
            ListTile(
              leading: Icon(Icons.image_search, color: AppColors.woodDark),
              title: const Text('Buscar otra foto automática'),
              subtitle: const Text('Busca una imagen nueva por el nombre'),
              onTap: () => Navigator.of(ctx).pop('regenerate'),
            ),
            ListTile(
              leading: Icon(
                Icons.photo_library_outlined,
                color: AppColors.woodDark,
              ),
              title: const Text('Elegir de la galería'),
              onTap: () => Navigator.of(ctx).pop('gallery'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (!mounted || action == null) return;
    if (action == 'regenerate') {
      await _regeneratePhoto();
    } else if (action == 'gallery') {
      await _pickPhotoFromGallery();
    }
  }

  /// Vuelve a buscar una foto automática por el nombre de la receta y la
  /// guarda como foto externa (image_url). Degrada con elegancia.
  Future<void> _regeneratePhoto() async {
    setState(() => _changingPhoto = true);
    try {
      // Excluimos las fotos ya vistas: así cada pulsación trae una distinta
      // (antes devolvía siempre el mismo primer resultado).
      final current = _recipe.externalImageUrl;
      if (current != null) _seenPhotoUrls.add(current);
      final url = await RecipePhotoService(
        _client,
      ).find(title: _recipe.title, exclude: _seenPhotoUrls);
      if (url != null) _seenPhotoUrls.add(url);
      if (!mounted) return;
      if (url == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No he encontrado otra foto mejor por ahora'),
          ),
        );
        return;
      }
      // Guardamos como foto externa. Al poner una externa nueva, quitamos la
      // manual (image_path) para que esta sea la que se vea.
      await _client
          .from('recipes')
          .update({'image_url': url, 'image_path': null})
          .eq('id', _recipe.id);
      await _refreshRecipe();
      _changed = true;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(friendlyError(e, 'No se pudo cambiar la foto')),
            backgroundColor: AppColors.expired,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _changingPhoto = false);
    }
  }

  /// Elige una foto de la galería, la sube al bucket y la fija como foto manual
  /// (image_path), que tiene prioridad sobre la externa.
  Future<void> _pickPhotoFromGallery() async {
    try {
      final file = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        imageQuality: 82,
      );
      if (file == null) return;
      setState(() => _changingPhoto = true);
      final bytes = await file.readAsBytes();
      final ext = file.name.toLowerCase().endsWith('.png') ? 'png' : 'jpg';
      final path =
          '${_recipe.homeId}/${DateTime.now().millisecondsSinceEpoch}.$ext';
      await _client.storage
          .from('recipe-images')
          .uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(
              contentType: ext == 'png' ? 'image/png' : 'image/jpeg',
              upsert: false,
            ),
          );
      await _client
          .from('recipes')
          .update({'image_path': path})
          .eq('id', _recipe.id);
      await _refreshRecipe();
      _changed = true;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(friendlyError(e, 'No se pudo subir la foto')),
            backgroundColor: AppColors.expired,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _changingPhoto = false);
    }
  }

  /// Primer supermercado del hogar (clave), o '' si no hay. Best-effort.
  Future<String> _firstHomeSupermarket() async {
    try {
      final home = await _client
          .from('homes')
          .select('supermarkets')
          .eq('id', _recipe.homeId)
          .maybeSingle();
      final raw = home?['supermarkets'];
      if (raw is List && raw.isNotEmpty) return raw.first.toString();
    } catch (_) {}
    return '';
  }

  /// Relee la receta de la BD y refresca la UI (tras cambiar la foto).
  Future<void> _refreshRecipe() async {
    final r = await _client
        .from('recipes')
        .select()
        .eq('id', _recipe.id)
        .maybeSingle();
    if (r != null && mounted) {
      setState(() => _recipe = Recipe.fromMap(r));
    }
  }

  /// Comparte un código con el que otra persona guarda la receta en su app.
  Future<void> _share() async {
    final box = context.findRenderObject() as RenderBox?;
    try {
      final code = await RecipeShare(_client).share(_recipe.id);
      await SharePlus.instance.share(
        ShareParams(
          text:
              'Te paso mi receta de ${_recipe.title} en PrezHome. En la app, '
              've a Recetas, toca Añadir receta y luego Con un código: $code',
          sharePositionOrigin: box == null
              ? null
              : box.localToGlobal(Offset.zero) & box.size,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(friendlyError(e)),
          backgroundColor: AppColors.expired,
        ),
      );
    }
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cream,
        title: const Text('¿Eliminar receta?'),
        content: Text('Se borrará "${_recipe.title}" y sus ingredientes.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.expired,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      // Antes de borrar la receta, quitamos sus comidas del plan. La FK de
      // meal_plan_entries es ON DELETE SET NULL, así que sin esto quedarían
      // entradas con recipe_id null que se verían como "Receta" fantasma en
      // el plan y en el Inicio. Las borramos para dejar el plan limpio.
      await _client
          .from('meal_plan_entries')
          .delete()
          .eq('recipe_id', _recipe.id);
      await _client.from('recipes').delete().eq('id', _recipe.id);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(friendlyError(e, 'No se pudo eliminar')),
            backgroundColor: AppColors.expired,
          ),
        );
      }
    }
  }

  /// Gramos de UNA comida para todo el hogar: suma de los gramos que come cada
  /// miembro (con perfil, que come en casa hoy) según su objetivo para esta
  /// comida. Es la base de "×1 = comida para todos".
  double? _householdMealGrams(Recipe r) {
    final today = DateTime.now().weekday;
    double total = 0;
    var counted = 0;
    for (final p in _profiles) {
      final eatsHome = r.mealTypes.any((t) => p.eatsAtHome(t, today));
      if (!eatsHome) continue;
      final kcal = p.caloriesForMealTypes(r.mealTypes);
      if (kcal == null) continue;
      final g = r.gramsForCalories(kcal);
      if (g == null) continue;
      total += g;
      counted++;
    }
    return counted > 0 ? total : null;
  }

  /// Registra la receta como cocinada: guarda en el congelador las raciones
  /// preparadas como "plato listo" (para meal prep). El nº de raciones = nº de
  /// comidas de hogar (el multiplicador) × personas que comen en casa.
  Future<void> _markCooked() async {
    try {
      final r = _recipe;
      // Raciones preparadas (las del conversor) y cuántas comidas de hogar son.
      final servings = _servingsNow.toDouble();
      final perMeal = _householdServings(r);
      final meals = perMeal == null || perMeal <= 0
          ? 1.0
          : double.parse((servings / perMeal).toStringAsFixed(1));

      final now = DateTime.now();
      // Consumo preferente: hoy + días recomendados por la IA (o 90 por defecto).
      final days = r.freezerDays ?? 90;
      final bestBefore = days > 0
          ? DateTime(now.year, now.month, now.day + days)
          : null;

      final item = InventoryItem(
        id: '',
        homeId: r.homeId,
        name: r.title,
        category: 'Congelador',
        quantity: meals, // nº de comidas de hogar
        unit: 'comidas',
        kind: 'dish',
        recipeId: r.id,
        servings: double.parse(servings.toStringAsFixed(1)),
        frozenOn: now,
        bestBefore: bestBefore,
        // El plato congelado lleva la FOTO y el nombre de la receta, para que
        // en el congelador se vea igual que en el recetario.
        imageUrl: r.imageUrl,
      );
      await _client.from('inventory_items').insert(item.toMap());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Guardado en el congelador como plato listo.'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(friendlyError(e, 'No se pudo guardar')),
            backgroundColor: AppColors.expired,
          ),
        );
      }
    }
  }

  /// Abre el enlace de video de la receta en una app/pestaña externa.
  Future<void> _openVideo() async {
    final url = _recipe.videoUrl?.trim();
    if (url == null || url.isEmpty) return;
    try {
      final ok = await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );
      if (!ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No se pudo abrir el enlace del video'),
            backgroundColor: AppColors.expired,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No se pudo abrir el enlace del video'),
            backgroundColor: AppColors.expired,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = _recipe;
    final steps = r.instructions == null
        ? const <String>[]
        : splitRecipeSteps(r.instructions!);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) Navigator.of(context).pop(_changed);
      },
      child: Scaffold(
        backgroundColor: AppColors.cream,
        bottomNavigationBar: steps.isEmpty ? null : _cookBar(r, steps),
        body: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              expandedHeight: 320,
              backgroundColor: AppColors.cream,
              surfaceTintColor: Colors.transparent,
              automaticallyImplyLeading: false,
              leading: Padding(
                padding: const EdgeInsets.all(6),
                child: _roundAction(
                  icon: Icons.arrow_back_rounded,
                  tooltip: 'Volver',
                  onTap: () => Navigator.of(context).pop(_changed),
                ),
              ),
              actions: [
                _roundAction(
                  icon: r.isFavorite
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  color: r.isFavorite ? AppColors.favorite : AppColors.ink,
                  tooltip: r.isFavorite
                      ? 'Quitar de favoritas'
                      : 'Marcar favorita',
                  onTap: _toggleFavorite,
                ),
                const SizedBox(width: 6),
                _moreMenu(),
                const SizedBox(width: 10),
              ],
              flexibleSpace: FlexibleSpaceBar(
                collapseMode: CollapseMode.parallax,
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    RecipeImage(recipe: r, height: 360, radius: 0),
                    if (_changingPhoto)
                      Container(
                        color: Colors.black26,
                        alignment: Alignment.center,
                        child: const CircularProgressIndicator(),
                      ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.cream,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      r.title,
                      style: TextStyle(
                        fontSize: 26,
                        letterSpacing: -0.4,
                        height: 1.15,
                        fontWeight: FontWeight.w900,
                        color: AppColors.ink,
                      ),
                    ),
                    if (r.description != null &&
                        r.description!.trim().isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        r.description!,
                        style: AppTextStyles.bodyMuted.copyWith(height: 1.35),
                      ),
                    ],
                    const SizedBox(height: 18),
                    _statsRow(r),
                    const SizedBox(height: 14),
                    _tagsWrap(r),
                    if (r.videoUrl != null &&
                        r.videoUrl!.trim().isNotEmpty) ...[
                      const SizedBox(height: 14),
                      OutlinedButton.icon(
                        onPressed: _openVideo,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.ink,
                          side: BorderSide(color: AppColors.wood),
                        ),
                        icon: const Icon(Icons.play_circle_outline),
                        label: const Text('Ver vídeo'),
                      ),
                    ],
                    const SizedBox(height: 22),
                    _sectionTabs(steps.length),
                    const SizedBox(height: 16),
                    switch (_tab) {
                      0 => _ingredientsTab(r),
                      1 => _stepsTab(steps),
                      _ => _nutritionTab(r),
                    },
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _roundAction({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    Color? color,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: AppColors.card.withValues(alpha: 0.92),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 42,
            height: 42,
            child: Icon(icon, color: color ?? AppColors.ink, size: 22),
          ),
        ),
      ),
    );
  }

  Widget _moreMenu() {
    return Material(
      color: AppColors.card.withValues(alpha: 0.92),
      shape: const CircleBorder(),
      child: SizedBox(
        width: 42,
        height: 42,
        child: PopupMenuButton<String>(
          tooltip: 'Más opciones',
          icon: Icon(Icons.more_horiz_rounded, color: AppColors.ink),
          padding: EdgeInsets.zero,
          onSelected: (v) {
            switch (v) {
              case 'photo':
                if (!_changingPhoto) _openPhotoMenu();
              case 'share':
                _share();
              case 'edit':
                _edit();
              case 'delete':
                _delete();
            }
          },
          itemBuilder: (_) => [
            PopupMenuItem(
              value: 'photo',
              child: ListTile(
                leading: Icon(Icons.photo_camera_outlined),
                title: Text('Cambiar foto'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            PopupMenuItem(
              value: 'share',
              child: ListTile(
                leading: Icon(Icons.ios_share_rounded),
                title: Text('Compartir'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            PopupMenuItem(
              value: 'edit',
              child: ListTile(
                leading: Icon(Icons.edit_outlined),
                title: Text('Editar receta'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            PopupMenuItem(
              value: 'delete',
              child: ListTile(
                leading: Icon(Icons.delete_outline, color: AppColors.expired),
                title: Text('Eliminar'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Tres datos clave de un vistazo: tiempo, calorías y coste por ración.
  Widget _statsRow(Recipe r) {
    final tiles = <Widget>[
      _stat(
        Icons.schedule_rounded,
        r.totalTimeMinutes == null ? '—' : '${r.totalTimeMinutes}',
        'Minutos',
        AppColors.frost,
        AppColors.frostBg,
      ),
      _stat(
        Icons.local_fire_department_rounded,
        r.calories == null ? '—' : '${r.calories}',
        'Kcal/ración',
        AppColors.terracotta,
        AppColors.terracottaBg,
      ),
      if (_cost != null)
        _stat(
          Icons.euro_rounded,
          _cost!.perServing.toStringAsFixed(2).replaceAll('.', ','),
          '€/ración',
          AppColors.sage,
          AppColors.sageBg,
        )
      else
        _stat(
          Icons.restaurant_rounded,
          '${r.servings}',
          r.servings == 1 ? 'Ración' : 'Raciones',
          AppColors.peach,
          AppColors.peachBg,
        ),
    ];
    return Row(
      children: [
        for (var i = 0; i < tiles.length; i++) ...[
          if (i > 0) const SizedBox(width: 10),
          Expanded(child: tiles[i]),
        ],
      ],
    );
  }

  Widget _stat(IconData icon, String value, String label, Color fg, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Icon(icon, color: fg, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontFeatures: const [FontFeature.tabularFigures()],
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: fg,
            ),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.inkMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _tagsWrap(Recipe r) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final type in r.mealTypes)
          RecipeChip(
            text: Recipe.mealTypeLabels[type] ?? type,
            icon: mealTypeIcon(type),
            style: RecipeChipStyle.type,
          ),
        if (r.appliance != 'none')
          RecipeChip(
            text: r.applianceLabel,
            icon: Icons.kitchen_rounded,
            style: RecipeChipStyle.type,
          ),
        if (r.freezable)
          const RecipeChip(
            text: 'Congelable',
            icon: Icons.ac_unit,
            style: RecipeChipStyle.freezer,
          ),
        if (_homeSupermarketLabel != null)
          RecipeChip(
            text: _homeSupermarketLabel!,
            icon: Icons.storefront_rounded,
            style: RecipeChipStyle.type,
          ),
      ],
    );
  }

  /// Selector de sección (Ingredientes · Pasos · Nutrición): menos scroll y
  /// cada cosa en su sitio, como en las apps de recetas más usadas.
  Widget _sectionTabs(int stepCount) {
    final labels = [
      'Ingredientes',
      stepCount == 0 ? 'Pasos' : 'Pasos ($stepCount)',
      'Nutrición',
    ];
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            Expanded(
              child: Semantics(
                button: true,
                selected: _tab == i,
                child: GestureDetector(
                  onTap: () => setState(() => _tab = i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _tab == i ? AppColors.ink : Colors.transparent,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      labels[i],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: _tab == i ? AppColors.cream : AppColors.ink,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _servingsText(int n) => '$n ${n == 1 ? 'ración' : 'raciones'}';

  /// Cantidad + nombre listos para leer ("200 g arroz", "Sal (al gusto)").
  ({String prefix, String name}) _ingredientParts(Ingredient ing) {
    final scaledRaw = ing.quantity == null
        ? null
        : ing.quantity! * _servingsFactor;
    final practical = makePractical(ing.name, scaledRaw, ing.unit);
    final pq = practical.quantity;
    final qty = pq == null
        ? ''
        : (pq % 1 == 0 ? pq.toStringAsFixed(0) : pq.toStringAsFixed(1));
    final rawUnit = practical.unit.trim();
    final unit = rawUnit.isEmpty ? '' : pluralizeUnit(rawUnit, pq ?? 0);
    final isLooseMeasure = qty.isEmpty && unit.isNotEmpty;
    final parts = <String>[if (qty.isNotEmpty) qty, if (unit.isNotEmpty) unit];
    return (
      prefix: isLooseMeasure ? '' : parts.join(' '),
      name: isLooseMeasure ? '${ing.name} ($unit)' : ing.name,
    );
  }

  String _ingredientLine(Ingredient ing) {
    final p = _ingredientParts(ing);
    return p.prefix.isEmpty ? p.name : '${p.prefix} ${p.name}';
  }

  Widget _ingredientsTab(Recipe r) {
    return FutureBuilder<List<Ingredient>>(
      future: _ingredientsFuture,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const ListSkeleton(rows: 5, leading: false);
        }
        final ings = snap.data ?? [];
        final split = splitByPantry([for (final i in ings) i.name], _pantry);
        final have = split.have.toSet();
        final missing = split.missing.toSet();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _amountCard(r),
            const SizedBox(height: 12),
            if (ings.isEmpty)
              Text(
                'Sin ingredientes registrados.',
                style: AppTextStyles.bodyMuted,
              )
            else ...[
              if (_pantry.isNotEmpty) ...[
                _pantrySummary(have.length, split.missing),
                const SizedBox(height: 12),
              ],
              _card(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Column(
                  children: [
                    for (var i = 0; i < ings.length; i++)
                      _ingredientRow(
                        i,
                        ings[i],
                        // Básicos que no están: sin etiqueta (se suponen).
                        inPantry: _pantry.isEmpty
                            ? null
                            : have.contains(ings[i].name.trim())
                            ? true
                            : missing.contains(ings[i].name.trim())
                            ? false
                            : null,
                      ),
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _amountCard(Recipe r) {
    return _card(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Raciones',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.inkMuted,
                      ),
                    ),
                    Text(
                      _servingsText(_servingsNow),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Menos',
                icon: const Icon(Icons.remove_circle_outline_rounded),
                onPressed: _servingsNow > 1
                    ? () => setState(() => _servings = _servingsNow - 1)
                    : null,
              ),
              Text(
                '$_servingsNow',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              IconButton(
                tooltip: 'Más',
                icon: const Icon(Icons.add_circle_outline_rounded),
                onPressed: _servingsNow < 99
                    ? () => setState(() => _servings = _servingsNow + 1)
                    : null,
              ),
            ],
          ),
          _servingsHints(r),
          if (_isMealPrep)
            Padding(
              padding: const EdgeInsets.only(right: 8, top: 4),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _markCooked,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.ink,
                    side: BorderSide(color: AppColors.wood, width: 1.5),
                  ),
                  icon: const Icon(Icons.ac_unit),
                  label: const Text('Ya cocinado → al congelador'),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Atajos del conversor: volver a lo guardado o ajustar a lo que come hoy
  /// el hogar (según perfiles y peso por ración).
  Widget _servingsHints(Recipe r) {
    final perMeal = _householdServings(r)?.round();
    return Wrap(
      spacing: 8,
      children: [
        if (_servingsNow != _recipeServings)
          ActionChip(
            label: Text('Receta original: ${_servingsText(_recipeServings)}'),
            onPressed: () => setState(() => _servings = null),
          ),
        if (perMeal != null && perMeal >= 1 && perMeal != _servingsNow)
          ActionChip(
            label: Text('Para tu hogar hoy: ${_servingsText(perMeal)}'),
            onPressed: () => setState(() => _servings = perMeal),
          ),
      ],
    );
  }

  /// "Tienes 5 de 8 en casa" + atajo para mandar lo que falta a la compra.
  Widget _pantrySummary(int haveCount, List<String> missing) {
    final total = haveCount + missing.length;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.sageBg,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Icon(Icons.kitchen_rounded, color: AppColors.sage),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              missing.isEmpty
                  ? 'Tienes todo en casa'
                  : 'Tienes $haveCount de $total en casa',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
              ),
            ),
          ),
          if (missing.isNotEmpty)
            TextButton.icon(
              onPressed: _addingMissing ? null : () => _addMissing(missing),
              icon: const Icon(Icons.add_shopping_cart_rounded, size: 18),
              label: Text('Faltan ${missing.length}'),
              style: TextButton.styleFrom(foregroundColor: AppColors.sage),
            ),
        ],
      ),
    );
  }

  Widget _ingredientRow(int i, Ingredient ing, {required bool? inPantry}) {
    final checked = _checkedIngs.contains(i);
    final p = _ingredientParts(ing);
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => checked ? _checkedIngs.remove(i) : _checkedIngs.add(i));
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: checked ? AppColors.sage : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: checked ? AppColors.sage : AppColors.wood,
                  width: 2,
                ),
              ),
              child: checked
                  ? const Icon(
                      Icons.check_rounded,
                      size: 16,
                      color: Colors.white,
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text.rich(
                TextSpan(
                  children: [
                    if (p.prefix.isNotEmpty)
                      TextSpan(
                        text: '${p.prefix}  ',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    TextSpan(text: p.name),
                  ],
                ),
                style: TextStyle(
                  fontSize: 16,
                  color: checked ? AppColors.inkMuted : AppColors.ink,
                  decoration: checked ? TextDecoration.lineThrough : null,
                ),
              ),
            ),
            if (inPantry != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: inPantry ? AppColors.sageBg : AppColors.terracottaBg,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  inPantry ? 'En casa' : 'Falta',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: inPantry ? AppColors.sage : AppColors.terracotta,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _stepsTab(List<String> steps) {
    if (steps.isEmpty) {
      return Text(
        'Esta receta no tiene pasos. Puedes añadirlos editándola.',
        style: AppTextStyles.bodyMuted,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [for (var i = 0; i < steps.length; i++) _stepRow(i, steps[i])],
    );
  }

  Widget _stepRow(int i, String step) {
    final done = _doneSteps.contains(i);
    final minutes = stepTimerMinutes(step);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: done ? AppColors.card.withValues(alpha: 0.5) : AppColors.card,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => done ? _doneSteps.remove(i) : _doneSteps.add(i));
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 30,
                  height: 30,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: done ? AppColors.sage : AppColors.ink,
                    shape: BoxShape.circle,
                  ),
                  child: done
                      ? Icon(
                          Icons.check_rounded,
                          size: 18,
                          color: done ? Colors.white : AppColors.cream,
                        )
                      : Text(
                          '${i + 1}',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            color: AppColors.cream,
                          ),
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        step,
                        style: TextStyle(
                          fontSize: 16,
                          height: 1.4,
                          color: done ? AppColors.inkMuted : AppColors.ink,
                          decoration: done ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      if (minutes != null && !done)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Row(
                            children: [
                              Icon(
                                Icons.timer_outlined,
                                size: 15,
                                color: AppColors.woodDark,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '$minutes min',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.woodDark,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _nutritionTab(Recipe r) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Por ración',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 12),
              if (r.calories != null || r.protein != null)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    if (r.calories != null) _macro('${r.calories}', 'kcal'),
                    if (r.protein != null)
                      _macro('${r.protein!.toStringAsFixed(0)}g', 'Proteína'),
                    if (r.carbs != null)
                      _macro('${r.carbs!.toStringAsFixed(0)}g', 'Carbos'),
                    if (r.fat != null)
                      _macro('${r.fat!.toStringAsFixed(0)}g', 'Grasa'),
                  ],
                )
              else
                Text('Sin datos de nutrición.', style: AppTextStyles.bodyMuted),
              if (r.kcalPer100g != null)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(
                    '${r.kcalPer100g!.toStringAsFixed(0)} kcal / 100 g',
                    style: TextStyle(color: AppColors.inkMuted, fontSize: 12),
                  ),
                ),
              if (_cost != null) ...[
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(Icons.euro_rounded, size: 18, color: AppColors.sage),
                    const SizedBox(width: 8),
                    Text(
                      '${_cost!.perServing.toStringAsFixed(2).replaceAll('.', ',')} € por ración',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '≈ ${_cost!.total.toStringAsFixed(2).replaceAll('.', ',')} € total',
                      style: TextStyle(fontSize: 12, color: AppColors.inkMuted),
                    ),
                  ],
                ),
                if (_cost!.approx)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Coste aproximado. Escanea tickets para afinarlo con '
                      'tus precios reales.',
                      style: TextStyle(fontSize: 11, color: AppColors.inkMuted),
                    ),
                  ),
              ],
            ],
          ),
        ),
        if (r.kcalPer100g != null) ...[
          const SizedBox(height: 16),
          _autoTaperCard(r),
        ],
      ],
    );
  }

  /// Barra fija de abajo: el gran botón para cocinar paso a paso.
  Widget _cookBar(Recipe r, List<String> steps) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
        child: SizedBox(
          height: 56,
          child: FilledButton.icon(
            onPressed: () async {
              final ings = await _ingredientsFuture;
              if (!mounted) return;
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => CookModeScreen(
                    title: r.title,
                    steps: [for (final s in steps) CookStep.fromText(s)],
                    ingredients: [for (final i in ings) _ingredientLine(i)],
                  ),
                ),
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.ink,
              foregroundColor: AppColors.cream,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
              textStyle: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            icon: const Icon(Icons.soup_kitchen_rounded),
            label: const Text('Empezar a cocinar'),
          ),
        ),
      ),
    );
  }

  /// Despensa del hogar para marcar los ingredientes que ya hay.
  Future<void> _loadPantry() async {
    try {
      final rows = await _client
          .from('inventory_items')
          .select()
          .eq('home_id', _recipe.homeId);
      final items = (rows as List)
          .map((r) => InventoryItem.fromMap(Map<String, dynamic>.from(r)))
          .toList();
      if (mounted)
        setState(() => _pantry = pantryNamesForIdeas(items, max: 1000));
    } catch (_) {
      // Sin despensa no se marca nada.
    }
  }

  /// Manda a la lista de la compra los ingredientes que faltan.
  Future<void> _addMissing(List<String> missing) async {
    setState(() => _addingMissing = true);
    try {
      await _client.from('shopping_list_items').insert([
        for (final name in missing)
          ShoppingListItem(
            homeId: _recipe.homeId,
            name: name,
            category: defaultCategoryFor(name),
          ).toInsertMap(),
      ]);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            missing.length == 1
                ? 'Añadido a la lista de la compra'
                : 'Añadidos ${missing.length} productos a la compra',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(friendlyError(e, 'No se pudo añadir'))),
      );
    } finally {
      if (mounted) setState(() => _addingMissing = false);
    }
  }

  /// Muestra, para cada miembro del hogar (con perfil), cuántos gramos y kcal
  /// le corresponden de este plato según su perfil. Si el plato tiene
  /// componentes (pollo + arroz...), desglosa los gramos por componente.
  Widget _autoTaperCard(Recipe r) {
    if (_profiles.isEmpty) {
      return _card(
        child: Text(
          'Completa un Perfil Nutricional para ver cuántos gramos y calorías '
          'corresponden a cada persona.',
          style: TextStyle(color: AppColors.inkMuted),
        ),
      );
    }

    final today = DateTime.now().weekday; // 1=Lun..7=Dom
    final rows = <Widget>[];
    for (final p in _profiles) {
      // Si ese miembro come FUERA hoy en todos los tipos de esta receta, se salta.
      final eatsHome = r.mealTypes.any((t) => p.eatsAtHome(t, today));
      if (!eatsHome) continue;

      final kcal = p.caloriesForMealTypes(r.mealTypes);
      if (kcal == null) continue;
      final grams = r.gramsForCalories(kcal);
      if (grams == null) continue;
      final name = (p.fullName?.trim().isNotEmpty == true)
          ? p.fullName!.trim()
          : 'Miembro';

      rows.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Text(
                    '${grams.toStringAsFixed(0)} g · $kcal kcal',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.woodDark,
                    ),
                  ),
                ],
              ),
              // Desglose por componentes del plato (pollo + arroz...)
              if (r.hasComponents) ...[
                const SizedBox(height: 4),
                ...r.components.map(
                  (c) => Padding(
                    padding: const EdgeInsets.only(left: 4, top: 2),
                    child: Text(
                      '· ${c.name}: ${c.gramsFromTotal(grams).toStringAsFixed(0)} g',
                      style: TextStyle(color: AppColors.inkMuted, fontSize: 13),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    if (rows.isEmpty) {
      return _card(
        child: Text(
          'Ajusta el reparto de calorías por comida en el perfil para este tipo '
          'de receta.',
          style: TextStyle(color: AppColors.inkMuted),
        ),
      );
    }

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Según el perfil de cada uno',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 4),
          Text(
            'Cantidad y calorías por persona para esta comida.',
            style: TextStyle(color: AppColors.inkMuted, fontSize: 13),
          ),
          const Divider(height: 20),
          ...rows,
        ],
      ),
    );
  }

  Widget _macro(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: AppColors.ink,
          ),
        ),
        Text(label, style: TextStyle(color: AppColors.inkMuted, fontSize: 12)),
      ],
    );
  }

  Widget _card({
    required Widget child,
    EdgeInsets padding = const EdgeInsets.all(20),
  }) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: AppTheme.surfaceDecoration(),
      child: child,
    );
  }
}
