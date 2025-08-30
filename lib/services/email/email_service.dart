// lib/services/email/email_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'models/email_models.dart';
// The `data_sources` import is no longer needed
// import 'data_sources/email_data_source.dart';

class EmailService {
  final String _resendApiKey;

  EmailService() : _resendApiKey = dotenv.env['RESEND_API_KEY'] ?? '';

  Future<EmailCreationResult> createEmail({
    required String recipient,
    required String subject,
    required String content,
    String priority = 'normal',
  }) async {
    if (_resendApiKey.isEmpty) {
      return EmailCreationResult(
        success: false,
        emailId: '',
        subject: subject,
        recipient: recipient,
        content: content,
        message:
            'Resend API key not found in .env file. Please check your setup.',
      );
    }

    try {
      final response = await http.post(
        Uri.parse('https://api.resend.com/emails'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_resendApiKey',
        },
        body: json.encode({
          // NOTE: You must replace `onboarding@resend.dev` with an email address
          // from a domain you have verified in your Resend account.
          'from': 'onboarding@resend.dev',
          'to': [recipient],
          'subject': subject,
          'html': '<p>$content</p>',
        }),
      );

      if (response.statusCode == 200) {
        return EmailCreationResult(
          success: true,
          emailId: 'real-email-${DateTime.now().millisecondsSinceEpoch}',
          subject: subject,
          recipient: recipient,
          content: content,
          message: 'Email sent successfully via Resend API!',
        );
      } else {
        return EmailCreationResult(
          success: false,
          emailId: '',
          subject: subject,
          recipient: recipient,
          content: content,
          message:
              'Failed to send email. Status: ${response.statusCode}, Body: ${response.body}',
        );
      }
    } catch (e) {
      return EmailCreationResult(
        success: false,
        emailId: '',
        subject: subject,
        recipient: recipient,
        content: content,
        message: 'An error occurred while sending the email: ${e.toString()}',
      );
    }
  }

  // The following methods will no longer work without a local data source
  // and need to be re-implemented to use the Resend API if you need them.
  // For now, they will return a generic failure message.

  Future<Map<String, dynamic>> getEmailStatus(String emailId) async {
    return {
      'success': false,
      'data': {
        'email_id': emailId,
        'status': 'unavailable',
        'timestamp': DateTime.now().toIso8601String(),
        'message': 'Status retrieval is not implemented with Resend API.',
      },
    };
  }
}
