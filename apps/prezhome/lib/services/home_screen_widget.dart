import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';

/// Widget "Hoy" de la pantalla de inicio del móvil (por ahora, Android):
/// guarda los textos ya traducidos y pide al sistema que lo repinte. El
/// dibujo está en android/.../TodayWidgetProvider.kt.
class HomeScreenWidget {
  HomeScreenWidget._();

  static const _android = 'com.example.prezhome.TodayWidgetProvider';
  static String? _last;

  static Future<void> update({
    required String date,
    String? mealTag,
    String? meal,
    String? line1,
    String? line2,
  }) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    // Solo si cambia algo: Hoy se repinta a menudo.
    final key = [date, mealTag, meal, line1, line2].join('|');
    if (key == _last) return;
    _last = key;
    try {
      await Future.wait([
        HomeWidget.saveWidgetData<String>('w_date', date),
        HomeWidget.saveWidgetData<String>('w_meal_tag', mealTag),
        HomeWidget.saveWidgetData<String>('w_meal', meal),
        HomeWidget.saveWidgetData<String>('w_line1', line1),
        HomeWidget.saveWidgetData<String>('w_line2', line2),
      ]);
      await HomeWidget.updateWidget(qualifiedAndroidName: _android);
    } catch (_) {
      // Sin widget puesto o sin el plugin (tests): no pasa nada.
      _last = null;
    }
  }
}
