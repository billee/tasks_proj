// lib/services/tool_orchestrator.dart
import 'dart:async';
import 'base_tool_service.dart';
import 'tool_registry.dart';
import '../models/llm_models.dart' as models;

/// Central orchestrator for coordinating tool execution across services
class ToolOrchestrator {
  static final ToolOrchestrator _instance = ToolOrchestrator._internal();
  factory ToolOrchestrator() => _instance;
  ToolOrchestrator._internal();

  final ToolRegistry _registry = ToolRegistry();
  final List<ToolExecutionInterceptor> _interceptors = [];
  bool _isInitialized = false;

  /// Initialize the orchestrator and registry
  Future<void> initialize() async {
    if (_isInitialized) return;

    _registry.initialize();
    _isInitialized = true;
  }

  /// Execute a single tool call
  Future<ToolResult> executeToolCall(models.ToolCall toolCall) async {
    await _ensureInitialized();

    try {
      // Pre-execution interceptors
      for (final interceptor in _interceptors) {
        final result = await interceptor.beforeExecution(toolCall);
        if (result != null) return result;
      }

      // Find the appropriate service
      final service = _registry.getServiceForTool(toolCall.toolName);
      if (service == null) {
        return _createErrorResult(
          'No service found for tool: ${toolCall.toolName}',
          {'tool_name': toolCall.toolName},
        );
      }

      // Execute the tool call
      final result = await service.executeToolCall(toolCall);

      // Post-execution interceptors
      for (final interceptor in _interceptors) {
        await interceptor.afterExecution(toolCall, result);
      }

      return result;
    } catch (e) {
      final errorResult = _createErrorResult(
        'Tool execution failed: ${e.toString()}',
        {'tool_name': toolCall.toolName, 'error': e.toString()},
      );

      // Error interceptors
      for (final interceptor in _interceptors) {
        await interceptor.onError(toolCall, e);
      }

      return errorResult;
    }
  }

  /// Execute multiple tool calls concurrently
  Future<List<ToolResult>> executeToolCalls(
      List<models.ToolCall> toolCalls) async {
    await _ensureInitialized();

    if (toolCalls.isEmpty) return [];

    // Group tool calls by service for potential optimization
    final serviceGroups = <String, List<models.ToolCall>>{};
    for (final toolCall in toolCalls) {
      final service = _registry.getServiceForTool(toolCall.toolName);
      if (service != null) {
        serviceGroups.putIfAbsent(service.serviceId, () => []).add(toolCall);
      }
    }

    // Execute all tool calls concurrently
    final futures = toolCalls.map((toolCall) => executeToolCall(toolCall));
    return await Future.wait(futures);
  }

  /// Execute tool calls sequentially (for dependent operations)
  Future<List<ToolResult>> executeToolCallsSequentially(
      List<models.ToolCall> toolCalls) async {
    await _ensureInitialized();

    final results = <ToolResult>[];
    for (final toolCall in toolCalls) {
      final result = await executeToolCall(toolCall);
      results.add(result);

      // Stop on first error if desired
      if (!result.success) {
        break;
      }
    }
    return results;
  }

  /// Process an LLM response with tool calls
  Future<LLMToolExecutionResult> processLLMResponse(
      models.LLMResponse response) async {
    if (!response.hasToolCalls) {
      return LLMToolExecutionResult(
        originalResponse: response,
        toolResults: [],
        success: true,
        message: 'No tools to execute',
      );
    }

    try {
      final results = await executeToolCalls(response.toolCalls!);
      final success = results.every((result) => result.success);
      final failedCount = results.where((result) => !result.success).length;

      return LLMToolExecutionResult(
        originalResponse: response,
        toolResults: results,
        success: success,
        message: success
            ? 'All ${results.length} tools executed successfully'
            : '$failedCount of ${results.length} tools failed',
      );
    } catch (e) {
      return LLMToolExecutionResult(
        originalResponse: response,
        toolResults: [],
        success: false,
        message: 'Failed to process tool calls: ${e.toString()}',
      );
    }
  }

