// lib/services/chat_service.dart
import 'llm_service.dart';

class ChatService {
  final LLMService _llmService = LLMService();

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
}
