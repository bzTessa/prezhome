import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'home_onboarding_screen.dart';
import 'main_shell.dart';
import 'login_screen.dart';
import 'models/nutrition_profile.dart';
import 'profile_wizard_screen.dart';

/// Resultado de evaluar el estado del usuario para decidir a donde llevarlo:
/// si pertenece a un hogar y si su perfil nutricional esta completo.
class _SessionState {
  final bool hasHome;
  final bool profileComplete;

  const _SessionState({required this.hasHome, required this.profileComplete});
}

class HomeSessionScreen extends StatefulWidget {
  const HomeSessionScreen({super.key});

  @override
  State<HomeSessionScreen> createState() => _HomeSessionScreenState();
}

class _HomeSessionScreenState extends State<HomeSessionScreen> {
  late Future<_SessionState> _session;

  // Evita lanzar el wizard automatico mas de una vez por montaje de la pantalla
  // (p. ej. si el FutureBuilder se reconstruye), asi no hay bucles ni dobles
  // aperturas del cuestionario.
  bool _wizardLaunched = false;

  // Clave de MainShell para refrescar la pestana Inicio cuando el wizard
  // automatico se cierra, de modo que el dashboard refleje el objetivo recien
  // calculado sin que el usuario tenga que cambiar de pestana. Es la clave
  // compartida del shell (MainShell.shellKey) para que otras entradas al wizard
  // (aviso de calorias en Inicio, perfil nutricional) tambien puedan avisar al
  // shell del cambio de modulos.
  final GlobalKey<MainShellState> _shellKey = MainShell.shellKey;

  @override
  void initState() {
    super.initState();
    _session = _loadSession();
  }

  Future<_SessionState> _loadSession() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      return const _SessionState(hasHome: false, profileComplete: false);
    }

    // Solo necesitamos home_id y las columnas que consume isComplete; incluimos
    // 'id' porque NutritionProfile.fromMap lo lee. Asi no cargamos el perfil
    // entero en la ruta critica del arranque.
    final profile = await Supabase.instance.client
        .from('profiles')
        .select('id, home_id, sex, birth_date, height_cm, weight_kg')
        .eq('id', user.id)
        .maybeSingle();

    final homeId = profile?['home_id'];
    final hasHome = homeId is String && homeId.isNotEmpty;
    final profileComplete =
        profile != null && NutritionProfile.fromMap(profile).isComplete;

    return _SessionState(hasHome: hasHome, profileComplete: profileComplete);
  }

  void _retry() {
    final future = _loadSession();
    setState(() {
      _session = future;
    });
  }

  /// Lanza el cuestionario UNA sola vez sobre MainShell en el primer frame,
  /// cuando el usuario ya tiene hogar pero el perfil no esta completo. El
  /// wizard siempre tiene salida (el usuario puede cerrarlo y entrar a la app),
  /// por lo que no hay bucles ni callejones sin salida.
  void _maybeLaunchWizard() {
    if (_wizardLaunched) return;
    _wizardLaunched = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const ProfileWizardScreen()));
      // Al volver del cuestionario, refrescamos la pestana Inicio para que el
      // aviso de calorias y la tarjeta reflejen el objetivo ya calculado.
      if (!mounted) return;
      _shellKey.currentState?.refreshHome();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (Supabase.instance.client.auth.currentSession == null) {
      return const LoginScreen();
    }

    return FutureBuilder<_SessionState>(
      future: _session,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _ProfileLoadError(onRetry: _retry);
        }
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final state = snapshot.data!;
        if (!state.hasHome) {
          return const HomeOnboardingScreen();
        }
        if (!state.profileComplete) {
          // Hogar + perfil incompleto: entramos a la app y abrimos el
          // cuestionario encima una sola vez, siempre con salida.
          _maybeLaunchWizard();
        }
        return MainShell(key: _shellKey);
      },
    );
  }
}

class _ProfileLoadError extends StatelessWidget {
  final VoidCallback onRetry;

  const _ProfileLoadError({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('No se pudo cargar tu perfil.'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: onRetry,
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
