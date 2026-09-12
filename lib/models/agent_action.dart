/// Represents an action to be executed by the AI agent.
enum ActionType {
  CLICK,      // Click on a node
  TAP,        // Tap at coordinates
  SWIPE,      // Swipe gesture
  SET_TEXT,   // Input text
  PRESS_ENTER,// Submit/Enter
  GO_BACK,    // System back
  GO_HOME,    // System home
  OPEN_RECENTS, // System recents
  WAIT,       // Wait for UI to settle
  SCROLL_UP,  // Scroll up
  SCROLL_DOWN,// Scroll down
}

class AgentAction {
  final ActionType type;
  final String thought;     // AI's reasoning for this action
  final int? targetId;      // Node ID to act upon
  final int? x;             // X coordinate (for TAP)
  final int? y;             // Y coordinate (for TAP)
  final int? startX;        // Start X (for SWIPE)
  final int? startY;        // Start Y (for SWIPE)
  final int? endX;          // End X (for SWIPE)
  final int? endY;          // End Y (for SWIPE)
  final int? duration;      // Gesture duration in ms
  final String? text;       // Text to input (for SET_TEXT)
  final int? waitMs;        // Milliseconds to wait

  const AgentAction({
    required this.type,
    required this.thought,
    this.targetId,
    this.x,
    this.y,
    this.startX,
    this.startY,
    this.endX,
    this.endY,
    this.duration,
    this.text,
    this.waitMs,
  });

  factory AgentAction.fromJson(Map<String, dynamic> json) {
    final actionStr = (json['action'] as String).toUpperCase();
    
    ActionType type;
    switch (actionStr) {
      case 'CLICK':
        type = ActionType.CLICK;
        break;
      case 'TAP':
        type = ActionType.TAP;
        break;
      case 'SWIPE':
        type = ActionType.SWIPE;
        break;
      case 'SET_TEXT':
      case 'TYPE':
      case 'INPUT':
        type = ActionType.SET_TEXT;
        break;
      case 'PRESS_ENTER':
      case 'ENTER':
      case 'SUBMIT':
        type = ActionType.PRESS_ENTER;
        break;
      case 'GO_BACK':
      case 'BACK':
        type = ActionType.GO_BACK;
        break;
      case 'GO_HOME':
      case 'HOME':
        type = ActionType.GO_HOME;
        break;
      case 'OPEN_RECENTS':
      case 'RECENTS':
        type = ActionType.OPEN_RECENTS;
        break;
      case 'WAIT':
      case 'PAUSE':
        type = ActionType.WAIT;
        break;
      case 'SCROLL_UP':
      case 'SCROLLUP':
      case 'UP':
        type = ActionType.SCROLL_UP;
        break;
      case 'SCROLL_DOWN':
      case 'SCROLLDOWN':
      case 'DOWN':
        type = ActionType.SCROLL_DOWN;
        break;
      default:
        type = ActionType.CLICK;
    }

    return AgentAction(
      type: type,
      thought: json['thought'] as String? ?? '',
      targetId: json['target_id'] as int?,
      x: json['x'] as int?,
      y: json['y'] as int?,
      startX: json['startX'] as int?,
      startY: json['startY'] as int?,
      endX: json['endX'] as int?,
      endY: json['endY'] as int?,
      duration: json['duration'] as int?,
      text: json['text'] as String?,
      waitMs: json['wait_ms'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
        'action': type.name,
        'thought': thought,
        if (targetId != null) 'target_id': targetId,
        if (x != null) 'x': x,
        if (y != null) 'y': y,
        if (startX != null) 'startX': startX,
        if (startY != null) 'startY': startY,
        if (endX != null) 'endX': endX,
        if (endY != null) 'endY': endY,
        if (duration != null) 'duration': duration,
        if (text != null) 'text': text,
        if (waitMs != null) 'wait_ms': waitMs,
      };

  @override
  String toString() {
    return 'AgentAction(type: $type, thought: "$thought", targetId: $targetId, text: ${text != null ? '"$text"' : 'null'})';
  }
}

/// Result of executing an agent action
class ActionResult {
  final bool success;
  final String message;
  final DateTime timestamp;

  const ActionResult({
    required this.success,
    required this.message,
    this.timestamp = const DateTime.now(),
  });

  factory ActionResult.success(String message) {
    return ActionResult(success: true, message: message);
  }

  factory ActionResult.failure(String message) {
    return ActionResult(success: false, message: message);
  }
}
