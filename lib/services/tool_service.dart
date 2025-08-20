// lib/services/tool_service.dart
import 'dart:math';
import '../models/llm_models.dart';

class ToolService {
  Future<EmailCreationResult> createEmail(
    Map<String, dynamic> arguments,
  ) async {
    try {
      // Extract parameters from arguments
      final recipient = arguments['recipient'] as String? ?? '';
      final subject = arguments['subject'] as String? ?? '';
      final content = arguments['content'] as String? ?? '';

      // Validate required parameters
      if (recipient.isEmpty || subject.isEmpty || content.isEmpty) {
        return EmailCreationResult(
          success: false,
          emailId: '',
          subject: subject,
          recipient: recipient,
          content: content,
          message:
              'Missing required parameters: recipient, subject, or content',
        );
      }

      // Simulate email creation delay
      await Future.delayed(const Duration(seconds: 1));

      // Generate fake email ID
      final emailId = _generateFakeEmailId();

      // Simulate successful email creation
      return EmailCreationResult(
        success: true,
        emailId: emailId,
        subject: subject,
        recipient: recipient,
        content: content,
        message: 'Email has been created and queued for sending!',
      );
    } catch (e) {
      return EmailCreationResult(
        success: false,
        emailId: '',
        subject: '',
        recipient: '',
        content: '',
        message: 'Failed to create email: ${e.toString()}',
      );
    }
  }

  String _generateFakeEmailId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(9999);
    return 'email_${timestamp}_$random';
  }
}
