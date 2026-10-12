import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prezhome/models/inventory_item.dart';
import 'package:prezhome/widgets/inventory_item_card.dart';

/// Regresión de layout de la tarjeta del grid de la despensa.
///
/// La tarjeta vive en celdas de alto FIJO (childAspectRatio 0.74) dentro del
/// grid. Antes la imagen usaba un AspectRatio cuadrado fijo como primer hijo de
/// la Column, de modo que con fuente del sistema grande el bloque de texto
/// (nombre + cantidad + barra) desbordaba la celda. Ahora la imagen va en un
/// Expanded y CEDE altura al texto, así que no debe desbordar ni con escalado
/// de fuente alto. Estos tests fijan ese comportamiento.
void main() {
  // Celda típica de 2 columnas en móvil (ancho ~157, alto = ancho / 0.74).
  const double cellWidth = 157;
  const double cellHeight = cellWidth / 0.74;

  Widget harness(double textScale, {required bool withBar}) {
    return MediaQuery(
      data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: SizedBox(
            width: cellWidth,
            height: cellHeight,
            child: InventoryItemCard(
              item: InventoryItem(
                id: 'abc',
                homeId: 'home',
                name: 'Tomates cherry en rama',
                category: 'Despensa',
                quantity: 3,
                unit: 'unidades',
                expirationDate: DateTime.now().add(const Duration(days: 5)),
              ),
              showExpiryBar: withBar,
              onTap: () {},
              onLongPress: () {},
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('no desborda con fuente normal (con barra)', (tester) async {
    await tester.pumpWidget(harness(1.0, withBar: true));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byType(InventoryItemCard), findsOneWidget);
  });

  testWidgets('no desborda con fuente grande (textScale 2.0)', (tester) async {
    await tester.pumpWidget(harness(2.0, withBar: true));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('no desborda con fuente muy grande (textScale 3.0)', (
    tester,
  ) async {
    await tester.pumpWidget(harness(3.0, withBar: true));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('no desborda sin barra (especias/hogar) con fuente grande', (
    tester,
  ) async {
    await tester.pumpWidget(harness(2.5, withBar: false));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
