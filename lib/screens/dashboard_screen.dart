import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/services.dart';
import '../models/models.dart';
import 'active_task_screen.dart';
import 'settings_screen.dart';

/// Main dashboard screen with prompt box, quick actions, and engine status
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final TextEditingController _goalController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _goalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF08080A),
      body: SafeArea(
        child: Column(
          children: [
            // Top Status Bar
            _buildStatusBar(),
            
            // Main Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // App Title
                    Text(
                      'NovaAgent',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF00F5A0),
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Local AI Automation',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.5),
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Goal Input Card
                    _buildGoalInputCard(),
                    
                    const SizedBox(height: 24),
                    
                    // Quick Actions
                    _buildQuickActions(),
                    
                    const SizedBox(height: 24),
                    
                    // Recent Tasks
                    _buildRecentTasks(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF131318),
        border: Border(
          bottom: BorderSide(
            color: const Color(0xFF22222C),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Connection Status
          _buildStatusChip(
            icon: Icons.wifi,
            label: 'Local',
            color: const Color(0xFF00F5A0),
          ),
          
          const SizedBox(width: 12),
          
          // Accessibility Status
          FutureBuilder<bool>(
            future: AccessibilityBridge.checkAccessibilityPermission(),
            builder: (context, snapshot) {
              final isActive = snapshot.data ?? false;
              return _buildStatusChip(
                icon: Icons.accessibility_new,
                label: isActive ? 'Active' : 'Inactive',
                color: isActive ? const Color(0xFF00F5A0) : Colors.orange,
              );
            },
          ),
          
          const Spacer(),
          
          // Settings Button
          IconButton(
            icon: const Icon(Icons.settings, size: 22),
            color: Colors.white.withOpacity(0.7),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalInputCard() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF131318),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF22222C)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What should I do?',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.9),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _goalController,
            maxLines: 3,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'e.g., Open WhatsApp and send "Hello" to Bilal',
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
              filled: true,
              fillColor: const Color(0xFF08080A),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _startTask,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00F5A0),
                foregroundColor: const Color(0xFF08080A),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF08080A)),
                      ),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.play_arrow, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Start Agent',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 14,
            color: Colors.white.withOpacity(0.5),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildQuickActionChip('Open Settings', Icons.settings),
            _buildQuickActionChip('Search Contact', Icons.person_search),
            _buildQuickActionChip('Send Message', Icons.message),
            _buildQuickActionChip('Take Screenshot', Icons.screenshot),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionChip(String label, IconData icon) {
    return ActionChip(
      avatar: Icon(icon, size: 16, color: const Color(0xFF00D2FF)),
      label: Text(
        label,
        style: const TextStyle(fontSize: 13, color: Colors.white),
      ),
      backgroundColor: const Color(0xFF131318),
      side: const BorderSide(color: Color(0xFF22222C)),
      onPressed: () {
        // Quick action handlers
      },
    );
  }

  Widget _buildRecentTasks() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Tasks',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.5),
                fontWeight: FontWeight.w500,
              ),
            ),
            TextButton(
              onPressed: () {},
              child: const Text(
                'View All',
                style: TextStyle(color: Color(0xFF00D2FF), fontSize: 12),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Empty state or recent tasks list
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF131318),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF22222C)),
          ),
          child: Center(
            child: Text(
              'No recent tasks',
              style: TextStyle(color: Colors.white.withOpacity(0.3)),
            ),
          ),
        ),
      ],
    );
  }

  void _startTask() async {
    final goal = _goalController.text.trim();
    if (goal.isEmpty) return;

    setState(() => _isLoading = true);

    // Check permissions first
    final hasAccessibility = await AccessibilityBridge.checkAccessibilityPermission();
    if (!hasAccessibility) {
      await AccessibilityBridge.requestAccessibilityPermission();
      setState(() => _isLoading = false);
      return;
    }

    // Start overlay
    await AccessibilityBridge.startOverlay();

    // Navigate to active task screen
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ActiveTaskScreen(goal: goal),
        ),
      );
      setState(() => _isLoading = false);
    }
  }
}
