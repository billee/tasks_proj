// lib/screens/tasks_chat_screen.dart
import 'package:flutter/material.dart';
import '../widgets/chat_input_widget.dart';
import '../widgets/chat_response_widget.dart';
import '../widgets/tasks_title_widget.dart';

class TasksChatScreen extends StatefulWidget {
  const TasksChatScreen({Key? key}) : super(key: key);

  @override
  State<TasksChatScreen> createState() => _TasksChatScreenState();
}

class _TasksChatScreenState extends State<TasksChatScreen> {
  final TextEditingController _chatController = TextEditingController();
  String _llmResponse = '';
  bool _isLoading = false;

  @override
  void dispose() {
    _chatController.dispose();
    super.dispose();
  }

  void _handleSendMessage(String message) {
    // TODO: Implement LLM logic here
    print('Message sent: $message');

    setState(() {
      _isLoading = true;
    });

    // Placeholder for LLM response logic
    // This will be implemented later
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _llmResponse = 'This is where the LLM response will appear...';
          _isLoading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
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
