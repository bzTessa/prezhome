import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'nutrition_profile_screen.dart';
import 'login_screen.dart';

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
    setState(() => _future = future);
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
        backgroundColor: const Color(0xFFFDF8E1),
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
              backgroundColor: const Color(0xFFE2C792),
              foregroundColor: const Color(0xFF1E1E1E),
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
        backgroundColor: const Color(0xFFFDF8E1),
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
              backgroundColor: const Color(0xFFE2C792),
              foregroundColor: const Color(0xFF1E1E1E),
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
      backgroundColor: const Color(0xFFFDF8E1),
      appBar: AppBar(
        title: const Text(
          'Mi Hogar',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFFFDF8E1),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite_outline),
            tooltip: 'Mi Perfil Nutricional',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const NutritionProfileScreen()),
            ),
          ),
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
            const Icon(Icons.home_outlined, size: 64, color: Color(0xFFE2C792)),
            const SizedBox(height: 16),
            const Text(
              'Aún no perteneces a ningún hogar.',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE2C792),
                foregroundColor: const Color(0xFF1E1E1E),
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
                foregroundColor: const Color(0xFF1E1E1E),
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
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Nombre del hogar',
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit, size: 20),
                    onPressed: () => _renameHome(data.homeId!, data.homeName!),
                  ),
                ],
              ),
              Text(
                data.homeName!,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E1E1E),
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
                    icon: const Icon(Icons.copy, color: Color(0xFFB58A3C)),
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
              ...data.members.map(
                (m) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFE2C792),
                    child: Icon(Icons.person, color: Color(0xFF1E1E1E)),
                  ),
                  title: Text(
                    (m.name != null && m.name!.isNotEmpty)
                        ? m.name!
                        : 'Miembro',
                  ),
                  subtitle: Text(
                    m.role == 'owner' ? 'Administrador' : 'Miembro',
                  ),
                  trailing: m.isMe
                      ? const Chip(
                          label: Text('Tú'),
                          backgroundColor: Color(0xFFFDF8E1),
                        )
                      : null,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
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
