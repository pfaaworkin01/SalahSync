package com.pfaacodin01.salahsync

import android.app.NotificationManager
import android.content.Context
import android.content.Intent
import android.media.AudioManager
import android.os.Build
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.pfaacodin01.salahsync/sound_mode"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            val audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

            when (call.method) {
                "getSoundMode" -> {
                    val mode = when (audioManager.ringerMode) {
                        AudioManager.RINGER_MODE_NORMAL -> "normal"
                        AudioManager.RINGER_MODE_VIBRATE -> "vibrate"
                        AudioManager.RINGER_MODE_SILENT -> "silent"
                        else -> "unknown"
                    }
                    result.success(mode)
                }
                "setSoundMode" -> {
                    val mode = call.argument<String>("mode")
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && !notificationManager.isNotificationPolicyAccessGranted) {
                        result.error("PERMISSION_DENIED", "Notification Policy access is not granted", null)
                        return@setMethodCallHandler
                    }
                    try {
                        when (mode) {
                            "normal" -> audioManager.ringerMode = AudioManager.RINGER_MODE_NORMAL
                            "vibrate" -> audioManager.ringerMode = AudioManager.RINGER_MODE_VIBRATE
                            "silent" -> audioManager.ringerMode = AudioManager.RINGER_MODE_SILENT
                            else -> {
                                result.error("INVALID_ARGUMENT", "Invalid mode: $mode", null)
                                return@setMethodCallHandler
                            }
                        }
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("ERROR", e.message, null)
                    }
                }
                "hasNotificationPolicyAccess" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        result.success(notificationManager.isNotificationPolicyAccessGranted)
                    } else {
                        result.success(true)
                    }
                }
                "openNotificationPolicySettings" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        val intent = Intent(Settings.ACTION_NOTIFICATION_POLICY_ACCESS_SETTINGS)
                        intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
                        startActivity(intent)
                        result.success(true)
                    } else {
                        result.success(false)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
}
