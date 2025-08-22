// lib/services/todo/models/todo_models.dart
import '../../base_tool_service.dart';

class Todo {
  final String id;
  final String title;
  final String description;
  final String priority;
  final DateTime dueDate;
  final bool completed;

  Todo({
    required this.id,
    required this.title,
    required this.description,
    required this.priority,
    required this.dueDate,
    this.completed = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'priority': priority,
      'due_date': dueDate.toIso8601String(),
      'completed': completed,
    };
  }

  factory Todo.fromJson(Map<String, dynamic> json) {
    return Todo(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      priority: json['priority'],
      dueDate: DateTime.parse(json['due_date']),
      completed: json['completed'] ?? false,
    );
  }
}

class TodoCreationResult extends ToolResult {
  final String todoId;
  final String title;
  final String description;
  final String priority;
  final DateTime dueDate;

  TodoCreationResult({
    required bool success,
    required this.todoId,
    required this.title,
    required this.description,
    required this.priority,
    required this.dueDate,
    required String message,
  }) : super(success: success, message: message);

  @override
  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'todo_id': todoId,
      'title': title,
      'description': description,
      'priority': priority,
      'due_date': dueDate.toIso8601String(),
      'message': message,
    };
  }
}

class TodoListResult extends ToolResult {
  final List<Map<String, dynamic>> todos;

  TodoListResult({
    required bool success,
    required this.todos,
    required String message,
  }) : super(success: success, message: message);

  @override
  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'todos': todos,
      'message': message,
    };
  }
}

class TodoUpdateResult extends ToolResult {
  final String todoId;
  final Map<String, dynamic> updatedFields;

  TodoUpdateResult({
    required bool success,
    required this.todoId,
    required this.updatedFields,
    required String message,
  }) : super(success: success, message: message);

  @override
  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'todo_id': todoId,
      'updated_fields': updatedFields,
      'message': message,
    };
  }
}

class TodoDeletionResult extends ToolResult {
  final String todoId;

  TodoDeletionResult({
    required bool success,
    required this.todoId,
    required String message,
  }) : super(success: success, message: message);

  @override
  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'todo_id': todoId,
      'message': message,
    };
  }
}
