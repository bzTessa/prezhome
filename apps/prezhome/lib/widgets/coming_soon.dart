import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'miau_character.dart';

/// Pantalla reutilizable de "Próximamente", con Presidente Miau.
class ComingSoon extends StatelessWidget {
  final String title;
  final String message;
  final MiauMood mood;

  const ComingSoon({
    super.key,
    required this.title,
    required this.message,
    this.mood = MiauMood.curious,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            MiauCharacter(mood: mood, size: 140),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.wood,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'PRÓXIMAMENTE',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                  fontSize: 12,
                  letterSpacing: 1,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 15,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
