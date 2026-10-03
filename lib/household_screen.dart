import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'economy_screen.dart';
import 'nutrition_profile_screen.dart';
import 'profile_wizard_screen.dart';
import 'login_screen.dart';
import 'theme/app_theme.dart';
import 'widgets/miau_character.dart';

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

    if (homeId == null || homeId.isEmpty) {
      return _HouseholdData(homeId: null);
    }

    final home = await _client
        .from('homes')
        .select('id, name')
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

    return _HouseholdData(
      homeId: homeId,
      homeName: (home?['name'] as String?) ?? 'Mi Hogar',
      members: members,
    );
  }

  Future<void> _createHome() async {
    try {
      await _client.rpc('create_home_and_join');
      _reload();
    } catch (e) {
      _snack('No se pudo crear el hogar: $e', error: true);
    }
  }

  Future<void> _joinHome() async {
    final controller = TextEditingController();
    final id = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cream,
        title: const Text('Unirme a un hogar'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Pega el código del hogar',
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
            child: const Text('Unirme'),
          ),
        ],
      ),
    );
    if (id == null || id.isEmpty) return;
    try {
      await _client.rpc('join_home', params: {'target_home_id': id});
      _reload();
    } catch (e) {
      _snack('No se pudo unir al hogar: $e', error: true);
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
      _snack('No se pudo renombrar: $e', error: true);
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
      SnackBar(content: Text(msg), backgroundColor: error ? Colors.red : null),
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
                child: Text('Error: ${snapshot.error}'),
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
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Código de invitación',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 4),
              const Text(
                'Compártelo con los demás para que se unan a este hogar.',
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: SelectableText(
                      data.homeId!,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy, color: AppColors.woodDark),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: data.homeId!));
                      _snack('Código copiado');
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
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
                  trailing: m.isMe
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
                subtitle: 'Objetivo de calorías y preferencias',
                iconBg: AppColors.terracottaBg,
                iconFg: AppColors.terracotta,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const NutritionProfileScreen(),
                  ),
                ),
              ),
              _settingTile(
                icon: Icons.quiz_outlined,
                title: 'Cuestionario de perfil',
                subtitle: 'Recalcula tu objetivo paso a paso',
                iconBg: AppColors.peachBg,
                iconFg: AppColors.peach,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const ProfileWizardScreen(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
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
  _HouseholdData({
    required this.homeId,
    this.homeName,
    this.members = const [],
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
