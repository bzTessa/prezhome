import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:prezhome/services/connection_status.dart';
import 'package:prezhome/widgets/offline_banner.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  group('serverReachable', () {
    test('sin error, el servidor responde', () {
      expect(serverReachable(null), isTrue);
    });

    test('error propio de la base de datos = el servidor contestó', () {
      expect(
        serverReachable(
          const PostgrestException(message: 'denegado', code: '42501'),
        ),
        isTrue,
      );
    });

    test('5xx, timeout o fallo de red = caído', () {
      expect(
        serverReachable(const PostgrestException(message: '', code: '503')),
        isFalse,
      );
      expect(serverReachable(Exception('Failed host lookup')), isFalse);
    });
  });

  group('parseStatusNotice', () {
    test('lee el mensaje', () {
      expect(
        parseStatusNotice('{"mensaje": " Estamos arreglando un fallo. "}'),
        'Estamos arreglando un fallo.',
      );
    });

    test('vacío o roto = sin aviso', () {
      expect(parseStatusNotice('{"mensaje": ""}'), isNull);
      expect(parseStatusNotice('{"otro": 1}'), isNull);
      expect(parseStatusNotice('<html>'), isNull);
    });
  });

  group('OfflineBanner', () {
    Future<void> pump(WidgetTester tester, Widget w) =>
        tester.pumpWidget(MaterialApp(home: Scaffold(body: w)));

    testWidgets('con conexión y sin aviso no pinta nada', (tester) async {
      await pump(tester, const OfflineBanner(online: true));
      expect(find.byType(Text), findsNothing);
    });

    testWidgets('sin conexión explica qué sigue funcionando', (tester) async {
      await pump(
        tester,
        const OfflineBanner(online: false, notice: 'Volvemos en un rato.'),
      );
      expect(find.text('Sin conexión ahora mismo'), findsOneWidget);
      expect(find.text('Volvemos en un rato.'), findsOneWidget);
      expect(find.text(kOfflineExplanation), findsOneWidget);
    });

    testWidgets('con conexión muestra solo el aviso publicado', (tester) async {
      await pump(
        tester,
        const OfflineBanner(online: true, notice: 'Mantenimiento esta noche.'),
      );
      expect(find.text('Mantenimiento esta noche.'), findsOneWidget);
      expect(find.text(kOfflineExplanation), findsNothing);
    });
  });
}
