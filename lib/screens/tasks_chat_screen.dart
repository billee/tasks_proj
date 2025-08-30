// lib/screens/tasks_chat_screen.dart
import 'package:flutter/material.dart';
import '../widgets/chat_input_widget.dart';
import '../widgets/chat_response_widget.dart';
import '../widgets/tasks_title_widget.dart';
import '../services/chat_service.dart';

class TasksChatScreen extends StatefulWidget {
  const TasksChatScreen({Key? key}) : super(key: key);

  @override
  State<TasksChatScreen> createState() => _TasksChatScreenState();
}

class _TasksChatScreenState extends State<TasksChatScreen> {
  final TextEditingController _chatController = TextEditingController();
  final ChatService _chatService = ChatService();
  String _llmResponse = '';
  bool _isLoading = false;
  bool _isEmailApprovalPending = false;

  @override
  void dispose() {
    _chatController.dispose();
    super.dispose();
  }

  void _handleSendMessage(String message) async {
    if (message.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
      _llmResponse = '';
      _isEmailApprovalPending = false;
    });

    try {
      final response = await _chatService.processUserMessage(message);

      if (mounted) {
        setState(() {
          _llmResponse = response;
          _isLoading = false;
          // Check if the response is an email draft awaiting approval
          if (response
              .contains('I have drafted the following email for you.')) {
            _isEmailApprovalPending = true;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _llmResponse = 'Sorry, something went wrong. Please try again.';
          _isLoading = false;
          _isEmailApprovalPending = false;
        });
      }
    }
  }

  void _handleApprovalAction(String action) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _chatService.handleEmailApproval(action);

      if (mounted) {
        setState(() {
          _llmResponse = response;
          _isLoading = false;
          // Keep approval pending if we're in edit mode (response contains edit instructions)
          _isEmailApprovalPending =
              response.contains('Please provide your edits');
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _llmResponse = 'Sorry, something went wrong. Please try again.';
          _isLoading = false;
          _isEmailApprovalPending = false;
        });
      }
    }
  }

  void _handleSaveEdits(String editedContent) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _chatService.handleEmailApproval('approve',
          editedContent: editedContent);

      if (mounted) {
        setState(() {
          _llmResponse = response;
          _isLoading = false;
          _isEmailApprovalPending = false; // Hide buttons after sending
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _llmResponse = 'Sorry, something went wrong. Please try again.';
          _isLoading = false;
          _isEmailApprovalPending = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          children: [
            // Title Section
            const TasksTitleWidget(),

            // Response Section (Expanded to take available space)
            Expanded(
              child: ChatResponseWidget(
                response: _llmResponse,
                isLoading: _isLoading,
                isEmailApprovalPending: _isEmailApprovalPending,
                onApprove: () => _handleApprovalAction('approve'),
                onCancel: () => _handleApprovalAction('cancel'),
                onEdit: () => _handleApprovalAction('edit'),
                onSaveEdits: _handleSaveEdits,
              ),
            ),

            // Chat Input Section (Fixed at bottom)
            ChatInputWidget(
              controller: _chatController,
              onSendMessage: _handleSendMessage,
              isLoading: _isLoading,
            ),
          ],
        ),
      ),
    );
  }
}
