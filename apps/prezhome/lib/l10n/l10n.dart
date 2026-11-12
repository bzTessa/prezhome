import 'package:flutter/widgets.dart';

import 'app_localizations.dart';

export 'app_localizations.dart';

extension L10n on BuildContext {
  /// Textos en el idioma del móvil; en español si el árbol no tiene los
  /// delegados (tests que montan una pantalla suelta).
  AppLocalizations get l =>
      Localizations.of<AppLocalizations>(this, AppLocalizations) ??
      lookupAppLocalizations(const Locale('es'));
}

/// Textos para código sin BuildContext (errores, avisos del móvil, calendario,
/// planificador): el idioma que eligió la app al arrancar (main.dart). En
/// español hasta entonces y en los tests.
AppLocalizations appL10n = lookupAppLocalizations(const Locale('es'));
