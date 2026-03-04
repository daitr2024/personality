package com.example.personality_ai

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.util.Log
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin

class HomeWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        for (appWidgetId in appWidgetIds) {
            try {
                val views = RemoteViews(context.packageName, R.layout.widget_layout)

                // Read data from HomeWidget shared preferences
                val widgetData = HomeWidgetPlugin.getData(context)
                val taskList = widgetData.getString("task_list", "Uygulamayı açın...") ?: "Uygulamayı açın..."
                val progress = widgetData.getString("progress", "—") ?: "—"

                // Set text views
                views.setTextViewText(R.id.widget_task_list, taskList)
                views.setTextViewText(R.id.widget_progress, progress)

                // Container click -> Open app
                val openAppIntent = Intent(context, MainActivity::class.java).apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                }
                val openAppPending = PendingIntent.getActivity(
                    context, 100, openAppIntent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                views.setOnClickPendingIntent(R.id.widget_container, openAppPending)

                // Mic Button -> ACTION_QUICK_NOTE
                val micIntent = Intent(context, MainActivity::class.java).apply {
                    action = "ACTION_QUICK_NOTE"
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                }
                val micPendingIntent = PendingIntent.getActivity(
                    context, 0, micIntent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                views.setOnClickPendingIntent(R.id.widget_mic_btn, micPendingIntent)

                // Text Button -> ACTION_QUICK_TEXT
                val textIntent = Intent(context, MainActivity::class.java).apply {
                    action = "ACTION_QUICK_TEXT"
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                }
                val textPendingIntent = PendingIntent.getActivity(
                    context, 1, textIntent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                views.setOnClickPendingIntent(R.id.widget_text_btn, textPendingIntent)

                appWidgetManager.updateAppWidget(appWidgetId, views)
            } catch (e: Exception) {
                Log.e("HomeWidgetProvider", "Error updating widget $appWidgetId", e)
                // Show a fallback widget so the user doesn't see a black screen
                try {
                    val fallbackViews = RemoteViews(context.packageName, R.layout.widget_layout)
                    fallbackViews.setTextViewText(R.id.widget_task_list, "Uygulamayı açın...")
                    fallbackViews.setTextViewText(R.id.widget_progress, "—")
                    appWidgetManager.updateAppWidget(appWidgetId, fallbackViews)
                } catch (e2: Exception) {
                    Log.e("HomeWidgetProvider", "Fallback also failed", e2)
                }
            }
        }
    }
}
