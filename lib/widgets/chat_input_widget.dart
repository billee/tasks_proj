// lib/widgets/chat_input_widget.dart
import 'package:flutter/material.dart';

class ChatInputWidget extends StatefulWidget {
  final TextEditingController controller;
  final Function(String) onSendMessage;
  final bool isLoading;

  const ChatInputWidget({
    Key? key,
    required this.controller,
    required this.onSendMessage,
    this.isLoading = false,
  }) : super(key: key);

  @override
  State<ChatInputWidget> createState() => _ChatInputWidgetState();
}

class _ChatInputWidgetState extends State<ChatInputWidget> {
  void _sendMessage() {
    if (widget.isLoading) return; // Prevent sending if loading
    final message = widget.controller.text.trim();
    if (message.isNotEmpty) {
      // Hide keyboard immediately
      FocusScope.of(context).unfocus();

      widget.onSendMessage(message);
      widget.controller.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        border: Border(
          top: BorderSide(color: Colors.grey[700]!, width: 1.0),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: widget.controller,
              enabled: !widget.isLoading, // Disable when loading
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'What task do you want me to do?',
                hintStyle: const TextStyle(color: Colors.white54),
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
                color: widget.isLoading ? Colors.grey[700] : Colors.blue[600],
                borderRadius: BorderRadius.circular(24.0),
              ),
              child: const Icon(
                Icons.send,
                color: Colors.white,
                size: 20.0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
