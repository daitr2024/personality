package com.daitr2024.personalityai.wear

import android.app.Activity
import android.content.Intent
import android.os.Bundle
import android.speech.RecognizerIntent
import android.util.Log
import android.widget.Toast
import com.google.android.gms.wearable.MessageClient
import com.google.android.gms.wearable.MessageEvent
import com.google.android.gms.wearable.Wearable
import java.util.Locale

/**
 * Voice Input Activity — Launches system speech recognition on the watch.
 *
 * Complete flow (user never touches phone):
 * 1. System speech recognizer opens (full screen on watch)
 * 2. User speaks (e.g. "Yarın saat 3'te toplantı")
 * 3. Recognized text is sent to phone via MessageClient
 * 4. Phone's WearVoiceProcessor processes it in background (AI → DB save)
 * 5. Phone sends result back: "/personality/voice_result"
 * 6. Watch shows confirmation toast (e.g. "✅ 📅 Toplantı (2026-03-10 15:00)")
 */
class VoiceInputActivity : Activity(), MessageClient.OnMessageReceivedListener {

    companion object {
        private const val SPEECH_REQUEST_CODE = 100
        private const val TAG = "WearVoiceInput"
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Register for result messages from phone
        Wearable.getMessageClient(this).addListener(this)

        // Immediately launch speech recognizer
        val intent = Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply {
            putExtra(
                RecognizerIntent.EXTRA_LANGUAGE_MODEL,
                RecognizerIntent.LANGUAGE_MODEL_FREE_FORM
            )
            putExtra(RecognizerIntent.EXTRA_LANGUAGE, Locale.getDefault())
            putExtra(
                RecognizerIntent.EXTRA_PROMPT,
                getString(R.string.voice_input_hint)
            )
            putExtra(
                RecognizerIntent.EXTRA_SUPPORTED_LANGUAGES,
                arrayListOf("tr-TR", "en-US", "ar-SA")
            )
        }

        try {
            startActivityForResult(intent, SPEECH_REQUEST_CODE)
        } catch (e: Exception) {
            Log.e(TAG, "Speech recognition not available", e)
            Toast.makeText(this, "Ses tanıma kullanılamıyor", Toast.LENGTH_SHORT).show()
            finish()
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        Wearable.getMessageClient(this).removeListener(this)
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)

        if (requestCode == SPEECH_REQUEST_CODE) {
            if (resultCode == RESULT_OK && data != null) {
                val results = data.getStringArrayListExtra(RecognizerIntent.EXTRA_RESULTS)
                val spokenText = results?.firstOrNull() ?: ""

                if (spokenText.isNotEmpty()) {
                    Log.d(TAG, "Recognized: $spokenText")
                    sendToPhone(spokenText)
                } else {
                    finish()
                }
            } else {
                finish()
            }
        }
    }

    /**
     * Receive result from phone after AI processing + save.
     */
    override fun onMessageReceived(messageEvent: MessageEvent) {
        if (messageEvent.path == "/personality/voice_result") {
            val resultMessage = String(messageEvent.data)
            Log.d(TAG, "Result from phone: $resultMessage")

            runOnUiThread {
                // Show the result (e.g. "✅ 📅 Doktor Randevusu (2026-03-10 15:00)")
                Toast.makeText(this, resultMessage, Toast.LENGTH_LONG).show()

                // Wait a moment for Toast to be visible, then close
                window.decorView.postDelayed({ finish() }, 2500)
            }
        }
    }

    private fun sendToPhone(text: String) {
        Toast.makeText(this, "⏳ İşleniyor...", Toast.LENGTH_SHORT).show()

        Wearable.getNodeClient(this).connectedNodes.addOnSuccessListener { nodes ->
            if (nodes.isEmpty()) {
                runOnUiThread {
                    Toast.makeText(
                        this,
                        getString(R.string.no_connection),
                        Toast.LENGTH_SHORT
                    ).show()
                    finish()
                }
                return@addOnSuccessListener
            }

            for (node in nodes) {
                Wearable.getMessageClient(this)
                    .sendMessage(node.id, "/personality/voice_input", text.toByteArray())
                    .addOnSuccessListener {
                        Log.d(TAG, "Sent to phone, waiting for AI result...")
                        // Don't finish yet — wait for /personality/voice_result
                    }
                    .addOnFailureListener { e ->
                        Log.e(TAG, "Failed to send to ${node.displayName}", e)
                        runOnUiThread {
                            Toast.makeText(
                                this,
                                getString(R.string.sent_error),
                                Toast.LENGTH_SHORT
                            ).show()
                            finish()
                        }
                    }
            }
        }.addOnFailureListener { e ->
            Log.e(TAG, "Failed to get connected nodes", e)
            Toast.makeText(this, getString(R.string.sent_error), Toast.LENGTH_SHORT).show()
            finish()
        }
    }
}
