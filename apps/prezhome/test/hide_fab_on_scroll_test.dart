import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prezhome/widgets/hide_fab_on_scroll.dart';

void main() {
  testWidgets('el botón se aparta al bajar y vuelve al subir', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: HideFabOnScroll(
          child: Scaffold(
            body: ListView(
              children: [
                for (var i = 0; i < 60; i++)
                  SizedBox(height: 60, child: Text('$i')),
              ],
            ),
            floatingActionButton: HideFabOnScroll.fab(
              FloatingActionButton(
                onPressed: () {},
                child: const Icon(Icons.add),
              ),
            ),
          ),
        ),
      ),
    );
    double opacity() =>
        tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity)).opacity;
    expect(opacity(), 1);
    await tester.drag(find.byType(ListView), const Offset(0, -300));
    await tester.pumpAndSettle();
    expect(opacity(), 0);
    await tester.drag(find.byType(ListView), const Offset(0, 100));
    await tester.pumpAndSettle();
    expect(opacity(), 1);
  });
}
