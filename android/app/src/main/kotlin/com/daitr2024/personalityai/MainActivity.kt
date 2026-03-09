package com.daitr2024.personalityai

import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.daitr2024.personalityai/quick_actions"
    private val WEAR_CHANNEL = "com.daitr2024.personalityai/wear_sync"
    private var pendingAction: String? = null
    private var pendingVoiceText: String? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        handleIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleNewIntent(intent)
    }

    private fun handleIntent(intent: Intent) {
        when (intent.action) {
            "ACTION_QUICK_NOTE" -> pendingAction = "ACTION_QUICK_NOTE"
            "ACTION_QUICK_TEXT" -> pendingAction = "ACTION_QUICK_TEXT"
            "ACTION_IMAGE_SCAN" -> pendingAction = "ACTION_IMAGE_SCAN"
            "ACTION_GALLERY_SCAN" -> pendingAction = "ACTION_GALLERY_SCAN"
            "ACTION_WEAR_VOICE_INPUT" -> {
                pendingAction = "ACTION_WEAR_VOICE_INPUT"
                pendingVoiceText = intent.getStringExtra("voice_text")
            }
            "ACTION_WEAR_SYNC_REQUEST" -> pendingAction = "ACTION_WEAR_SYNC_REQUEST"
        }
    }

    private fun handleNewIntent(intent: Intent) {
        val engine = flutterEngine ?: return
        val messenger = engine.dartExecutor.binaryMessenger

        when (intent.action) {
            "ACTION_QUICK_NOTE" -> {
                MethodChannel(messenger, CHANNEL).invokeMethod("quickNoteTriggered", null)
            }
            "ACTION_QUICK_TEXT" -> {
                MethodChannel(messenger, CHANNEL).invokeMethod("quickTextTriggered", null)
            }
            "ACTION_IMAGE_SCAN" -> {
                MethodChannel(messenger, CHANNEL).invokeMethod("quickImageScanTriggered", null)
            }
            "ACTION_GALLERY_SCAN" -> {
                MethodChannel(messenger, CHANNEL).invokeMethod("quickGalleryScanTriggered", null)
            }
            "ACTION_WEAR_VOICE_INPUT" -> {
                val voiceText = intent.getStringExtra("voice_text") ?: ""
                MethodChannel(messenger, CHANNEL)
                    .invokeMethod("wearVoiceInput", voiceText)
            }
            "ACTION_WEAR_SYNC_REQUEST" -> {
                MethodChannel(messenger, WEAR_CHANNEL)
                    .invokeMethod("syncRequested", null)
            }
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Quick Actions channel (existing + wear voice input)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "checkPendingAction" -> {
                        if (pendingAction == "ACTION_WEAR_VOICE_INPUT") {
                            result.success(mapOf(
                                "action" to pendingAction,
                                "voiceText" to pendingVoiceText
                            ))
                        } else {
                            result.success(pendingAction)
                        }
                        pendingAction = null
                        pendingVoiceText = null
                    }
                    else -> result.notImplemented()
                }
            }

        // Wear Sync channel — Flutter sends task data to watch
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, WEAR_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "syncTasks" -> {
                        val taskJson = call.argument<String>("taskJson") ?: "[]"
                        PhoneWearSyncHelper.syncTasksToWatch(this, taskJson)
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
