// lib/services/todo_tool_service.dart
import '../base_tool_service.dart';
import '../../models/llm_models.dart';
import 'models/todo_models.dart'; // Import from the new location

class TodoToolService extends BaseToolService {
  static const String _serviceId = 'todo';
  static const String _serviceName = 'Todo Management Service';

  // In-memory storage for demonstration
  final Map<String, TodoItem> _todos = {};

  @override
  String get serviceId => _serviceId;

  @override
  String get serviceName => _serviceName;

  @override
  List<LLMTool> get availableTools => [
        LLMTool(
          name: 'create_todo',
          description: 'Create a new todo item',
          parameters: {
            'type': 'object',
            'properties': {
              'title': {
                'type': 'string',
                'description': 'New title for the todo item',
              },
              'description': {
                'type': 'string',
                'description': 'New description for the todo item',
              },
              'priority': {
                'type': 'string',
                'enum': ['low', 'medium', 'high', 'urgent'],
                'description': 'New priority level',
              },
              'status': {
                'type': 'string',
                'enum': ['pending', 'inProgress', 'completed', 'cancelled'],
                'description': 'New status',
              },
              'due_date': {
                'type': 'string',
                'description': 'New due date in ISO 8601 format',
              },
              'tags': {
                'type': 'array',
                'items': {'type': 'string'},
                'description': 'New list of tags',
              },
            },
            'required': ['todo_id'],
          },
        ),
        LLMTool(
          name: 'delete_todo',
          description: 'Delete a todo item',
          parameters: {
            'type': 'object',
            'properties': {
              'todo_id': {
                'type': 'string',
                'description': 'ID of the todo item to delete',
              },
            },
            'required': ['todo_id'],
          },
        ),
        LLMTool(
          name: 'mark_todo_complete',
          description: 'Mark a todo item as completed',
          parameters: {
            'type': 'object',
            'properties': {
              'todo_id': {
                'type': 'string',
                'description': 'ID of the todo item to mark as complete',
              },
            },
            'required': ['todo_id'],
          },
        ),
      ];

  @override
  Future<ToolResult> executeToolCall(ToolCall toolCall) async {
    try {
      final validatedArgs =
          validateParameters(toolCall.toolName, toolCall.arguments);

      switch (toolCall.toolName) {
        case 'create_todo':
          return await _createTodo(validatedArgs);
        case 'list_todos':
          return await _listTodos(validatedArgs);
        case 'get_todo':
          return await _getTodo(validatedArgs);
        case 'update_todo':
          return await _updateTodo(validatedArgs);
        case 'delete_todo':
          return await _deleteTodo(validatedArgs);
        case 'mark_todo_complete':
          return await _markTodoComplete(validatedArgs);
        default:
          throw ToolExecutionException('Unknown tool: ${toolCall.toolName}');
      }
    } on ToolValidationException catch (e) {
      return createErrorResult(e.message);
    } on ToolExecutionException catch (e) {
      return createErrorResult(e.message);
    } catch (e) {
      return createErrorResult('Unexpected error: ${e.toString()}');
    }
  }

  Future<TodoCreationResult> _createTodo(Map<String, dynamic> arguments) async {
    try {
      // Simulate creation delay
      await Future.delayed(Duration(milliseconds: 300 + Random().nextInt(200)));

      final title = arguments['title'] as String;
      final description = arguments['description'] as String? ?? '';
      final priorityStr = arguments['priority'] as String? ?? 'medium';
      final dueDateStr = arguments['due_date'] as String?;
      final tags = List<String>.from(arguments['tags'] as List? ?? []);

      // Parse priority
      final priority = TodoPriority.values.firstWhere(
        (p) => p.name == priorityStr,
        orElse: () => TodoPriority.medium,
      );

      // Parse due date
      DateTime? dueDate;
      if (dueDateStr != null) {
        try {
          dueDate = DateTime.parse(dueDateStr);
        } catch (e) {
          return TodoCreationResult(
            success: false,
            message:
                'Invalid due_date format. Please use ISO 8601 format (e.g., 2024-12-25T10:00:00Z)',
          );
        }
      }

      // Generate unique ID
      final todoId = _generateTodoId();
      final now = DateTime.now();

      // Create todo item
      final todo = TodoItem(
        id: todoId,
        title: title,
        description: description,
        priority: priority,
        status: TodoStatus.pending,
        dueDate: dueDate,
        createdAt: now,
        updatedAt: now,
        tags: tags,
      );

      // Store the todo
      _todos[todoId] = todo;

      return TodoCreationResult(
        success: true,
        message: 'Todo item created successfully',
        todo: todo,
      );
    } catch (e) {
      return TodoCreationResult(
        success: false,
        message: 'Failed to create todo: ${e.toString()}',
      );
    }
  }

