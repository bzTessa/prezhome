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
      SingleChildScrollView(child: HomeSkeleton()),
    ]) {
      await tester.pumpWidget(_app(s));
      expect(tester.takeException(), isNull, reason: '${s.runtimeType}');
      expect(find.bySemanticsLabel('Cargando'), findsOneWidget);
    }
  });

  testWidgets('recetas: dos columnas como la rejilla real', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_app(const RecipesSkeleton()));
    final grid = tester.widget<SliverGrid>(find.byType(SliverGrid));
    expect(grid.gridDelegate, same(recipeGridDelegate));
    final cards = find.descendant(
      of: find.byType(SliverGrid),
      matching: find.byType(Stack),
    );
    final a = tester.getRect(cards.at(0));
    final b = tester.getRect(cards.at(1));
    expect(a.top, b.top);
    expect(a.width, closeTo((390 - 32 - 14) / 2, 0.5));
  });
}
