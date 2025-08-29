// lib/widgets/chat_response_widget.dart
import 'package:flutter/material.dart';

class ChatResponseWidget extends StatelessWidget {
  final String response;
  final bool isLoading;
  final bool isEmailApprovalPending;
  final VoidCallback? onApprove;
  final VoidCallback? onEdit;
  final VoidCallback? onCancel;

  const ChatResponseWidget({
    Key? key,
    required this.response,
    required this.isLoading,
    this.isEmailApprovalPending = false,
    this.onApprove,
    this.onEdit,
    this.onCancel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      padding: const EdgeInsets.all(20.0),
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isLoading)
              _buildLoadingIndicator()
            else if (response.isEmpty)
              _buildEmptyState()
            else
              _buildResponseContent(),
            if (isEmailApprovalPending) _buildApprovalButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return const Column(
      children: [
        CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
          strokeWidth: 2.0,
        ),
        SizedBox(height: 16.0),
        Text(
          'Thinking...',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 16.0,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return const Column(
      children: [
        Icon(
          Icons.chat_bubble_outline,
          size: 48.0,
          color: Colors.white30,
        ),
        SizedBox(height: 16.0),
        Text(
          'Ask me what task you need help with!',
          style: TextStyle(
            color: Colors.white54,
            fontSize: 16.0,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildResponseContent() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.grey[700]!, width: 1.0),
      ),
      child: Text(
        response,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16.0,
          height: 1.5,
        ),
        textAlign: TextAlign.left,
      ),
    );
  }

  Widget _buildApprovalButtons() {
    // Wrap the Row with a SingleChildScrollView to prevent overflow
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildButton('Approve', Colors.green, onApprove),
          const SizedBox(width: 12.0),
          _buildButton('Edit', Colors.blue, onEdit),
          const SizedBox(width: 12.0),
          _buildButton('Cancel', Colors.red, onCancel),
        ],
      ),
    );
  }

  Widget _buildButton(String text, Color color, VoidCallback? onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.0),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
      ),
      child: Text(text),
    );
  }
}
