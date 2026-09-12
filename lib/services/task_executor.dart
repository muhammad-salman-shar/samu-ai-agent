import 'dart:async';
import '../models/models.dart';
import '../services/services.dart';

/// Execution state of the task executor
enum TaskState {
  idle,
  running,
  paused,
  completed,
  error,
}

/// Log entry for the execution timeline
class ExecutionLog {
  final DateTime timestamp;
  final String thought;
  final AgentAction action;
  final ActionResult result;

  ExecutionLog({
    required this.timestamp,
    required this.thought,
    required this.action,
    required this.result,
  });

  String get formattedTime => 
      '${timestamp.hour.toString().padLeft(2, '0')}:'
      '${timestamp.minute.toString().padLeft(2, '0')}:'
      '${timestamp.second.toString().padLeft(2, '0')}';
}

/// Orchestrates the perception-action loop for autonomous agent execution
class TaskExecutor {
  final LocalAIService _aiService;
  
  TaskState _state = TaskState.idle;
  String _currentGoal = '';
  final List<ExecutionLog> _executionHistory = [];
  
  AgentAction? _lastAction;
  ActionResult? _lastResult;
  int _retryCount = 0;
  int _maxRetries = 2;
  
  Timer? _executionTimer;
  
  // Callbacks
  Function(TaskState)? onStateChanged;
  Function(ExecutionLog)? onLogEntry;
  Function(String)? onError;
  Function()? onCompleted;

  TaskExecutor({
    LocalAIService? aiService,
  }) : _aiService = aiService ?? LocalAIService();

  TaskState get state => _state;
  String get currentGoal => _currentGoal;
  List<ExecutionLog> get executionHistory => List.unmodifiable(_executionHistory);
  bool get isRunning => _state == TaskState.running;

  /// Start executing a task with the given goal
  Future<void> startTask(String goal) async {
    if (_state == TaskState.running) {
      throw StateError('Task already running');
    }

    _currentGoal = goal;
    _state = TaskState.running;
    _lastAction = null;
    _lastResult = null;
    _retryCount = 0;
    _executionHistory.clear();
    
    onStateChanged?.call(_state);
    
    // Begin the perception-action loop
    await _executeLoop();
  }

  /// Pause the current task
  void pause() {
    if (_state != TaskState.running) return;
    
    _state = TaskState.paused;
    _executionTimer?.cancel();
    onStateChanged?.call(_state);
  }

  /// Resume a paused task
  Future<void> resume() async {
    if (_state != TaskState.paused) return;
    
    _state = TaskState.running;
    onStateChanged?.call(_state);
    await _executeLoop();
  }

  /// Stop the current task
  void stop() {
    _state = TaskState.idle;
    _executionTimer?.cancel();
    _currentGoal = '';
    onStateChanged?.call(_state);
  }

  /// Emergency stop - halts everything immediately
  void emergencyStop() {
    _executionTimer?.cancel();
    _state = TaskState.idle;
    _currentGoal = '';
    AccessibilityBridge.stopOverlay();
    onStateChanged?.call(_state);
  }

  /// Main perception-action loop
  Future<void> _executeLoop() async {
    while (_state == TaskState.running) {
      try {
        // Phase 1: Perception - Get current screen state
        final screenNodes = await AccessibilityBridge.getScreenNodes();
        
        if (screenNodes.isEmpty) {
          await _delay(500);
          continue;
        }

        // Phase 2: Reasoning - Ask AI for next action
        final action = await _aiService.generateAction(
          goal: _currentGoal,
          screenHierarchy: screenNodes.map((n) => n.toPromptString()).join('\n'),
          previousAction: _lastAction?.type.name,
          previousResult: _lastResult?.message,
        );

        if (action == null) {
          throw Exception('AI returned null action');
        }

        // Phase 3: Execution - Perform the action
        final result = await _executeAction(action);

        // Phase 4: Logging
        final logEntry = ExecutionLog(
          timestamp: DateTime.now(),
          thought: action.thought,
          action: action,
          result: result,
        );
        _executionHistory.add(logEntry);
        onLogEntry?.call(logEntry);

        // Update state for next iteration
        _lastAction = action;
        _lastResult = result;

        // Phase 5: Verification & Recovery
        if (!result.success) {
          _retryCount++;
          if (_retryCount >= _maxRetries) {
            // Fallback: Try going back and reassessing
            await AccessibilityBridge.goBack();
            _retryCount = 0;
            await _delay(600);
          }
        } else {
          _retryCount = 0;
        }

        // Check if we should wait
        if (action.type == ActionType.WAIT || action.waitMs != null) {
          await _delay(action.waitMs ?? 600);
        } else {
          // Standard delay for UI to settle
          await _delay(600);
        }

      } catch (e) {
        _state = TaskState.error;
        onError?.call(e.toString());
        onStateChanged?.call(_state);
        break;
      }
    }

    if (_state == TaskState.running) {
      _state = TaskState.completed;
      onStateChanged?.call(_state);
      onCompleted?.call();
    }
  }

