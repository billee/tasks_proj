// lib/widgets/chat_input_widget.dart
import 'package:flutter/material.dart';

class ChatInputWidget extends StatelessWidget {
  final TextEditingController controller;
  final Function(String) onSendMessage;

  const ChatInputWidget({
    Key? key,
    required this.controller,
    required this.onSendMessage,
  }) : super(key: key);

  void _sendMessage() {
    final message = controller.text.trim();
    if (message.isNotEmpty) {
      onSendMessage(message);
      controller.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        border: Border(top: BorderSide(color: Colors.grey[700]!, width: 1.0)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'What task do you want me to do?',
                hintStyle: TextStyle(color: Colors.white54),
                filled: true,
                fillColor: Colors.grey[800],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25.0),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20.0,
                  vertical: 12.0,
                ),
              ),
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 12.0),
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              width: 48.0,
              height: 48.0,
              decoration: BoxDecoration(
                color: Colors.blue[600],
                borderRadius: BorderRadius.circular(24.0),
              ),
              child: const Icon(Icons.send, color: Colors.white, size: 20.0),
            ),
          ),
        ],
      ),
    );
  }
}
