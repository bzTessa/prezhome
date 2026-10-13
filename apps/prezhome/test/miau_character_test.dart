import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prezhome/widgets/miau_character.dart';

String? _shownAsset(WidgetTester tester) {
  final image = tester.widget<Image>(find.byType(Image));
  return (image.image as AssetImage).assetName;
}

void main() {
  testWidgets('el saludo pasa por los fotogramas y vuelve al primero', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: MiauCharacter(mood: MiauMood.greeting)),
    );
    expect(_shownAsset(tester), 'assets/images/miau_saludo_1.png');
    await tester.pump(const Duration(milliseconds: 140));
    expect(_shownAsset(tester), 'assets/images/miau_saludo_2.png');
    await tester.pump(const Duration(milliseconds: 1000));
    expect(_shownAsset(tester), 'assets/images/miau_saludo_1.png');
  });

  testWidgets('con reducir movimiento el saludo se queda quieto', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MediaQuery(
        data: MediaQueryData(disableAnimations: true),
        child: MaterialApp(
          home: MiauCharacter(mood: MiauMood.greeting, float: false),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 140));
    expect(_shownAsset(tester), 'assets/images/miau_saludo_1.png');
  });
}
