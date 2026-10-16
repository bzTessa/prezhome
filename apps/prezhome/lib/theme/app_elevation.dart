import 'package:flutter/widgets.dart';

import 'app_theme.dart';

/// Niveles de elevación "táctiles" del logo: borde de trazo y sombra dura
/// (sin desenfoque) debajo, como si la pieza estuviera dibujada a mano.
///
/// Cada nivel se expone como `List<BoxShadow>` para usarse directamente en
/// `BoxDecoration(boxShadow: AppElevation.level1, border: AppElevation.border)`.
///
/// - [level0]: plano, sin sombra (fondos, superficies pegadas al scaffold).
/// - [level1]: tarjeta en reposo, sombra dura de 3 px.
/// - [level2]: elemento elevado o flotante, sombra dura de 6 px.
/// - [pressed]: pieza pulsada: la sombra desaparece (la pieza "baja" 3 px).
class AppElevation {
  AppElevation._();

  /// Desplazamiento vertical de la sombra en reposo; lo que baja al pulsar.
  static const double restOffset = 3;

  /// Borde de trazo de las piezas táctiles.
  static Border get border => Border.all(color: AppColors.stroke, width: 1.5);

  static List<BoxShadow> _hard(double dy) => <BoxShadow>[
    BoxShadow(color: AppColors.stroke, offset: Offset(0, dy)),
  ];

  /// Nivel 0: superficie plana, sin sombra.
  static List<BoxShadow> get level0 => <BoxShadow>[];

  /// Nivel 1: tarjeta en reposo.
  static List<BoxShadow> get level1 => _hard(restOffset);

  /// Nivel 2: elemento elevado o flotante.
  static List<BoxShadow> get level2 => _hard(6);

  /// Pulsado: sin sombra.
  static List<BoxShadow> get pressed => _hard(0);
}
