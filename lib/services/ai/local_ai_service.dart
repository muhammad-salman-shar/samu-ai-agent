import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/models.dart';

class LocalAIService {
  EngineConfig _config;

  LocalAIService({EngineConfig? config})
      : _config = config ??
            const EngineConfig(
              type: EngineType.localStudio,
              name: 'Local Studio',
              baseUrl: 'http://192.168.1.100:8080/v1',
              model: 'default',
            );

  EngineConfig get currentConfig => _config;

  void updateConfig(EngineConfig newConfig) {
    _config = newConfig;
  }

  /// Generate an action based on the user's goal and current screen state.
  /// 
  /// Parameters:
  /// - [goal]: The user's high-level task/goal
  /// - [screenHierarchy]: String representation of the current screen UI nodes
  /// - [previousAction]: Optional previous action type name
  /// - [previousResult]: Optional result message from the previous action
  Future<AgentAction?> generateAction({
    required String goal,
    required String screenHierarchy,
    String? previousAction,
    String? previousResult,
  }) async {
    try {
      final messages = <Map<String, dynamic>>[
        {'role': 'system', 'content': ActionPromptTemplate.systemPrompt},
        {
          'role': 'user',
          'content': ActionPromptTemplate.buildUserPrompt(
            userGoal: goal,
            screenNodes: [screenHierarchy],
            previousAction: previousAction,
            previousResult: previousResult,
          )
        },
      ];

      final response = await http.post(
        Uri.parse('${_config.chatEndpoint}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(_buildRequestBody(messages)),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = _extractResponseContent(data);
        final actionJson = jsonDecode(content);
        return AgentAction.fromJson(actionJson);
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  /// Cleanup any resources held by this service.
  /// Currently no persistent resources require cleanup, but this method
  /// is provided for lifecycle management compatibility.
  void dispose() {
    // No-op: No HTTP client, streams, or other resources require cleanup
  }

  Map<String, dynamic> _buildRequestBody(List<Map<String, dynamic>> messages) {
    switch (_config.type) {
      case EngineType.localStudio:
      case EngineType.cloud:
        return {
          'model': _config.model,
          'messages': messages,
          'temperature': 0.2,
        };
      case EngineType.ollama:
        return {
          'model': _config.model,
          'prompt': messages.isNotEmpty ? messages.last['content'] : '',
          'stream': false,
        };
      default:
        return {
          'messages': messages,
        };
    }
  }

  String _extractResponseContent(Map<String, dynamic> responseData) {
    switch (_config.type) {
      case EngineType.localStudio:
      case EngineType.cloud:
        final choices = responseData['choices'] as List?;
        if (choices != null && choices.isNotEmpty) {
          return choices[0]['message']['content'] ?? '';
        }
        return '';
      case EngineType.ollama:
        return responseData['response'] ?? '';
      default:
        return '';
    }
  }
}
