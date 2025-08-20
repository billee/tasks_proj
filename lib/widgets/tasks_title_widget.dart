// lib/widgets/tasks_title_widget.dart
import 'package:flutter/material.dart';

class TasksTitleWidget extends StatelessWidget {
  const TasksTitleWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 20.0),
      width: double.infinity,
      child: const Text(
        'Tasks To Do',
        style: TextStyle(
          color: Colors.white,
          fontSize: 28.0,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
