// lib/services/chat_service.dart
import 'llm_service.dart';
import 'tool_orchestrator.dart';
import 'base_tool_service.dart';
import '../models/llm_models.dart';
import 'email/email_service.dart';
import '../utils/email_validator.dart';
import 'email_lookup_service.dart';

class ChatService {
  final LLMService _llmService = LLMService(provider: LLMProviderType.openai);
  final ToolOrchestrator _toolOrchestrator = ToolOrchestrator();
  // Add an instance of the EmailService
  final EmailService _emailService = EmailService();
  // Add the EmailLookupService
  final EmailLookupService _emailLookupService = EmailLookupService();

  // Store the pending email tool call for approval
  ToolCall? _pendingEmailToolCall;

  ChatService() {
    _llmService.setProvider(LLMProviderType.openai);
    _toolOrchestrator.initialize();
  }

  Future<String> processUserMessage(String userMessage) async {
    try {
      print(
          'ppppppppppppppppppppppppppppppppppppppppp - chat_service.dart - processUserMessage');
      final availableTools = _toolOrchestrator.getAvailableTools();
      print('==========availableTools: $availableTools');
      final llmResponse = await _llmService.sendMessage(
          userMessage); //=================================================== goes to llm_service.dart

      if (llmResponse.hasToolCalls) {
        final toolCall = llmResponse.toolCalls!.first;

        // Check if the LLM wants to create an email
        if (toolCall.toolName == 'create_email') {
          // Validate the recipient email address
          final arguments = toolCall.arguments;
          String recipient = arguments['recipient'] as String;

          if (!EmailValidator.isValidEmail(recipient)) {
            final lookedUpEmail =
                await _emailLookupService.lookupEmailByName(recipient);
            if (lookedUpEmail != null) {
              arguments['recipient'] = lookedUpEmail;
              recipient = lookedUpEmail;
            } else {
              //if there is no email found then return below.
              return 'ðŸ"§ I need an email address to send this message.\n\n'
                  '"$recipient" appears to be a name, but I need their actual email address.\n\n'
                  'âœ¨ Could you please provide $recipient\'s email address?\n\n';
            }
          }

          // Store the tool call and format a message for user approval
          _pendingEmailToolCall = toolCall;
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
    String content = arguments['content'] as String;

    if (action == 'cancel') {
      cancelEmailDraft();
      return 'Email draft has been cancelled.';
    }

    if (action == 'edit') {
      // For edit action, return a message asking user to provide their edits
      // Keep the pending email so they can still approve/cancel after editing
      return 'Please provide your edits to the email draft. You can type your revised content, and I will update the draft for you.\n\n'
          'Current draft:\n\n'
          'To: $recipient\n\n'
          'Subject: $subject\n\n'
          '$content';
    }

    if (action == 'approve') {
      try {
        // Convert newlines to HTML <br> tags for correct formatting in email clients
        String htmlContent = content.replaceAll('\n', '<br>');

        // Use the email creation method
        final result = await _emailService.createEmail(
          recipient: recipient,
          subject: subject,
          content: htmlContent,
          priority: arguments['priority'] ?? 'normal',
        );

        // Clear the pending email after attempting to send
        _pendingEmailToolCall = null;

        if (result.success) {
          return 'Email sent successfully!';
        } else {
          return 'Failed to send email: ${result.message}';
        }
      } catch (e) {
        return 'An error occurred while sending the email: ${e.toString()}';
      }
    }

    return 'Invalid action specified.';
  }

  // New method to update draft content without sending
  String updateEmailDraft(String editedContent) {
    if (_pendingEmailToolCall == null) {
      return 'No email draft is currently pending.';
    }

    // Update the pending tool call with new content
    _pendingEmailToolCall!.arguments['content'] = editedContent;

    final arguments = _pendingEmailToolCall!.arguments;
    final recipient = arguments['recipient'] as String;
    final subject = arguments['subject'] as String;

    // Return the updated draft for approval
    return _formatEmailForApproval(recipient, subject, editedContent);
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
