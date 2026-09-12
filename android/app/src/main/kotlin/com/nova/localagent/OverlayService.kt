package com.nova.localagent

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.graphics.PixelFormat
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.view.Gravity
import android.view.LayoutInflater
import android.view.MotionEvent
import android.view.View
import android.view.WindowManager
import android.widget.LinearLayout
import android.widget.TextView
import androidx.core.app.NotificationCompat

class OverlayService : Service() {

    companion object {
        private const val CHANNEL_ID = "NovaAgentOverlayChannel"
        private const val NOTIFICATION_ID = 1001
        private const val OVERLAY_TAG = "nova_overlay_pill"
        
        @Volatile
        var isRunning: Boolean = false
            private set
        
        var emergencyStopCallback: (() -> Unit)? = null
    }

    private lateinit var windowManager: WindowManager
    private lateinit var overlayView: View
    private var isViewAdded = false

    private val handler = Handler(Looper.getMainLooper())

    override fun onCreate() {
        super.onCreate()
        windowManager = getSystemService(WINDOW_SERVICE) as WindowManager
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val action = intent?.action
        
        when (action) {
            "STOP_OVERLAY" -> {
                removeOverlay()
                stopSelf()
                return START_NOT_STICKY
            }
            else -> {
                startForeground(NOTIFICATION_ID, createNotification())
                showOverlay()
                isRunning = true
            }
        }
        
        return START_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onDestroy() {
        removeOverlay()
        isRunning = false
        super.onDestroy()
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "NovaAgent Overlay Control",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Control pill for NovaAgent AI automation"
                setShowBadge(false)
            }
            
            val notificationManager = getSystemService(NotificationManager::class.java)
            notificationManager.createNotificationChannel(channel)
        }
    }

    private fun createNotification(): Notification {
        val stopIntent = Intent(this, OverlayService::class.java).apply {
            action = "STOP_OVERLAY"
        }
        val stopPendingIntent = PendingIntent.getService(
            this, 0, stopIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("NovaAgent Active")
            .setContentText("AI agent is running. Tap the floating pill to stop.")
            .setSmallIcon(android.R.drawable.ic_menu_compass)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setOngoing(true)
            .addAction(android.R.drawable.ic_media_pause, "Stop", stopPendingIntent)
            .build()
    }

    private fun showOverlay() {
        if (isViewAdded) return

        // Create a simple pill view programmatically
        overlayView = LinearLayout(this).apply {
            id = View.generateViewId()
            tag = OVERLAY_TAG
            
            val layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.WRAP_CONTENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            ).apply {
                gravity = Gravity.CENTER
            }
            
            background = android.graphics.drawable.GradientDrawable().apply {
                setColor(android.graphics.Color.parseColor("#131318"))
                cornerRadius = 50f
                setStroke(2, android.graphics.Color.parseColor("#00F5A0"))
            }
            
            setPadding(24, 12, 24, 12)
            elevation = 8f
            
            addView(TextView(this@apply.context).apply {
                text = "⏹ STOP"
                setTextColor(android.graphics.Color.parseColor("#00F5A0"))
                textSize = 14f
                isAllCaps = true
            })
        }

        val params = WindowManager.LayoutParams(
            WindowManager.LayoutParams.WRAP_CONTENT,
            WindowManager.LayoutParams.WRAP_CONTENT,
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O)
                WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
            else
                WindowManager.LayoutParams.TYPE_PHONE,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN or
                WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS,
            PixelFormat.TRANSLUCENT
        ).apply {
            gravity = Gravity.TOP or Gravity.END
            x = 100
            y = 200
        }

        // Make draggable
        overlayView.setOnTouchListener { view, event ->
            when (event.action) {
                MotionEvent.ACTION_DOWN -> {
                    // Check if tap (not drag)
                    handler.postDelayed({
                        if (!view.isPressed) {
                            // It was a tap - trigger emergency stop
                            emergencyStopCallback?.invoke()
                            removeOverlay()
                            stopSelf()
                        }
                    }, 150)
                    true
                }
                MotionEvent.ACTION_UP -> {
                    view.isPressed = false
                    true
                }
                MotionEvent.ACTION_MOVE -> {
                    // Handle dragging
                    params.x = event.rawX.toInt() - overlayView.width / 2
                    params.y = event.rawY.toInt() - overlayView.height / 2
                    windowManager.updateViewLayout(overlayView, params)
                    view.isPressed = true
                    handler.removeCallbacksAndMessages(null)
                    true
                }
                else -> false
            }
        }

        try {
            windowManager.addView(overlayView, params)
            isViewAdded = true
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    private fun removeOverlay() {
        if (isViewAdded) {
            try {
                windowManager.removeView(overlayView)
            } catch (e: Exception) {
                // View might already be removed
            }
            isViewAdded = false
        }
    }

    companion object {
        fun getStartIntent(context: Context): Intent {
            return Intent(context, OverlayService::class.java)
        }
        
        fun getStopIntent(context: Context): Intent {
            return Intent(context, OverlayService::class.java).apply {
                action = "STOP_OVERLAY"
            }
        }
    }
}
