import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:prezhome/batch_prep_timeline_screen.dart';
import 'package:prezhome/cook_mode_screen.dart';
import 'package:prezhome/models/recipe.dart';

void main() {
  testWidgets('la tanda se lee de un vistazo y empieza en el modo cocina', (
    tester,
  ) async {
    GoogleFonts.config.allowRuntimeFetching = false;
    tester.view.physicalSize = const Size(400, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: BatchPrepTimelineScreen(
          recipes: [
            Recipe(
              id: 'a',
              homeId: 'h',
              title: 'Lentejas',
              servings: 4,
              appliance: 'pot',
              cookTimeMinutes: 70,
              instructions: 'Pica la cebolla.\nCuece las lentejas.',
            ),
          ],
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('1 receta de una vez'), findsOneWidget);
    expect(find.text('Qué vas a cocinar'), findsOneWidget);
    expect(find.text('Así irá la tanda'), findsOneWidget);
    expect(find.textContaining(' h'), findsWidgets); // más de una hora

    await tester.tap(find.text('Empezar paso a paso'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(CookModeScreen), findsOneWidget);
    expect(find.textContaining('PASO 1 DE'), findsOneWidget);
  });
}
