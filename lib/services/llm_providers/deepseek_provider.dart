// lib/services/llm_providers/deepseek_provider.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../models/llm_models.dart';
import 'base_llm_provider.dart';

class DeepSeekProvider extends BaseLLMProvider {
  static const String _baseUrl = 'https://api.deepseek.com/v1';

  @override
  String get providerName => 'DeepSeek';

  @override
  String get modelName => 'deepseek-chat';

  String get _apiKey => dotenv.env['DEEPSEEK_API_KEY'] ?? '';

  @override
  Future<LLMResponse> sendMessage(String userMessage) async {
    try {
      if (_apiKey.isEmpty) {
        throw Exception(
            'DeepSeek API key not found. Please add DEEPSEEK_API_KEY to your .env file.');
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
            'DeepSeek API error: ${response.statusCode} - ${response.body}');
      }

      final responseData = json.decode(response.body);
      final message = responseData['choices'][0]['message'];

      return _parseDeepSeekResponse(message);
    } catch (e) {
      return LLMResponse(
        content:
            'Sorry, I encountered an error while processing your request: ${e.toString()}',
      );
    }
  }

  LLMResponse _parseDeepSeekResponse(Map<String, dynamic> message) {
    // DeepSeek might have slightly different response format
    // Adjust parsing logic if needed
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
