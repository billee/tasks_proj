// lib/models/llm_models.dart

class LLMRequest {
  final String message;
  final List<LLMTool> tools;

  LLMRequest({required this.message, required this.tools});

  Map<String, dynamic> toJson() {
    return {
      'message': message,
      'tools': tools.map((tool) => tool.toJson()).toList(),
    };
  }
}

class LLMResponse {
  final String content;
  final List<ToolCall>? toolCalls;
  final bool hasToolCalls;

  LLMResponse({required this.content, this.toolCalls})
    : hasToolCalls = toolCalls != null && toolCalls.isNotEmpty;

  factory LLMResponse.fromJson(Map<String, dynamic> json) {
    return LLMResponse(
      content: json['content'] ?? '',
      toolCalls: json['tool_calls'] != null
          ? (json['tool_calls'] as List)
                .map((tc) => ToolCall.fromJson(tc))
                .toList()
          : null,
    );
  }
}

class LLMTool {
  final String name;
  final String description;
  final Map<String, dynamic> parameters;

  LLMTool({
    required this.name,
    required this.description,
    required this.parameters,
  });

  Map<String, dynamic> toJson() {
    return {'name': name, 'description': description, 'parameters': parameters};
  }
}

class ToolCall {
  final String toolName;
  final Map<String, dynamic> arguments;

  ToolCall({required this.toolName, required this.arguments});

  factory ToolCall.fromJson(Map<String, dynamic> json) {
    return ToolCall(
      toolName: json['tool_name'] ?? '',
      arguments: json['arguments'] ?? {},
    );
  }
}

class EmailCreationResult {
  final bool success;
  final String emailId;
  final String subject;
  final String recipient;
  final String content;
  final String message;

  EmailCreationResult({
    required this.success,
    required this.emailId,
    required this.subject,
    required this.recipient,
    required this.content,
    required this.message,
  });

  factory EmailCreationResult.fromJson(Map<String, dynamic> json) {
    return EmailCreationResult(
      success: json['success'] ?? false,
      emailId: json['email_id'] ?? '',
      subject: json['subject'] ?? '',
      recipient: json['recipient'] ?? '',
      content: json['content'] ?? '',
      message: json['message'] ?? '',
    );
  }
}
