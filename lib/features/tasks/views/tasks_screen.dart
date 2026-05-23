import 'package:flutter/material.dart';

import 'package:staffportal/core/widgets/responsive_layout.dart';

class TasksScreen extends StatelessWidget {
  const TasksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tasks')),
      body: const ResponsiveWidth(
        child: Center(child: Text('Tasks screen coming soon')),
      ),
    );
  }
}
