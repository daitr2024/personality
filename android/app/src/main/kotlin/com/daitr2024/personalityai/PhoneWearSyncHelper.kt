package com.daitr2024.personalityai

import android.content.Context
import android.util.Log
import com.google.android.gms.wearable.PutDataMapRequest
import com.google.android.gms.wearable.Wearable

/**
 * Helper class for sending task/event data to the Wear OS watch.
 *
 * Called from Flutter via MethodChannel when tasks/events are created or updated.
 * Sends a JSON array of today's items to the watch via DataClient.
 */
object PhoneWearSyncHelper {

    private const val TAG = "PhoneWearSync"

    /**
     * Send task/event data to the watch.
     *
     * @param context Android context
     * @param taskJson JSON string of task/event array:
     *   [{"title":"...", "time":"HH:mm", "type":"task|event|note", "urgent":bool, "completed":bool}, ...]
     */
    fun syncTasksToWatch(context: Context, taskJson: String) {
        try {
            val putDataReq = PutDataMapRequest.create("/personality/tasks").apply {
                dataMap.putString("task_json", taskJson)
                // Add timestamp to force data change event even if content is same
                dataMap.putLong("timestamp", System.currentTimeMillis())
            }

            val request = putDataReq.asPutDataRequest().setUrgent()

            Wearable.getDataClient(context)
                .putDataItem(request)
                .addOnSuccessListener {
                    Log.d(TAG, "Task data sent to watch successfully")
                }
                .addOnFailureListener { e ->
                    Log.e(TAG, "Failed to send task data to watch", e)
                }
        } catch (e: Exception) {
            Log.e(TAG, "Error syncing to watch", e)
        }
    }
}
