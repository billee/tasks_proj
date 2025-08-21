// lib/services/llm_providers/deepseek_provider.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../models/llm_models.dart';
import '../../config/llm_config.dart';
import 'base_llm_provider.dart';

class DeepSeekProvider extends BaseLLMProvider {
  @override
  String get providerName => LLMConfig.deepseekProviderName;

  @override
  String get modelName => LLMConfig.deepseekModelName;

  String get _apiKey => dotenv.env[LLMConfig.deepseekApiKeyEnv] ?? '';

  @override
  Future<LLMResponse> sendMessage(String userMessage) async {
    try {
      if (_apiKey.isEmpty) {
        throw Exception(LLMConfig.deepseekApiKeyError);
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
        'max_tokens': LLMConfig.defaultMaxTokens,
        'temperature': LLMConfig.defaultTemperature,
      };

      final response = await http.post(
        Uri.parse('${LLMConfig.deepseekBaseUrl}/chat/completions'),
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
        content: '${LLMConfig.defaultErrorMessage}: ${e.toString()}',
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
        content: message['content'] ?? LLMConfig.emailCreationMessage,
        toolCalls: toolCalls,
      );
    } else {
      return LLMResponse(
        content: message['content'] ?? LLMConfig.emailTaskOnlyMessage,
      );
    }
  }
}
