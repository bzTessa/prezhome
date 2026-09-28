import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'home_screen.dart';

class HomeOnboardingScreen extends StatefulWidget {
  const HomeOnboardingScreen({super.key});

  @override
  State<HomeOnboardingScreen> createState() => _HomeOnboardingScreenState();
}

class _HomeOnboardingScreenState extends State<HomeOnboardingScreen> {
  final _homeIdController = TextEditingController();
  bool _isLoading = false;

  SupabaseClient get _client => Supabase.instance.client;

  Future<void> _createHome() async {
    await _runHomeAction(() async {
      await _client.rpc('create_home_and_join');
    });
  }

  Future<void> _joinHome() async {
    final homeId = _homeIdController.text.trim();
    if (!_isUuid(homeId)) {
      _showError('Introduce un UUID de hogar válido.');
      return;
    }

    await _runHomeAction(() async {
      await _client.rpc('join_home', params: {'target_home_id': homeId});
    });
  }

  Future<void> _runHomeAction(Future<void> Function() action) async {
    setState(() => _isLoading = true);
    try {
      await action();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (_) => false,
        );
      }
    } on PostgrestException catch (error) {
      if (mounted) _showError(error.message);
    } catch (error) {
      if (mounted) _showError('No se pudo configurar el hogar: $error');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  bool _isUuid(String value) {
    return RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
    ).hasMatch(value);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  void dispose() {
    _homeIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Configura tu hogar',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFFFDF8E1),
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  '¡Bienvenido a PrezHome!',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Crea un hogar nuevo o únete al hogar que ya comparte tu familia.',
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _isLoading ? null : _createHome,
                  style: _buttonStyle(),
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : const Text('Crear un hogar nuevo'),
                ),
                const SizedBox(height: 32),
                const Divider(),
                const SizedBox(height: 24),
                const Text(
                  '¿Te han invitado a un hogar?',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _homeIdController,
                  enabled: !_isLoading,
                  decoration: InputDecoration(
                    labelText: 'UUID del hogar',
                    hintText: 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: _isLoading ? null : _joinHome,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF1E1E1E),
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text('Unirme al hogar'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  ButtonStyle _buttonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFFE2C792),
      foregroundColor: const Color(0xFF1E1E1E),
      minimumSize: const Size.fromHeight(50),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
    );
  }
}
