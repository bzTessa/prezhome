import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'home_session_screen.dart';
import 'theme/app_theme.dart';
import 'widgets/miau_character.dart';
import 'widgets/tactile_button.dart';
import 'services/native_google_sign_in.dart';
import 'utils/friendly_error.dart';
import 'l10n/l10n.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.startInSignUp = false});

  /// Abrir directamente en "Crear cuenta" (al terminar el cuestionario).
  final bool startInSignUp;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  late bool _isLoginMode = !widget.startInSignUp;
  bool _isLoading = false;
  bool _oauthLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submitAuth() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      if (_isLoginMode) {
        await Supabase.instance.client.auth.signInWithPassword(
          email: email,
          password: password,
        );
      } else {
        await Supabase.instance.client.auth.signUp(
          email: email,
          password: password,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.l.loginAccountCreated)),
          );
        }
      }

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeSessionScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(friendlyError(e, context.l.loginAuthError)),
            backgroundColor: AppColors.expired,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWith(OAuthProvider provider, String name) async {
    setState(() => _oauthLoading = true);
    try {
      if (provider == OAuthProvider.google && nativeGoogleAvailable) {
        await signInWithNativeGoogle();
        return;
      }
      // Requiere tener el proveedor configurado en Supabase.
      await Supabase.instance.client.auth.signInWithOAuth(
        provider,
        // En móvil vuelve a la app por deep link; en web, a la página actual
        // (la Site URL de Supabase es el esquema de la app, no sirve en web).
        redirectTo: kIsWeb
            ? Uri.base.origin
            : 'com.prezhome.app://login-callback',
        // Chrome normal no devuelve el control a la app tras la redirección
        // (se queda cargando); la pestaña integrada sí.
        authScreenLaunchMode: LaunchMode.inAppBrowserView,
      );
      // El flujo continúa vía redirección; el AuthGate detecta la sesión.
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(friendlyError(e, context.l.loginProviderError(name))),
            backgroundColor: AppColors.expired,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _oauthLoading = false);
    }
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l.loginResetNeedsEmail)));
      return;
    }
    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(email);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l.loginResetSent)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(friendlyError(e, context.l.loginResetError)),
          backgroundColor: AppColors.expired,
        ),
      );
    }
  }

  InputDecoration _dec(String label, {Widget? suffixIcon}) => InputDecoration(
    labelText: label,
    labelStyle: AppTextStyles.bodyMuted,
    filled: true,
    fillColor: AppColors.card,
    suffixIcon: suffixIcon,
    enabledBorder: OutlineInputBorder(
      borderRadius: AppRadius.mdRadius,
      borderSide: BorderSide(color: AppColors.wood),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: AppRadius.mdRadius,
      borderSide: BorderSide(color: AppColors.woodDark, width: 2),
    ),
    border: OutlineInputBorder(
      borderRadius: AppRadius.mdRadius,
      borderSide: BorderSide(color: AppColors.wood),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 24,
              bottom: 24 + MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const MiauCharacter(mood: MiauMood.greeting, size: 120),
                  const SizedBox(height: 20),
                  Text(
                    _isLoginMode
                        ? context.l.loginWelcomeBack
                        : context.l.loginCreateAccount,
                    style: AppTextStyles.display,
                  ),
                  const SizedBox(height: 4),
                  Text(context.l.loginTagline, style: AppTextStyles.bodyMuted),
                  const SizedBox(height: 28),

                  // Botón de Google
                  _OAuthButton(
                    label: context.l.loginContinueWith('Google'),
                    icon: const Text(
                      'G',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: Color(0xFF4285F4),
                      ),
                    ),
                    loading: _oauthLoading,
                    onPressed: _oauthLoading
                        ? null
                        : () => _signInWith(OAuthProvider.google, 'Google'),
                  ),
                  // App Store exige "Iniciar sesión con Apple" si hay Google.
                  if (!kIsWeb &&
                      defaultTargetPlatform == TargetPlatform.iOS) ...[
                    const SizedBox(height: 12),
                    _OAuthButton(
                      label: context.l.loginContinueWith('Apple'),
                      icon: const Icon(Icons.apple, size: 22),
                      loading: _oauthLoading,
                      onPressed: _oauthLoading
                          ? null
                          : () => _signInWith(OAuthProvider.apple, 'Apple'),
                    ),
                  ],
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      const Expanded(child: Divider()),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          context.l.loginOrEmail,
                          style: AppTextStyles.bodyMuted,
                        ),
                      ),
                      const Expanded(child: Divider()),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: _dec(context.l.loginEmail),
                          validator: (value) {
                            if (value == null ||
                                value.isEmpty ||
                                !value.contains('@')) {
                              return context.l.loginEmailInvalid;
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: _dec(
                            context.l.loginPassword,
                            suffixIcon: IconButton(
                              onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword,
                              ),
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: AppColors.inkMuted,
                              ),
                              tooltip: _obscurePassword
                                  ? context.l.loginShowPassword
                                  : context.l.loginHidePassword,
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.length < 6) {
                              return context.l.loginPasswordShort;
                            }
                            return null;
                          },
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: _resetPassword,
                            child: Text(
                              context.l.loginForgot,
                              style: AppTextStyles.labelMuted,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: TactileButton(
                            label: _isLoading
                                ? context.l.oneMoment
                                : (_isLoginMode
                                      ? context.l.loginSignIn
                                      : context.l.loginSignUp),
                            onPressed: _isLoading ? null : _submitAuth,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () =>
                        setState(() => _isLoginMode = !_isLoginMode),
                    child: Text(
                      _isLoginMode
                          ? context.l.loginNoAccount
                          : context.l.loginHaveAccount,
                      style: TextStyle(
                        color: AppColors.ink,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OAuthButton extends StatelessWidget {
  final String label;
  final Widget icon;
  final bool loading;
  final VoidCallback? onPressed;
  const _OAuthButton({
    required this.label,
    required this.icon,
    required this.loading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: AppColors.card,
          foregroundColor: AppColors.ink,
          side: BorderSide(color: AppColors.stroke, width: 1.5),
        ),
        icon: loading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : icon,
        label: Text(label, style: AppTextStyles.title),
      ),
    );
  }
}
