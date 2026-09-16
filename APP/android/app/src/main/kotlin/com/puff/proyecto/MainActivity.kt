package com.puff.proyecto

import android.app.admin.DevicePolicyManager
import android.content.ComponentName
import android.content.Context
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.colegiosanmartin.mdm/kiosk"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            val dpm = getSystemService(Context.DEVICE_POLICY_SERVICE) as? DevicePolicyManager

            when (call.method) {
                "isDeviceOwner" -> {
                    val isOwner = dpm?.isDeviceOwnerApp(packageName) ?: false
                    result.success(isOwner)
                }
                "startLockTask" -> {
                    try {
                        startLockTask()
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("LOCK_TASK_ERROR", e.message, null)
                    }
                }
                "stopLockTask" -> {
                    try {
                        stopLockTask()
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("STOP_LOCK_TASK_ERROR", e.message, null)
                    }
                }
                "setPackageSuspended" -> {
                    val targetPackage = call.argument<String>("packageName")
                    val suspended = call.argument<Boolean>("suspended") ?: false
                    if (targetPackage != null && dpm != null && dpm.isDeviceOwnerApp(packageName)) {
                        try {
                            val adminComponent = ComponentName(this, MainActivity::class.java)
                            dpm.setPackagesSuspended(adminComponent, arrayOf(targetPackage), suspended)
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("SUSPEND_ERROR", e.message, null)
                        }
                    } else {
                        result.success(false)
                    }
                }
                "setStatusBarDisabled" -> {
                    val disabled = call.argument<Boolean>("disabled") ?: false
                    if (dpm != null && dpm.isDeviceOwnerApp(packageName)) {
                        try {
                            val adminComponent = ComponentName(this, MainActivity::class.java)
                            dpm.setStatusBarDisabled(adminComponent, disabled)
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("STATUS_BAR_ERROR", e.message, null)
                        }
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
