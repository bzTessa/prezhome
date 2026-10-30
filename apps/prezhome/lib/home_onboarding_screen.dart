import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'main_shell.dart';
import 'onboarding/onboarding_widgets.dart';
import 'services/home_country.dart';
import 'services/home_invites.dart';
import 'theme/app_theme.dart';
import 'utils/friendly_error.dart';
import 'widgets/miau_character.dart';

class HomeOnboardingScreen extends StatefulWidget {
  const HomeOnboardingScreen({super.key});

  @override
  State<HomeOnboardingScreen> createState() => _HomeOnboardingScreenState();
}

class _HomeOnboardingScreenState extends State<HomeOnboardingScreen> {
  final _homeIdController = TextEditingController();
  bool _isLoading = false;
  bool _joining = false;

  SupabaseClient get _client => Supabase.instance.client;

  Future<void> _createHome() async {
    await _runHomeAction(() async {
      await _client.rpc('create_home_and_join');
      await HomeCountry.load(_client);
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
      // Las funciones del hogar lanzan mensajes ya en español.
      if (mounted) _showError(error.message);
    } catch (error) {
      if (mounted) {
        _showError(friendlyError(error, 'No se pudo configurar el hogar'));
      }
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
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const MiauCharacter(mood: MiauMood.greeting, size: 120),
                  const SizedBox(height: 16),
                  Text(
                    'Último paso: tu hogar',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      letterSpacing: -0.6,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Créalo ahora y, cuando quieras, invita a quien viva '
                    'contigo desde Inicio.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.4,
                      color: AppColors.inkMuted,
                    ),
                  ),
                  const SizedBox(height: 32),
                  OnboardingButton(
                    label: _isLoading ? 'Un momento…' : 'Crear mi hogar',
                    onPressed: _isLoading ? null : _createHome,
                  ),
                  const SizedBox(height: 12),
                  if (!_joining)
                    TextButton(
                      onPressed: _isLoading
                          ? null
                          : () => setState(() => _joining = true),
                      child: Text(
                        'Me han invitado a un hogar',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                      ),
                    )
                  else ...[
                    const SizedBox(height: 12),
                    TextField(
                      controller: _homeIdController,
                      enabled: !_isLoading,
                      autofocus: true,
                      textCapitalization: TextCapitalization.characters,
                      decoration: const InputDecoration(
                        labelText: 'Código de invitación',
                        hintText: 'ABCD-EFGH',
                      ),
                    ),
                    const SizedBox(height: 12),
                    OnboardingButton(
                      label: 'Unirme a un hogar',
                      outlined: true,
                      onPressed: _isLoading ? null : _joinHome,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
