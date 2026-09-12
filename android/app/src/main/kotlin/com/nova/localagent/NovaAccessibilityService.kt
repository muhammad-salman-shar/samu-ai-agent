package com.nova.localagent

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.GestureDescription
import android.content.Intent
import android.graphics.Path
import android.graphics.Rect
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo
import org.json.JSONArray
import org.json.JSONObject

class NovaAccessibilityService : AccessibilityService() {

    companion object {
        private const val TAG = "NovaAccessibility"
        
        @Volatile
        var instance: NovaAccessibilityService? = null
            private set

        private val actionCallback: ((String) -> Unit)? = null
    }

    private val handler = Handler(Looper.getMainLooper())
    private var actionResultCallback: ((String) -> Unit)? = null

    override fun onServiceConnected() {
        super.onServiceConnected()
        instance = this
        Log.i(TAG, "Accessibility Service Connected")
    }

    override fun onInterrupt() {
        Log.w(TAG, "Accessibility Service Interrupted")
    }

    override fun onUnbind(intent: Intent?): Boolean {
        instance = null
        Log.i(TAG, "Accessibility Service Disconnected")
        return super.onUnbind(intent)
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        // Intentionally empty - we use rootInActiveWindow for on-demand queries
        // rather than processing every accessibility event for performance
    }

    /**
     * Recursively traverses the active window and extracts actionable nodes.
     * Returns a sanitized JSON array of screen nodes.
     */
    fun getScreenNodes(): String {
        val rootNode = rootInActiveWindow ?: return JSONArray().toString()
        
        val nodes = JSONArray()
        var nodeIdCounter = 0

        try {
            traverseNode(rootNode, nodes, ::nextNodeId)
        } catch (e: Exception) {
            Log.e(TAG, "Error traversing node tree", e)
        } finally {
            rootNode.recycle()
        }

        return nodes.toString()
    }

    private var currentId = 0
    private fun nextNodeId(): Int = ++currentId

