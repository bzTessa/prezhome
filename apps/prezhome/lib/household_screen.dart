import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'economy_screen.dart';
import 'models/dashboard_prefs.dart';
import 'models/supermarket.dart';
import 'services/home_invites.dart';
import 'services/offline_provider.dart';
import 'nutrition_profile_screen.dart';
import 'home_session_screen.dart';
import 'login_screen.dart';
import 'theme/app_theme.dart';
import 'widgets/miau_character.dart';
import 'utils/friendly_error.dart';

class HouseholdScreen extends StatefulWidget {
  const HouseholdScreen({super.key});

  @override
  State<HouseholdScreen> createState() => _HouseholdScreenState();
}

class _HouseholdScreenState extends State<HouseholdScreen> {
  final SupabaseClient _client = Supabase.instance.client;
  late Future<_HouseholdData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  void _reload() {
    final future = _load();
    setState(() {
      _future = future;
    });
  }

  Future<_HouseholdData> _load() async {
    final user = _client.auth.currentUser;
    if (user == null) throw 'No autenticado';

    final profile = await _client
        .from('profiles')
        .select('home_id')
        .eq('id', user.id)
        .maybeSingle();
    final homeId = profile?['home_id'] as String?;

    // Preferencias del hogar: deciden si el "Modo Puntos" (acceso a Economía)
    // está visible. Mismo patrón tolerante que HomeTab._loadPrefs.
    final prefsRow = await _client
        .from('profiles')
        .select('dashboard_prefs')
        .eq('id', user.id)
        .maybeSingle();
    final rawPrefs = prefsRow?['dashboard_prefs'];
    final prefs = rawPrefs is Map
        ? DashboardPrefs.fromJson(Map<String, dynamic>.from(rawPrefs))
        : DashboardPrefs.defaults();
    final pointsEnabled = prefs.isModuleEnabled(HomeModule.points);

    if (homeId == null || homeId.isEmpty) {
      return _HouseholdData(homeId: null, pointsEnabled: pointsEnabled);
    }

    final home = await _client
        .from('homes')
        .select('id, name, supermarkets')
        .eq('id', homeId)
        .maybeSingle();

    // Miembros del hogar (no hay FK directa home_members->profiles, así que
    // hacemos dos consultas y las cruzamos en memoria por user_id).
    final membersRes = await _client
        .from('home_members')
        .select('user_id, role')
        .eq('home_id', homeId);

    final profilesRes = await _client
        .from('profiles')
        .select('id, full_name')
        .eq('home_id', homeId);

    final nameById = <String, String?>{
      for (final p in (profilesRes as List))
        p['id'] as String: p['full_name'] as String?,
    };

    final members = (membersRes as List).map((m) {
      final uid = m['user_id'] as String;
      return _Member(
        userId: uid,
        role: (m['role'] as String?) ?? 'member',
        name: nameById[uid],
        isMe: uid == user.id,
      );
    }).toList();

    HomeInvite? invite;
    try {
      invite = await HomeInvites(_client).current(homeId);
    } catch (_) {
      invite = null;
    }

    final rawSupers = home?['supermarkets'];
    final supermarkets = rawSupers is List
        ? rawSupers.map((e) => e.toString()).toList()
        : <String>[];

    return _HouseholdData(
      homeId: homeId,
      homeName: (home?['name'] as String?) ?? 'Mi Hogar',
      members: members,
      supermarkets: supermarkets,
      pointsEnabled: pointsEnabled,
      invite: invite,
    );
  }

  Future<void> _createHome() async {
    try {
      await _client.rpc('create_home_and_join');
      _reload();
    } catch (e) {
      _snack(friendlyError(e, 'No se pudo crear el hogar'), error: true);
    }
  }

