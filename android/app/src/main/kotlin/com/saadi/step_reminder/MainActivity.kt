package com.saadi.step_reminder

import android.os.Build
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

// Lets a ringing alarm show over the keyguard, and only while it is ringing.
//
// The manifest's showWhenLocked/turnScreenOn would do the same thing, but they
// apply to every launch: with those set, locking the phone with the app open
// and waking it again showed the app instead of the lock screen. Switching
// them on for the alarm screen and off again when it closes keeps the alarm
// behaving like an alarm without the app getting past the keyguard otherwise.
class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "show" -> {
                        showOverLockScreen(true)
                        result.success(null)
                    }
                    "release" -> {
                        showOverLockScreen(false)
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    @Suppress("DEPRECATION")
    private fun showOverLockScreen(show: Boolean) {
        runOnUiThread {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
                setShowWhenLocked(show)
                setTurnScreenOn(show)
            } else {
                val flags = WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                    WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON
                if (show) window.addFlags(flags) else window.clearFlags(flags)
            }
        }
    }

    private companion object {
        const val CHANNEL = "step_reminder/alarm"
    }
}