    private fun traverseNode(node: AccessibilityNodeInfo?, nodes: JSONArray, idProvider: () -> Int) {
        if (node == null || !node.isVisibleToUser) return

        try {
            val rect = Rect()
            node.getBoundsInScreen(rect)

            // Only include actionable or meaningful nodes
            val isActionable = node.isClickable || node.isLongClickable || 
                node.isCheckable || node.isEditable || node.isEnabled
            
            val hasText = !node.text.isNullOrBlank() || !node.contentDescription.isNullOrBlank()
            
            if (isActionable || hasText) {
                val nodeObj = JSONObject().apply {
                    put("id", idProvider())
                    put("text", node.text?.toString()?.take(200))
                    put("description", node.contentDescription?.toString()?.take(200))
                    put("className", node.className?.toString())
                    put("bounds", JSONObject().apply {
                        put("left", rect.left)
                        put("top", rect.top)
                        put("right", rect.right)
                        put("bottom", rect.bottom)
                    })
                    put("centerX", rect.centerX())
                    put("centerY", rect.centerY())
                    put("isClickable", node.isClickable)
                    put("isEditable", node.isEditable)
                    put("isCheckable", node.isCheckable)
                    put("isChecked", node.isChecked)
                    put("isEnabled", node.isEnabled)
                    put("depth", getNodeDepth(node))
                }
                nodes.put(nodeObj)
            }

            // Traverse children
            for (i in 0 until node.childCount) {
                val child = node.getChild(i)
                traverseNode(child, nodes, idProvider)
                child?.recycle()
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error processing node", e)
            node?.recycle()
        }
    }

    private fun getNodeDepth(node: AccessibilityNodeInfo?): Int {
        var depth = 0
        var parent = node?.parent
        while (parent != null) {
            depth++
            val grandParent = parent.parent
            parent.recycle()
            parent = grandParent
        }
        return depth
    }

    /**
     * Perform a tap gesture at the specified coordinates.
     */
    fun tap(x: Int, y: Int, callback: ((Boolean) -> Unit)? = null) {
        Log.d(TAG, "Tap at ($x, $y)")
        
        val path = Path().apply { moveTo(x.toFloat(), y.toFloat()) }
        val gesture = GestureDescription.StrokeDescription(path, 0, 100)
        
        val result = dispatchGesture(GestureDescription.Builder().addStroke(gesture).build(), 
            object : AccessibilityService.GestureResultCallback() {
                override fun onCompleted(gestureDescription: GestureDescription?) {
                    Log.d(TAG, "Tap completed")
                    callback?.invoke(true)
                }
                
                override fun onCancelled(gestureDescription: GestureDescription?) {
                    Log.w(TAG, "Tap cancelled")
                    callback?.invoke(false)
                }
            }, handler
        )
        
        if (!result) {
            Log.e(TAG, "Failed to dispatch tap gesture")
            callback?.invoke(false)
        }
    }

    /**
     * Perform a swipe gesture from start to end coordinates.
     */
    fun swipe(startX: Int, startY: Int, endX: Int, endY: Int, duration: Int = 300, callback: ((Boolean) -> Unit)? = null) {
        Log.d(TAG, "Swipe from ($startX, $startY) to ($endX, $endY)")
        
        val path = Path().apply { 
            moveTo(startX.toFloat(), startY.toFloat())
            lineTo(endX.toFloat(), endY.toFloat())
        }
        val gesture = GestureDescription.StrokeDescription(path, 0, duration.toLong())
        
        dispatchGesture(GestureDescription.Builder().addStroke(gesture).build(),
            object : AccessibilityService.GestureResultCallback() {
                override fun onCompleted(gestureDescription: GestureDescription?) {
                    Log.d(TAG, "Swipe completed")
                    callback?.invoke(true)
                }
                
                override fun onCancelled(gestureDescription: GestureDescription?) {
                    Log.w(TAG, "Swipe cancelled")
                    callback?.invoke(false)
                }
            }, handler
        )
    }

    /**
     * Set text on an editable node.
     */
    fun setText(nodeId: Int, text: String, callback: ((Boolean) -> Unit)? = null) {
        Log.d(TAG, "Setting text on node $nodeId")
        
        val node = findNodeById(nodeId)
        if (node == null || !node.isEditable) {
            Log.e(TAG, "Node $nodeId not found or not editable")
            callback?.invoke(false)
            return
        }

        try {
            val arguments = Bundle().apply {
                putCharSequence(AccessibilityNodeInfo.ACTION_ARGUMENT_SET_TEXT_CHARSEQUENCE, text)
            }
            
            val result = node.performAction(AccessibilityNodeInfo.ACTION_SET_TEXT, arguments)
            Log.d(TAG, "SetText result: $result")
            callback?.invoke(result)
        } catch (e: Exception) {
            Log.e(TAG, "Error setting text", e)
            callback?.invoke(false)
        } finally {
            node.recycle()
        }
    }

    /**
     * Click on a node by its internal ID.
     */
    fun clickNode(nodeId: Int, callback: ((Boolean) -> Unit)? = null) {
        Log.d(TAG, "Clicking node $nodeId")
        
        val node = findNodeById(nodeId)
        if (node == null) {
            Log.e(TAG, "Node $nodeId not found")
            callback?.invoke(false)
            return
        }

        try {
            if (node.isClickable && node.isEnabled) {
                val result = node.performAction(AccessibilityNodeInfo.ACTION_CLICK)
                Log.d(TAG, "Node click result: $result")
                callback?.invoke(result)
            } else {
                // Fallback to tap at center
                val rect = Rect()
                node.getBoundsInScreen(rect)
                tap(rect.centerX(), rect.centerY(), callback)
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error clicking node", e)
            callback?.invoke(false)
        } finally {
            node.recycle()
        }
    }

    /**
     * Find a node by our internal tracking ID.
     * Note: This is a simplified implementation. In production, you'd want
     * to maintain a map of IDs to node references with proper lifecycle management.
     */
    private fun findNodeById(targetId: Int): AccessibilityNodeInfo? {
        val rootNode = rootInActiveWindow ?: return null
        var foundNode: AccessibilityNodeInfo? = null
        
        try {
            // Reset counter and search
            currentId = 0
            foundNode = findNodeByIdRecursive(rootNode, targetId)
        } finally {
            if (foundNode != rootNode) {
                rootNode.recycle()
            }
        }
        
        return foundNode
    }

    private fun findNodeByIdRecursive(node: AccessibilityNodeInfo?, targetId: Int): AccessibilityNodeInfo? {
        if (node == null || !node.isVisibleToUser) return null

        val isActionable = node.isClickable || node.isLongClickable || 
            node.isCheckable || node.isEditable || node.isEnabled
        val hasText = !node.text.isNullOrBlank() || !node.contentDescription.isNullOrBlank()

        if (isActionable || hasText) {
            currentId++
            if (currentId == targetId) {
                // Return a copy since we need to recycle the original
                return AccessibilityNodeInfo.obtain(node)
            }
        }

        for (i in 0 until node.childCount) {
            val child = node.getChild(i)
            val found = findNodeByIdRecursive(child, targetId)
            child?.recycle()
            if (found != null) return found
        }

        return null
    }

    /**
     * Perform global system actions.
     */
    fun goBack(): Boolean = performGlobalAction(AccessibilityService.GLOBAL_ACTION_BACK)
    fun goHome(): Boolean = performGlobalAction(AccessibilityService.GLOBAL_ACTION_HOME)
    fun openRecents(): Boolean = performGlobalAction(AccessibilityService.GLOBAL_ACTION_RECENTS)
}
