// lib/services/chat_service.dart
import 'llm_service.dart';
import 'tool_orchestrator.dart';
import 'base_tool_service.dart'; // Add this import

class ChatService {
  final LLMService _llmService = LLMService(provider: LLMProviderType.openai);
  final ToolOrchestrator _toolOrchestrator = ToolOrchestrator();

  ChatService() {
    _llmService.setProvider(LLMProviderType.openai);
    _toolOrchestrator.initialize();
  }

  Future<String> processUserMessage(String userMessage) async {
    try {
      final availableTools = _toolOrchestrator.getAvailableTools();
      final llmResponse =
          await _llmService.sendMessage(userMessage, tools: availableTools);

      if (llmResponse.hasToolCalls) {
        final executionResult =
            await _toolOrchestrator.processLLMResponse(llmResponse);

        if (executionResult.success) {
          return _formatToolResults(executionResult.toolResults);
        } else {
          return 'Failed to execute tools: ${executionResult.message}';
        }
      } else {
        return llmResponse.content;
      }
    } catch (e) {
      return 'Sorry, I encountered an error while processing your message: ${e.toString()}';
    }
  }

  String _formatToolResults(List<ToolResult> results) {
    return results.map((result) {
      return result.success ? '✓ ${result.message}' : '✗ ${result.message}';
    }).join('\n\n');
  }

  String getCurrentModelInfo() {
    return 'Using ${_llmService.currentProvider.providerName} - ${_llmService.currentProvider.modelName}';
  }
}
