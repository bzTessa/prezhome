import 'package:flutter/widgets.dart';

import 'app_theme.dart';

/// Niveles de elevación de PrezHome: tarjetas sin borde negro, con una sombra
/// suave y cálida debajo. Un único estilo de tarjeta en toda la app.
///
/// Cada nivel se expone como `List<BoxShadow>` para usarse directamente en
/// `BoxDecoration(boxShadow: AppElevation.level1, border: AppElevation.border)`.
///
/// - [level0]: plano, sin sombra (fondos, superficies pegadas al scaffold).
/// - [level1]: tarjeta en reposo.
/// - [level2]: elemento elevado o flotante.
/// - [pressed]: pieza pulsada.
class AppElevation {
  AppElevation._();

  /// Desplazamiento vertical que baja una pieza al pulsarla.
  static const double restOffset = 3;

  /// Borde de las tarjetas: invisible en claro (manda la sombra suave) y una
  /// línea discreta en oscuro, donde la sombra apenas se ve.
  static Border get border => Border.all(color: AppColors.cardEdge, width: 1);

  /// Nivel 0: superficie plana, sin sombra.
  static List<BoxShadow> get level0 => <BoxShadow>[];

  /// Nivel 1: tarjeta en reposo, sombra suave y cálida.
  static List<BoxShadow> get level1 => <BoxShadow>[
    BoxShadow(color: AppColors.faintShadow, offset: const Offset(0, 1)),
    BoxShadow(
      color: AppColors.cardShadow,
      offset: const Offset(0, 8),
      blurRadius: 22,
      spreadRadius: -14,
    ),
  ];

  /// Nivel 2: elemento elevado o flotante (barra inferior, botón flotante).
  static List<BoxShadow> get level2 => <BoxShadow>[
    BoxShadow(color: AppColors.faintShadow, offset: const Offset(0, 1)),
    BoxShadow(
      color: AppColors.cardShadow,
      offset: const Offset(0, 14),
      blurRadius: 30,
      spreadRadius: -14,
    ),
  ];

  /// Pulsado: la sombra casi desaparece (la pieza "baja").
  static List<BoxShadow> get pressed => <BoxShadow>[
    BoxShadow(color: AppColors.faintShadow, offset: const Offset(0, 1)),
  ];
}
