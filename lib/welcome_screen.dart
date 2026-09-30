import 'package:flutter/material.dart';

import 'login_screen.dart';
import 'theme/app_theme.dart';
import 'widgets/miau_character.dart';

/// Bienvenida/onboarding la primera vez: explica la app en unos pasos y lleva
/// al login. Presidente Miau acompaña cada pantalla.
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final _controller = PageController();
  int _page = 0;

  final _slides = const [
    _Slide(
      mood: MiauMood.greeting,
      title: 'Bienvenida a PrezHome',
      text:
          'Organiza la comida, las tareas y los gastos de tu hogar en un solo '
          'sitio. Presidente Miau supervisa que todo esté en orden.',
    ),
    _Slide(
      mood: MiauMood.cooking,
      title: 'Comidas a tu medida',
      text:
          'Guarda recetas, rellénalas con IA o descubre ideas nuevas. La app te '
          'dice cuántos gramos y calorías tocan a cada persona.',
    ),
    _Slide(
      mood: MiauMood.celebrating,
      title: 'Hogar en equipo',
      text:
          'Repartid las tareas con un sistema de puntos y controlad el gasto '
          'escaneando los tickets de la compra.',
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _goLogin() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _page == _slides.length - 1;
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: _goLogin,
                child: const Text(
                  'Saltar',
                  style: TextStyle(color: AppColors.ink),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _slides.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (context, i) {
                  final s = _slides[i];
                  return Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        MiauCharacter(mood: s.mood, size: 180),
                        const SizedBox(height: 32),
                        Text(
                          s.title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          s.text,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            height: 1.5,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            // Indicadores de página
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _slides.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _page == i ? 22 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _page == i ? AppColors.wood : Colors.grey[400],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: ElevatedButton(
                onPressed: () {
                  if (isLast) {
                    _goLogin();
                  } else {
                    _controller.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                    );
                  }
                },
                child: Text(isLast ? 'Empezar' : 'Siguiente'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Slide {
  final MiauMood mood;
  final String title;
  final String text;
  const _Slide({required this.mood, required this.title, required this.text});
}
