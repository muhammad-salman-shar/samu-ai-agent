package com.nova.localagent

import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import android.util.Log
import androidx.annotation.OptIn
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.StandardMethodCodec
import org.json.JSONObject

class MainActivity : FlutterActivity() {

    companion object {
        private const val TAG = "NovaMainActivity"
        private const val CHANNEL = "com.nova.localagent/bridge"
    }

    private var methodChannel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        methodChannel = MethodChannel(this, CHANNEL).apply {
            setMethodCallHandler { call, result ->
                when (call.method) {
                    "checkAccessibilityPermission" -> {
                        val hasPermission = isAccessibilityServiceEnabled()
                        result.success(hasPermission)
                    }
                    "requestAccessibilityPermission" -> {
                        openAccessibilitySettings()
                        result.success(true)
                    }
                    "checkOverlayPermission" -> {
                        val hasPermission = Settings.canDrawOverlays(this@MainActivity)
                        result.success(hasPermission)
                    }
                    "requestOverlayPermission" -> {
                        openOverlaySettings()
                        result.success(true)
                    }
                    "getScreenNodes" -> {
                        val nodesJson = NovaAccessibilityService.instance?.getScreenNodes() ?: "[]"
                        result.success(nodesJson)
                    }
                    "tap" -> {
                        val x = call.argument<Int>("x") ?: 0
                        val y = call.argument<Int>("y") ?: 0
                        NovaAccessibilityService.instance?.tap(x, y) { success ->
                            runOnUiThread {
                                result.success(success)
                            }
                        }
                    }
                    "swipe" -> {
                        val startX = call.argument<Int>("startX") ?: 0
                        val startY = call.argument<Int>("startY") ?: 0
                        val endX = call.argument<Int>("endX") ?: 0
                        val endY = call.argument<Int>("endY") ?: 0
                        val duration = call.argument<Int>("duration") ?: 300
                        
                        NovaAccessibilityService.instance?.swipe(startX, startY, endX, endY, duration) { success ->
                            runOnUiThread {
                                result.success(success)
                            }
                        }
                    }
                    "clickNode" -> {
                        val nodeId = call.argument<Int>("nodeId") ?: -1
                        if (nodeId < 0) {
                            result.success(false)
                            return@setMethodCallHandler
                        }
                        
                        NovaAccessibilityService.instance?.clickNode(nodeId) { success ->
                            runOnUiThread {
                                result.success(success)
                            }
                        }
                    }
                    "setText" -> {
                        val nodeId = call.argument<Int>("nodeId") ?: -1
                        val text = call.argument<String>("text") ?: ""
                        
                        if (nodeId < 0) {
                            result.success(false)
                            return@setMethodCallHandler
                        }
                        
                        NovaAccessibilityService.instance?.setText(nodeId, text) { success ->
                            runOnUiThread {
                                result.success(success)
                            }
                        }
                    }
                    "goBack" -> {
                        val success = NovaAccessibilityService.instance?.goBack() ?: false
                        result.success(success)
                    }
                    "goHome" -> {
                        val success = NovaAccessibilityService.instance?.goHome() ?: false
                        result.success(success)
                    }
                    "openRecents" -> {
                        val success = NovaAccessibilityService.instance?.openRecents() ?: false
                        result.success(success)
                    }
                    "startOverlay" -> {
                        startOverlayService()
                        result.success(true)
                    }
                    "stopOverlay" -> {
                        stopOverlayService()
                        result.success(true)
                    }
                    "isOverlayRunning" -> {
                        result.success(OverlayService.isRunning)
                    }
                    else -> {
                        result.notImplemented()
                    }
                }
            }
        }
    }

    private fun isAccessibilityServiceEnabled(): Boolean {
        return NovaAccessibilityService.instance != null
    }

    private fun openAccessibilitySettings() {
        try {
            val intent = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)
            startActivity(intent)
        } catch (e: Exception) {
            Log.e(TAG, "Error opening accessibility settings", e)
        }
    }

    private fun openOverlaySettings() {
        try {
            val intent = Intent(
                Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                android.net.Uri.parse("package:$packageName")
            )
            startActivity(intent)
        } catch (e: Exception) {
            Log.e(TAG, "Error opening overlay settings", e)
        }
    }

    private fun startOverlayService() {
        try {
            val intent = OverlayService.getStartIntent(this)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                startForegroundService(intent)
            } else {
                startService(intent)
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error starting overlay service", e)
        }
    }

    private fun stopOverlayService() {
        try {
            val intent = OverlayService.getStopIntent(this)
            startService(intent)
        } catch (e: Exception) {
            Log.e(TAG, "Error stopping overlay service", e)
        }
    }

    override fun onDestroy() {
        // Clean up
        stopOverlayService()
        super.onDestroy()
    }
}
