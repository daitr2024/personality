package com.daitr2024.personalityai

import android.util.Log
import com.google.android.gms.wearable.MessageEvent
import com.google.android.gms.wearable.Wearable
import com.google.android.gms.wearable.WearableListenerService
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.launch

/**
 * Phone-side Wearable Listener Service — Receives messages from the watch.
 *
 * Handles:
 * - /personality/voice_input — Voice text from watch → background AI process → auto-save → send result to watch
 * - /personality/request_sync — Watch requests fresh task data
 */
class PhoneWearListenerService : WearableListenerService() {

    companion object {
        private const val TAG = "PhoneWearListener"
    }

    private val serviceScope = CoroutineScope(SupervisorJob() + Dispatchers.IO)

    override fun onMessageReceived(messageEvent: MessageEvent) {
        Log.d(TAG, "Message received: ${messageEvent.path}")

        when (messageEvent.path) {
            "/personality/voice_input" -> {
                val voiceText = String(messageEvent.data)
                Log.d(TAG, "Voice input from watch: $voiceText")

                // Process in background — NO UI shown on phone
                serviceScope.launch {
                    processVoiceInput(messageEvent.sourceNodeId, voiceText)
                }
            }

            "/personality/request_sync" -> {
                Log.d(TAG, "Watch requested data sync")
                // When Flutter is running, it handles sync via HomeWidgetService
                // For background sync, we could read DB and send, but the main
                // sync path is through Flutter's updateWidget() which also syncs to wear
            }
        }
    }

    /**
     * Complete background pipeline:
     * 1. AI classifies the voice text
     * 2. Saves to SQLite database
     * 3. Sends confirmation back to watch
     * 4. Triggers home widget update
     */
    private suspend fun processVoiceInput(sourceNodeId: String, voiceText: String) {
        try {
            // Step 1 & 2: AI process + save to DB
            val result = WearVoiceProcessor.process(this, voiceText)

            // Step 3: Send confirmation back to watch
            sendResultToWatch(sourceNodeId, result.message)

            // Step 4: Trigger widget update (when Flutter is running)
            if (result.success && result.savedCount > 0) {
                triggerWidgetRefresh()
            }

            Log.d(TAG, "Voice processing complete: ${result.message}")
        } catch (e: Exception) {
            Log.e(TAG, "Error processing voice input", e)
            sendResultToWatch(sourceNodeId, "❌ Hata oluştu")
        }
    }

    private fun sendResultToWatch(nodeId: String, message: String) {
        Wearable.getMessageClient(this)
            .sendMessage(nodeId, "/personality/voice_result", message.toByteArray())
            .addOnSuccessListener {
                Log.d(TAG, "Result sent to watch: $message")
            }
            .addOnFailureListener { e ->
                Log.e(TAG, "Failed to send result to watch", e)
            }
    }

    private fun triggerWidgetRefresh() {
        try {
            // Send broadcast to trigger Flutter widget update if app is running
            val intent = android.content.Intent("com.daitr2024.personalityai.WEAR_DATA_CHANGED")
            sendBroadcast(intent)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to trigger widget refresh", e)
        }
    }
}
