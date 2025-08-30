// lib/services/chat_service.dart
import 'llm_service.dart';
import 'tool_orchestrator.dart';
import 'base_tool_service.dart';
import '../models/llm_models.dart';
import 'email/email_service.dart';

class ChatService {
  final LLMService _llmService = LLMService(provider: LLMProviderType.openai);
  final ToolOrchestrator _toolOrchestrator = ToolOrchestrator();
  // Add an instance of the EmailService
  final EmailService _emailService = EmailService();

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
          final recipient = arguments['recipient'] as String;
          final subject = arguments['subject'] as String;
          final content = arguments['content'] as String;
          return _formatEmailForApproval(recipient, subject, content);
        }

        // Execute any other tool calls
        final toolResults =
            await _toolOrchestrator.executeToolCalls(llmResponse.toolCalls!);
        return _formatToolResults(toolResults);
      } else {
        return llmResponse.content;
      }
    } catch (e) {
      return 'Sorry, an error occurred: ${e.toString()}';
    }
  }

  /// Handles the user's action (approve, cancel, edit) on a pending email.
  Future<String> handleEmailApproval(String action,
      {String? editedContent}) async {
    if (_pendingEmailToolCall == null) {
      return 'No email draft is currently pending.';
    }

    final arguments = _pendingEmailToolCall!.arguments;
    final recipient = arguments['recipient'] as String;
    final subject = arguments['subject'] as String;

    if (action == 'cancel') {
      cancelEmailDraft();
      return 'Email draft has been cancelled.';
    }

    if (action == 'edit' && editedContent != null) {
      // Logic for handling the edited content goes here
      // For now, we'll just update the content and proceed to send.
      arguments['content'] = editedContent;
    }

    try {
      // Use the email creation method
      final result = await _emailService.createEmail(
        recipient: arguments['recipient'],
        subject: arguments['subject'],
        content: arguments['content'],
        priority: arguments['priority'] ?? 'normal',
      );

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
        'To: $recipient\n'
        'Subject: $subject\n'
        'Content:\n$content';
  }

  String _formatToolResults(List<ToolResult> toolResults) {
    // Logic for formatting tool results
    return 'Tool results: ${toolResults.first.success}';
  }
}
