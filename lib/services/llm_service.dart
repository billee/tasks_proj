// lib/services/llm_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/llm_models.dart';
import 'tool_service.dart';

class LLMService {
  final ToolService _toolService = ToolService();
  static const String _baseUrl = 'https://api.openai.com/v1';

  String get _apiKey => dotenv.env['OPENAI_API_KEY'] ?? '';

  Future<LLMResponse> sendMessage(String userMessage) async {
    try {
      if (_apiKey.isEmpty) {
        throw Exception(
            'OpenAI API key not found. Please add OPENAI_API_KEY to your .env file.');
      }

      // Prepare system prompt and tools
      final systemPrompt = _getSystemPrompt();
      final tools = _getAvailableTools();

      final requestBody = {
        'model': 'gpt-4o-mini',
        'messages': [
          {
            'role': 'system',
            'content': systemPrompt,
          },
          {
            'role': 'user',
            'content': userMessage,
          },
        ],
        'tools': tools,
        'tool_choice': 'auto',
        'max_tokens': 1000,
        'temperature': 0.7,
      };

      final response = await http.post(
        Uri.parse('$_baseUrl/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: json.encode(requestBody),
      );

      if (response.statusCode != 200) {
        throw Exception(
            'OpenAI API error: ${response.statusCode} - ${response.body}');
      }

      final responseData = json.decode(response.body);
      final message = responseData['choices'][0]['message'];

      // Check if LLM wants to use tools
      if (message['tool_calls'] != null && message['tool_calls'].isNotEmpty) {
        final toolCalls = (message['tool_calls'] as List)
            .map((tc) => ToolCall(
                  toolName: tc['function']['name'],
                  arguments: json.decode(tc['function']['arguments']),
                ))
            .toList();

        return LLMResponse(
          content: message['content'] ?? "I'll help you create an email.",
          toolCalls: toolCalls,
        );
      } else {
        // No tools needed, return LLM response directly
        return LLMResponse(
          content: message['content'] ??
              'Sorry, this task is not valid for me. I can only help with email-related tasks.',
        );
      }
    } catch (e) {
      return LLMResponse(
        content:
            'Sorry, I encountered an error while processing your request: ${e.toString()}',
      );
    }
  }

  Future<String> executeToolCalls(List<ToolCall> toolCalls) async {
    final results = <String>[];

    for (final toolCall in toolCalls) {
      switch (toolCall.toolName) {
        case 'create_email':
          final result = await _toolService.createEmail(toolCall.arguments);
          results.add(_formatEmailCreationResult(result));
          break;
        default:
          results.add("Unknown tool: ${toolCall.toolName}");
      }
    }

    return results.join('\n\n');
  }

  String _getSystemPrompt() {
    return '''
You are an AI assistant that specializes in email-related tasks. Your primary function is to help users create and compose emails.

IMPORTANT GUIDELINES:
1. If a user's message is related to email (creating, composing, sending, drafting emails), use the create_email tool.
2. If a user's message is NOT email-related, respond with: "Sorry, this task is not valid for me. I can only help with email-related tasks."
3. Email-related keywords include: email, send email, create email, compose email, write email, draft email, mail, send message, write to, contact.
4. When using the create_email tool, extract the recipient, subject, and content from the user's message intelligently.
5. If the user doesn't provide all email details, make reasonable assumptions or ask for clarification.

Examples of email-related requests:
- "Send an email to john@example.com"
- "Create an email about the meeting tomorrow"
- "Write an email to my boss"
- "Compose a message for me"

Examples of non-email requests (respond with the standard message):
- "What's the weather like?"
- "Help me with math"
- "Tell me a joke"
- "Calculate 2+2"
''';
  }

  List<Map<String, dynamic>> _getAvailableTools() {
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

  String _formatEmailCreationResult(EmailCreationResult result) {
    if (result.success) {
      return '''
📧 Email Created Successfully!

**Email ID:** ${result.emailId}
**Recipient:** ${result.recipient}
**Subject:** ${result.subject}
**Content:** ${result.content}

${result.message}
''';
    } else {
      return '''
❌ Failed to Create Email

**Error:** ${result.message}
''';
    }
  }
}
