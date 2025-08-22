// lib/services/llm_providers/base_llm_provider.dart
import '../../models/llm_models.dart';

abstract class BaseLLMProvider {
  Future<LLMResponse> sendMessage(String message, {List<LLMTool>? tools});
  String get providerName;
  String get modelName;

  // Common system prompt - can be overridden by specific providers
  String getSystemPrompt() {
    return '''
You are an AI assistant that specializes in email-related tasks. Your primary function is to help users create and compose emails.

IMPORTANT GUIDELINES:
1. If a user's message is related to email (creating, composing, sending, drafting emails), use the create_email tool.
2. If a user's message is NOT email-related, respond with: "Sorry, this task is not valid for me. I can only help with email-related tasks."
3. Email-related keywords include: email, send email, create email, compose email, write email, draft email, mail, send message, write to, contact.
4. When using the create_email tool, extract the recipient, subject, and content from the user's message intelligently.
5. If the user doesn't provide all email details, make reasonable assumptions or ask for clarification.
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
              'Creates an email with specified recipient, subject, and content',
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
    ];
  }
}
