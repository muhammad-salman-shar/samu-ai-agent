import 'package:flutter/material.dart';
import '../services/task_executor.dart';
import '../services/services.dart';
import '../models/models.dart';

/// Active task execution view showing real-time thought -> action log
class ActiveTaskScreen extends StatefulWidget {
  final String goal;

  const ActiveTaskScreen({super.key, required this.goal});

  @override
  State<ActiveTaskScreen> createState() => _ActiveTaskScreenState();
}

class _ActiveTaskScreenState extends State<ActiveTaskScreen> {
  late TaskExecutor _executor;
  final ScrollController _scrollController = ScrollController();
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _executor = TaskExecutor();
    _setupExecutorCallbacks();
    
    // Start the task after a short delay to allow UI to build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _executor.startTask(widget.goal);
    });
  }

  void _setupExecutorCallbacks() {
    _executor.onStateChanged = (state) {
      if (mounted) setState(() {});
    };
    
    _executor.onLogEntry = (log) {
      if (mounted) {
        setState(() {});
        // Auto-scroll to bottom
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
            );
          }
        });
      }
    };
    
    _executor.onError = (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $error'), backgroundColor: Colors.red),
        );
      }
    };
  }

  @override
  void dispose() {
    _executor.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF08080A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF131318),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF00F5A0)),
          onPressed: () {
            _executor.stop();
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'Agent Running',
          style: TextStyle(color: Color(0xFF00F5A0)),
        ),
        actions: [
          // Emergency Stop Button
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: ElevatedButton.icon(
              onPressed: () {
                _executor.emergencyStop();
                Navigator.pop(context);
              },
              icon: const Icon(Icons.stop, size: 18),
              label: const Text('STOP'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.withOpacity(0.2),
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Status Header
          _buildStatusHeader(),
          
          // Goal Display
          _buildGoalCard(),
          
          // Execution Log
          Expanded(
            child: _buildExecutionLog(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusHeader() {
    final stateColor = _getStateColor(_executor.state);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF131318),
        border: Border(
          bottom: BorderSide(color: const Color(0xFF22222C)),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: stateColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            _executor.state.name.toUpperCase(),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: stateColor,
              letterSpacing: 1,
            ),
          ),
          const Spacer(),
          Text(
            '${_executor.executionHistory.length} actions',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF131318),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF22222C)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Goal',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.5),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.goal,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExecutionLog() {
    final logs = _executor.executionHistory;
    
    if (logs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.psychology_outlined,
              size: 64,
              color: Colors.white.withOpacity(0.2),
            ),
            const SizedBox(height: 16),
            Text(
              'Thinking...',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withOpacity(0.5),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: logs.length,
      itemBuilder: (context, index) {
        final log = logs[index];
        return _buildLogEntry(log, index == logs.length - 1);
      },
    );
  }

  Widget _buildLogEntry(ExecutionLog log, bool isLatest) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isLatest 
            ? const Color(0xFF131318).withOpacity(0.8)
            : const Color(0xFF131318),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isLatest 
              ? const Color(0xFF00F5A0).withOpacity(0.3)
              : const Color(0xFF22222C),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timestamp and status
          Row(
            children: [
              Text(
                log.formattedTime,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white.withOpacity(0.4),
                ),
              ),
              const SizedBox(width: 8),
              if (log.result.success)
                const Icon(Icons.check_circle, size: 14, color: Color(0xFF00F5A0))
              else
                const Icon(Icons.error, size: 14, color: Colors.orange),
              const Spacer(),
              _buildActionChip(log.action.type),
            ],
          ),
          const SizedBox(height: 10),
          // Thought
          Text(
            '💭 ${log.thought}',
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withOpacity(0.9),
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 8),
          // Action details
          Text(
            '→ ${_formatActionDetails(log.action)}',
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF00D2FF),
            ),
          ),
          if (!log.result.success) ...[
            const SizedBox(height: 8),
            Text(
              '⚠ ${log.result.message}',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.orange,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionChip(ActionType type) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF00F5A0).withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        type.name,
        style: const TextStyle(
          fontSize: 10,
          color: Color(0xFF00F5A0),
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _formatActionDetails(AgentAction action) {
    switch (action.type) {
      case ActionType.CLICK:
        return 'Click node #${action.targetId}';
      case ActionType.TAP:
        return 'Tap at (${action.x}, ${action.y})';
      case ActionType.SWIPE:
        return 'Swipe from (${action.startX}, ${action.startY}) to (${action.endX}, ${action.endY})';
      case ActionType.SET_TEXT:
        return 'Type "${action.text}" on node #${action.targetId}';
      case ActionType.GO_BACK:
        return 'Go Back';
      case ActionType.GO_HOME:
        return 'Go Home';
      case ActionType.SCROLL_UP:
        return 'Scroll Up';
      case ActionType.SCROLL_DOWN:
        return 'Scroll Down';
      case ActionType.WAIT:
        return 'Wait ${action.waitMs ?? 600}ms';
      default:
        return action.type.name;
    }
  }

  Color _getStateColor(TaskState state) {
    switch (state) {
      case TaskState.idle:
        return Colors.grey;
      case TaskState.running:
        return const Color(0xFF00F5A0);
      case TaskState.paused:
        return Colors.orange;
      case TaskState.completed:
        return const Color(0xFF00D2FF);
      case TaskState.error:
        return Colors.red;
    }
  }
}