  Future<TodoListResult> _listTodos(Map<String, dynamic> arguments) async {
    try {
      // Simulate query delay
      await Future.delayed(Duration(milliseconds: 200 + Random().nextInt(300)));

      var todos = _todos.values.toList();

      // Apply filters
      final statusFilter = arguments['status'] as String?;
      if (statusFilter != null) {
        final status = TodoStatus.values.firstWhere(
          (s) => s.name == statusFilter,
          orElse: () => TodoStatus.pending,
        );
        todos = todos.where((todo) => todo.status == status).toList();
      }

      final priorityFilter = arguments['priority'] as String?;
      if (priorityFilter != null) {
        final priority = TodoPriority.values.firstWhere(
          (p) => p.name == priorityFilter,
          orElse: () => TodoPriority.medium,
        );
        todos = todos.where((todo) => todo.priority == priority).toList();
      }

      final tagFilter = arguments['tag'] as String?;
      if (tagFilter != null) {
        todos = todos.where((todo) => todo.tags.contains(tagFilter)).toList();
      }

      // Apply sorting
      final sortBy = arguments['sort_by'] as String? ?? 'created_at';
      final sortOrder = arguments['sort_order'] as String? ?? 'desc';
      final ascending = sortOrder == 'asc';

      todos.sort((a, b) {
        int comparison = 0;
        switch (sortBy) {
          case 'created_at':
            comparison = a.createdAt.compareTo(b.createdAt);
            break;
          case 'updated_at':
            comparison = a.updatedAt.compareTo(b.updatedAt);
            break;
          case 'due_date':
            if (a.dueDate == null && b.dueDate == null) return 0;
            if (a.dueDate == null) return 1;
            if (b.dueDate == null) return -1;
            comparison = a.dueDate!.compareTo(b.dueDate!);
            break;
          case 'priority':
            comparison = a.priority.index.compareTo(b.priority.index);
            break;
          case 'title':
            comparison = a.title.compareTo(b.title);
            break;
        }
        return ascending ? comparison : -comparison;
      });

      // Apply limit
      final limit = arguments['limit'] as int? ?? 20;
      final totalCount = todos.length;
      todos = todos.take(limit).toList();

      // Add sample data if empty
      if (_todos.isEmpty) {
        await _createSampleTodos();
        todos = _todos.values.take(limit).toList();
      }

      return TodoListResult(
        success: true,
        message: 'Todos retrieved successfully',
        todos: todos,
        totalCount: totalCount,
      );
    } catch (e) {
      return TodoListResult(
        success: false,
        message: 'Failed to retrieve todos: ${e.toString()}',
        todos: [],
        totalCount: 0,
      );
    }
  }

  Future<ToolResult> _getTodo(Map<String, dynamic> arguments) async {
    try {
      await Future.delayed(Duration(milliseconds: 100 + Random().nextInt(200)));

      final todoId = arguments['todo_id'] as String;
      final todo = _todos[todoId];

      if (todo == null) {
        return createErrorResult('Todo not found with ID: $todoId');
      }

      return createSuccessResult(
        'Todo retrieved successfully',
        {'todo': todo.toJson()},
      );
    } catch (e) {
      return createErrorResult('Failed to retrieve todo: ${e.toString()}');
    }
  }

