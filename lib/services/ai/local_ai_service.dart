import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/models.dart';

/// Service for communicating with local/remote AI backends
class LocalAIService {
  EngineConfig _config;
  final http.Client _client;

  LocalAIService({
    EngineConfig config = const EngineConfig(
      type: EngineType.localStudio,
      name: 'Local Studio',
      baseUrl: 'http://192.168.1.100:8080',
      model: 'local-model',
    ),
    http.Client? client,
  })  : _config = config,
        _client = client ?? http.Client();

  EngineConfig get currentConfig => _config;

  /// Update the engine configuration
  void updateConfig(EngineConfig newConfig) {
    _config = newConfig;
  }

  /// Test connection to the backend
  Future<ConnectionTestResult> testConnection() async {
    try {
      final stopwatch = Stopwatch()..start();
      
      // Simple HEAD request to test connectivity
      final response = await _client
          .get(Uri.parse(_config.baseUrl))
          .timeout(Duration(seconds: _config.timeoutSeconds));
      
      stopwatch.stop();
      
      return ConnectionTestResult(
        success: response.statusCode >= 200 && response.statusCode < 400,
        latencyMs: stopwatch.elapsedMilliseconds,
        message: 'Connected to ${_config.name} in ${stopwatch.elapsedMilliseconds}ms',
      );
    } catch (e) {
      return ConnectionTestResult(
        success: false,
        latencyMs: -1,
        message: 'Connection failed: ${e.toString()}',
      );
    }
  }

  /// Send a chat completion request and parse the action response
  Future<AgentAction?> generateAction({
    required String userGoal,
    required List<String> screenNodes,
    String? previousAction,
    String? previousResult,
  }) async {
    final messages = [
      {
        'role': 'system',
        'content': ActionPromptTemplate.systemPrompt,
      },
      {
        'role': 'user',
        'content': ActionPromptTemplate.buildUserPrompt(
          userGoal: userGoal,
          screenNodes: screenNodes,
          previousAction: previousAction,
          previousResult: previousResult,
        ),
      },
    ];

    try {
      final response = await _client
          .post(
            Uri.parse(_config.chatEndpoint),
            headers: {
              'Content-Type': 'application/json',
              if (_config.apiKey != null) 'Authorization': 'Bearer ${_config.apiKey}',
            },
            body: jsonEncode(_buildRequestBody(messages)),
          )
          .timeout(Duration(seconds: _config.timeoutSeconds));

      if (response.statusCode != 200) {
        throw Exception('API error: ${response.statusCode} - ${response.body}');
      }

      final responseData = jsonDecode(response.body);
      final content = _extractResponseContent(responseData);
      
      if (content.isEmpty) {
        throw Exception('Empty response from AI');
      }

      // Parse the JSON action from the response
      final actionJson = _parseJsonFromResponse(content);
      if (actionJson == null) {
        throw Exception('Could not parse action from response: $content');
      }

      return AgentAction.fromJson(actionJson);
    } catch (e) {
      throw Exception('Failed to generate action: ${e.toString()}');
    }
  }

  /// Build request body based on engine type
  Map<String, dynamic> _buildRequestBody(List<Map<String, String>> messages) {
    switch (_config.type) {
      case EngineType.localStudio:
      case EngineType.cloud:
        // OpenAI-compatible format
        return {
          'model': _config.model,
          'messages': messages,
          'temperature': 0.1, // Low temperature for deterministic actions
          'max_tokens': 500,
        };
        
      case EngineType.ollama:
        // Ollama format
        return {
          'model': _config.model,
          'prompt': messages.map((m) => m['content']).join('\n\n'),
          'stream': false,
          'options': {
            'temperature': 0.1,
          },
        };
    }
  }

  /// Extract content from response based on engine type
  String _extractResponseContent(Map<String, dynamic> responseData) {
    switch (_config.type) {
      case EngineType.localStudio:
      case EngineType.cloud:
        // OpenAI format: choices[0].message.content
        final choices = responseData['choices'] as List?;
        if (choices == null || choices.isEmpty) {
          return '';
        }
        final message = choices[0]['message'] as Map?;
        return message?['content'] as String? ?? '';
        
      case EngineType.ollama:
        // Ollama format: response field
        return responseData['response'] as String? ?? '';
    }
  }

  /// Parse JSON from the AI response (handles markdown code blocks)
  Map<String, dynamic>? _parseJsonFromResponse(String content) {
    // Try to extract JSON from markdown code blocks
    final jsonBlockRegex = RegExp(r'```(?:json)?\s*([\s\S]*?)\s*```');
    final match = jsonBlockRegex.firstMatch(content);
    
    String jsonString;
    if (match != null) {
      jsonString = match.group(1)!.trim();
    } else {
      // Try to find JSON object directly
      final braceStart = content.indexOf('{');
      final braceEnd = content.lastIndexOf('}');
      if (braceStart == -1 || braceEnd == -1) {
        return null;
      }
      jsonString = content.substring(braceStart, braceEnd + 1);
    }

    try {
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  void dispose() {
    _client.close();
  }
}

/// Result of a connection test
class ConnectionTestResult {
  final bool success;
  final int latencyMs;
  final String message;

  ConnectionTestResult({
    required this.success,
    required this.latencyMs,
    required this.message,
  });
}
