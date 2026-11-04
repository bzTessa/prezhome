import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prezhome/l10n/app_localizations.dart';
import 'package:prezhome/services/local_store.dart';
import 'package:prezhome/services/offline_provider.dart';
import 'package:prezhome/services/offline_repository.dart';
import 'package:prezhome/shopping_list_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Sin red: cualquier llamada al servidor falla y la pantalla tira de caché.
class _Offline implements RemoteSender {
  @override
  Future<void> sendInsert(String t, Map<String, dynamic> p) async => throw 'x';
  @override
  Future<void> sendUpdate(String t, Map<String, dynamic> p, String id) async =>
      throw 'x';
  @override
  Future<void> sendDelete(String t, String id) async => throw 'x';
  @override
  Future<List<Map<String, dynamic>>> fetch(String t) async => throw 'x';
}

void main() {
  // Cerrar "Añadir a la lista" (menú ··· -> "Añadir con detalles") daba
  // pantalla roja '_dependents.isEmpty': se liberaban los campos antes de que
  // el diálogo terminara de cerrarse.
  testWidgets('cancelar el diálogo de añadir no rompe la pantalla', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.runAsync(
      () => Supabase.initialize(url: 'http://127.0.0.1:9', publishableKey: 'k'),
    );
    OfflineProvider.instance.configureForTest(
      store: InMemoryLocalStore(),
      sender: _Offline(),
    );
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('es'),
        home: const Scaffold(body: ShoppingListScreen(embedded: true)),
      ),
    );
    await tester.pump(const Duration(seconds: 1));

    await tester.tap(find.byIcon(Icons.more_horiz_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    // El menú ofrece la acción con nombre; esa abre el formulario completo.
    await tester.tap(find.text('Añadir con detalles'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Añadir a la lista'), findsOneWidget);

    await tester.tap(find.text('Cancelar'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Añadir a la lista'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
