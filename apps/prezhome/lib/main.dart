import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'welcome_screen.dart';
import 'home_session_screen.dart';
import 'services/offline_provider.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://ubrihtnnkbwcbchvvlno.supabase.co',
    publishableKey: 'sb_publishable_9bsI8HUy7IlctmudvIljtg_zxZmKoAu',
  );

  runApp(const PrezHomeApp());
}

class PrezHomeApp extends StatelessWidget {
  const PrezHomeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PrezHome',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.build(context),
      home: const _AuthGate(),
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
        }
        final session = Supabase.instance.client.auth.currentSession;
        if (session != null) {
          return const HomeSessionScreen();
        }
        return const WelcomeScreen();
      },
    );
  }
}
