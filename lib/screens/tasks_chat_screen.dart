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
    });

    try {
      final response = await _chatService.processUserMessage(message);

      if (mounted) {
        setState(() {
          _llmResponse = response;
          _isLoading = false;
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
              ),
            ),

            // Chat Input Section (Fixed at bottom)
            ChatInputWidget(
              controller: _chatController,
              onSendMessage: _handleSendMessage,
            ),
          ],
        ),
      ),
    );
  }
}
