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

  // State management variables for email contact workflow
  String? _pendingContactName;
  Map<String, dynamic>? _originalEmailArgs;

  // Add this flag to track if we're waiting for an email address
  bool _isWaitingForEmail = false;

  ChatService() {
    _llmService.setProvider(LLMProviderType.openai);
    _toolOrchestrator.initialize();
  }

  Future<String> processUserMessage(String userMessage) async {
    try {
      print(
          'ppppppppppppppppppppppppppppppppppppppppp - chat_service.dart - processUserMessage');

      // Check if we're waiting for an email address
      if (_isWaitingForEmailAddress(userMessage)) {
        print('-----------------------waiting for email address');
        return await _handleEmailAddressResponse(userMessage);
      }

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
              // Store the original email arguments and contact name for later use
              _originalEmailArgs = Map<String, dynamic>.from(arguments);
              _pendingContactName = recipient;
              _isWaitingForEmail = true;

              //if there is no email found then return below.
              return 'I need an email address to send this message.\n\n'
                  '"$recipient" appears to be a name, but I need their actual email address.\n\n'
                  'Could you please provide $recipient\'s email address?\n\n';
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

  // NEW METHOD: Check if we're waiting for an email address
  bool _isWaitingForEmailAddress(String userMessage) {
    return _isWaitingForEmail &&
        _pendingContactName != null &&
        _originalEmailArgs != null;
  }

  // NEW METHOD: Handle the user's email address response
  Future<String> _handleEmailAddressResponse(String userMessage) async {
    try {
      // Extract potential email from user message
      final emailMatch =
          RegExp(r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b')
              .firstMatch(userMessage);

      if (emailMatch == null ||
          !EmailValidator.isValidEmail(emailMatch.group(0)!)) {
        return 'Please provide a valid email address for $_pendingContactName.\n\n'
            'Example: john.smith@example.com';
      }

      final emailAddress = emailMatch.group(0)!;
      final contactName = _pendingContactName!;
      final originalArgs = _originalEmailArgs!;

      print('Extracted email: $emailAddress for contact: $contactName');

      // Save the contact for future use
      final saveSuccess =
          await _emailLookupService.saveEmailContact(contactName, emailAddress);

      if (!saveSuccess) {
        print('Failed to save contact, but continuing with email creation...');
      } else {
        print('Contact saved successfully: $contactName -> $emailAddress');
      }

      // Update the original email arguments with the provided email
      originalArgs['recipient'] = emailAddress;

      // Create the tool call with updated arguments
      _pendingEmailToolCall = ToolCall(
        toolName: 'create_email',
        arguments: originalArgs,
      );

      // Clear the waiting state
      _isWaitingForEmail = false;
      _pendingContactName = null;
      _originalEmailArgs = null;

      // Format the email for approval
      final subject = originalArgs['subject'] as String;
      final content = originalArgs['content'] as String;

      String approvalMessage = '';
      if (saveSuccess) {
        approvalMessage =
            'Great! I\'ve saved $contactName\'s email address ($emailAddress) for future use.\n\n';
      }

      approvalMessage +=
          _formatEmailForApproval(emailAddress, subject, content);

      return approvalMessage;
    } catch (e) {
      // Reset state on error
      _isWaitingForEmail = false;
      _pendingContactName = null;
      _originalEmailArgs = null;

      return 'Sorry, there was an error processing the email address: ${e.toString()}';
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

  /// Cancels the current email draft and resets waiting state.
  void cancelEmailDraft() {
    _pendingEmailToolCall = null;
    // Also reset the waiting for email state if active
    _isWaitingForEmail = false;
    _pendingContactName = null;
    _originalEmailArgs = null;
  }

  /// Retrieves the content of the pending email for editing.
  String getPendingEmailContent() {
    if (_pendingEmailToolCall != null) {
      final args = _pendingEmailToolCall!.arguments;
      return 'To: ${args['recipient']}\nSubject: ${args['subject']}\n\n${args['content']}';
    }
    return '';
  }

  // NEW METHOD: Check if we're currently waiting for email input
  bool get isWaitingForEmailAddress => _isWaitingForEmail;

  // NEW METHOD: Get the name we're waiting for an email address for
  String? get pendingContactName => _pendingContactName;

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
