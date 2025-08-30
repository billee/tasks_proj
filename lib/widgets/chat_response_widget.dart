// lib/widgets/chat_response_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class ChatResponseWidget extends StatefulWidget {
  final String response;
  final bool isLoading;
  final bool isEmailApprovalPending;
  final VoidCallback onApprove;
  final VoidCallback onCancel;
  final VoidCallback onEdit;
  final Function(String)? onSaveEdits;

  const ChatResponseWidget({
    Key? key,
    required this.response,
    required this.isLoading,
    required this.isEmailApprovalPending,
    required this.onApprove,
    required this.onCancel,
    required this.onEdit,
    this.onSaveEdits,
  }) : super(key: key);

  @override
  State<ChatResponseWidget> createState() => _ChatResponseWidgetState();
}

class _ChatResponseWidgetState extends State<ChatResponseWidget> {
  bool _isEditingMode = false;
  final TextEditingController _editController = TextEditingController();

  @override
  void dispose() {
    _editController.dispose();
    super.dispose();
  }

  void _enterEditMode() {
    // Extract email content from the response for editing
    final content = _extractEmailContent(widget.response);
    _editController.text = content;
    setState(() {
      _isEditingMode = true;
    });
  }

  void _exitEditMode() {
    setState(() {
      _isEditingMode = false;
    });
  }

  void _saveEdits() {
    // Call the parent callback with the edited content
    if (widget.onSaveEdits != null) {
      widget.onSaveEdits!(_editController.text);
    }
    _exitEditMode();
  }

  String _extractEmailContent(String response) {
    // Extract just the email content part for editing
    // This is a simple extraction - you might want to make this more robust
    final lines = response.split('\n');
    final contentStartIndex = lines.indexWhere((line) =>
        line.trim().isEmpty &&
        lines.indexOf(line) > lines.indexWhere((l) => l.contains('Subject:')));

    if (contentStartIndex != -1 && contentStartIndex < lines.length - 1) {
      return lines.sublist(contentStartIndex + 1).join('\n').trim();
    }

    // Fallback: return the part after "Subject:" line
    final subjectIndex = lines.indexWhere((line) => line.contains('Subject:'));
    if (subjectIndex != -1 && subjectIndex < lines.length - 2) {
      return lines.sublist(subjectIndex + 2).join('\n').trim();
    }

    return '';
  }

  @override
  Widget build(BuildContext context) {
    final isEmailDraft = widget.response
            .contains('I have drafted the following email for you.') ||
        widget.response
            .contains('Please provide your edits to the email draft.');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: isEmailDraft
                  ? _EmailDraftWidget(
                      draft: widget.response,
                      isEditingMode: _isEditingMode,
                      editController: _editController,
                      onEnterEditMode: _enterEditMode,
                      onExitEditMode: _exitEditMode,
                      onSaveEdits: _saveEdits,
                    )
                  : MarkdownBody(
                      data: widget.isLoading ? '...' : widget.response,
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
          if (widget.isEmailApprovalPending && !_isEditingMode) ...[
            const SizedBox(height: 16),
            _buildApprovalButtons(),
          ],
          if (_isEditingMode) ...[
            const SizedBox(height: 16),
            _buildEditButtons(),
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
              onPressed: widget.onApprove,
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
              onPressed: widget.onCancel,
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
          onPressed: _enterEditMode,
          child: const Text(
            'Edit Draft',
            style: TextStyle(color: Colors.white70),
          ),
        ),
      ],
    );
  }

  Widget _buildEditButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ElevatedButton.icon(
          onPressed: _saveEdits,
          icon: const Icon(Icons.save, size: 20),
          label: const Text('Save Changes'),
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: Colors.blue,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0)),
          ),
        ),
        ElevatedButton.icon(
          onPressed: _exitEditMode,
          icon: const Icon(Icons.cancel, size: 20),
          label: const Text('Cancel Edit'),
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: Colors.grey,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0)),
          ),
        ),
      ],
    );
  }
}

class _EmailDraftWidget extends StatelessWidget {
  final String draft;
  final bool isEditingMode;
  final TextEditingController? editController;
  final VoidCallback? onEnterEditMode;
  final VoidCallback? onExitEditMode;
  final VoidCallback? onSaveEdits;

  const _EmailDraftWidget({
    Key? key,
    required this.draft,
    this.isEditingMode = false,
    this.editController,
    this.onEnterEditMode,
    this.onExitEditMode,
    this.onSaveEdits,
  }) : super(key: key);

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
            Center(
              child: Text(
                isEditingMode ? 'Edit Email Draft' : 'Email Draft',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18.0,
                ),
              ),
            ),
            const Divider(color: Colors.white38, height: 24),
            if (isEditingMode && editController != null) ...[
              _buildEditableEmailContent(),
            ] else ...[
              _buildReadOnlyEmailContent(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildReadOnlyEmailContent() {
    return MarkdownBody(
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
    );
  }

  Widget _buildEditableEmailContent() {
    // Parse the draft to extract recipient and subject for display
    final lines = draft.split('\n');
    String recipient = '';
    String subject = '';

    for (final line in lines) {
      if (line.startsWith('To: ')) {
        recipient = line.substring(4).trim();
      } else if (line.startsWith('Subject: ')) {
        subject = line.substring(9).trim();
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Show recipient and subject as read-only
        if (recipient.isNotEmpty) ...[
          Text(
            'To: $recipient',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16.0,
            ),
          ),
          const SizedBox(height: 8),
        ],
        if (subject.isNotEmpty) ...[
          Text(
            'Subject: $subject',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16.0,
            ),
          ),
          const SizedBox(height: 16),
        ],
        // Editable content field
        const Text(
          'Email Content:',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16.0,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: editController,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16.0,
            height: 1.5,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey[800],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: BorderSide(color: Colors.grey[600]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: BorderSide(color: Colors.grey[600]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: const BorderSide(color: Colors.blue),
            ),
            hintText: 'Edit your email content here...',
            hintStyle: const TextStyle(color: Colors.white54),
          ),
          maxLines: 10,
          minLines: 5,
        ),
      ],
    );
  }
}
