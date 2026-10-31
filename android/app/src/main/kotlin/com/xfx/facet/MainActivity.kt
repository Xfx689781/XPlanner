package com.xfx.facet

import android.app.NotificationManager
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "facet/system_settings")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    // 打开本 App 的「应用信息」页，三星上从这里进入 电池 → 不受限制
                    "openAppDetails" -> {
                        try {
                            val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS)
                                .setData(Uri.fromParts("package", packageName, null))
                                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            startActivity(intent)
                            result.success(true)
                        } catch (e: Exception) {
                            result.success(false)
                        }
                    }
                    // 是否已不受电池优化限制（只读查询，不需要额外权限）
                    "isIgnoringBatteryOptimizations" -> {
                        val pm = getSystemService(Context.POWER_SERVICE) as PowerManager
                        result.success(pm.isIgnoringBatteryOptimizations(packageName))
                    }
                    // 能否使用全屏通知（Android 14+ 可能默认没有；更低版本总是可以）
                    "canUseFullScreenIntent" -> {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
                            val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
                            result.success(nm.canUseFullScreenIntent())
                        } else {
                            result.success(true)
                        }
                    }
                    // 闹钟页：临时允许显示在锁屏上方并点亮屏幕；离开闹钟页时关掉，
                    // 不让整个 App 都能在锁屏上打开
                    "setShowOnLockScreen" -> {
                        val show = call.argument<Boolean>("show") == true
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
                            setShowWhenLocked(show)
                            setTurnScreenOn(show)
                        } else {
                            @Suppress("DEPRECATION")
                            val flags = WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                                WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON
                            @Suppress("DEPRECATION")
                            if (show) window.addFlags(flags) else window.clearFlags(flags)
                        }
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
