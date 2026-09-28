import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'login_screen.dart';
import 'home_session_screen.dart';

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
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(
          0xFFFDF8E1,
        ), // Amarillo pastel cálido[cite: 10]
        primaryColor: const Color(
          0xFFE2C792,
        ), // Tonos de madera clara[cite: 10]
        textTheme: GoogleFonts.nunitoTextTheme(
          Theme.of(context).textTheme.apply(
            bodyColor: const Color(
              0xFF1E1E1E,
            ), // Gris oscuro Presidente Miau[cite: 10]
            displayColor: const Color(0xFF1E1E1E),
          ),
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 4,
          shadowColor: const Color(0x0A000000), // Sombra extremadamente sutil
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide.none, // Cero bordes negros duros[cite: 10]
          ),
        ),
      ),
      home: session == null ? const LoginScreen() : const HomeSessionScreen(),
    );
  }
}
