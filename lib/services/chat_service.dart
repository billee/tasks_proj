// lib/services/chat_service.dart
import 'llm_service.dart';
import 'tool_orchestrator.dart';
import 'base_tool_service.dart';
import '../models/llm_models.dart';
import 'email/email_service.dart';

class ChatService {
  final LLMService _llmService = LLMService(provider: LLMProviderType.openai);
  final ToolOrchestrator _toolOrchestrator = ToolOrchestrator();
  final EmailService _emailService = EmailService();

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

        if (toolCall.toolName == 'create_email') {
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

    if (action == 'cancel') {
      cancelEmailDraft();
      return 'Email draft has been cancelled.';
    }

    if (action == 'edit' && editedContent != null) {
      arguments['content'] = editedContent;
    }

    try {
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

  void cancelEmailDraft() {
    _pendingEmailToolCall = null;
  }

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
