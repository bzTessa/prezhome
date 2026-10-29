// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String tabLabel(String tab) {
    String _temp0 = intl.Intl.selectLogic(tab, {
      'inicio': 'Heute',
      'comidas': 'Essen',
      'compra': 'Einkauf',
      'despensa': 'Vorrat',
      'tareas': 'Aufgaben',
      'other': '',
    });
    return '$_temp0';
  }

  @override
  String get country => 'Land';

  @override
  String get countryHint => 'Währung, Supermärkte und Richtpreise';
}
