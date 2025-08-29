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
  bool _isEmailApprovalPending = false; // New state variable

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
          // Check if the response is an email for approval
          if (response.startsWith('I have drafted the following email')) {
            _isEmailApprovalPending = true;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _llmResponse = 'Sorry, something went wrong. Please try again.';
          _isLoading = false;
        });
      }
    }
  }

  // New method to handle button presses
  void _handleApprovalAction(String action) async {
    setState(() {
      _isLoading = true;
      _llmResponse = '';
    });

    try {
      String response = '';
      if (action == 'approve') {
        response = await _chatService.sendApprovedEmail();
      } else if (action == 'cancel') {
        _chatService.cancelEmailDraft();
        response = 'Email draft cancelled.';
      } else if (action == 'edit') {
        response = 'What changes would you like to make?';
        _chatController.text = _chatService.getPendingEmailContent();
      }

      if (mounted) {
        setState(() {
          _llmResponse = response;
          _isLoading = false;
          _isEmailApprovalPending = false; // Hide buttons after action
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
