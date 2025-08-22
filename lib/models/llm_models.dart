// lib/models/llm_models.dart
import '../services/base_tool_service.dart';

class LLMResponse {
  final String content;
  final List<ToolCall>? toolCalls;

  LLMResponse({
    required this.content,
    this.toolCalls,
  });

  bool get hasToolCalls => toolCalls != null && toolCalls!.isNotEmpty;
}

class ToolCall {
  final String toolName;
  final Map<String, dynamic> arguments;

  ToolCall({
    required this.toolName,
    required this.arguments,
  });

  Map<String, dynamic> toJson() {
    return {
      'tool_name': toolName,
      'arguments': arguments,
    };
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
    return {
      'name': name,
      'description': description,
      'parameters': parameters,
    };
  }
}

class LLMProvider {
  final String providerName;
  final String modelName;
  final String apiKey;

  LLMProvider({
    required this.providerName,
    required this.modelName,
    required this.apiKey,
  });
}

class ToolSearchResult {
  final LLMTool tool;
  final String serviceId;
  final String serviceName;

  ToolSearchResult({
    required this.tool,
    required this.serviceId,
    required this.serviceName,
  });

  Map<String, dynamic> toJson() {
    return {
      'tool': tool.toJson(),
      'service_id': serviceId,
      'service_name': serviceName,
    };
  }
}

class ServiceInfo {
  final String serviceId;
  final String serviceName;
  final int toolCount;
  final bool isEnabled;

  ServiceInfo({
    required this.serviceId,
    required this.serviceName,
    required this.toolCount,
    required this.isEnabled,
  });

  Map<String, dynamic> toJson() {
    return {
      'service_id': serviceId,
      'service_name': serviceName,
      'tool_count': toolCount,
      'is_enabled': isEnabled,
    };
  }
}

// Remove all Todo-related classes from this file since they're now in todo_models.dart
