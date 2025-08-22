// lib/services/email_tool_service.dart
import 'dart:math';
import 'base_tool_service.dart';
import '../models/llm_models.dart';

class EmailToolService extends BaseToolService {
  static const String _serviceId = 'email';
  static const String _serviceName = 'Email Service';

  // In-memory storage for demonstration
  final List<EmailStatus> _emailHistory = [];

  @override
  String get serviceId => _serviceId;

  @override
  String get serviceName => _serviceName;

  @override
  List<LLMTool> get availableTools => [
        LLMTool(
          name: 'create_email',
          description: 'Create and send an email to a recipient',
          parameters: {
            'type': 'object',
            'properties': {
              'recipient': {
                'type': 'string',
                'description': 'Email address of the recipient',
              },
              'subject': {
                'type': 'string',
                'description': 'Subject line of the email',
              },
              'content': {
                'type': 'string',
                'description': 'Body content of the email',
              },
              'priority': {
                'type': 'string',
                'enum': ['low', 'normal', 'high'],
                'default': 'normal',
                'description': 'Priority level of the email',
              },
            },
            'required': ['recipient', 'subject', 'content'],
          },
        ),
        LLMTool(
          name: 'get_email_status',
          description: 'Get the delivery status of an email',
          parameters: {
            'type': 'object',
            'properties': {
              'email_id': {
                'type': 'string',
                'description': 'ID of the email to check status for',
              },
            },
            'required': ['email_id'],
          },
        ),
        LLMTool(
          name: 'get_email_history',
          description: 'Get recent email history',
          parameters: {
            'type': 'object',
            'properties': {
              'limit': {
                'type': 'integer',
                'default': 10,
                'description': 'Maximum number of emails to return',
              },
              'status_filter': {
                'type': 'string',
                'enum': ['queued', 'sent', 'delivered', 'failed'],
                'description': 'Filter emails by status',
              },
            },
            'required': [],
          },
        ),
      ];

  @override
  Future<ToolResult> executeToolCall(ToolCall toolCall) async {
    try {
      final validatedArgs =
          validateParameters(toolCall.toolName, toolCall.arguments);

      switch (toolCall.toolName) {
        case 'create_email':
          return await _createEmail(validatedArgs);
        case 'get_email_status':
          return await _getEmailStatus(validatedArgs);
        case 'get_email_history':
          return await _getEmailHistory(validatedArgs);
        default:
          throw ToolExecutionException('Unknown tool: ${toolCall.toolName}');
      }
    } on ToolValidationException catch (e) {
      return createErrorResult(e.message);
    } on ToolExecutionException catch (e) {
      return createErrorResult(e.message);
    } catch (e) {
      return createErrorResult('Unexpected error: ${e.toString()}');
    }
  }

  Future<EmailCreationResult> _createEmail(
      Map<String, dynamic> arguments) async {
    try {
      final recipient = arguments['recipient'] as String;
      final subject = arguments['subject'] as String;
      final content = arguments['content'] as String;
      final priority = arguments['priority'] as String? ?? 'normal';

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

      // Simulate email creation delay (more realistic)
      await Future.delayed(Duration(milliseconds: 800 + Random().nextInt(700)));

      // Generate realistic email ID
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

      // Store email status in history
      final status = EmailStatus(
        emailId: emailId,
        status: 'queued',
        timestamp: timestamp,
      );
      _emailHistory.add(status);

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

  Future<ToolResult> _getEmailStatus(Map<String, dynamic> arguments) async {
    final emailId = arguments['email_id'] as String;

    // Simulate checking email status
    await Future.delayed(Duration(milliseconds: 500));

    // Check if email exists in history
    final existingStatus =
        _emailHistory.where((status) => status.emailId == emailId).lastOrNull;

    if (existingStatus != null) {
      // Simulate status progression
      final statuses = ['queued', 'sent', 'delivered'];
      final currentIndex = statuses.indexOf(existingStatus.status);
      String newStatus = existingStatus.status;

      if (currentIndex < statuses.length - 1 && Random().nextDouble() < 0.7) {
        newStatus = statuses[currentIndex + 1];
      } else if (Random().nextDouble() < 0.05) {
        newStatus = 'failed';
      }

      final updatedStatus = EmailStatus(
        emailId: emailId,
        status: newStatus,
        timestamp: DateTime.now(),
      );

      return createSuccessResult(
        'Email status retrieved successfully',
        updatedStatus.toJson(),
      );
    }

    // Generate random status for unknown email IDs
    final statuses = ['queued', 'sent', 'delivered', 'failed'];
    final randomStatus = statuses[Random().nextInt(statuses.length)];

    return createSuccessResult(
      'Email status retrieved successfully',
      {
        'email_id': emailId,
        'status': randomStatus,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  Future<ToolResult> _getEmailHistory(Map<String, dynamic> arguments) async {
    final limit = arguments['limit'] as int? ?? 10;
    final statusFilter = arguments['status_filter'] as String?;

    // Simulate getting email history
    await Future.delayed(Duration(milliseconds: 800));

    var history = List<EmailStatus>.from(_emailHistory);

    // Apply status filter if provided
    if (statusFilter != null) {
      history = history.where((email) => email.status == statusFilter).toList();
    }

    // Sort by timestamp (newest first) and apply limit
    history.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    history = history.take(limit).toList();

    // Add some sample data if history is empty
    if (history.isEmpty) {
      history = [
        EmailStatus(
          emailId: 'MSG_1234567_001',
          status: 'delivered',
          timestamp: DateTime.now().subtract(Duration(hours: 2)),
        ),
        EmailStatus(
          emailId: 'MSG_1234567_002',
          status: 'sent',
          timestamp: DateTime.now().subtract(Duration(minutes: 30)),
        ),
      ];
    }

    return createSuccessResult(
      'Email history retrieved successfully',
      {
        'emails': history.map((email) => email.toJson()).toList(),
        'total_count': history.length,
      },
    );
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
}
