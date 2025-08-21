// lib/models/llm_models.dart

class LLMRequest {
  final String message;
  final List<LLMTool> tools;

  LLMRequest({required this.message, required this.tools});

  Map<String, dynamic> toJson() {
    return {
      'message': message,
      'tools': tools.map((tool) => tool.toJson()).toList(),
    };
  }
}

class LLMResponse {
  final String content;
  final List<ToolCall>? toolCalls;
  final bool hasToolCalls;

  LLMResponse({required this.content, this.toolCalls})
      : hasToolCalls = toolCalls != null && toolCalls.isNotEmpty;

  factory LLMResponse.fromJson(Map<String, dynamic> json) {
    return LLMResponse(
      content: json['content'] ?? '',
      toolCalls: json['tool_calls'] != null
          ? (json['tool_calls'] as List)
              .map((tc) => ToolCall.fromJson(tc))
              .toList()
          : null,
    );
  }
}

class LLMTool {
  final String name;
  final String description;
  final Map<String, dynamic> parameters;

  LLMTool({
    required this.name,
    required this.description,
    required this.parameters,
  });

  Map<String, dynamic> toJson() {
    return {'name': name, 'description': description, 'parameters': parameters};
  }
}

class ToolCall {
  final String toolName;
  final Map<String, dynamic> arguments;

  ToolCall({required this.toolName, required this.arguments});

  factory ToolCall.fromJson(Map<String, dynamic> json) {
    return ToolCall(
      toolName: json['tool_name'] ?? '',
      arguments: json['arguments'] ?? {},
    );
  }
}

// Base result class for all tool operations
abstract class ToolResult {
  final bool success;
  final String message;

  ToolResult({required this.success, required this.message});

  Map<String, dynamic> toJson();
}

// Email-related models
class EmailCreationResult extends ToolResult {
  final String emailId;
  final String subject;
  final String recipient;
  final String content;

  EmailCreationResult({
    required bool success,
    required this.emailId,
    required this.subject,
    required this.recipient,
    required this.content,
    required String message,
  }) : super(success: success, message: message);

  factory EmailCreationResult.fromJson(Map<String, dynamic> json) {
    return EmailCreationResult(
      success: json['success'] ?? false,
      emailId: json['email_id'] ?? '',
      subject: json['subject'] ?? '',
      recipient: json['recipient'] ?? '',
      content: json['content'] ?? '',
      message: json['message'] ?? '',
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'email_id': emailId,
      'subject': subject,
      'recipient': recipient,
      'content': content,
      'message': message,
    };
  }
}

class EmailStatus {
  final String emailId;
  final String status;
  final DateTime timestamp;

  EmailStatus({
    required this.emailId,
    required this.status,
    required this.timestamp,
  });

  factory EmailStatus.fromJson(Map<String, dynamic> json) {
    return EmailStatus(
      emailId: json['email_id'] ?? '',
      status: json['status'] ?? '',
      timestamp: DateTime.parse(json['timestamp']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'email_id': emailId,
      'status': status,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

// Todo-related models
enum TodoPriority { low, medium, high, urgent }

enum TodoStatus { pending, inProgress, completed, cancelled }

class TodoItem {
  final String id;
  final String title;
  final String description;
  final TodoPriority priority;
  final TodoStatus status;
  final DateTime? dueDate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String> tags;

  TodoItem({
    required this.id,
    required this.title,
    required this.description,
    required this.priority,
    required this.status,
    this.dueDate,
    required this.createdAt,
    required this.updatedAt,
    this.tags = const [],
  });

  factory TodoItem.fromJson(Map<String, dynamic> json) {
    return TodoItem(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      priority: TodoPriority.values.firstWhere(
        (p) => p.name == json['priority'],
        orElse: () => TodoPriority.medium,
      ),
      status: TodoStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => TodoStatus.pending,
      ),
      dueDate:
          json['due_date'] != null ? DateTime.parse(json['due_date']) : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      tags: List<String>.from(json['tags'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'priority': priority.name,
      'status': status.name,
      'due_date': dueDate?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'tags': tags,
    };
  }

  TodoItem copyWith({
    String? title,
    String? description,
    TodoPriority? priority,
    TodoStatus? status,
    DateTime? dueDate,
    List<String>? tags,
  }) {
    return TodoItem(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      dueDate: dueDate ?? this.dueDate,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      tags: tags ?? this.tags,
    );
  }
}

class TodoCreationResult extends ToolResult {
  final TodoItem? todo;

  TodoCreationResult({
    required bool success,
    required String message,
    this.todo,
  }) : super(success: success, message: message);

  factory TodoCreationResult.fromJson(Map<String, dynamic> json) {
    return TodoCreationResult(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      todo: json['todo'] != null ? TodoItem.fromJson(json['todo']) : null,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'todo': todo?.toJson(),
    };
  }
}

class TodoListResult extends ToolResult {
  final List<TodoItem> todos;
  final int totalCount;

  TodoListResult({
    required bool success,
    required String message,
    required this.todos,
    required this.totalCount,
  }) : super(success: success, message: message);

  factory TodoListResult.fromJson(Map<String, dynamic> json) {
    return TodoListResult(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      todos: (json['todos'] as List<dynamic>?)
              ?.map((todo) => TodoItem.fromJson(todo))
              .toList() ??
          [],
      totalCount: json['total_count'] ?? 0,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'todos': todos.map((todo) => todo.toJson()).toList(),
      'total_count': totalCount,
    };
  }
}

class TodoUpdateResult extends ToolResult {
  final TodoItem? todo;

  TodoUpdateResult({
    required bool success,
    required String message,
    this.todo,
  }) : super(success: success, message: message);

  factory TodoUpdateResult.fromJson(Map<String, dynamic> json) {
    return TodoUpdateResult(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      todo: json['todo'] != null ? TodoItem.fromJson(json['todo']) : null,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'todo': todo?.toJson(),
    };
  }
}

class TodoDeletionResult extends ToolResult {
  final String todoId;

  TodoDeletionResult({
    required bool success,
    required String message,
    required this.todoId,
  }) : super(success: success, message: message);

  factory TodoDeletionResult.fromJson(Map<String, dynamic> json) {
    return TodoDeletionResult(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      todoId: json['todo_id'] ?? '',
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'todo_id': todoId,
    };
  }
}
