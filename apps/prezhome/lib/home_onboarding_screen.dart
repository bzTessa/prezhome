import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'main_shell.dart';
import 'services/home_invites.dart';
import 'theme/app_theme.dart';

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
    final code = _homeIdController.text;
    if (!looksLikeInviteCode(code)) {
      _showError('El código tiene 8 letras y números (por ejemplo ABCD-EFGH).');
      return;
    }

    await _runHomeAction(() async {
      await HomeInvites(_client).join(normalizeInviteCode(code));
    });
  }

  Future<void> _runHomeAction(Future<void> Function() action) async {
    setState(() => _isLoading = true);
    try {
      await action();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          // Clave compartida del shell para que, tras crear/unirse a un hogar,
          // los cambios de módulos hechos en el wizard (p. ej. desde el aviso
          // de calorías de Inicio) refresquen la barra de navegación vía
          // MainShell.reloadModules(), igual que en el flujo post-login.
          MaterialPageRoute(builder: (_) => const MainShell()),
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

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.expired),
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
          style: TextStyle(fontFamily: 'Literata', fontWeight: FontWeight.w600),
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: true,
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
                  '¿Qué ambiente deseas crear en casa?',
                  style: TextStyle(
                    fontFamily: 'Literata',
                    fontSize: 28,
                    letterSpacing: -0.6,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Crea tu santuario culinario o únete al hogar que comparte tu familia. Comenzaremos a diseñar tu experiencia.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, height: 1.4),
                ),
                const SizedBox(height: 48),
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      ElevatedButton(
                        onPressed: _isLoading ? null : _createHome,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(
                            0xFFC85A32,
                          ), // Warm Terracotta
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(56),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999),
                          ),
                          elevation: 0,
                          textStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Comenzar un hogar nuevo'),
                      ),
                      const SizedBox(height: 32),
                      const Divider(),
                      const SizedBox(height: 24),
                      const Text(
                        '¿Ya tienes una invitación?',
                        style: TextStyle(
                          fontFamily: 'Literata',
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _homeIdController,
                        enabled: !_isLoading,
                        textCapitalization: TextCapitalization.characters,
                        decoration: InputDecoration(
                          labelText: 'Código de invitación',
                          hintText: 'ABCD-EFGH',
                          filled: true,
                          fillColor: Theme.of(context).scaffoldBackgroundColor,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton(
                        onPressed: _isLoading ? null : _joinHome,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Theme.of(
                            context,
                          ).colorScheme.onSurface,
                          minimumSize: const Size.fromHeight(56),
                          side: BorderSide(
                            color: Theme.of(
                              context,
                            ).dividerColor.withOpacity(0.2),
                            width: 1.5,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        child: const Text('Unirme a un hogar'),
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
}
