// lib/services/email/email_tool_service.dart
import 'package:flutter/material.dart';
import '../base_tool_service.dart';
import '../../models/llm_models.dart';
import 'models/email_models.dart';
import 'email_service.dart';
import 'data_sources/local_email_data_source.dart';

class EmailToolService extends BaseToolService {
  static const String _serviceId = 'email';
  static const String _serviceName = 'Email Service';

  final EmailService _emailService;

  EmailToolService()
      : _emailService = EmailService(dataSource: LocalEmailDataSource());

  @override
  String get serviceId => _serviceId;

  @override
  String get serviceName => _serviceName;

  @override
  List<LLMTool> get availableTools => [
        LLMTool(
          name: 'create_email',
          description:
              'Drafts an email with specified recipient, subject, and content for user approval.',
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
            },
            'required': ['recipient', 'subject', 'content'],
          },
        ),
        LLMTool(
          name: 'send_email',
          description: 'Sends a previously drafted email.',
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
          return _createEmailDraft(validatedArgs);
        case 'send_email':
          return await _sendEmail(validatedArgs);
        case 'get_email_status':
          return await _getEmailStatus(validatedArgs);
        case 'get_email_history':
          return await _getEmailHistory(validatedArgs);
        default:
          return createErrorResult('Unknown tool: ${toolCall.toolName}');
      }
    } on ToolValidationException catch (e) {
      return createErrorResult(e.message);
    } on ToolExecutionException catch (e) {
      return createErrorResult(e.message);
    } catch (e) {
      return createErrorResult('Unexpected error: ${e.toString()}');
    }
  }

  Future<ToolResult> _createEmailDraft(Map<String, dynamic> arguments) async {
    // This tool no longer sends the email, it just confirms the draft is ready
    return createSuccessResult(
      'Email draft prepared. Recipient: ${arguments['recipient']}, Subject: ${arguments['subject']}',
      arguments,
    );
  }

  Future<ToolResult> _sendEmail(Map<String, dynamic> arguments) async {
    final recipient = arguments['recipient'] as String;
    final subject = arguments['subject'] as String;
    final content = arguments['content'] as String;
    final priority = arguments['priority'] as String? ?? 'normal';

    final result = await _emailService.createEmail(
      recipient: recipient,
      subject: subject,
      content: content,
      priority: priority,
    );

    if (result.success) {
      return createSuccessResult(
        result.message,
        result.toJson(),
      );
    } else {
      return createErrorResult(result.message);
    }
  }

  Future<ToolResult> _getEmailStatus(Map<String, dynamic> arguments) async {
    final emailId = arguments['email_id'] as String;
    final result = await _emailService.getEmailStatus(emailId);

    return createSuccessResult(
      'Email status retrieved successfully',
      result['data'],
    );
  }

  Future<ToolResult> _getEmailHistory(Map<String, dynamic> arguments) async {
    final limit = arguments['limit'] as int? ?? 10;
    final statusFilter = arguments['status_filter'] as String?;

    // This would be implemented in the EmailService if needed
    // For now, return a placeholder response
    return createSuccessResult(
      'Email history retrieval is not yet implemented.',
      {'limit': limit, 'status_filter': statusFilter},
    );
  }
}
