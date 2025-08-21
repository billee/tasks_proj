// lib/services/chat_service.dart
import 'llm_service.dart';

class ChatService {
  // =========================================================
  // Hard code to use OpenAI GPT-4o-mini
  final LLMService _llmService = LLMService(provider: LLMProviderType.openai);

  ChatService() {
    // =========================================================
    // Ensure we're using OpenAI provider (GPT-4o-mini)
    // This is redundant since we set it in constructor, but makes intent clear
    _llmService.setProvider(LLMProviderType.openai);
  }

  Future<String> processUserMessage(String userMessage) async {
    try {
      // Step 1: Send message to LLM
      final llmResponse = await _llmService.sendMessage(userMessage);

      // Step 2: Check if LLM wants to use tools
      if (llmResponse.hasToolCalls) {
        // Step 3: Execute the tool calls
        final toolResults = await _llmService.executeToolCalls(
          llmResponse.toolCalls!,
        );

        // Step 4: Return the tool results (email creation result)
        return toolResults;
      } else {
        // No tools needed, return LLM response directly
        // This will be the "not valid task" message for non-email requests
        return llmResponse.content;
      }
    } catch (e) {
      return 'Sorry, I encountered an error while processing your message: ${e.toString()}';
    }
  }

  // Optional: Method to get info about the hardcoded model being used
  String getCurrentModelInfo() {
    return 'Using ${_llmService.currentProvider.providerName} - ${_llmService.currentProvider.modelName}';
  }
}
