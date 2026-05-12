package com.PakRentals.PakRentals

import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterFragmentActivity

// flutter_stripe requires FlutterFragmentActivity instead of FlutterActivity
class MainActivity : FlutterFragmentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Explicitly create notification channel for Android 8.0+
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                "pakrentals_high",
                "PakRentals Notifications",
                NotificationManager.IMPORTANCE_HIGH
            )
            channel.description = "Booking requests, approvals, messages"
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(channel)
        }
    }
}
