// lib/services/base_tool_service.dart
import '../models/llm_models.dart';

/// Abstract base class for all tool results
abstract class ToolResult {
  final bool success;
  final String message;

  ToolResult({required this.success, required this.message});

  Map<String, dynamic> toJson();
}

/// Abstract base class for all tool services
/// Provides common interface and shared functionality
abstract class BaseToolService {
  /// Unique identifier for this tool service
  String get serviceId;

  /// Human-readable name for this service
  String get serviceName;

  /// List of tools this service provides
  List<LLMTool> get availableTools;

  /// Execute a tool call and return the result
  Future<ToolResult> executeToolCall(ToolCall toolCall);

  /// Check if this service can handle a given tool name
  bool canHandle(String toolName) {
    return availableTools.any((tool) => tool.name == toolName);
  }

  /// Get tool definition by name
  LLMTool? getToolByName(String toolName) {
    try {
      return availableTools.firstWhere((tool) => tool.name == toolName);
    } catch (e) {
      return null;
    }
  }

  /// Validate required parameters for a tool call
  Map<String, dynamic> validateParameters(
    String toolName,
    Map<String, dynamic> arguments,
  ) {
    final tool = getToolByName(toolName);
    if (tool == null) {
      throw ToolValidationException('Unknown tool: $toolName');
    }

    final requiredParams = tool.parameters['required'] as List<dynamic>? ?? [];
    final properties =
        tool.parameters['properties'] as Map<String, dynamic>? ?? {};

    final errors = <String>[];
    final validatedArgs = <String, dynamic>{};

    // Check required parameters
    for (final param in requiredParams) {
      if (!arguments.containsKey(param) || arguments[param] == null) {
        errors.add('Missing required parameter: $param');
        continue;
      }
      validatedArgs[param] = arguments[param];
    }

    // Validate optional parameters and add defaults
    for (final entry in properties.entries) {
      final paramName = entry.key;
      final paramDef = entry.value as Map<String, dynamic>;

      if (arguments.containsKey(paramName)) {
        final value = arguments[paramName];
        final validatedValue =
            _validateParameterType(paramName, value, paramDef);
        validatedArgs[paramName] = validatedValue;
      } else if (paramDef.containsKey('default')) {
        validatedArgs[paramName] = paramDef['default'];
      }
    }

    if (errors.isNotEmpty) {
      throw ToolValidationException(errors.join(', '));
    }

    return validatedArgs;
  }

  /// Validate parameter type according to JSON Schema
  dynamic _validateParameterType(
    String paramName,
    dynamic value,
    Map<String, dynamic> paramDef,
  ) {
    final type = paramDef['type'] as String?;

    switch (type) {
      case 'string':
        if (value is! String) {
          throw ToolValidationException(
              'Parameter $paramName must be a string');
        }

        // Check enum constraints
        final enumValues = paramDef['enum'] as List<dynamic>?;
        if (enumValues != null && !enumValues.contains(value)) {
          throw ToolValidationException(
            'Parameter $paramName must be one of: ${enumValues.join(', ')}',
          );
        }

        return value;

      case 'integer':
      case 'number':
        if (value is! num) {
          throw ToolValidationException(
              'Parameter $paramName must be a number');
        }
        return value;

      case 'boolean':
        if (value is! bool) {
          throw ToolValidationException(
              'Parameter $paramName must be a boolean');
        }
        return value;

      case 'array':
        if (value is! List) {
          throw ToolValidationException(
              'Parameter $paramName must be an array');
        }
        return value;

      case 'object':
        if (value is! Map) {
          throw ToolValidationException(
              'Parameter $paramName must be an object');
        }
        return value;

      default:
        return value; // No validation for unknown types
    }
  }

  /// Create a standardized error result
  ToolResult createErrorResult(String message,
      [Map<String, dynamic>? details]) {
    return GenericToolResult(
      success: false,
      message: message,
      data: details,
    );
  }

  /// Create a standardized success result
  ToolResult createSuccessResult(String message, [Map<String, dynamic>? data]) {
    return GenericToolResult(
      success: true,
      message: message,
      data: data,
    );
  }
}

/// Generic tool result for services that don't need specific result types
class GenericToolResult extends ToolResult {
  final Map<String, dynamic>? data;

  GenericToolResult({
    required bool success,
    required String message,
    this.data,
  }) : super(success: success, message: message);

  @override
  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      if (data != null) 'data': data,
    };
  }
}

/// Exception thrown during tool validation
class ToolValidationException implements Exception {
  final String message;

  ToolValidationException(this.message);

  @override
  String toString() => 'ToolValidationException: $message';
}

/// Exception thrown during tool execution
class ToolExecutionException implements Exception {
  final String message;
  final dynamic originalError;

  ToolExecutionException(this.message, [this.originalError]);

  @override
  String toString() => 'ToolExecutionException: $message';
}
