// lib/services/email/models/email_models.dart
import '../../base_tool_service.dart'; // Import ToolResult

class EmailStatus {
  final String emailId;
  final String status; // queued, sent, delivered, failed
  final DateTime timestamp;

  EmailStatus({
    required this.emailId,
    required this.status,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'email_id': emailId,
      'status': status,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory EmailStatus.fromJson(Map<String, dynamic> json) {
    return EmailStatus(
      emailId: json['email_id'],
      status: json['status'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}

class EmailCreationResult extends ToolResult {
  final String emailId;
  final String subject;
  final String recipient;
  final String content;

  EmailCreationResult({
    required bool success,
    required this.emailId,
    required this.subject,
    required this.recipient,
    required this.content,
    required String message,
  }) : super(success: success, message: message);

  @override
  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'email_id': emailId,
      'subject': subject,
      'recipient': recipient,
      'content': content,
      'message': message,
    };
  }
}
