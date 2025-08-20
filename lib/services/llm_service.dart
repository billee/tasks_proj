// lib/services/llm_service.dart
//import 'dart:convert';
import 'dart:math';
import '../models/llm_models.dart';
import 'tool_service.dart';

class LLMService {
  final ToolService _toolService = ToolService();

  // Simulates DeepSeek LLM API call
  Future<LLMResponse> sendMessage(String userMessage) async {
    try {
      // Prepare available tools
      //final tools = _getAvailableTools();

      //final request = LLMRequest(message: userMessage, tools: tools);

      // Simulate API delay
      await Future.delayed(const Duration(seconds: 2));

      // Simulate LLM decision making
      final shouldUseEmailTool = _shouldCreateEmail(userMessage);

      if (shouldUseEmailTool) {
        // LLM decides to use email creation tool
        final toolCall = _generateEmailToolCall(userMessage);

        return LLMResponse(
          content:
              "I'll help you create an email. Let me use the email creation tool.",
          toolCalls: [toolCall],
        );
      } else {
        // Regular response without tool usage
        return LLMResponse(content: _generateRegularResponse(userMessage));
      }
    } catch (e) {
      return LLMResponse(
        content:
            "Sorry, I encountered an error while processing your request: ${e.toString()}",
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

  // List<LLMTool> _getAvailableTools() {
  //   return [
  //     LLMTool(
  //       name: 'create_email',
  //       description:
  //           'Creates an email with specified recipient, subject, and content',
  //       parameters: {
  //         'type': 'object',
  //         'properties': {
  //           'recipient': {
  //             'type': 'string',
  //             'description': 'Email address of the recipient',
  //           },
  //           'subject': {
  //             'type': 'string',
  //             'description': 'Subject line of the email',
  //           },
  //           'content': {
  //             'type': 'string',
  //             'description': 'Body content of the email',
  //           },
  //         },
  //         'required': ['recipient', 'subject', 'content'],
  //       },
  //     ),
  //   ];
  // }

  bool _shouldCreateEmail(String message) {
    final emailKeywords = [
      'email',
      'send email',
      'create email',
      'compose email',
      'write email',
      'draft email',
      'mail',
      'send message',
      'email to',
      'write to',
      'contact',
    ];

    final lowerMessage = message.toLowerCase();
    return emailKeywords.any((keyword) => lowerMessage.contains(keyword));
  }

  ToolCall _generateEmailToolCall(String userMessage) {
    // Simple extraction logic - in real implementation,
    // the LLM would extract these parameters intelligently
    final arguments = _extractEmailParameters(userMessage);

    return ToolCall(toolName: 'create_email', arguments: arguments);
  }

  Map<String, dynamic> _extractEmailParameters(String message) {
    // Simplified parameter extraction
    // In real implementation, LLM would extract these intelligently
    return {
      'recipient': 'example@email.com',
      'subject': 'Generated Email Subject',
      'content':
          'This is the email content generated based on your request: $message',
    };
  }

  String _generateRegularResponse(String message) {
    final responses = [
      "I understand you want help with: $message. How can I assist you further?",
      "That's an interesting request about: $message. What specific help do you need?",
      "I can help you with that task: $message. Please provide more details.",
    ];

    return responses[Random().nextInt(responses.length)];
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
