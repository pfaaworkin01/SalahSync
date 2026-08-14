package com.pfaacodin01.salahsync

import android.app.AlarmManager
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.media.AudioManager
import android.os.Build

class SalahAlarmReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val audioManager = context.getSystemService(Context.AUDIO_SERVICE) as AudioManager
        val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

        val action = intent.getStringExtra("action") ?: return
        val salahName = intent.getStringExtra("salahName") ?: "Salah"
        val targetMode = intent.getStringExtra("targetMode") ?: "silent"
        val durationMinutes = intent.getIntExtra("durationMinutes", 20)
        val alarmId = intent.getIntExtra("alarmId", 0)

        val prefs = context.getSharedPreferences("SalahSyncPrefs", Context.MODE_PRIVATE)

        if (action == "MUTE") {
            // Check DND access on Android 6.0+
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && !notificationManager.isNotificationPolicyAccessGranted) {
                return
            }

            try {
                // Save current ringer mode before silencing
                val currentRinger = audioManager.ringerMode
                prefs.edit().putInt("prev_ringer_$alarmId", currentRinger).apply()

                // Switch to target sound mode
                when (targetMode) {
                    "vibrate" -> audioManager.ringerMode = AudioManager.RINGER_MODE_VIBRATE
                    else -> audioManager.ringerMode = AudioManager.RINGER_MODE_SILENT
                }

                // Schedule Restore Alarm after durationMinutes
                scheduleRestoreAlarm(context, alarmId, durationMinutes)
            } catch (e: Exception) {
                e.printStackTrace()
            }
        } else if (action == "RESTORE") {
            try {
                // Read previous ringer mode and restore
                val prevRinger = prefs.getInt("prev_ringer_$alarmId", AudioManager.RINGER_MODE_NORMAL)
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && notificationManager.isNotificationPolicyAccessGranted) {
                    audioManager.ringerMode = prevRinger
                } else if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) {
                    audioManager.ringerMode = prevRinger
                }
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }
    }

    private fun scheduleRestoreAlarm(context: Context, alarmId: Int, durationMinutes: Long) {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val intent = Intent(context, SalahAlarmReceiver::class.java).apply {
            putExtra("action", "RESTORE")
            putExtra("alarmId", alarmId)
        }

        val restorePendingIntent = PendingIntent.getBroadcast(
            context,
            alarmId + 1000,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val triggerAtMillis = System.currentTimeMillis() + (durationMinutes * 60 * 1000)

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            alarmManager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerAtMillis, restorePendingIntent)
        } else {
            alarmManager.setExact(AlarmManager.RTC_WAKEUP, triggerAtMillis, restorePendingIntent)
        }
    }
}
