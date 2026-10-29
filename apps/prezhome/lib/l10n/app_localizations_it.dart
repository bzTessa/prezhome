// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String tabLabel(String tab) {
    String _temp0 = intl.Intl.selectLogic(tab, {
      'inicio': 'Oggi',
      'comidas': 'Pasti',
      'compra': 'Spesa',
      'despensa': 'Dispensa',
      'tareas': 'Faccende',
      'other': '',
    });
    return '$_temp0';
  }

  @override
  String get country => 'Paese';

  @override
  String get countryHint => 'Valuta, supermercati e prezzi di riferimento';
}
