// lib/services/llm_providers/openai_provider.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../models/llm_models.dart';
import 'base_llm_provider.dart';

class OpenAIProvider extends BaseLLMProvider {
  static const String _baseUrl = 'https://api.openai.com/v1';

  @override
  String get providerName => 'OpenAI';

  @override
  String get modelName => 'gpt-4o-mini';

  String get _apiKey => dotenv.env['OPENAI_API_KEY'] ?? '';

  @override
  Future<LLMResponse> sendMessage(String userMessage) async {
    try {
      if (_apiKey.isEmpty) {
        throw Exception(
            'OpenAI API key not found. Please add OPENAI_API_KEY to your .env file.');
      }

      final requestBody = {
        'model': modelName,
        'messages': [
          {
            'role': 'system',
            'content': getSystemPrompt(),
          },
          {
            'role': 'user',
            'content': userMessage,
          },
        ],
        'tools': getAvailableTools(),
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

      return _parseOpenAIResponse(message);
    } catch (e) {
      return LLMResponse(
        content:
            'Sorry, I encountered an error while processing your request: ${e.toString()}',
      );
    }
  }

  LLMResponse _parseOpenAIResponse(Map<String, dynamic> message) {
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
      return LLMResponse(
        content: message['content'] ??
            'Sorry, this task is not valid for me. I can only help with email-related tasks.',
      );
    }
  }
}