  /// Execute a single action and return the result
  Future<ActionResult> _executeAction(AgentAction action) async {
    try {
      bool success = false;
      String message = '';

      switch (action.type) {
        case ActionType.CLICK:
          if (action.targetId != null) {
            success = await AccessibilityBridge.clickNode(action.targetId!);
            message = success ? 'Clicked node ${action.targetId}' : 'Failed to click node ${action.targetId}';
          } else {
            message = 'No target ID specified for CLICK';
          }
          break;

        case ActionType.TAP:
          if (action.x != null && action.y != null) {
            success = await AccessibilityBridge.tap(action.x!, action.y!);
            message = success ? 'Tapped at (${action.x}, ${action.y})' : 'Failed to tap';
          } else {
            message = 'No coordinates specified for TAP';
          }
          break;

        case ActionType.SWIPE:
          if (action.startX != null && action.startY != null && 
              action.endX != null && action.endY != null) {
            success = await AccessibilityBridge.swipe(
              startX: action.startX!,
              startY: action.startY!,
              endX: action.endX!,
              endY: action.endY!,
              duration: action.duration ?? 300,
            );
            message = success ? 'Swiped successfully' : 'Failed to swipe';
          } else {
            message = 'Invalid coordinates for SWIPE';
          }
          break;

        case ActionType.SET_TEXT:
          if (action.targetId != null && action.text != null) {
            success = await AccessibilityBridge.setText(action.targetId!, action.text!);
            message = success ? 'Text set on node ${action.targetId}' : 'Failed to set text';
          } else {
            message = 'Missing targetId or text for SET_TEXT';
          }
          break;

        case ActionType.PRESS_ENTER:
          // Simulated by clicking a search/submit button if available
          message = 'PRESS_ENTER not fully implemented';
          success = true;
          break;

        case ActionType.GO_BACK:
          success = await AccessibilityBridge.goBack();
          message = success ? 'Navigated back' : 'Failed to go back';
          break;

        case ActionType.GO_HOME:
          success = await AccessibilityBridge.goHome();
          message = success ? 'Navigated home' : 'Failed to go home';
          break;

        case ActionType.OPEN_RECENTS:
          success = await AccessibilityBridge.openRecents();
          message = success ? 'Opened recents' : 'Failed to open recents';
          break;

        case ActionType.WAIT:
          success = true;
          message = 'Waiting ${action.waitMs ?? 600}ms';
          break;

        case ActionType.SCROLL_UP:
          // Swipe from bottom to top
          success = await AccessibilityBridge.swipe(
            startX: 500,
            startY: 1500,
            endX: 500,
            endY: 500,
            duration: 300,
          );
          message = success ? 'Scrolled up' : 'Failed to scroll up';
          break;

        case ActionType.SCROLL_DOWN:
          // Swipe from top to bottom
          success = await AccessibilityBridge.swipe(
            startX: 500,
            startY: 500,
            endX: 500,
            endY: 1500,
            duration: 300,
          );
          message = success ? 'Scrolled down' : 'Failed to scroll down';
          break;
      }

      return success 
          ? ActionResult.success(message) 
          : ActionResult.failure(message);
          
    } catch (e) {
      return ActionResult.failure('Execution error: ${e.toString()}');
    }
  }

  Future<void> _delay(int milliseconds) async {
    await Future.delayed(Duration(milliseconds: milliseconds));
  }

  void dispose() {
    stop();
    _aiService.dispose();
  }
}
