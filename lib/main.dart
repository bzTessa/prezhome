import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_screen.dart';
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
    final session = Supabase.instance.client.auth.currentSession;

    return MaterialApp(
      title: 'PrezHome',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.build(context),
      home: session == null ? const LoginScreen() : const HomeSessionScreen(),
    );
  }
}
