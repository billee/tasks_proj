// lib/services/llm_providers/base_llm_provider.dart
import '../../models/llm_models.dart';

abstract class BaseLLMProvider {
  Future<LLMResponse> sendMessage(
    String userMessage, {
    List<Map<String, dynamic>> conversationHistory = const [],
    List<LLMTool> tools = const [],
  });
  String get providerName;
  String get modelName;

  // Common system prompt - can be overridden by specific providers
  String getSystemPrompt() {
    return '''
You are an AI assistant that specializes in email-related tasks. Your primary function is to help users create and compose professional and well-written emails.

IMPORTANT GUIDELINES:
1. If a user's message is related to email (creating, composing, sending, drafting emails), use the create_email tool to draft it.
2. The user will then approve the drafted email. You will not receive a message to \"send\" the email, as that is handled by a separate function in the application.
3. If a user's message is NOT email-related, respond with: \"Sorry, this task is not valid for me. I can only help with email-related tasks.\"
4. Email-related keywords include: email, send email, create email, compose email, write email, draft email, mail, send message, write to, contact.
5. When using the create_email tool, intelligently extract the recipient, subject, and content from the user's message.
6. The email content you generate must be professional, polite, and well-composed. Structure the content with a clear greeting, a detailed body that expands on the user's intent, and a polite closing.
7. If the user doesn't provide all email details, ask for clarification.
''';
  }

  // Common tools definition - can be overridden by specific providers
  List<Map<String, dynamic>> getAvailableTools() {
    return [
      {
        'type': 'function',
        'function': {
          'name': 'create_email',
          'description':
              'Drafts an email with specified recipient, subject, and content for user approval.',
          'parameters': {
            'type': 'object',
            'properties': {
              'recipient': {
                'type': 'string',
                'description': 'Email address of the recipient',
              },
              'subject': {
                'type': 'string',
                'description': 'Subject line of the email',
              },
              'content': {
                'type': 'string',
                'description': 'Body content of the email',
              },
            },
            'required': ['recipient', 'subject', 'content'],
          },
        },
      },
      {
        'type': 'function',
        'function': {
          'name': 'send_email',
          'description': 'Sends a previously drafted email.',
          'parameters': {
            'type': 'object',
            'properties': {
              'recipient': {
                'type': 'string',
                'description': 'Email address of the recipient',
              },
              'subject': {
                'type': 'string',
                'description': 'Subject line of the email',
              },
              'content': {
                'type': 'string',
                'description': 'Body content of the email',
              },
              'priority': {
                'type': 'string',
                'enum': ['low', 'normal', 'high'],
                'default': 'normal',
                'description': 'Priority level of the email',
              },
            },
            'required': ['recipient', 'subject', 'content'],
          },
        },
      },
      {
        'type': 'function',
        'function': {
          'name': 'get_email_status',
          'description': 'Get the delivery status of an email',
          'parameters': {
            'type': 'object',
            'properties': {
              'email_id': {
                'type': 'string',
                'description': 'ID of the email to check status for',
              },
            },
            'required': ['email_id'],
          },
        },
      },
    ];
  }
}
