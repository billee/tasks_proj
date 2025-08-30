// lib/widgets/chat_response_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class ChatResponseWidget extends StatelessWidget {
  final String response;
  final bool isLoading;
  final bool isEmailApprovalPending;
  final VoidCallback onApprove;
  final VoidCallback onCancel;
  final VoidCallback onEdit;

  const ChatResponseWidget({
    Key? key,
    required this.response,
    required this.isLoading,
    required this.isEmailApprovalPending,
    required this.onApprove,
    required this.onCancel,
    required this.onEdit,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isEmailDraft =
        response.contains('I have drafted the following email for you.');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: isEmailDraft
                  ? _EmailDraftWidget(draft: response)
                  : MarkdownBody(
                      data: isLoading ? '...' : response,
                      styleSheet: MarkdownStyleSheet(
                        p: const TextStyle(
                          color: Colors.white,
                          fontSize: 16.0,
                          height: 1.5,
                        ),
                        strong: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
            ),
          ),
          if (isEmailApprovalPending) ...[
            const SizedBox(height: 16),
            _buildApprovalButtons(),
          ],
        ],
      ),
    );
  }

  Widget _buildApprovalButtons() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton.icon(
              onPressed: onApprove,
              icon: const Icon(Icons.check, size: 20),
              label: const Text('Approve'),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.green,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0)),
              ),
            ),
            ElevatedButton.icon(
              onPressed: onCancel,
              icon: const Icon(Icons.close, size: 20),
              label: const Text('Cancel'),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: onEdit,
          child: const Text(
            'Edit Draft',
            style: TextStyle(color: Colors.white70),
          ),
        ),
      ],
    );
  }
}

class _EmailDraftWidget extends StatelessWidget {
  final String draft;

  const _EmailDraftWidget({Key? key, required this.draft}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(16.0),
        ),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: Text(
                'Email Draft',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18.0,
                ),
              ),
            ),
            const Divider(color: Colors.white38, height: 24),
            MarkdownBody(
              data: draft,
              styleSheet: MarkdownStyleSheet.fromTheme(
                ThemeData(
                  textTheme: const TextTheme(
                    bodyMedium: TextStyle(
                      color: Colors.white70,
                      fontSize: 16.0,
                      height: 1.5,
                    ),
                  ),
                ),
              ).copyWith(
                p: const TextStyle(
                  color: Colors.white70,
                  fontSize: 16.0,
                  height: 1.5,
                ),
                strong: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16.0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
