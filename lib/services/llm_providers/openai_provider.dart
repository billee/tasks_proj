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
  Future<LLMResponse> sendMessage(
    String userMessage, {
    List<Map<String, dynamic>> conversationHistory = const [],
    List<LLMTool> tools = const [],
  }) async {
    print(
        'rooooooooooooooooooooooooooooooooooooooooooooooo - openai_provider.dart');
    try {
      if (_apiKey.isEmpty) {
        throw Exception(LLMConfig.openaiApiKeyError);
      }

      // Prepare messages for the API
      final messages = <Map<String, dynamic>>[];

      // Add system prompt (using inherited method from base class)
      messages.add({
        'role': 'system',
        'content': getSystemPrompt(),
      });

      // Add conversation history
      for (var msg in conversationHistory) {
        // Skip tool messages as OpenAI doesn't support them directly
        if (msg['role'] == 'tool') continue;

        messages.add({
          'role': msg['role'],
          'content': msg['content'],
        });
      }

      // Add the current user message
      messages.add({
        'role': 'user',
        'content': userMessage,
      });

      // Prepare tools for the API
      final openAITools = tools.map((tool) {
        return {
          'type': 'function',
          'function': {
            'name': tool.name,
            'description': tool.description,
            'parameters': tool.parameters,
          }
        };
      }).toList();

      final requestBody = {
        'model': modelName,
        'messages': messages,
        'tools': openAITools.isNotEmpty ? openAITools : null,
        'tool_choice': openAITools.isNotEmpty ? 'auto' : null,
        'max_tokens': LLMConfig.defaultMaxTokens,
        'temperature': LLMConfig.defaultTemperature,
      };

      print(
          '==============================Sending to OpenAI: ${jsonEncode(requestBody)}');

      final response = await http.post(
        Uri.parse('${LLMConfig.openaiBaseUrl}/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: json.encode(requestBody),
      );

      print(
          '========================OpenAI response: ${response.statusCode} - ${response.body}');

      if (response.statusCode != 200) {
        throw Exception(
            'OpenAI API error: ${response.statusCode} - ${response.body}');
      }

      final responseData = json.decode(response.body);
      final message = responseData['choices'][0]['message'];

      return _parseOpenAIResponse(message);
    } catch (e) {
      print('=================================OpenAI API exception: $e');
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
