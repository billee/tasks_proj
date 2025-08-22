// lib/services/llm_providers/llama_provider.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../models/llm_models.dart';
import '../../config/llm_config.dart';
import 'base_llm_provider.dart';

class LlamaProvider extends BaseLLMProvider {
  @override
  String get providerName => LLMConfig.llamaProviderName;

  @override
  String get modelName => LLMConfig.llamaModelName;

  String get _apiKey => dotenv.env[LLMConfig.llamaApiKeyEnv] ?? '';

  @override
  Future<LLMResponse> sendMessage(String userMessage,
      {List<LLMTool>? tools}) async {
    try {
      if (_apiKey.isEmpty) {
        throw Exception(LLMConfig.llamaApiKeyError);
      }

      // Llama might not support tools the same way, so we might need to handle differently
      final requestBody = {
        'model': modelName,
        'messages': [
          {
            'role': 'system',
            'content': _getLlamaSystemPrompt(), // Custom prompt for Llama
          },
          {
            'role': 'user',
            'content': userMessage,
          },
        ],
        'max_tokens': LLMConfig.defaultMaxTokens,
        'temperature': LLMConfig.defaultTemperature,
      };

      final response = await http.post(
        Uri.parse('${LLMConfig.llamaBaseUrl}/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: json.encode(requestBody),
      );

      if (response.statusCode != 200) {
        throw Exception(
            'Llama API error: ${response.statusCode} - ${response.body}');
      }

      final responseData = json.decode(response.body);
      final responseMessage =
          responseData['choices'][0]['message']; // Renamed variable

      return _parseLlamaResponse(responseMessage, userMessage);
    } catch (e) {
      return LLMResponse(
        content: '${LLMConfig.defaultErrorMessage}: ${e.toString()}',
      );
    }
  }

  String _getLlamaSystemPrompt() {
    return '''
You are an AI assistant that specializes in email-related tasks. 

When a user asks you to create an email, respond ONLY with a JSON object in this exact format:
{
  "action": "create_email",
  "recipient": "email@example.com",
  "subject": "Subject line",
  "content": "Email body content"
}

If the request is NOT email-related, respond with: "${LLMConfig.emailTaskOnlyMessage}"

Email-related requests include: send email, create email, compose email, write email, draft email, mail, send message, write to, contact, or any message containing an email address.
''';
  }

  LLMResponse _parseLlamaResponse(
      Map<String, dynamic> message, String originalMessage) {
    final content = message['content'] ?? '';

    // Try to parse JSON response for tool calls
    try {
      if (content.contains('"action": "create_email"')) {
        // Extract JSON from response
        final jsonStart = content.indexOf('{');
        final jsonEnd = content.lastIndexOf('}') + 1;

        if (jsonStart >= 0 && jsonEnd > jsonStart) {
          final jsonStr = content.substring(jsonStart, jsonEnd);
          final emailData = json.decode(jsonStr);

          if (emailData['action'] == 'create_email') {
            final toolCall = ToolCall(
              toolName: 'create_email',
              arguments: {
                'recipient': emailData['recipient'],
                'subject': emailData['subject'],
                'content': emailData['content'],
              },
            );

            return LLMResponse(
              content: LLMConfig.emailCreationMessage,
              toolCalls: [toolCall],
            );
          }
        }
      }
    } catch (e) {
      // If JSON parsing fails, fall through to regular response
    }

    return LLMResponse(content: content);
  }
}
