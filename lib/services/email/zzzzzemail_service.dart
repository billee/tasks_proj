// lib/services/email/email_service.dart
import 'dart:math';
import 'data_sources/email_data_source.dart';
import 'models/email_models.dart';

class EmailService {
  final EmailDataSource dataSource;
  final Random _random = Random();

  EmailService({required this.dataSource});

  Future<EmailCreationResult> createEmail({
    required String recipient,
    required String subject,
    required String content,
    String priority = 'normal',
  }) async {
    // Validate email format
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

    // Simulate email creation delay
    await Future.delayed(Duration(milliseconds: 800 + _random.nextInt(700)));

    // Generate realistic email ID
    final emailId = _generateRealisticEmailId();

    // Simulate occasional failures
    if (_random.nextDouble() < 0.1) {
      return EmailCreationResult(
        success: false,
        emailId: '',
        subject: subject,
        recipient: recipient,
        content: content,
        message: 'Email server temporarily unavailable. Please try again.',
      );
    }

    // Store email status
    final status = EmailStatus(
      emailId: emailId,
      status: 'queued',
      timestamp: DateTime.now(),
    );

    await dataSource.saveEmailStatus(status);

    return EmailCreationResult(
      success: true,
      emailId: emailId,
      subject: subject,
      recipient: recipient,
      content: content,
      message: 'Email created successfully and queued for delivery',
    );
  }

  Future<Map<String, dynamic>> getEmailStatus(String emailId) async {
    await Future.delayed(Duration(milliseconds: 500));

    final existingStatus = await dataSource.getEmailStatus(emailId);

    if (existingStatus != null) {
      // Simulate status progression
      final statuses = ['queued', 'sent', 'delivered'];
      final currentIndex = statuses.indexOf(existingStatus.status);
      String newStatus = existingStatus.status;

      if (currentIndex < statuses.length - 1 && _random.nextDouble() < 0.7) {
        newStatus = statuses[currentIndex + 1];
      } else if (_random.nextDouble() < 0.05) {
        newStatus = 'failed';
      }

      final updatedStatus = EmailStatus(
        emailId: emailId,
        status: newStatus,
        timestamp: DateTime.now(),
      );

      await dataSource.saveEmailStatus(updatedStatus);

      return {
        'success': true,
        'data': updatedStatus.toJson(),
      };
    }

    // For unknown emails, generate random status
    final statuses = ['queued', 'sent', 'delivered', 'failed'];
    final randomStatus = statuses[_random.nextInt(statuses.length)];

    return {
      'success': true,
      'data': {
        'email_id': emailId,
        'status': randomStatus,
        'timestamp': DateTime.now().toIso8601String(),
      },
    };
  }

  String _generateRealisticEmailId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = _random.nextInt(999999);
    final prefix = ['MSG', 'EML', 'MAIL'][_random.nextInt(3)];
    return '${prefix}_${timestamp.toString().substring(8)}_${random.toString().padLeft(6, '0')}';
  }

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }
}
