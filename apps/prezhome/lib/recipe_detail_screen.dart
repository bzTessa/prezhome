import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import 'utils/money.dart';

import 'add_recipe_screen.dart';
import 'cook_mode_screen.dart';
import 'services/home_food_restrictions.dart';
import 'services/offline_provider.dart';
import 'services/pantry_usage.dart';
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
import 'theme/app_theme.dart';
import 'widgets/post_cook_sheet.dart';
import 'widgets/recipe_chip.dart';
import 'widgets/recipe_image.dart';
import 'utils/friendly_error.dart';
import 'utils/pantry_ideas.dart';
import 'utils/recipe_steps.dart';
import 'utils/shopping_categories.dart';
import 'widgets/list_skeleton.dart';
import 'l10n/l10n.dart';

class RecipeDetailScreen extends StatefulWidget {
  final Recipe recipe;
  final String? heroTag;
  const RecipeDetailScreen({super.key, required this.recipe, this.heroTag});

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
  RecipeCost? _cost; // coste estimado de la receta (precio real o aproximado)
  List<NutritionProfile> _profiles =
      []; // miembros del hogar con perfil visible

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

  /// Ingredientes que faltaban y ya se han mandado a la lista de la compra.
  final Set<String> _inList = {};
  List<String> _shoppingNames = const [];
  bool _addingMissing = false;
  bool _finishingCook = false;

  int get _recipeServings => _recipe.servings < 1 ? 1 : _recipe.servings;

