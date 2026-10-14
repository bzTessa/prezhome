import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prezhome/widgets/animations/celebrate.dart';
import 'package:prezhome/widgets/animations/spring_value.dart';
import 'package:prezhome/widgets/animations/swipe_action.dart';
import 'package:prezhome/widgets/segmented_pill.dart';
import 'package:prezhome/widgets/shopping/shopping_parts.dart';

Widget _host(Widget child, {double width = 320}) => MaterialApp(
  home: Scaffold(
    body: Center(
      child: SizedBox(width: width, child: child),
    ),
  ),
);

void main() {
  group('popScale', () {
    test('va de rest a 1 pasando por el pico', () {
      expect(popScale(0, rest: 0.8), 0.8);
      expect(popScale(0.5, rest: 0.8), closeTo(1.2, 1e-9));
      expect(popScale(1, rest: 0.8), 1);
    });
  });

  group('swipeDisplayOffset', () {
    test('libre hasta el límite y elástico después', () {
      expect(swipeDisplayOffset(50, 90, 300), 50);
      expect(swipeDisplayOffset(-50, 90, 300), -50);
      final far = swipeDisplayOffset(400, 90, 300);
      expect(far, greaterThan(90));
      expect(far, lessThan(400));
    });
  });

  testWidgets('deslizar pasado el umbral lanza la acción; poco, no', (
    tester,
  ) async {
    var done = 0;
    await tester.pumpWidget(
      _host(
        SwipeAction(
          toRight: SwipeSide(
            icon: Icons.check,
            color: Colors.green,
            label: 'Hecha',
            onTrigger: () => done++,
          ),
          child: const SizedBox(height: 60, child: Text('Tarea')),
        ),
      ),
    );
    await tester.drag(find.text('Tarea'), const Offset(40, 0));
    await tester.pumpAndSettle();
    expect(done, 0);
    await tester.drag(find.text('Tarea'), const Offset(160, 0));
    await tester.pumpAndSettle();
    expect(done, 1);
    // Sin acción a la izquierda, deslizar hacia allí no hace nada.
    await tester.drag(find.text('Tarea'), const Offset(-160, 0));
    await tester.pumpAndSettle();
    expect(done, 1);
  });

  testWidgets('la píldora cambia de vista al tocar', (tester) async {
    var selected = 0;
    await tester.pumpWidget(
      StatefulBuilder(
        builder: (context, setState) => _host(
          SegmentedPill(
            labels: const ['Pendientes', 'Bolsa', 'Hechas'],
            selected: selected,
            onChanged: (i) => setState(() => selected = i),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Hechas'));
    await tester.pumpAndSettle();
    expect(selected, 2);
  });

  testWidgets('fila con cantidad: cabe en 320 px y − / + cambian', (
    tester,
  ) async {
    final changes = <double>[];
    await tester.pumpWidget(
      _host(
        ShoppingItemTile(
          name: 'Tomates de rama muy largos para probar el ancho',
          checked: false,
          quantity: 1,
          unit: 'kg',
          quantityLabel: '1 kg',
          leading: const Icon(Icons.eco),
          onToggle: () {},
          onQuantityChanged: changes.add,
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    await tester.tap(find.bySemanticsLabel('Más'));
    await tester.tap(find.bySemanticsLabel('Menos'));
    expect(changes, [1.5, 0.5]);
  });

  testWidgets('marcar una fila anima el check sin errores', (tester) async {
    var checked = false;
    await tester.pumpWidget(
      StatefulBuilder(
        builder: (context, setState) => _host(
          ShoppingItemTile(
            name: 'Leche',
            checked: checked,
            onToggle: () => setState(() => checked = !checked),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Leche'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    await tester.pumpAndSettle();
  });

  testWidgets('el check de tarea hecha se va solo', (tester) async {
    late BuildContext ctx;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            ctx = context;
            return const SizedBox();
          },
        ),
      ),
    );
    Celebrate.check(ctx, points: 10);
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('+10'), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text('+10'), findsNothing);
  });
}
