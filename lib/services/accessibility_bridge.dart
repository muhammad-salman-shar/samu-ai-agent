import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/models.dart';
import 'ai/local_ai_service.dart';

/// Native bridge to Android Accessibility Service
class AccessibilityBridge {
  static const MethodChannel _channel = MethodChannel('com.nova.localagent/bridge');

  /// Check if accessibility service is enabled
  static Future<bool> checkAccessibilityPermission() async {
    try {
      final result = await _channel.invokeMethod<bool>('checkAccessibilityPermission');
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Open accessibility settings
  static Future<void> requestAccessibilityPermission() async {
    await _channel.invokeMethod('requestAccessibilityPermission');
  }

  /// Check if overlay permission is granted
  static Future<bool> checkOverlayPermission() async {
    try {
      final result = await _channel.invokeMethod<bool>('checkOverlayPermission');
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Open overlay permission settings
  static Future<void> requestOverlayPermission() async {
    await _channel.invokeMethod('requestOverlayPermission');
  }

  /// Get current screen nodes as JSON string
  static Future<String> getScreenNodesJson() async {
    try {
      final result = await _channel.invokeMethod<String>('getScreenNodes');
      return result ?? '[]';
    } catch (e) {
      return '[]';
    }
  }

  /// Parse screen nodes from native
  static Future<List<ScreenNode>> getScreenNodes() async {
    final jsonStr = await getScreenNodesJson();
    try {
      final List<dynamic> jsonArray = jsonDecode(jsonStr);
      return jsonArray.map((item) => ScreenNode.fromJson(item as Map<String, dynamic>)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Tap at coordinates
  static Future<bool> tap(int x, int y) async {
    try {
      final result = await _channel.invokeMethod<bool>('tap', {'x': x, 'y': y});
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Swipe gesture
  static Future<bool> swipe({
    required int startX,
    required int startY,
    required int endX,
    required int endY,
    int duration = 300,
  }) async {
    try {
      final result = await _channel.invokeMethod<bool>('swipe', {
        'startX': startX,
        'startY': startY,
        'endX': endX,
        'endY': endY,
        'duration': duration,
      });
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Click on a node by ID
  static Future<bool> clickNode(int nodeId) async {
    try {
      final result = await _channel.invokeMethod<bool>('clickNode', {'nodeId': nodeId});
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Set text on an editable node
  static Future<bool> setText(int nodeId, String text) async {
    try {
      final result = await _channel.invokeMethod<bool>('setText', {
        'nodeId': nodeId,
        'text': text,
      });
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  /// System back action
  static Future<bool> goBack() async {
    try {
      final result = await _channel.invokeMethod<bool>('goBack');
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  /// System home action
  static Future<bool> goHome() async {
    try {
      final result = await _channel.invokeMethod<bool>('goHome');
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Open recent apps
  static Future<bool> openRecents() async {
    try {
      final result = await _channel.invokeMethod<bool>('openRecents');
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Start the floating overlay pill
  static Future<bool> startOverlay() async {
    try {
      final result = await _channel.invokeMethod<bool>('startOverlay');
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Stop the floating overlay pill
  static Future<bool> stopOverlay() async {
    try {
      final result = await _channel.invokeMethod<bool>('stopOverlay');
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Check if overlay is running
  static Future<bool> isOverlayRunning() async {
    try {
      final result = await _channel.invokeMethod<bool>('isOverlayRunning');
      return result ?? false;
    } catch (e) {
      return false;
    }
  }
}
