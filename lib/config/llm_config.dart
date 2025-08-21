// lib/config/llm_config.dart
class LLMConfig {
  // Provider Names
  static const String openaiProviderName = 'OpenAI';
  static const String deepseekProviderName = 'DeepSeek';
  static const String llamaProviderName = 'Llama';

  // Model Names
  static const String openaiModelName = 'gpt-4o-mini';
  static const String deepseekModelName = 'deepseek-chat';
  static const String llamaModelName =
      'meta-llama/Meta-Llama-3.1-8B-Instruct-Turbo';

  // API Base URLs
  static const String openaiBaseUrl = 'https://api.openai.com/v1';
  static const String deepseekBaseUrl = 'https://api.deepseek.com/v1';
  static const String llamaBaseUrl =
      'https://api.together.xyz/v1'; // or 'https://api.groq.com/openai/v1'

  // Environment Variable Keys (Safe to commit - these are just variable names)
  static const String openaiApiKeyEnv = 'OPENAI_API_KEY';
  static const String deepseekApiKeyEnv = 'DEEPSEEK_API_KEY';
  static const String llamaApiKeyEnv = 'TOGETHER_API_KEY'; // or 'GROQ_API_KEY'

  // Default Parameters
  static const int defaultMaxTokens = 1000;
  static const double defaultTemperature = 0.7;

  // Error Messages
  static const String openaiApiKeyError =
      'OpenAI API key not found. Please add OPENAI_API_KEY to your .env file.';
  static const String deepseekApiKeyError =
      'DeepSeek API key not found. Please add DEEPSEEK_API_KEY to your .env file.';
  static const String llamaApiKeyError =
      'Together API key not found. Please add TOGETHER_API_KEY to your .env file.';

  // System Messages
  static const String defaultErrorMessage =
      'Sorry, I encountered an error while processing your request';
  static const String emailTaskOnlyMessage =
      'Sorry, this task is not valid for me. I can only help with email-related tasks.';
  static const String emailCreationMessage = "I'll help you create an email.";
}
