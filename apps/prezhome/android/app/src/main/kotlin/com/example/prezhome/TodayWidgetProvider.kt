package com.example.prezhome

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

// Widget "Hoy" de la pantalla de inicio: la comida que toca y lo pendiente.
// Los textos (ya traducidos) los guarda la app en services/home_screen_widget.dart.
class TodayWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        for (id in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.today_widget).apply {
                setTextViewText(R.id.w_date, widgetData.getString("w_date", "PrezHome"))
                setOrHide(this, R.id.w_meal_tag, widgetData.getString("w_meal_tag", null))
                setTextViewText(
                    R.id.w_meal,
                    widgetData.getString("w_meal", null)
                        ?: context.getString(R.string.today_widget_empty),
                )
                setOrHide(this, R.id.w_line1, widgetData.getString("w_line1", null))
                setOrHide(this, R.id.w_line2, widgetData.getString("w_line2", null))
                setOnClickPendingIntent(
                    R.id.w_root,
                    HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java),
                )
            }
            appWidgetManager.updateAppWidget(id, views)
        }
    }

    private fun setOrHide(views: RemoteViews, viewId: Int, text: String?) {
        if (text.isNullOrBlank()) {
            views.setViewVisibility(viewId, View.GONE)
        } else {
            views.setViewVisibility(viewId, View.VISIBLE)
            views.setTextViewText(viewId, text)
        }
    }
}
