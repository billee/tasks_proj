// lib/routes/app_routes.dart
import 'package:flutter/material.dart';
import '../screens/tasks_chat_screen.dart';

class AppRoutes {
  static const String tasksChatScreen = '/tasks_chat';

  static Map<String, WidgetBuilder> get routes {
    return {tasksChatScreen: (context) => const TasksChatScreen()};
  }
}