  Future<void> _joinHome() async {
    final controller = TextEditingController();
    final code = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unirme a un hogar'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(
            labelText: 'Código de invitación',
            hintText: 'ABCD-EFGH',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('Unirme'),
          ),
        ],
      ),
    );
    if (code == null || code.trim().isEmpty) return;
    if (!looksLikeInviteCode(code)) {
      _snack('El código tiene 8 letras y números', error: true);
      return;
    }
    try {
      await HomeInvites(_client).join(normalizeInviteCode(code));
      // Hogar nuevo: la caché local del anterior no debe mezclarse.
      await OfflineProvider.instance.clearForLogout();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeSessionScreen()),
        (_) => false,
      );
    } catch (e) {
      _snack(friendlyError(e, 'Código no válido o caducado'), error: true);
    }
  }

  Future<void> _newInvite() async {
    try {
      await HomeInvites(_client).create();
      _reload();
    } catch (e) {
      _snack(friendlyError(e, 'No se pudo crear el código'), error: true);
    }
  }

  Future<void> _removeMember(_Member m) async {
    final name = (m.name?.isNotEmpty ?? false) ? m.name! : 'este miembro';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('¿Quitar a $name del hogar?'),
        content: const Text('Dejará de ver la compra, la despensa y el plan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.expired),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Quitar'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await HomeInvites(_client).removeMember(m.userId);
      _reload();
    } catch (e) {
      _snack(friendlyError(e, 'No se pudo quitar'), error: true);
    }
  }

  Future<void> _leaveHome() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Salir del hogar?'),
        content: const Text(
          'Dejarás de ver sus datos. Para volver necesitarás un código nuevo.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.expired),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Salir'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await HomeInvites(_client).leave();
      await OfflineProvider.instance.clearForLogout();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeSessionScreen()),
        (_) => false,
      );
    } catch (e) {
      _snack(friendlyError(e, 'No se pudo salir del hogar'), error: true);
    }
  }

  Future<void> _renameHome(String homeId, String current) async {
    final controller = TextEditingController(text: current);
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cream,
        title: const Text('Nombre del hogar'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.wood,
              foregroundColor: AppColors.ink,
              elevation: 0,
            ),
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    if (name == null || name.isEmpty) return;
    try {
      await _client.from('homes').update({'name': name}).eq('id', homeId);
      _reload();
    } catch (e) {
      _snack(friendlyError(e, 'No se pudo renombrar'), error: true);
    }
  }

  Future<void> _logout() async {
    await _client.auth.signOut();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
    }
  }

  void _snack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: error ? AppColors.expired : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: const Text(
          'Mi Hogar',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.cream,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: _logout,
          ),
        ],
      ),
      body: FutureBuilder<_HouseholdData>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(friendlyError(snapshot.error)),
              ),
            );
          }
          final data = snapshot.data!;
          return data.homeId == null ? _buildNoHome() : _buildHome(data);
        },
      ),
    );
  }

  Widget _buildNoHome() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const MiauCharacter(mood: MiauMood.curious, size: 110),
            const SizedBox(height: 16),
            const Text(
              'Aún no perteneces a ningún hogar.',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.wood,
                foregroundColor: AppColors.ink,
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              onPressed: _createHome,
              child: const Text('Crear un hogar nuevo'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.ink,
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: _joinHome,
              child: const Text('Unirme a un hogar existente'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHome(_HouseholdData data) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        // Cabecera cozy: Miau saluda y presenta el hogar.
        Container(
          padding: const EdgeInsets.all(16),
          decoration: AppTheme.cardDecoration(),
          child: Row(
            children: [
              const MiauCharacter(mood: MiauMood.greeting, size: 64),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            data.homeName!,
                            style: const TextStyle(
                              fontSize: 22,
                              letterSpacing: -0.4,
                              fontWeight: FontWeight.bold,
                              color: AppColors.ink,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.edit,
                            size: 20,
                            color: AppColors.woodDark,
                          ),
                          tooltip: 'Renombrar hogar',
                          onPressed: () =>
                              _renameHome(data.homeId!, data.homeName!),
                        ),
                      ],
                    ),
                    Text(
                      data.members.length == 1
                          ? 'Tu hogar, de momento para ti.'
                          : 'Un hogar de ${data.members.length} personas.',
                      style: TextStyle(color: AppColors.inkMuted, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _inviteCard(data),
        const SizedBox(height: 16),
        _supermarketsCard(data),
        const SizedBox(height: 16),
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Miembros (${data.members.length})',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              ...data.members.map((m) {
                final displayName = (m.name != null && m.name!.isNotEmpty)
                    ? m.name!
                    : 'Miembro';
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: _memberAvatar(displayName),
                  title: Text(
                    displayName,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    m.role == 'owner' ? 'Administrador' : 'Miembro',
                  ),
                  trailing: !m.isMe && data.iAmOwner
                      ? IconButton(
                          tooltip: 'Quitar del hogar',
                          icon: const Icon(
                            Icons.person_remove_outlined,
                            color: AppColors.inkMuted,
                          ),
                          onPressed: () => _removeMember(m),
                        )
                      : m.isMe
                      ? Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.wood,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Tú',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.ink,
                              fontSize: 12,
                            ),
                          ),
                        )
                      : null,
                );
              }),
              const SizedBox(height: 4),
              TextButton.icon(
                onPressed: _leaveHome,
                icon: const Icon(Icons.logout_rounded, size: 18),
                label: const Text('Salir del hogar'),
                style: TextButton.styleFrom(foregroundColor: AppColors.expired),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Accesos agrupados en Hogar/Ajustes: economía del hogar, perfil
        // nutricional y cuestionario guiado. Economía dejó de ser una pestaña
        // propia y vive ahora aquí.
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Hogar y ajustes',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 4),
              // Economía (presupuesto/gastos + puntos) es la pieza ligada al
              // "Modo Puntos": solo se muestra si el módulo está activado. El
              // resto de la tarjeta (Mi perfil nutricional, etc.) permanece.
              if (data.pointsEnabled)
                _settingTile(
                  icon: Icons.savings_outlined,
                  title: 'Economía',
                  subtitle: 'Presupuesto y gastos del hogar',
                  iconBg: AppColors.sageBg,
                  iconFg: AppColors.sage,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const EconomyScreen()),
                  ),
                ),
              _settingTile(
                icon: Icons.favorite_outline,
                title: 'Mi perfil nutricional',
                subtitle: 'Objetivo de calorías, preferencias y asistente',
                iconBg: AppColors.terracottaBg,
                iconFg: AppColors.terracotta,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const NutritionProfileScreen(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Tarjeta de supermercados del hogar: chips de los elegidos (o un texto si
  /// no hay ninguno) y un botón para editarlos.
  /// Invitar: código corto que caduca. Uno nuevo anula el anterior.
  Widget _inviteCard(_HouseholdData data) {
    final invite = data.invite;
    const months = [
      'ene',
      'feb',
      'mar',
      'abr',
      'may',
      'jun',
      'jul',
      'ago',
      'sep',
      'oct',
      'nov',
      'dic',
    ];
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Invitar a alguien',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
          const SizedBox(height: 12),
          if (invite == null)
            FilledButton.icon(
              onPressed: _newInvite,
              icon: const Icon(Icons.person_add_alt_1_rounded, size: 20),
              label: const Text('Crear código'),
            )
          else ...[
            Row(
              children: [
                Expanded(
                  child: SelectableText(
                    formatInviteCode(invite.code),
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Copiar',
                  icon: const Icon(
                    Icons.copy_rounded,
                    color: AppColors.woodDark,
                  ),
                  onPressed: () {
                    Clipboard.setData(
                      ClipboardData(text: formatInviteCode(invite.code)),
                    );
                    _snack('Código copiado');
                  },
                ),
              ],
            ),
            Text(
              'Vale hasta el ${invite.expiresAt.day} '
              '${months[invite.expiresAt.month - 1]}',
              style: const TextStyle(color: AppColors.inkMuted, fontSize: 13),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _newInvite,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Nuevo código'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _supermarketsCard(_HouseholdData data) {
    final labels = Supermarket.labelsFor(data.supermarkets);
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.sageBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.storefront_outlined,
                  color: AppColors.sage,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Supermercados',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              TextButton(
                onPressed: () => _editSupermarkets(data),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.woodDark,
                ),
                child: Text(labels.isEmpty ? 'Elegir' : 'Editar'),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Las recetas se adaptarán a lo que haya en tus súper. Es opcional.',
            style: TextStyle(color: AppColors.inkMuted, fontSize: 13),
          ),
          const SizedBox(height: 10),
          if (labels.isEmpty)
            Text(
              'Sin supermercado elegido.',
              style: TextStyle(color: AppColors.inkMuted, fontSize: 13),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: labels
                  .map(
                    (l) => Chip(
                      label: Text(l),
                      backgroundColor: AppColors.sageBg,
                      side: BorderSide.none,
                      labelStyle: const TextStyle(
                        color: AppColors.sage,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }

  /// Bottom sheet para elegir uno o varios supermercados (opcional). Guarda la
  /// selección en homes.supermarkets. Cualquier miembro del hogar puede
  /// editarla (igual que el nombre del hogar).
  Future<void> _editSupermarkets(_HouseholdData data) async {
    final selected = {...data.supermarkets};
    final result = await showModalBottomSheet<List<String>>(
      context: context,
      backgroundColor: AppColors.cream,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '¿Dónde compráis?',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 4),
                Text(
                  'Puedes elegir varios. Es opcional.',
                  style: TextStyle(color: AppColors.inkMuted, fontSize: 13),
                ),
                const SizedBox(height: 8),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: Supermarket.all.map((s) {
                      final isSel = selected.contains(s.key);
                      return CheckboxListTile(
                        value: isSel,
                        activeColor: AppColors.woodDark,
                        contentPadding: EdgeInsets.zero,
                        title: Text(s.label),
                        onChanged: (v) => setSheet(() {
                          if (v == true) {
                            selected.add(s.key);
                          } else {
                            selected.remove(s.key);
                          }
                        }),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(ctx).pop(selected.toList()),
                    child: const Text('Guardar'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (result == null) return;
    try {
      await _client
          .from('homes')
          .update({'supermarkets': result})
          .eq('id', data.homeId!);
      _reload();
    } catch (e) {
      _snack(friendlyError(e, 'No se pudo guardar'), error: true);
    }
  }

  /// Avatar circular con la inicial del nombre y un color cálido estable
  /// derivado del propio nombre (misma persona = mismo color).
  Widget _memberAvatar(String name) {
    final initial = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : '?';
    // Paleta cozy de fondos y sus colores de texto a juego.
    const palette = <(Color, Color)>[
      (AppColors.sageBg, AppColors.sage),
      (AppColors.peachBg, AppColors.peach),
      (AppColors.terracottaBg, AppColors.terracotta),
      (AppColors.frostBg, AppColors.frost),
    ];
    final idx = name.hashCode.abs() % palette.length;
    final (bg, fg) = palette[idx];
    return CircleAvatar(
      backgroundColor: bg,
      child: Text(
        initial,
        style: TextStyle(fontWeight: FontWeight.bold, color: fg),
      ),
    );
  }

  /// Fila táctil de un acceso dentro de la tarjeta de hogar/ajustes.
  Widget _settingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? iconBg,
    Color? iconFg,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: iconBg ?? AppColors.cream,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: iconFg ?? AppColors.woodDark),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right, color: Colors.black26),
      onTap: onTap,
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.cardDecoration(),
      child: child,
    );
  }
}

class _HouseholdData {
  final String? homeId;
  final String? homeName;
  final List<_Member> members;
  final List<String> supermarkets; // claves canónicas de súper del hogar

  /// Código de invitación vigente (null si no hay).
  final HomeInvite? invite;

  bool get iAmOwner => members.any((m) => m.isMe && m.role == 'owner');

  /// "Modo Puntos" activado: controla si se muestra el acceso a Economía.
  final bool pointsEnabled;
  _HouseholdData({
    required this.homeId,
    this.homeName,
    this.members = const [],
    this.supermarkets = const [],
    this.pointsEnabled = true,
    this.invite,
  });
}

class _Member {
  final String userId;
  final String role;
  final String? name;
  final bool isMe;
  _Member({
    required this.userId,
    required this.role,
    this.name,
    required this.isMe,
  });
}
