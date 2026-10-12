import 'package:flutter/widgets.dart';

import 'app_theme.dart';

/// Niveles de elevación (sombra) con intención de PrezHome.
///
/// En lugar de una única sombra plana para todo, define una pequeña jerarquía
/// de profundidad. Cada nivel se expone como `List<BoxShadow>` para usarse
/// directamente en `BoxDecoration(boxShadow: AppElevation.level1)`.
///
/// Niveles:
/// - [level0]: plano, sin sombra (fondos, superficies pegadas al scaffold).
/// - [level1]: tarjeta en reposo, sombra suave (profundidad discreta).
/// - [level2]: elemento elevado o interactivo (al pulsar, flotante, destacado).
class AppElevation {
  const AppElevation._();

  /// Nivel 0: superficie plana, sin sombra.
  static const List<BoxShadow> level0 = <BoxShadow>[];

  /// Nivel 1: tarjeta en reposo. Sombra suave coherente con el estilo cozy
  /// original (blur ~12, desplazamiento vertical pequeño).
  static const List<BoxShadow> level1 = <BoxShadow>[
    BoxShadow(
      color: AppColors.softShadow,
      blurRadius: 12,
      offset: Offset(0, 4),
    ),
  ];

  /// Nivel 2: elemento elevado o interactivo. Sombra algo mayor y una capa
  /// extra muy tenue para dar sensación de "flotar" al pulsar o destacar.
  static const List<BoxShadow> level2 = <BoxShadow>[
    BoxShadow(
      color: AppColors.mediumShadow,
      blurRadius: 20,
      offset: Offset(0, 8),
    ),
    BoxShadow(
      color: AppColors.faintShadow,
      blurRadius: 6,
      offset: Offset(0, 2),
    ),
  ];
}
