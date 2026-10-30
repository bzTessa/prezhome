// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String tabLabel(String tab) {
    String _temp0 = intl.Intl.selectLogic(tab, {
      'inicio': 'Today',
      'comidas': 'Meals',
      'compra': 'Shopping',
      'despensa': 'Pantry',
      'tareas': 'Chores',
      'other': '',
    });
    return '$_temp0';
  }

  @override
  String get country => 'Country';

  @override
  String get countryHint => 'Currency, supermarkets and reference prices';
}
