// lib/services/llm_providers/openai_provider.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../models/llm_models.dart';
import '../../config/llm_config.dart';
import 'base_llm_provider.dart';

class OpenAIProvider extends BaseLLMProvider {
  @override
  String get providerName => LLMConfig.openaiProviderName;

  @override
  String get modelName => LLMConfig.openaiModelName;

  String get _apiKey => dotenv.env[LLMConfig.openaiApiKeyEnv] ?? '';

  @override
  Future<LLMResponse> sendMessage(String userMessage,
      {List<LLMTool>? tools}) async {
    try {
      if (_apiKey.isEmpty) {
        throw Exception(LLMConfig.openaiApiKeyError);
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
        'max_tokens': LLMConfig.defaultMaxTokens,
        'temperature': LLMConfig.defaultTemperature,
      };

      final response = await http.post(
        Uri.parse('${LLMConfig.openaiBaseUrl}/chat/completions'),
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
      final responseMessage =
          responseData['choices'][0]['message']; // Renamed variable

      return _parseOpenAIResponse(responseMessage);
    } catch (e) {
      return LLMResponse(
        content: '${LLMConfig.defaultErrorMessage}: ${e.toString()}',
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
