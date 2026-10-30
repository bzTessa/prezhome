import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'home_onboarding_screen.dart';
import 'main_shell.dart';
import 'login_screen.dart';
import 'services/offline_provider.dart';
import 'widgets/miau_character.dart';
import 'l10n/l10n.dart';

/// Resultado de evaluar el estado del usuario para decidir a donde llevarlo:
/// si pertenece a un hogar. El perfil de calorías NO se pide al entrar: se
/// ofrece desde Inicio y Perfil para no alargar el primer arranque.
class _SessionState {
  final bool hasHome;

  const _SessionState({required this.hasHome});
}

class HomeSessionScreen extends StatefulWidget {
  const HomeSessionScreen({super.key});

  @override
  State<HomeSessionScreen> createState() => _HomeSessionScreenState();
}

class _HomeSessionScreenState extends State<HomeSessionScreen> {
  late Future<_SessionState> _session;

  @override
  void initState() {
    super.initState();
    _session = _loadSession();
  }

  Future<_SessionState> _loadSession() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      return const _SessionState(hasHome: false);
    }

    final profile = await Supabase.instance.client
        .from('profiles')
        .select('home_id')
        .eq('id', user.id)
        .maybeSingle();

    final homeId = profile?['home_id'];
    final hasHome = homeId is String && homeId.isNotEmpty;

    // OFFLINE-FIRST (Paso 7): namespaceamos la caché local por hogar. Si el
    // hogar resuelto difiere del cacheado, switchHome separa (borra) la caché y
    // la cola del hogar anterior para no mezclar datos entre hogares (ver
    // steering de seguridad). Es idempotente si el hogar no cambió.
    if (hasHome) {
      await OfflineProvider.instance.switchHome(homeId);
    }

    return _SessionState(hasHome: hasHome);
  }

  void _retry() {
    final future = _loadSession();
    setState(() {
      _session = future;
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
        return const MainShell();
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
              const MiauCharacter(mood: MiauMood.worried, size: 110),
              const SizedBox(height: 16),
              Text(context.l.sessionLoadError),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: onRetry, child: Text(context.l.retry)),
            ],
          ),
        ),
      ),
    );
  }
}
