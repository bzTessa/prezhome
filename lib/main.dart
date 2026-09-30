import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'welcome_screen.dart';
import 'home_session_screen.dart';
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
class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final session = Supabase.instance.client.auth.currentSession;
        if (session != null) {
          return const HomeSessionScreen();
        }
        return const WelcomeScreen();
      },
    );
  }
}
