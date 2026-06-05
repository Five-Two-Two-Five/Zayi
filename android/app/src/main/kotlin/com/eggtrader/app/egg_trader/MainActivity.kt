package com.eggtrader.app.egg_trader

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.eggtrader.printer/print"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "print") {
                val content = call.argument<String>("content")
                if (content != null) {
                    val intent = Intent(Intent.ACTION_SEND)
                    intent.setPackage("mate.bluetoothprint")
                    intent.putExtra(Intent.EXTRA_TEXT, content)
                    intent.type = "text/plain"
                    
                    val pm = packageManager
                    val activities = pm.queryIntentActivities(intent, 0)
                    if (activities.isNotEmpty()) {
                        startActivity(intent)
                        result.success(true)
                    } else {
                        result.error("NOT_INSTALLED", "Bluetooth Print app not installed", null)
                    }
                } else {
                    result.error("INVALID_CONTENT", "Content is null", null)
                }
            } else {
                result.notImplemented()
            }
        }
    }
}
