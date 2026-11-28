package com.example.abakascan

import android.Manifest
import android.app.Activity
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import io.flutter.plugin.common.MethodChannel

class CompletionNotifier(private val activity: Activity) {
    companion object { const val REQUEST = 4203; const val CHANNEL = "analysis_completion" }
    @Volatile var analyzeVisible = false
    @Volatile var foreground = false
    private var pending: MethodChannel.Result? = null
    private val manager get() = activity.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
    fun prepare(result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT >= 26) {
            manager.createNotificationChannel(NotificationChannel(CHANNEL, "Analysis completion", NotificationManager.IMPORTANCE_DEFAULT))
        }
        if (Build.VERSION.SDK_INT >= 33 && activity.checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED) {
            if (pending != null) { result.success(false); return }
            pending = result
            try { activity.requestPermissions(arrayOf(Manifest.permission.POST_NOTIFICATIONS), REQUEST) }
            catch (_: Exception) { pending = null; result.success(false) }
        } else result.success(manager.areNotificationsEnabled())
    }
    fun permissionResult(requestCode: Int, grants: IntArray) {
        if (requestCode != REQUEST) return
        pending?.success(grants.isNotEmpty() && grants[0] == PackageManager.PERMISSION_GRANTED)
        pending = null
    }
    fun dispose() { pending?.success(false); pending = null }
    @Suppress("DEPRECATION")
    fun show(workspaceVisible: Boolean = true) {
        if (foreground && analyzeVisible && workspaceVisible) return
        // Alerts are optional and must not change the classification/save outcome.
        try {
            if (Build.VERSION.SDK_INT >= 33 && activity.checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED) return
            if (!manager.areNotificationsEnabled()) return
            if (Build.VERSION.SDK_INT >= 26) manager.createNotificationChannel(NotificationChannel(CHANNEL, "Analysis completion", NotificationManager.IMPORTANCE_DEFAULT))
            val intent = Intent(activity, MainActivity::class.java).addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP)
            val tap = PendingIntent.getActivity(activity, 4204, intent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
            val builder = if (Build.VERSION.SDK_INT >= 26) Notification.Builder(activity, CHANNEL) else Notification.Builder(activity)
            val notification = builder.setSmallIcon(android.R.drawable.ic_dialog_info)
                .setContentTitle("ABAKASCAN").setContentText("The analysis is done")
                .setContentIntent(tap).setAutoCancel(true).setCategory(Notification.CATEGORY_STATUS)
                .setVisibility(Notification.VISIBILITY_PRIVATE).build()
            manager.notify(4204, notification)
        } catch (_: Exception) { /* Result and local save remain successful. */ }
    }
}
