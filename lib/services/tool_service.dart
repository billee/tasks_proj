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

      // Validate email format (basic validation)
      if (!_isValidEmail(recipient)) {
        return EmailCreationResult(
          success: false,
          emailId: '',
          subject: subject,
          recipient: recipient,
          content: content,
          message: 'Invalid email address format: $recipient',
        );
      }

      // Simulate email creation delay (more realistic)
      await Future.delayed(Duration(milliseconds: 800 + Random().nextInt(700)));

      // Generate fake email ID with more realistic format
      final emailId = _generateRealisticEmailId();

      // Simulate occasional failures (10% chance) for more realistic behavior
      if (Random().nextDouble() < 0.1) {
        return EmailCreationResult(
          success: false,
          emailId: '',
          subject: subject,
          recipient: recipient,
          content: content,
          message: 'Email server temporarily unavailable. Please try again.',
        );
      }

      // Generate realistic timestamp
      final timestamp = DateTime.now();

      // Simulate successful email creation
      return EmailCreationResult(
        success: true,
        emailId: emailId,
        subject: subject,
        recipient: recipient,
        content: content,
        message:
            'Email created successfully and queued for delivery at ${_formatTimestamp(timestamp)}',
      );
    } catch (e) {
      return EmailCreationResult(
        success: false,
        emailId: '',
        subject: arguments['subject'] as String? ?? '',
        recipient: arguments['recipient'] as String? ?? '',
        content: arguments['content'] as String? ?? '',
        message: 'Failed to create email: ${e.toString()}',
      );
    }
  }

  // Enhanced fake email ID generation
  String _generateRealisticEmailId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(999999);
    final prefix = ['MSG', 'EML', 'MAIL'][Random().nextInt(3)];
    return '${prefix}_${timestamp.toString().substring(8)}_${random.toString().padLeft(6, '0')}';
  }

  // Basic email validation
  bool _isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }

  // Format timestamp for display
  String _formatTimestamp(DateTime timestamp) {
    return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')} ${timestamp.day}/${timestamp.month}/${timestamp.year}';
  }

  // Future: Add more email-related tools

  Future<Map<String, dynamic>> getEmailStatus(String emailId) async {
    // Simulate checking email status
    await Future.delayed(Duration(milliseconds: 500));

    final statuses = ['queued', 'sent', 'delivered', 'failed'];
    final randomStatus = statuses[Random().nextInt(statuses.length)];

    return {
      'email_id': emailId,
      'status': randomStatus,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  Future<List<Map<String, dynamic>>> getEmailHistory() async {
    // Simulate getting email history
    await Future.delayed(Duration(milliseconds: 800));

    return [
      {
        'id': 'MSG_1234567_001',
        'recipient': 'john@example.com',
        'subject': 'Meeting Reminder',
        'status': 'delivered',
        'created_at':
            DateTime.now().subtract(Duration(hours: 2)).toIso8601String(),
      },
      {
        'id': 'MSG_1234567_002',
        'recipient': 'team@company.com',
        'subject': 'Project Update',
        'status': 'sent',
        'created_at':
            DateTime.now().subtract(Duration(minutes: 30)).toIso8601String(),
      },
    ];
  }
}
