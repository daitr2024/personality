package com.daitr2024.personalityai.wear

import android.content.SharedPreferences
import android.util.Log
import com.google.android.gms.wearable.DataEvent
import com.google.android.gms.wearable.DataEventBuffer
import com.google.android.gms.wearable.DataMapItem
import com.google.android.gms.wearable.WearableListenerService

/**
 * Wearable Listener Service — Receives data updates from the phone app.
 *
 * Listens for:
 * - /personality/tasks — JSON array of today's tasks/events/notes
 *
 * Stores received data in SharedPreferences so the WearMainActivity
 * and TaskTileService can display it even when they start fresh.
 */
class WearDataListenerService : WearableListenerService() {

    companion object {
        private const val TAG = "WearDataListener"
        const val PREFS_NAME = "wear_data"
        const val KEY_TASK_JSON = "task_json"
    }

    override fun onDataChanged(dataEvents: DataEventBuffer) {
        Log.d(TAG, "Data changed event received: ${dataEvents.count} events")

        for (event in dataEvents) {
            if (event.type == DataEvent.TYPE_CHANGED) {
                val path = event.dataItem.uri.path ?: continue
                Log.d(TAG, "Data path: $path")

                when (path) {
                    "/personality/tasks" -> {
                        val dataMap = DataMapItem.fromDataItem(event.dataItem).dataMap
                        val jsonStr = dataMap.getString("task_json", "[]")
                        Log.d(TAG, "Received task data: ${jsonStr.take(200)}...")

                        // Cache data for Activity and Tile
                        prefs.edit()
                            .putString(KEY_TASK_JSON, jsonStr)
                            .apply()

                        // Request tile update
                        try {
                            TaskTileService.requestTileUpdate(this)
                        } catch (e: Exception) {
                            Log.e(TAG, "Failed to request tile update", e)
                        }
                    }
                }
            }
        }
    }

    private val prefs: SharedPreferences
        get() = getSharedPreferences(PREFS_NAME, MODE_PRIVATE)
}
