import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prezhome/widgets/list_skeleton.dart';
import 'package:prezhome/widgets/skeleton.dart';

Widget _app(Widget body) => MaterialApp(
  home: MediaQuery(
    data: const MediaQueryData(size: Size(390, 844), disableAnimations: true),
    child: Scaffold(body: body),
  ),
);

void main() {
  testWidgets('el esqueleto se pinta y respeta reducir movimiento', (
    tester,
  ) async {
    await tester.pumpWidget(_app(const ListSkeleton(rows: 3)));
    expect(find.bySemanticsLabel('Cargando'), findsOneWidget);
    // Sin animación en marcha: no quedan fotogramas pendientes.
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('los esqueletos de cada pantalla caben en un móvil', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    for (final s in const <Widget>[
      PlanSkeleton(),
      RecipesSkeleton(),
      DiarySkeleton(),
      ShoppingSkeleton(),
      PantrySkeleton(),
      TasksSkeleton(),
      SingleChildScrollView(child: HomeSkeleton()),
    ]) {
      await tester.pumpWidget(_app(s));
      expect(tester.takeException(), isNull, reason: '${s.runtimeType}');
      expect(find.bySemanticsLabel('Cargando'), findsOneWidget);
    }
  });

  testWidgets('recetas: filas con foto pequeña como la lista real', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_app(const RecipesSkeleton()));
    final photos = find.byWidgetPredicate(
      (w) => w is Bone && w.width == 64 && w.height == 64,
    );
    expect(photos, findsNWidgets(6));
    expect(
      tester.getRect(photos.at(0)).left,
      tester.getRect(photos.at(1)).left,
    );
  });
}
