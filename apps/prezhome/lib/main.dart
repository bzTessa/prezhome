import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'home_session_screen.dart';
import 'services/connection_status.dart';
import 'services/offline_provider.dart';
import 'theme/app_theme.dart';
import 'theme/theme_preference.dart';
import 'widgets/drawn_icons.dart';
import 'services/plan_prefs.dart';
import 'services/reminders.dart';
import 'onboarding/onboarding_flow.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Las preferencias locales se leen a la vez que arranca Supabase.
  final prefs = Future.wait([
    ThemePreference.load(),
    PlanPrefs.load(),
    Reminders.load(),
  ]);
  await Supabase.initialize(
    url: 'https://ubrihtnnkbwcbchvvlno.supabase.co',
    publishableKey: 'sb_publishable_9bsI8HUy7IlctmudvIljtg_zxZmKoAu',
  );

  DrawnIcons.fetch = (key, {again = false}) async {
    final res = await Supabase.instance.client.functions.invoke(
      'product-icon',
      body: {'key': key, 'again': again},
    );
    final url = (res.data is Map ? res.data['url'] : null)?.toString();
    return url == null || url.isEmpty ? null : url;
  };

  await prefs;
  runApp(const PrezHomeApp());
}

class PrezHomeApp extends StatefulWidget {
  const PrezHomeApp({super.key});

  @override
  State<PrezHomeApp> createState() => _PrezHomeAppState();
}

/// Aplica la apariencia elegida en Ajustes (clara por defecto). Sin sesión
/// (bienvenida y registro) va siempre en claro. La paleta ([AppColors]) se lee
/// al construir cada widget, así que al cambiar se reconstruye todo el árbol
/// sin perder el estado de las pantallas.
class _PrezHomeAppState extends State<PrezHomeApp> with WidgetsBindingObserver {
  late final StreamSubscription<AuthState> _authSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    ThemePreference.mode.addListener(_applyTheme);
    _authSub = Supabase.instance.client.auth.onAuthStateChange.listen((s) {
      _applyTheme();
      if (s.event == AuthChangeEvent.signedOut) {
        unawaited(Reminders.clear());
      } else if (s.event == AuthChangeEvent.initialSession ||
          s.event == AuthChangeEvent.signedIn) {
        unawaited(Reminders.sync(Supabase.instance.client));
      }
    });
    _syncBrightness();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    ThemePreference.mode.removeListener(_applyTheme);
    _authSub.cancel();
    super.dispose();
  }

  @override
  void didChangePlatformBrightness() => _applyTheme();

  // En segundo plano no comprobamos la conexión; al volver, al momento.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (Supabase.instance.client.auth.currentSession == null) return;
    if (state == AppLifecycleState.resumed) {
      ConnectionStatus.instance.start();
    } else if (state == AppLifecycleState.paused) {
      ConnectionStatus.instance.stop();
      // Al salir, los avisos se rehacen con lo que se haya hecho en la app.
      unawaited(Reminders.sync(Supabase.instance.client));
    }
  }

  void _applyTheme() {
    final before = AppColors.dark;
    _syncBrightness();
    if (before == AppColors.dark || !mounted) return;
    setState(() {});
    void rebuild(Element e) {
      e.markNeedsBuild();
      e.visitChildren(rebuild);
    }

    (context as Element).visitChildren(rebuild);
  }

  void _syncBrightness() => AppColors.dark = ThemePreference.isDark(
    mode: ThemePreference.mode.value,
    systemDark:
        WidgetsBinding.instance.platformDispatcher.platformBrightness ==
        Brightness.dark,
    forceLight: Supabase.instance.client.auth.currentSession == null,
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PrezHome',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.build(context),
      // App en español de España: selectores de fecha, textos del sistema y
      // formato (lunes primero, coma decimal).
      locale: const Locale('es', 'ES'),
      supportedLocales: const [Locale('es', 'ES')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: const _AuthGate(),
      // En pantallas muy anchas la app no pasa de 1280 px, centrada. El menú
      // lateral y el ancho del contenido los decide MainShell.
      builder: (context, child) {
        final mq = MediaQuery.of(context);
        if (mq.size.width <= 1280) return child!;
        return ColoredBox(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Center(
            child: SizedBox(
              width: 1280,
              child: MediaQuery(
                data: mq.copyWith(size: Size(1280, mq.size.height)),
                child: child!,
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Escucha el estado de sesión: si hay sesión guardada, entra directo (no pide
/// el correo otra vez). Si no, muestra la bienvenida + login.
///
/// Además, en el arranque es el punto donde LIMPIAMOS la caché offline-first al
/// CERRAR SESIÓN (evento `signedOut`), de modo que la caché local nunca mezcle
/// datos de dos hogares distintos (ver steering de seguridad). La limpieza se
/// hace reaccionando al stream `onAuthStateChange`, sin alterar el flujo que ya
/// decide entre bienvenida y app según haya o no sesión.
class _AuthGate extends StatefulWidget {
  const _AuthGate();

  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        // Al cerrar sesión limpiamos la caché/cola offline para no arrastrar
        // datos del hogar anterior al siguiente inicio de sesión.
        if (snapshot.hasData &&
            snapshot.data!.event == AuthChangeEvent.signedOut) {
          // Best-effort y sin bloquear el build: si falla no rompe el arranque.
          OfflineProvider.instance.clearForLogout();
          ConnectionStatus.instance.stop();
        }
        final session = Supabase.instance.client.auth.currentSession;
        if (session != null) {
          return const HomeSessionScreen();
        }
        return const OnboardingFlow();
      },
    );
  }
}