  Future<TodoUpdateResult> _updateTodo(Map<String, dynamic> arguments) async {
    try {
      await Future.delayed(Duration(milliseconds: 200 + Random().nextInt(300)));

      final todoId = arguments['todo_id'] as String;
      final existingTodo = _todos[todoId];

      if (existingTodo == null) {
        return TodoUpdateResult(
          success: false,
          message: 'Todo not found with ID: $todoId',
        );
      }

      // Parse optional updates
      String? title = arguments['title'] as String?;
      String? description = arguments['description'] as String?;
      TodoPriority? priority;
      TodoStatus? status;
      DateTime? dueDate;
      List<String>? tags;

      if (arguments['priority'] != null) {
        priority = TodoPriority.values.firstWhere(
          (p) => p.name == arguments['priority'],
          orElse: () => existingTodo.priority,
        );
      }

      if (arguments['status'] != null) {
        status = TodoStatus.values.firstWhere(
          (s) => s.name == arguments['status'],
          orElse: () => existingTodo.status,
        );
      }

      if (arguments['due_date'] != null) {
        try {
          dueDate = DateTime.parse(arguments['due_date'] as String);
        } catch (e) {
          return TodoUpdateResult(
            success: false,
            message: 'Invalid due_date format. Please use ISO 8601 format',
          );
        }
      }

      if (arguments['tags'] != null) {
        tags = List<String>.from(arguments['tags'] as List);
      }

      // Update the todo
      final updatedTodo = existingTodo.copyWith(
        title: title,
        description: description,
        priority: priority,
        status: status,
        dueDate: dueDate,
        tags: tags,
      );

      _todos[todoId] = updatedTodo;

      return TodoUpdateResult(
        success: true,
        message: 'Todo updated successfully',
        todo: updatedTodo,
      );
    } catch (e) {
      return TodoUpdateResult(
        success: false,
        message: 'Failed to update todo: ${e.toString()}',
      );
    }
  }

  Future<TodoDeletionResult> _deleteTodo(Map<String, dynamic> arguments) async {
    try {
      await Future.delayed(Duration(milliseconds: 150 + Random().nextInt(200)));

      final todoId = arguments['todo_id'] as String;
      final todo = _todos.remove(todoId);

      if (todo == null) {
        return TodoDeletionResult(
          success: false,
          message: 'Todo not found with ID: $todoId',
          todoId: todoId,
        );
      }

      return TodoDeletionResult(
        success: true,
        message: 'Todo deleted successfully',
        todoId: todoId,
      );
    } catch (e) {
      return TodoDeletionResult(
        success: false,
        message: 'Failed to delete todo: ${e.toString()}',
        todoId: arguments['todo_id'] as String? ?? '',
      );
    }
  }

  Future<TodoUpdateResult> _markTodoComplete(
      Map<String, dynamic> arguments) async {
    try {
      await Future.delayed(Duration(milliseconds: 100 + Random().nextInt(150)));

      final todoId = arguments['todo_id'] as String;
      final existingTodo = _todos[todoId];

      if (existingTodo == null) {
        return TodoUpdateResult(
          success: false,
          message: 'Todo not found with ID: $todoId',
        );
      }

      final updatedTodo = existingTodo.copyWith(status: TodoStatus.completed);
      _todos[todoId] = updatedTodo;

      return TodoUpdateResult(
        success: true,
        message: 'Todo marked as completed',
        todo: updatedTodo,
      );
    } catch (e) {
      return TodoUpdateResult(
        success: false,
        message: 'Failed to mark todo as complete: ${e.toString()}',
      );
    }
  }

  String _generateTodoId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(999999);
    return 'todo_${timestamp}_${random.toString().padLeft(6, '0')}';
  }

  Future<void> _createSampleTodos() async {
    final sampleTodos = [
      TodoItem(
        id: _generateTodoId(),
        title: 'Complete project documentation',
        description: 'Write comprehensive documentation for the new feature',
        priority: TodoPriority.high,
        status: TodoStatus.inProgress,
        dueDate: DateTime.now().add(Duration(days: 3)),
        createdAt: DateTime.now().subtract(Duration(days: 2)),
        updatedAt: DateTime.now().subtract(Duration(hours: 1)),
        tags: ['work', 'documentation'],
      ),
      TodoItem(
        id: _generateTodoId(),
        title: 'Buy groceries',
        description: 'Milk, bread, eggs, vegetables',
        priority: TodoPriority.medium,
        status: TodoStatus.pending,
        dueDate: DateTime.now().add(Duration(days: 1)),
        createdAt: DateTime.now().subtract(Duration(hours: 6)),
        updatedAt: DateTime.now().subtract(Duration(hours: 6)),
        tags: ['personal', 'shopping'],
      ),
      TodoItem(
        id: _generateTodoId(),
        title: 'Schedule dentist appointment',
        description: 'Regular checkup and cleaning',
        priority: TodoPriority.low,
        status: TodoStatus.completed,
        dueDate: null,
        createdAt: DateTime.now().subtract(Duration(days: 7)),
        updatedAt: DateTime.now().subtract(Duration(days: 1)),
        tags: ['health', 'personal'],
      ),
    ];

    for (final todo in sampleTodos) {
      _todos[todo.id] = todo;
    }
  }
}