  /// Get all available tools for LLM requests
  List<models.LLMTool> getAvailableTools() {
    return _registry.getAllTools();
  }

  /// Get tools filtered by service or category
  List<models.LLMTool> getToolsByCategory(String category) {
    return _registry.getToolsByCategory(category);
  }

  /// Search for tools
  List<models.ToolSearchResult> searchTools(String query) {
    return _registry.searchTools(query);
  }

  /// Get service information
  List<models.ServiceInfo> getServicesInfo() {
    return _registry.getServicesInfo();
  }

  /// Get orchestrator statistics
  OrchestratorStats getStats() {
    final registryStats = _registry.getStats();
    return OrchestratorStats(
      isInitialized: _isInitialized,
      interceptorCount: _interceptors.length,
      registryStats: registryStats,
    );
  }

  /// Register an execution interceptor
  void addInterceptor(ToolExecutionInterceptor interceptor) {
    _interceptors.add(interceptor);
  }

  /// Remove an execution interceptor
  void removeInterceptor(ToolExecutionInterceptor interceptor) {
    _interceptors.remove(interceptor);
  }

  /// Register a custom service
  void registerService(BaseToolService service) {
    _registry.registerService(service);
  }

  /// Validate the orchestrator state
  bool validate() {
    return _isInitialized && _registry.validateRegistry();
  }

  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await initialize();
    }
  }

  ToolResult _createErrorResult(String message, [Map<String, dynamic>? data]) {
    return GenericToolResult(
      success: false,
      message: message,
      data: data,
    );
  }
}

/// Result of executing tools from an LLM response
class LLMToolExecutionResult {
  final models.LLMResponse originalResponse;
  final List<ToolResult> toolResults;
  final bool success;
  final String message;

  LLMToolExecutionResult({
    required this.originalResponse,
    required this.toolResults,
    required this.success,
    required this.message,
  });

  /// Get results by tool name
  List<ToolResult> getResultsForTool(String toolName) {
    final matchingIndices = <int>[];
    final toolCalls = originalResponse.toolCalls ?? [];

    for (int i = 0; i < toolCalls.length; i++) {
      if (toolCalls[i].toolName == toolName) {
        matchingIndices.add(i);
      }
    }

    return matchingIndices
        .where((i) => i < toolResults.length)
        .map((i) => toolResults[i])
        .toList();
  }

  /// Get successful results
  List<ToolResult> getSuccessfulResults() {
    return toolResults.where((result) => result.success).toList();
  }

  /// Get failed results
  List<ToolResult> getFailedResults() {
    return toolResults.where((result) => !result.success).toList();
  }

  Map<String, dynamic> toJson() {
    return {
      'original_response': {
        'content': originalResponse.content,
        'has_tool_calls': originalResponse.hasToolCalls,
        'tool_calls':
            originalResponse.toolCalls?.map((tc) => tc.toJson()).toList(),
      },
      'tool_results': toolResults.map((result) => result.toJson()).toList(),
      'success': success,
      'message': message,
    };
  }
}

/// Interceptor for tool execution events
abstract class ToolExecutionInterceptor {
  /// Called before tool execution, can return a result to skip execution
  Future<ToolResult?> beforeExecution(models.ToolCall toolCall);

  /// Called after successful tool execution
  Future<void> afterExecution(models.ToolCall toolCall, ToolResult result);

  /// Called when tool execution fails
  Future<void> onError(models.ToolCall toolCall, dynamic error);
}

/// Statistics about the orchestrator
class OrchestratorStats {
  final bool isInitialized;
  final int interceptorCount;
  final Map<String, dynamic> registryStats;

  OrchestratorStats({
    required this.isInitialized,
    required this.interceptorCount,
    required this.registryStats,
  });

  Map<String, dynamic> toJson() {
    return {
      'is_initialized': isInitialized,
      'interceptor_count': interceptorCount,
      'registry_stats': registryStats,
    };
  }
}
