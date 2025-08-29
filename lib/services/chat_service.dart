// lib/services/chat_service.dart
import 'llm_service.dart';
import 'tool_orchestrator.dart';
import 'base_tool_service.dart';
import '../models/llm_models.dart';

class ChatService {
  final LLMService _llmService = LLMService(provider: LLMProviderType.openai);
  final ToolOrchestrator _toolOrchestrator = ToolOrchestrator();

  // Store the pending email tool call for approval
  ToolCall? _pendingEmailToolCall;

  ChatService() {
    _llmService.setProvider(LLMProviderType.openai);
    _toolOrchestrator.initialize();
  }

  Future<String> processUserMessage(String userMessage) async {
    try {
      final availableTools = _toolOrchestrator.getAvailableTools();
      final llmResponse = await _llmService.sendMessage(userMessage);

      if (llmResponse.hasToolCalls) {
        final toolCall = llmResponse.toolCalls!.first;

        // Check if the LLM wants to create an email
        if (toolCall.toolName == 'create_email') {
          // Store the tool call and format a message for user approval
          _pendingEmailToolCall = toolCall;
          final arguments = toolCall.arguments;
          return _formatEmailForApproval(
            arguments['recipient'],
            arguments['subject'],
            arguments['content'],
          );
        } else {
          // Process other tool calls normally
          final executionResult =
              await _toolOrchestrator.processLLMResponse(llmResponse);
          if (executionResult.success) {
            return _formatToolResults(executionResult.toolResults);
          } else {
            return 'Failed to execute tools: ${executionResult.message}';
          }
        }
      } else {
        return llmResponse.content;
      }
    } catch (e) {
      return 'Sorry, I encountered an error while processing your message: ${e.toString()}';
    }
  }

  /// Sends the previously approved email.
  Future<String> sendApprovedEmail() async {
    if (_pendingEmailToolCall == null) {
      return 'No email draft to send.';
    }

    // Create a new tool call for sending the email using the stored arguments
    final sendEmailToolCall = ToolCall(
      toolName: 'send_email',
      arguments: _pendingEmailToolCall!.arguments,
    );
    _pendingEmailToolCall = null; // Clear the pending state

    try {
      final result = await _toolOrchestrator.executeToolCall(sendEmailToolCall);
      if (result.success) {
        return 'Email sent successfully!';
      } else {
        return 'Failed to send email: ${result.message}';
      }
    } catch (e) {
      return 'An error occurred while sending the email: ${e.toString()}';
    }
  }

  /// Cancels the current email draft.
  void cancelEmailDraft() {
    _pendingEmailToolCall = null;
  }

  /// Retrieves the content of the pending email for editing.
  String getPendingEmailContent() {
    if (_pendingEmailToolCall != null) {
      final args = _pendingEmailToolCall!.arguments;
      return 'To: ${args['recipient']}\nSubject: ${args['subject']}\n\n${args['content']}';
    }
    return '';
  }

  String _formatEmailForApproval(
      String recipient, String subject, String content) {
    return 'I have drafted the following email for you. Would you like to send it?\n\n'
        '**To:** $recipient\n'
        '**Subject:** $subject\n'
        '**Content:**\n$content';
  }

  String _formatToolResults(List<ToolResult> results) {
    return results.map((result) {
      if (result.success) {
        return '✅ ${result.message}';
      } else {
        return '❌ ${result.message}';
      }
    }).join('\n');
  }
}
