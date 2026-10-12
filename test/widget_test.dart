import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:prezhome/home_onboarding_screen.dart';

void main() {
  testWidgets('home onboarding offers both membership options', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: HomeOnboardingScreen()));

    expect(find.text('Comenzar un hogar nuevo'), findsOneWidget);
    expect(find.text('Unirme a un hogar'), findsOneWidget);
  });
}
