import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'home_onboarding_screen.dart';
import 'main_shell.dart';
import 'login_screen.dart';
import 'services/offline_provider.dart';
import 'theme/app_motion.dart';
import 'widgets/miau_character.dart';
import 'l10n/l10n.dart';

/// Resultado de evaluar el estado del usuario para decidir a donde llevarlo:
/// si pertenece a un hogar. El perfil de calorías NO se pide al entrar: se
/// ofrece desde Inicio y Perfil para no alargar el primer arranque.
class _SessionState {
  final bool hasHome;
  final String? homeId;

  const _SessionState({required this.hasHome, this.homeId});
}

class HomeSessionScreen extends StatefulWidget {
  const HomeSessionScreen({super.key});

  @override
  State<HomeSessionScreen> createState() => _HomeSessionScreenState();
}

class _HomeSessionScreenState extends State<HomeSessionScreen> {
  /// Último hogar de esta persona en este móvil ('usuario|hogar').
  static const _lastHomeKey = 'last_home';

  /// Solo al abrir la app se entra con el hogar recordado; al unirse a otro
  /// hogar o salir de él se espera a la respuesta del servidor.
  static bool _coldStart = true;

  _SessionState? _state;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _start();
  }

  /// Al abrir la app no se espera a la red: con el hogar de la última vez se
  /// entra al momento y se comprueba por detrás. Si el servidor dice otra
  /// cosa (otro hogar, sin hogar), se cambia en cuanto llega.
  Future<void> _start() async {
    final user = Supabase.instance.client.auth.currentUser;
    final optimistic = _coldStart;
    _coldStart = false;
    final store = OfflineProvider.instance.store;
    if (user != null && optimistic) {
      try {
        final last = (await store.read(_lastHomeKey))?.split('|');
        if (last != null &&
            last.length == 2 &&
            last[0] == user.id &&
            last[1].isNotEmpty) {
          await OfflineProvider.instance.switchHome(last[1]);
          _show(_SessionState(hasHome: true, homeId: last[1]));
        }
      } catch (_) {
        // Sin recuerdo legible: se espera al servidor como siempre.
      }
    }
    try {
      final fresh = await _loadSession();
      if (user != null) {
        await store.write(_lastHomeKey, '${user.id}|${fresh.homeId ?? ''}');
      }
      if (fresh.hasHome != _state?.hasHome || fresh.homeId != _state?.homeId) {
        _show(fresh);
      }
    } catch (e) {
      // Ya dentro con el hogar recordado (p. ej. sin red): se sigue offline.
      if (_state == null && mounted) setState(() => _error = e);
    }
  }

  void _show(_SessionState state) {
    if (mounted) setState(() => _state = state);
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

    return _SessionState(hasHome: hasHome, homeId: hasHome ? homeId : null);
  }

  void _retry() {
    setState(() => _error = null);
    _start();
  }

  @override
  Widget build(BuildContext context) {
    if (Supabase.instance.client.auth.currentSession == null) {
      return const LoginScreen();
    }

    final state = _state;
    final Widget child;
    if (state != null) {
      child = state.hasHome
          // Otro hogar: pantallas nuevas, sin datos del anterior.
          ? MainShell(key: ValueKey(state.homeId))
          : const HomeOnboardingScreen(key: ValueKey('onboarding'));
    } else if (_error != null) {
      child = _ProfileLoadError(onRetry: _retry);
    } else {
      child = const Scaffold(
        key: ValueKey('loading'),
        body: Center(child: CircularProgressIndicator()),
      );
    }
    // Del cargando a la app con un fundido, no de golpe.
    return AnimatedSwitcher(
      duration: AppMotion.effectiveDuration(
        AppMotion.base,
        reduceMotion: AppMotion.reduceMotionOf(context),
      ),
      child: child,
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
