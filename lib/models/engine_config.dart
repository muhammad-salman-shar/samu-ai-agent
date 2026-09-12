/// Backend engine types supported by NovaAgent
enum EngineType {
  localStudio,    // Local Studio / Llama.cpp with OpenAI-compatible API
  ollama,         // Ollama LAN endpoint
  cloud,          // Cloud-based API (OpenAI, Anthropic, etc.)
}

/// Configuration for AI backend connection
class EngineConfig {
  final EngineType type;
  final String name;
  final String baseUrl;
  final String? apiKey;
  final String model;
  final int timeoutSeconds;
  final bool useStreaming;

  const EngineConfig({
    required this.type,
    required this.name,
    required this.baseUrl,
    this.apiKey,
    required this.model,
    this.timeoutSeconds = 30,
    this.useStreaming = false,
  });

  /// Default Local Studio configuration
  static const localStudio = EngineConfig(
    type: EngineType.localStudio,
    name: 'Local Studio',
    baseUrl: 'http://192.168.1.100:8080',
    model: 'local-model',
  );

  /// Default Ollama configuration
  static const ollama = EngineConfig(
    type: EngineType.ollama,
    name: 'Ollama',
    baseUrl: 'http://192.168.1.100:11434',
    model: 'llama3',
  );

  /// Create config from JSON
  factory EngineConfig.fromJson(Map<String, dynamic> json) {
    return EngineConfig(
      type: EngineType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => EngineType.localStudio,
      ),
      name: json['name'] as String? ?? 'Custom Engine',
      baseUrl: json['baseUrl'] as String? ?? '',
      apiKey: json['apiKey'] as String?,
      model: json['model'] as String? ?? 'default',
      timeoutSeconds: json['timeoutSeconds'] as int? ?? 30,
      useStreaming: json['useStreaming'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'name': name,
        'baseUrl': baseUrl,
        if (apiKey != null) 'apiKey': apiKey,
        'model': model,
        'timeoutSeconds': timeoutSeconds,
        'useStreaming': useStreaming,
      };

  /// Get the chat completions endpoint URL
  String get chatEndpoint {
    switch (type) {
      case EngineType.localStudio:
        return '$baseUrl/v1/chat/completions';
      case EngineType.ollama:
        return '$baseUrl/api/generate';
      case EngineType.cloud:
        return '$baseUrl/v1/chat/completions';
    }
  }

  @override
  String toString() => 'EngineConfig(type: $type, name: $name, baseUrl: $baseUrl, model: $model)';
}

/// System prompt template for the AI agent
class ActionPromptTemplate {
  static const String systemPrompt = '''You are NovaAgent, an autonomous AI assistant that controls an Android device through accessibility services.

Your task is to help the user achieve their goal by interacting with the current screen.

You will receive:
1. The user's goal/task
2. A list of interactive UI elements on the current screen with IDs, text, and positions

Respond with a JSON object containing:
- "thought": Your reasoning about what needs to be done next
- "action": One of: CLICK, TAP, SWIPE, SET_TEXT, PRESS_ENTER, GO_BACK, GO_HOME, WAIT, SCROLL_UP, SCROLL_DOWN
- "target_id": The ID of the element to interact with (for CLICK, SET_TEXT)
- "text": Text to input (for SET_TEXT)
- "x", "y": Coordinates (for TAP)
- "startX", "startY", "endX", "endY": Swipe coordinates (for SWIPE)
- "wait_ms": Milliseconds to wait (for WAIT)

Rules:
1. Always think step-by-step before acting
2. Prefer clicking elements by ID over tapping coordinates
3. For text input, use SET_TEXT action with target_id of the text field
4. If you need to find something not visible, suggest scrolling
5. After actions that change screens, include a WAIT action
6. If stuck, try GO_BACK and reassess
7. Be efficient - minimize unnecessary actions

Respond ONLY with valid JSON, no additional text.''';

  static String buildUserPrompt({
    required String userGoal,
    required List<String> screenNodes,
    String? previousAction,
    String? previousResult,
  }) {
    final buffer = StringBuffer();
    
    buffer.writeln('## Current Task:');
    buffer.writeln(userGoal);
    buffer.writeln();
    
    if (previousAction != null && previousResult != null) {
      buffer.writeln('## Previous Action:');
      buffer.writeln('Action: $previousAction');
      buffer.writeln('Result: $previousResult');
      buffer.writeln();
    }
    
    buffer.writeln('## Current Screen Elements:');
    for (final node in screenNodes) {
      buffer.writeln(node);
    }
    buffer.writeln();
    
    buffer.writeln('Based on the above, what is your next action? Respond with JSON.');
    
    return buffer.toString();
  }
}
