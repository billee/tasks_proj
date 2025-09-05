// lib/services/llm_service.dart
import '../models/llm_models.dart';
import 'llm_providers/base_llm_provider.dart';
import 'llm_providers/openai_provider.dart';
import 'llm_providers/deepseek_provider.dart';
import 'llm_providers/llama_provider.dart';
import 'tool_orchestrator.dart';
import 'base_tool_service.dart';

enum LLMProviderType {
  openai,
  deepseek,
  llama,
}

class LLMService {
  final ToolOrchestrator _toolOrchestrator = ToolOrchestrator();
  late BaseLLMProvider _currentProvider;
  List<Map<String, dynamic>> _conversationHistory = [];

  //===============setting to openai
  LLMService({LLMProviderType provider = LLMProviderType.openai}) {
    setProvider(provider);
    _toolOrchestrator.initialize();
    print(
        '==================LLMService initialized with provider: ${provider.name}');
  }

  void setProvider(LLMProviderType provider) {
    print('==========================llm_service.dart');
    print('==================Switching LLM provider to: ${provider.name}');
    switch (provider) {
      case LLMProviderType.openai:
        _currentProvider = OpenAIProvider();
        break;
      case LLMProviderType.deepseek:
        _currentProvider = DeepSeekProvider();
        break;
      case LLMProviderType.llama:
        _currentProvider = LlamaProvider();
        break;
    }
  }

  BaseLLMProvider get currentProvider => _currentProvider;

  Future<LLMResponse> sendMessage(String userMessage) async {
    print('======================= llm_service.dart ========================');
    print('======================= LLMService.sendMessage called ===');
    print('User message: $userMessage');
    print(
        'Current conversation history length: ${_conversationHistory.length}');

    // Add user message to conversation history
    _conversationHistory.add({'role': 'user', 'content': userMessage});
    print('=====================Added user message to history');

    // Get available tools for the LLM
    final tools = _toolOrchestrator.getAvailableTools();
    print(
        '======================Available tools: ${tools.map((t) => t.name).toList()}');

    // Send message with conversation history and tools
    print('======================Sending to base_llm_provider.dart...');
    final response = await _currentProvider.sendMessage(
      userMessage,
      conversationHistory: _conversationHistory,
      tools: tools,
    ); //===================================go to base_llm_provider.dart - openai_provider.dart

    print('==================LLM response: ${response.content}');
    if (response.toolCalls != null) {
      print(
          '=================Tool calls: ${response.toolCalls!.map((tc) => tc.toolName).toList()}');
    }

    // Add assistant response to conversation history
    _conversationHistory
        .add({'role': 'assistant', 'content': response.content});
    if (response.toolCalls != null) {
      _conversationHistory.last['tool_calls'] = response.toolCalls;
    }

    print('=======================Added assistant response to history');
    print(
        '=======================New conversation history length: ${_conversationHistory.length}');

    return response;
  }

  Future<String> executeToolCalls(List<ToolCall> toolCalls) async {
    print(
        '============================= LLMService.executeToolCalls called ===');
    print('=============================Tool calls: $toolCalls');

    final results = await _toolOrchestrator.executeToolCalls(toolCalls);

    print('==========================Tool execution results: $results');

    final formattedResults = <String>[];
    for (int i = 0; i < toolCalls.length; i++) {
      final toolCall = toolCalls[i];
      final result = results[i];

      formattedResults.add(_formatToolResult(toolCall, result));
    }

    // Add tool results to conversation history
    _conversationHistory.add({
      'role': 'tool',
      'content': formattedResults.join('\n\n'),
      'toolResults': results.map((r) => r.toJson()).toList(),
    });

    print(
        '=========================Added tool results to conversation history');
    return formattedResults.join('\n\n');
  }

  String _formatToolResult(ToolCall toolCall, ToolResult result) {
    if (result.success) {
      return '''
✅ ${toolCall.toolName} executed successfully
${result.message}
${result.toJson().containsKey('data') ? 'Data: ${result.toJson()['data']}' : ''}
''';
    } else {
      return '''
❌ ${toolCall.toolName} failed
Error: ${result.message}
''';
    }
  }

  // Clear conversation history
  void clearHistory() {
    print('==========================Clearing conversation history');
    _conversationHistory.clear();
  }

  // Get conversation history
  List<Map<String, dynamic>> get conversationHistory => _conversationHistory;

  // Method to get available providers
  static List<String> getAvailableProviders() {
    return LLMProviderType.values.map((e) => e.name).toList();
  }

  // Method to switch providers at runtime
  void switchProvider(LLMProviderType newProvider) {
    setProvider(newProvider);
  }
}
