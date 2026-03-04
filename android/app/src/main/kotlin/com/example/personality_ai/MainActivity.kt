package com.example.personality_ai

import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.personality_ai/quick_actions"
    private var pendingAction: String? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Check init intent
        if (intent.action == "ACTION_QUICK_NOTE") {
            pendingAction = "ACTION_QUICK_NOTE"
        } else if (intent.action == "ACTION_QUICK_TEXT") {
            pendingAction = "ACTION_QUICK_TEXT"
        } else if (intent.action == "ACTION_IMAGE_SCAN") {
            pendingAction = "ACTION_IMAGE_SCAN"
        } else if (intent.action == "ACTION_GALLERY_SCAN") {
            pendingAction = "ACTION_GALLERY_SCAN"
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        // Check new intent (app already running)
        if (intent.action == "ACTION_QUICK_NOTE") {
            flutterEngine?.dartExecutor?.binaryMessenger?.let {
                 MethodChannel(it, CHANNEL).invokeMethod("quickNoteTriggered", null)
            }
        } else if (intent.action == "ACTION_QUICK_TEXT") {
            flutterEngine?.dartExecutor?.binaryMessenger?.let {
                 MethodChannel(it, CHANNEL).invokeMethod("quickTextTriggered", null)
            }
        } else if (intent.action == "ACTION_IMAGE_SCAN") {
            flutterEngine?.dartExecutor?.binaryMessenger?.let {
                 MethodChannel(it, CHANNEL).invokeMethod("quickImageScanTriggered", null)
            }
        } else if (intent.action == "ACTION_GALLERY_SCAN") {
            flutterEngine?.dartExecutor?.binaryMessenger?.let {
                 MethodChannel(it, CHANNEL).invokeMethod("quickGalleryScanTriggered", null)
            }
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "checkPendingAction") {
                result.success(pendingAction)
                pendingAction = null
            } else {
                result.notImplemented()
            }
        }
    }
}
