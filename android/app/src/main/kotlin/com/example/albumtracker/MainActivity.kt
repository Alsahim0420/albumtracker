package com.app.albumcollect

import android.content.Intent
import android.net.Uri
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val channel = "com.app.albumcollect/url_launcher"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channel).setMethodCallHandler { call, result ->
            if (call.method == "openUrl") {
                val url = call.argument<String>("url")
                if (url != null && url.isNotEmpty()) {
                    try {
                        val intent = Intent(Intent.ACTION_VIEW, Uri.parse(url))
                        intent.addCategory(Intent.CATEGORY_BROWSABLE)
                        startActivity(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("OPEN_FAILED", e.message, null)
                    }
                } else {
                    result.error("INVALID_URL", "URL vacía", null)
                }
            } else {
                result.notImplemented()
            }
        }
    }
}
