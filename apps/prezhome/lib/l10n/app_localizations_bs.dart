// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Bosnian (`bs`).
class AppLocalizationsBs extends AppLocalizations {
  AppLocalizationsBs([String locale = 'bs']) : super(locale);

  @override
  String tabLabel(String tab) {
    String _temp0 = intl.Intl.selectLogic(tab, {
      'inicio': 'Danas',
      'comidas': 'Obroci',
      'compra': 'Kupovina',
      'despensa': 'Ostava',
      'tareas': 'Zadaci',
      'other': '',
    });
    return '$_temp0';
  }

  @override
  String get country => 'Država';

  @override
  String get countryHint => 'Valuta, supermarketi i okvirne cijene';
}
