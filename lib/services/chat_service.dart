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

  Future<String> handleEmailApproval(String action,
      {String? editedContent}) async {
    if (_pendingEmailToolCall == null) {
      return 'No email draft is currently pending.';
    }

    final arguments = _pendingEmailToolCall!.arguments;
    final recipient = arguments['recipient'] as String;
    final subject = arguments['subject'] as String;
    String content = arguments['content'] as String; // Get the content here

    if (action == 'cancel') {
      cancelEmailDraft();
      return 'Email draft has been cancelled.';
    }

    if (action == 'edit' && editedContent != null) {
      content = editedContent;
    }

    try {
      // Convert newlines to HTML <br> tags for correct formatting in email clients
      String htmlContent = content.replaceAll('\n', '<br>');

      // Use the email creation method
      final result = await _emailService.createEmail(
        recipient: recipient,
        subject: subject,
        content: htmlContent, // Pass the HTML-formatted content
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
        'To: $recipient\n\n'
        'Subject: $subject\n\n'
        '$content';
  }

  String _formatToolResults(List<ToolResult> toolResults) {
    return 'Tool results: ${toolResults.first.success}';
  }
}
