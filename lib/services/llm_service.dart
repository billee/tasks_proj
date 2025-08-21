// lib/services/llm_service.dart (Updated)
import '../models/llm_models.dart';
import 'llm_providers/base_llm_provider.dart';
import 'llm_providers/openai_provider.dart';
import 'llm_providers/deepseek_provider.dart';
import 'llm_providers/llama_provider.dart';
import 'tool_service.dart';

enum LLMProviderType {
  openai,
  deepseek,
  llama,
}

class LLMService {
  final ToolService _toolService = ToolService();
  late BaseLLMProvider _currentProvider;

  LLMService({LLMProviderType provider = LLMProviderType.openai}) {
    setProvider(provider);
  }

  void setProvider(LLMProviderType provider) {
    switch (provider) {
      case LLMProviderType.openai:
        _currentProvider = OpenAIProvider();
        break;
      case LLMProviderType.deepseek:
        _currentProvider = DeepSeekProvider();
        break;
      case LLMProviderType.llama:
        _currentProvider = LlamaProvider();
        break;
    }
  }

  BaseLLMProvider get currentProvider => _currentProvider;

  Future<LLMResponse> sendMessage(String userMessage) async {
    return await _currentProvider.sendMessage(userMessage);
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

  // Method to get available providers
  static List<String> getAvailableProviders() {
    return LLMProviderType.values.map((e) => e.name).toList();
  }

  // Method to switch providers at runtime
  void switchProvider(LLMProviderType newProvider) {
    setProvider(newProvider);
  }
}




// Example usage in your main app:
// 
// class EmailChatScreen extends StatefulWidget {
//   @override
//   _EmailChatScreenState createState() => _EmailChatScreenState();
// }
//
// class _EmailChatScreenState extends State<EmailChatScreen> {
//   late LLMService _llmService;
//   LLMProviderType _currentProvider = LLMProviderType.openai;
//
//   @override
//   void initState() {
//     super.initState();
//     _llmService = LLMService(provider: _currentProvider);
//   }
//
//   void _switchProvider(LLMProviderType newProvider) {
//     setState(() {
//       _currentProvider = newProvider;
//       _llmService.setProvider(newProvider);
//     });
//   }
//
//   // Your existing chat logic...
// }