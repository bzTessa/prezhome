import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

/// Carga la letra de la app antes de los tests, como hace main.dart. Si se
/// carga a mitad de un test, desde Flutter 3.50 queda un callback pendiente
/// al cerrarlo y el test falla con "An animation is still running".
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  for (final w in FontWeight.values.sublist(3, 8)) {
    GoogleFonts.plusJakartaSans(fontWeight: w);
  }
  await GoogleFonts.pendingFonts().then((_) {}, onError: (_) {});
  await testMain();
}
