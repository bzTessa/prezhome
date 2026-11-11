import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prezhome/widgets/animations/app_transitions.dart';

void main() {
  testWidgets('FadeFutureBuilder funde del esqueleto al contenido', (
    tester,
  ) async {
    final c = Completer<String>();
    await tester.pumpWidget(
      MaterialApp(
        home: FadeFutureBuilder<String>(
          future: c.future,
          builder: (_, s) => Text(s.hasData ? s.data! : 'cargando'),
        ),
      ),
    );
    expect(find.text('cargando'), findsOneWidget);
    c.complete('listo');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    // A mitad de transición conviven ambos.
    expect(find.text('cargando'), findsOneWidget);
    expect(find.text('listo'), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text('cargando'), findsNothing);
    expect(find.text('listo'), findsOneWidget);
  });

  testWidgets('FadeInOnActivate conserva el estado del hijo', (tester) async {
    final key = GlobalKey<State<StatefulWidget>>();
    Widget build(bool active) => MaterialApp(
      home: Material(
        child: FadeInOnActivate(
          active: active,
          child: Checkbox(key: key, value: true, onChanged: (_) {}),
        ),
      ),
    );
    await tester.pumpWidget(build(false));
    final state = key.currentState;
    await tester.pumpWidget(build(true));
    await tester.pumpAndSettle();
    expect(key.currentState, same(state));
  });

  testWidgets('CollapseOut pliega hasta altura 0 animando', (tester) async {
    Widget build(bool collapsed) => MaterialApp(
      home: Column(
        children: [
          CollapseOut(
            collapsed: collapsed,
            child: const SizedBox(key: Key('row'), height: 80),
          ),
          const SizedBox(key: Key('below'), height: 10),
        ],
      ),
    );
    await tester.pumpWidget(build(false));
    expect(tester.getTopLeft(find.byKey(const Key('below'))).dy, 80);
    await tester.pumpWidget(build(true));
    await tester.pump(const Duration(milliseconds: 100));
    final mid = tester.getTopLeft(find.byKey(const Key('below'))).dy;
    expect(mid, greaterThan(0));
    expect(mid, lessThan(80));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.byKey(const Key('below'))).dy, 0);
  });
}
