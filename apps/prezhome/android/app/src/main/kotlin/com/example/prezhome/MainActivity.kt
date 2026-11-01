package com.example.prezhome

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

// Recibe los enlaces que se comparten a PrezHome desde Instagram, TikTok,
// YouTube... (menú Compartir) y se los pasa a Flutter (services/share_inbox.dart).
class MainActivity : FlutterActivity() {
    private var channel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "prezhome/share").apply {
            // Arranque en frío: el texto compartido viene en el intent inicial.
            setMethodCallHandler { call, result ->
                if (call.method == "initial") {
                    result.success(sharedText(intent))
                    intent.removeExtra(Intent.EXTRA_TEXT)
                } else {
                    result.notImplemented()
                }
            }
        }
    }

    // App ya abierta (singleTop): llega por aquí.
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        sharedText(intent)?.let { channel?.invokeMethod("shared", it) }
    }

    private fun sharedText(intent: Intent?): String? =
        if (intent?.action == Intent.ACTION_SEND) intent.getStringExtra(Intent.EXTRA_TEXT) else null
}
