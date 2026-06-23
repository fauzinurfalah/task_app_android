package com.example.task_app

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.os.SystemClock

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.example.task_app/boot"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "getBootSessionId") {
                // Calculate approximate boot time in seconds (rounded to nearest 10 seconds to avoid tiny fluctuations)
                val bootTimeSeconds = (System.currentTimeMillis() - SystemClock.elapsedRealtime()) / 10000
                result.success(bootTimeSeconds.toString())
            } else {
                result.notImplemented()
            }
        }
    }
}
