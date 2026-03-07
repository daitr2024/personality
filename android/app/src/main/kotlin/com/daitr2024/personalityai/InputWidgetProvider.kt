package com.daitr2024.personalityai

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews

class InputWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.input_widget_layout)

            // Container click -> Open app
            val openAppIntent = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            val openAppPending = PendingIntent.getActivity(
                context, 200, openAppIntent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.input_widget_container, openAppPending)

            // Mic Button -> ACTION_QUICK_NOTE
            val micIntent = Intent(context, MainActivity::class.java).apply {
                action = "ACTION_QUICK_NOTE"
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            val micPendingIntent = PendingIntent.getActivity(
                context, 10, micIntent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_mic_btn, micPendingIntent)

            // Text Area -> ACTION_QUICK_TEXT
            val textIntent = Intent(context, MainActivity::class.java).apply {
                action = "ACTION_QUICK_TEXT"
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            val textPendingIntent = PendingIntent.getActivity(
                context, 11, textIntent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_text_btn, textPendingIntent)

            // Camera Button -> ACTION_IMAGE_SCAN
            val cameraIntent = Intent(context, MainActivity::class.java).apply {
                action = "ACTION_IMAGE_SCAN"
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            val cameraPendingIntent = PendingIntent.getActivity(
                context, 12, cameraIntent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_camera_btn, cameraPendingIntent)

            // Gallery Button -> ACTION_GALLERY_SCAN
            val galleryIntent = Intent(context, MainActivity::class.java).apply {
                action = "ACTION_GALLERY_SCAN"
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            val galleryPendingIntent = PendingIntent.getActivity(
                context, 13, galleryIntent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_gallery_btn, galleryPendingIntent)

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
