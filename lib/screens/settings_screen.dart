import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/models.dart';

/// Settings screen for configuring AI backend and permissions
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  EngineType _selectedEngineType = EngineType.localStudio;
  final TextEditingController _baseUrlController = TextEditingController(
    text: 'http://192.168.1.100:8080',
  );
  final TextEditingController _modelController = TextEditingController(
    text: 'local-model',
  );
  final TextEditingController _apiKeyController = TextEditingController();
  
  bool _isTesting = false;
  String? _testResult;
  bool _hasAccessibility = false;
  bool _hasOverlay = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
    _loadSettings();
  }

  void _checkPermissions() async {
    final accessibility = await checkAccessibilityPermission();
    final overlay = await checkOverlayPermission();
    if (mounted) {
      setState(() {
        _hasAccessibility = accessibility;
        _hasOverlay = overlay;
      });
    }
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final configJson = prefs.getString('engine_config');
    if (configJson != null) {
      final config = EngineConfig.fromJson(jsonDecode(configJson));
      if (mounted) {
        setState(() {
          _selectedEngineType = config.type;
          _baseUrlController.text = config.baseUrl;
          _modelController.text = config.model;
          _apiKeyController.text = config.apiKey ?? '';
        });
      }
    }
  }

  Future<void> _saveSettings() async {
    final config = EngineConfig(
      type: _selectedEngineType,
      name: _selectedEngineType.name,
      baseUrl: _baseUrlController.text.trim(),
      apiKey: _apiKeyController.text.isEmpty ? null : _apiKeyController.text,
      model: _modelController.text.trim(),
    );
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('engine_config', jsonEncode(config.toJson()));
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settings saved')),
      );
    }
  }

  Future<void> _testConnection() async {
    setState(() {
      _isTesting = true;
      _testResult = null;
    });

    final config = EngineConfig(
      type: _selectedEngineType,
      name: _selectedEngineType.name,
      baseUrl: _baseUrlController.text.trim(),
      apiKey: _apiKeyController.text.isEmpty ? null : _apiKeyController.text,
      model: _modelController.text.trim(),
    );

    // Import the service here to avoid circular dependency
    // In a real app, you'd inject this properly
    try {
      // Simulated test - in real app, use LocalAIService
      await Future.delayed(const Duration(seconds: 2));
      setState(() {
        _testResult = 'Connection test requires actual service instance';
        _isTesting = false;
      });
    } catch (e) {
      setState(() {
        _testResult = 'Failed: ${e.toString()}';
        _isTesting = false;
      });
    }
  }

  @override
  void dispose() {
    _baseUrlController.dispose();
    _modelController.dispose();
    _apiKeyController.dispose();
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
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Settings',
          style: TextStyle(color: Color(0xFF00F5A0)),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Permissions Section
            _buildPermissionsCard(),
            
            const SizedBox(height: 24),
            
            // Engine Selection
            _buildEngineSelectionCard(),
            
            const SizedBox(height: 24),
            
            // Connection Settings
            _buildConnectionSettingsCard(),
            
            const SizedBox(height: 32),
            
            // Save Button
            ElevatedButton(
              onPressed: _saveSettings,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00F5A0),
                foregroundColor: const Color(0xFF08080A),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Save Configuration',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionsCard() {
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
          const Text(
            'Permissions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          
          _buildPermissionTile(
            icon: Icons.accessibility_new,
            title: 'Accessibility Service',
            subtitle: 'Required for screen reading and gestures',
            isGranted: _hasAccessibility,
            onGrant: () => requestAccessibilityPermission(),
          ),
          
          const Divider(color: Color(0xFF22222C)),
          
          _buildPermissionTile(
            icon: Icons.layers,
            title: 'Display Over Other Apps',
            subtitle: 'Required for floating control pill',
            isGranted: _hasOverlay,
            onGrant: () => requestOverlayPermission(),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isGranted,
    required VoidCallback onGrant,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        icon,
        color: isGranted ? const Color(0xFF00F5A0) : Colors.orange,
      ),
      title: Text(
        title,
        style: const TextStyle(color: Colors.white, fontSize: 14),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
      ),
      trailing: isGranted
          ? const Icon(Icons.check_circle, color: Color(0xFF00F5A0), size: 20)
          : TextButton(
              onPressed: onGrant,
              child: const Text('GRANT'),
            ),
    );
  }

  Widget _buildEngineSelectionCard() {
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
          const Text(
            'AI Backend',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: EngineType.values.map((type) {
              final isSelected = _selectedEngineType == type;
              return ChoiceChip(
                label: Text(_getEngineTypeName(type)),
                selected: isSelected,
                selectedColor: const Color(0xFF00F5A0).withOpacity(0.2),
                labelStyle: TextStyle(
                  color: isSelected 
                      ? const Color(0xFF00F5A0) 
                      : Colors.white.withOpacity(0.7),
                ),
                side: BorderSide(
                  color: isSelected 
                      ? const Color(0xFF00F5A0) 
                      : const Color(0xFF22222C),
                ),
                onSelected: (selected) {
                  if (selected) {
                    setState(() => _selectedEngineType = type);
                  }
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionSettingsCard() {
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
          const Text(
            'Connection',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          
          TextField(
            controller: _baseUrlController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Base URL',
              labelStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
              hintText: 'http://192.168.1.100:8080',
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
              filled: true,
              fillColor: const Color(0xFF08080A),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              prefixIcon: const Icon(Icons.link, color: Color(0xFF00D2FF)),
            ),
          ),
          
          const SizedBox(height: 16),
          
          TextField(
            controller: _modelController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Model Name',
              labelStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
              hintText: 'llama3, mistral, etc.',
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
              filled: true,
              fillColor: const Color(0xFF08080A),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              prefixIcon: const Icon(Icons.smart_toy, color: Color(0xFF00D2FF)),
            ),
          ),
          
          const SizedBox(height: 16),
          
          TextField(
            controller: _apiKeyController,
            style: const TextStyle(color: Colors.white),
            obscureText: true,
            decoration: InputDecoration(
              labelText: 'API Key (Optional)',
              labelStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
              hintText: 'For cloud backends only',
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
              filled: true,
              fillColor: const Color(0xFF08080A),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              prefixIcon: const Icon(Icons.key, color: Color(0xFF00D2FF)),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Test Connection Button
          OutlinedButton.icon(
            onPressed: _isTesting ? null : _testConnection,
            icon: _isTesting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.wifi_find, size: 18),
            label: Text(_isTesting ? 'Testing...' : 'Test Connection'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF00D2FF),
              side: const BorderSide(color: Color(0xFF00D2FF)),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
          
          if (_testResult != null) ...[
            const SizedBox(height: 12),
            Text(
              _testResult!,
              style: TextStyle(
                color: _testResult!.contains('Failed') ? Colors.red : const Color(0xFF00F5A0),
                fontSize: 13,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _getEngineTypeName(EngineType type) {
    switch (type) {
      case EngineType.localStudio:
        return 'Local Studio';
      case EngineType.ollama:
        return 'Ollama';
      case EngineType.cloud:
        return 'Cloud API';
    }
  }
}

// Re-export bridge functions for settings
Future<bool> checkAccessibilityPermission() => 
    AccessibilityBridge.checkAccessibilityPermission();
Future<void> requestAccessibilityPermission() => 
    AccessibilityBridge.requestAccessibilityPermission();
Future<bool> checkOverlayPermission() => 
    AccessibilityBridge.checkOverlayPermission();
Future<void> requestOverlayPermission() => 
    AccessibilityBridge.requestOverlayPermission();
