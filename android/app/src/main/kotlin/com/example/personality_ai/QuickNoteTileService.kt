package com.example.personality_ai

import android.content.Intent
import android.service.quicksettings.TileService
import android.os.Build
import android.app.PendingIntent

class QuickNoteTileService : TileService() {
    override fun onClick() {
        super.onClick()
        
        val intent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
            action = "ACTION_QUICK_NOTE"
        }

        if (Build.VERSION.SDK_INT >= 34) {
             val pendingIntent = PendingIntent.getActivity(
                this,
                0,
                intent,
                PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
            )
            startActivityAndCollapse(pendingIntent)
        } else {
            // Deprecated in API 34 but works for older
            startActivityAndCollapse(intent)
        }
    }
}