  /// Se abre con las raciones que come tu hogar (si se saben); el conversor
  /// deja volver a las de la receta.
  int get _servingsNow =>
      _servings ??
      _householdServings(_recipe)?.round().clamp(1, 99) ??
      _recipeServings;

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
    _loadCost();
    _loadPantry();
    _loadShopping();
    _loadRestrictions();
  }

  /// Alergia o dieta de casa con la que choca la receta (null si ninguna).
  String? _blocker;

  Future<void> _loadRestrictions() async {
    try {
      final limits = await HomeFoodRestrictions.load(_client);
      if (limits.isEmpty) return;
      final ings = await _ingredientsFuture;
      final b = limits.blockerIn([_recipe.title, for (final i in ings) i.name]);
      if (mounted) setState(() => _blocker = b);
    } catch (_) {
      // Sin aviso si falla.
    }
  }

  Widget _blockerBanner(String b) {
    final isDiet = const {'vegetariana', 'vegana', 'pescetariana'}.contains(b);
    final text = isDiet
        ? context.l.rdDietWarn(b)
        : context.l.rdAllergyWarn(
            const {
                  'gluten',
                  'lactosa',
                  'huevo',
                  'frutos secos',
                  'marisco',
                  'soja',
                  'pescado',
                }.contains(b)
                ? context.l.pwAllergy(b.replaceAll(' ', ''))
                : b,
          );
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.expiredBg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: AppColors.expired),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: AppColors.ink,
                fontWeight: FontWeight.w600,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
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
          content: Text(friendlyError(e, context.l.couldNotUpdate)),
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
                context.l.rdPhoto,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: AppColors.ink,
                ),
              ),
            ),
            ListTile(
              leading: Icon(Icons.image_search, color: AppColors.woodDark),
              title: Text(context.l.rdAutoPhoto),
              subtitle: Text(context.l.rdAutoPhotoHint),
              onTap: () => Navigator.of(ctx).pop('regenerate'),
            ),
            ListTile(
              leading: Icon(
                Icons.photo_library_outlined,
                color: AppColors.woodDark,
              ),
              title: Text(context.l.rdGallery),
              onTap: () => Navigator.of(ctx).pop('gallery'),
            ),
            if (_recipe.imageUrl != null)
              ListTile(
                leading: Icon(
                  Icons.hide_image_outlined,
                  color: AppColors.woodDark,
                ),
                title: Text(context.l.rdRemovePhoto),
                subtitle: Text(context.l.rdRemovePhotoHint),
                onTap: () => Navigator.of(ctx).pop('remove'),
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
    } else if (action == 'remove') {
      await _removePhoto();
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
      final ings = await _ingredientsFuture.catchError((_) => <Ingredient>[]);
      final url = await RecipePhotoService(_client).find(
        title: _recipe.title,
        description: _recipe.description,
        ingredients: [for (final i in ings) i.name],
        exclude: _seenPhotoUrls,
      );
      if (url != null) _seenPhotoUrls.add(url);
      if (!mounted) return;
      if (url == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.l.rdNoBetterPhoto)));
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
            content: Text(friendlyError(e, context.l.couldNotChangePhoto)),
            backgroundColor: AppColors.expired,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _changingPhoto = false);
    }
  }

  /// Quita la foto (automática o subida): la receta vuelve a su dibujo.
  Future<void> _removePhoto() async {
    setState(() => _changingPhoto = true);
    try {
      await _client
          .from('recipes')
          .update({'image_url': null, 'image_path': null})
          .eq('id', _recipe.id);
      await _refreshRecipe();
      _changed = true;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(friendlyError(e, context.l.couldNotChangePhoto)),
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
            content: Text(friendlyError(e, context.l.rdUploadError)),
            backgroundColor: AppColors.expired,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _changingPhoto = false);
    }
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
    final l = context.l;
    try {
      final code = await RecipeShare(_client).share(_recipe.id);
      await SharePlus.instance.share(
        ShareParams(
          text: l.rdShareText(_recipe.title, code),
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
        title: Text(context.l.recDeleteAsk),
        content: Text(context.l.recRemoveAsk(_recipe.title)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(context.l.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.expired,
              foregroundColor: AppColors.onTerracotta,
              elevation: 0,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(context.l.delete),
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
            content: Text(friendlyError(e, context.l.couldNotDelete)),
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

  /// Al terminar de cocinar (desde el modo paso a paso o directamente con
  /// "Ya lo cociné"), descuenta ingredientes de En casa y guarda tápers.
  Future<void> _finishCooking() async {
    if (_finishingCook) return;
    _finishingCook = true;
    try {
      final ings = await _ingredientsFuture;
      final uses = await PantryUsage.previewForRecipe(
        ingredients: ings,
        factor: _servingsFactor,
        client: _client,
        homeId: _recipe.homeId,
      );
      if (!mounted) return;
      final choice = await showPostCookSheet(
        context,
        recipe: _recipe,
        servingsCooked: _servingsNow,
        uses: uses,
      );
      if (!mounted || choice == null) return;
      final usesToDeduct = choice.deductPantry ? uses : const <PantryUse>[];
      if (usesToDeduct.isEmpty &&
          choice.fridgeServings == 0 &&
          choice.freezerServings == 0) {
        return;
      }
      final result = await PantryUsage.completeCook(
        recipe: _recipe,
        usesToDeduct: usesToDeduct,
        fridgeServings: choice.fridgeServings,
        freezerServings: choice.freezerServings,
        client: _client,
        homeId: _recipe.homeId,
      );
      if (!mounted || !result.hasAnyChange) return;
      _changed = true;
      HapticFeedback.mediumImpact();
      await _reloadPantry();
      if (!mounted) return;
      final l = context.l;
      final parts = [
        if (result.deductedUses.isNotEmpty)
          l.pcSummaryDeducted(result.deductedUses.length),
        if (choice.fridgeServings > 0) l.pcSummaryFridge(choice.fridgeServings),
        if (choice.freezerServings > 0)
          l.pcSummaryFreezer(choice.freezerServings),
      ];
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(parts.join(' · ')),
            duration: const Duration(seconds: 6),
            persist: false,
            action: SnackBarAction(
              label: l.undo,
              onPressed: () async {
                await PantryUsage.undoCompleteCook(result, client: _client);
                await _reloadPantry();
                if (!mounted) return;
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(context.l.pcUndone)));
              },
            ),
          ),
        );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(friendlyError(e, context.l.couldNotSave)),
          backgroundColor: AppColors.expired,
        ),
      );
    } finally {
      _finishingCook = false;
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
            content: Text(context.l.rdVideoError),
            backgroundColor: AppColors.expired,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l.rdVideoError),
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
        bottomNavigationBar: _cookBar(r, steps),
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
                  tooltip: context.l.back,
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
                      ? context.l.recUnfavorite
                      : context.l.recFavorite,
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
                    if (widget.heroTag != null)
                      Hero(
                        tag: widget.heroTag!,
                        child: RecipeImage(recipe: r, height: 360, radius: 0),
                      )
                    else
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
                    // Como en el concepto: una línea pequeña con el tipo,
                    // el tiempo y las calorías encima del título, en vez de
                    // las tres baldosas.
                    if (_kicker(r) case final k?) ...[
                      Text(
                        k.toUpperCase(),
                        style: AppTextStyles.label.copyWith(
                          color: AppColors.terracottaText,
                        ),
                      ),
                      const SizedBox(height: 6),
                    ],
                    Text(
                      r.title,
                      style: AppTextStyles.display.copyWith(fontSize: 26),
                    ),
                    if (r.description != null &&
                        r.description!.trim().isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        r.description!,
                        style: AppTextStyles.bodyMuted.copyWith(height: 1.35),
                      ),
                    ],
                    if (_blocker != null) _blockerBanner(_blocker!),
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
                        label: Text(context.l.rdWatchVideo),
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
          tooltip: context.l.moreOptions,
          icon: Icon(Icons.more_horiz_rounded, color: AppColors.ink),
          padding: EdgeInsets.zero,
          onSelected: (v) {
            switch (v) {
              case 'cooked':
                _finishCooking();
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
              value: 'cooked',
              child: ListTile(
                leading: const Icon(Icons.check_circle_outline_rounded),
                title: Text(context.l.rdCookedIt),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            PopupMenuItem(
              value: 'photo',
              child: ListTile(
                leading: Icon(Icons.photo_camera_outlined),
                title: Text(context.l.changePhoto),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            PopupMenuItem(
              value: 'share',
              child: ListTile(
                leading: Icon(Icons.ios_share_rounded),
                title: Text(context.l.share),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            PopupMenuItem(
              value: 'edit',
              child: ListTile(
                leading: Icon(Icons.edit_outlined),
                title: Text(context.l.rdEdit),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            PopupMenuItem(
              value: 'delete',
              child: ListTile(
                leading: Icon(Icons.delete_outline, color: AppColors.expired),
                title: Text(context.l.delete),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Tres datos clave de un vistazo: tiempo, calorías y coste por ración.
  /// "35 min · 560 kcal · 2,10 € por ración" (lo que se sepa).
  String? _kicker(Recipe r) {
    final parts = [
      if (r.totalTimeMinutes case final m?) '$m min',
      if (r.calories case final c?) '$c kcal',
      if (_cost case final c?)
        '${money(c.perServing)} ${context.l.rdPerServingShort}',
    ];
    return parts.isEmpty ? null : parts.join(' · ');
  }

  Widget _tagsWrap(Recipe r) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final type in r.mealTypes)
          RecipeChip(
            text: context.l.mealType(type),
            icon: mealTypeIcon(type),
            style: RecipeChipStyle.type,
          ),
        if (r.appliance != 'none')
          RecipeChip(
            text: context.l.appliance(r.appliance),
            icon: Icons.kitchen_rounded,
            style: RecipeChipStyle.type,
          ),
        if (r.freezesWell)
          RecipeChip(
            text: context.l.rdFreezable,
            icon: Icons.ac_unit,
            style: RecipeChipStyle.freezer,
          ),
      ],
    );
  }

  /// Selector de sección (Ingredientes · Pasos · Nutrición): menos scroll y
  /// cada cosa en su sitio, como en las apps de recetas más usadas.
  Widget _sectionTabs(int stepCount) {
    final labels = [
      context.l.rdIngredients,
      stepCount == 0 ? context.l.rdStepsWord : context.l.rdSteps(stepCount),
      context.l.rdNutrition,
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

  String _servingsText(int n) => context.l.planServings(n);

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
              Text(context.l.rdNoIngredients, style: AppTextStyles.bodyMuted)
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
                      context.l.diaServings,
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
                tooltip: context.l.less,
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
                tooltip: context.l.more,
                icon: const Icon(Icons.add_circle_outline_rounded),
                onPressed: _servingsNow < 99
                    ? () => setState(() => _servings = _servingsNow + 1)
                    : null,
              ),
            ],
          ),
          _servingsHints(r),
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
            label: Text(context.l.rdOriginal(_servingsText(_recipeServings))),
            onPressed: () => setState(() => _servings = _recipeServings),
          ),
        if (perMeal != null && perMeal >= 1 && perMeal != _servingsNow)
          ActionChip(
            label: Text(context.l.rdForHome(_servingsText(perMeal))),
            onPressed: () => setState(() => _servings = perMeal),
          ),
      ],
    );
  }

  /// "Tienes 5 de 8 en casa" + atajo para mandar lo que falta a la compra.
  Widget _pantrySummary(int haveCount, List<String> missing) {
    final total = haveCount + missing.length;
    final toAdd = [
      for (final m in missing)
        if (!_isInList(m)) m,
    ];
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
                  ? context.l.rdHaveAll
                  : context.l.rdHaveSome(haveCount, total),
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
              ),
            ),
          ),
          // Solo lo que falta y aún no está en la lista de la compra.
          if (toAdd.isNotEmpty)
            TextButton.icon(
              onPressed: _addingMissing ? null : () => _addMissing(toAdd),
              icon: const Icon(Icons.add_shopping_cart_rounded, size: 18),
              label: Text(context.l.rdMissing(toAdd.length)),
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
                      color: AppColors.onTerracotta,
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
            if (inPantry == true)
              _pill(context.l.rdAtHome, AppColors.sageBg, AppColors.sage)
            else if (inPantry == false && _isInList(ing.name))
              _pill(context.l.rdInList, AppColors.line, AppColors.inkMuted)
            else if (inPantry == false)
              // Lo que falta se manda a la compra con un toque.
              InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: _addingMissing
                    ? null
                    : () => _addMissing([ing.name.trim()]),
                child: _pill(
                  context.l.rdToShopping,
                  AppColors.terracottaBg,
                  AppColors.terracotta,
                  icon: Icons.add_rounded,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _pill(String text, Color bg, Color fg, {IconData? icon}) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(999),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) Icon(icon, size: 14, color: fg),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: fg,
          ),
        ),
      ],
    ),
  );

  Widget _stepsTab(List<String> steps) {
    if (steps.isEmpty) {
      return Text(context.l.rdNoSteps, style: AppTextStyles.bodyMuted);
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
                          color: AppColors.onTerracotta,
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
              Text(
                context.l.rdPerServingTitle,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 12),
              if (r.calories != null || r.protein != null)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    if (r.calories != null) _macro('${r.calories}', 'kcal'),
                    if (r.protein != null)
                      _macro(
                        '${r.protein!.toStringAsFixed(0)}g',
                        context.l.diaProtein,
                      ),
                    if (r.carbs != null)
                      _macro(
                        '${r.carbs!.toStringAsFixed(0)}g',
                        context.l.diaCarbs,
                      ),
                    if (r.fat != null)
                      _macro('${r.fat!.toStringAsFixed(0)}g', context.l.diaFat),
                  ],
                )
              else
                Text(context.l.rdNoNutrition, style: AppTextStyles.bodyMuted),
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
                      context.l.rdPerServing(money(_cost!.perServing)),
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      context.l.rdTotal(money(_cost!.total)),
                      style: TextStyle(fontSize: 12, color: AppColors.inkMuted),
                    ),
                  ],
                ),
                if (_cost!.approx)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      context.l.rdApproxCost,
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

  /// Barra fija de abajo: paso a paso + acceso directo "Ya lo cociné".
  Widget _cookBar(Recipe r, List<String> steps) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
        child: steps.isEmpty
            ? SizedBox(
                height: 56,
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _finishCooking,
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
                  icon: const Icon(Icons.check_circle_outline_rounded),
                  label: Text(context.l.rdCookedIt),
                ),
              )
            : Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 56,
                      child: FilledButton.icon(
                        onPressed: () async {
                          final ings = await _ingredientsFuture;
                          if (!mounted) return;
                          final done = await Navigator.of(context).push<bool>(
                            MaterialPageRoute(
                              builder: (_) => CookModeScreen(
                                title: r.title,
                                steps: [
                                  for (final s in steps) CookStep.fromText(s),
                                ],
                                ingredients: [
                                  for (final i in ings) _ingredientLine(i),
                                ],
                              ),
                            ),
                          );
                          if (done == true && mounted) await _finishCooking();
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.ink,
                          foregroundColor: AppColors.cream,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        icon: const Icon(Icons.soup_kitchen_rounded),
                        label: Text(
                          context.l.rdStartCooking,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Tooltip(
                    message: context.l.rdCookedIt,
                    child: SizedBox(
                      height: 56,
                      child: OutlinedButton.icon(
                        onPressed: _finishCooking,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.ink,
                          backgroundColor: AppColors.card,
                          side: BorderSide(color: AppColors.stroke, width: 1.4),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          textStyle: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        icon: const Icon(
                          Icons.check_circle_outline_rounded,
                          size: 20,
                        ),
                        label: Text(context.l.rdCookedShort),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  /// Refresca la despensa local desde la caché optimista tras cocinar.
  Future<void> _reloadPantry() async {
    try {
      final cached = await OfflineProvider.instance.inventory.readCached();
      final items = cached.map(InventoryItem.fromMap).toList();
      if (mounted) {
        setState(() => _pantry = pantryNamesForIdeas(items, max: 1000));
      }
      return;
    } catch (_) {}
    await _loadPantry();
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

  /// Lo que ya está en la lista de la compra: esos ingredientes dicen "En la
  /// lista" en vez de ofrecer "+ A la compra" otra vez.
  Future<void> _loadShopping() async {
    try {
      final rows = await _client
          .from('shopping_list_items')
          .select('name')
          .eq('home_id', _recipe.homeId)
          .eq('checked', false);
      final names = [for (final r in rows as List) '${r['name'] ?? ''}'];
      if (mounted) setState(() => _shoppingNames = names);
    } catch (_) {
      // Sin lista, se ofrece añadir como siempre.
    }
  }

  bool _isInList(String ingredient) {
    final name = ingredient.trim();
    return _inList.contains(name) ||
        _shoppingNames.any((s) => pantryNameMatches(name, s));
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
      setState(() => _inList.addAll(missing));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l.rdAddedMissing(missing.length))),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(friendlyError(e, context.l.couldNotAdd))),
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
          context.l.rdNeedProfile,
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
          : context.l.rdMember;

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
          context.l.rdAdjustSplit,
          style: TextStyle(color: AppColors.inkMuted),
        ),
      );
    }

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l.rdByProfile,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 4),
          Text(
            context.l.rdByProfileHint,
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
