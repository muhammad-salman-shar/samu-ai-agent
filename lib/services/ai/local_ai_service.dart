import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/models.dart';

class ActionPromptTemplate {
  static const String systemPrompt = '''
You are an autonomous Android UI Agent. Given the current screen UI nodes and the user's goal, output ONLY a JSON object indicating the next action to perform:
{
  "thought": "Reasoning for the step",
  "action": "CLICK" | "INPUT_TEXT" | "SWIPE" | "PRESS_HOME" | "PRESS_BACK" | "COMPLETE" | "FAIL",
  "target_id": 12,
  "text": "text to type if INPUT_TEXT"
}
''';

  static String buildUserPrompt(String goal, String screenHierarchy) {
    return '''
Goal: $goal

Screen Hierarchy:
$screenHierarchy
''';
  }
}

class LocalAIService {
  EngineConfig _config;

  LocalAIService({EngineConfig? config})
      : _config = config ??
            const EngineConfig(
              type: EngineType.localStudio,
              baseUrl: 'http://192.168.1.100:8080/v1',
              modelName: 'default',
            );

  EngineConfig get currentConfig => _config;

  void updateConfig(EngineConfig newConfig) {
    _config = newConfig;
  }

  Future<AgentAction?> generateAction({
    required String goal,
    required String screenHierarchy,
  }) async {
    try {
      final messages = <Map<String, dynamic>>[
        {'role': 'system', 'content': ActionPromptTemplate.systemPrompt},
        {
          'role': 'user',
          'content': ActionPromptTemplate.buildUserPrompt(goal, screenHierarchy)
        },
      ];

      final response = await http.post(
        Uri.parse('${_config.baseUrl}/chat/completions'),
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

  Map<String, dynamic> _buildRequestBody(List<Map<String, dynamic>> messages) {
    switch (_config.type) {
      case EngineType.localStudio:
      case EngineType.cloud:
        return {
          'model': _config.modelName,
          'messages': messages,
          'temperature': 0.2,
        };
      case EngineType.ollama:
        return {
          'model': _config.modelName,
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
