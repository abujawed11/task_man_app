import 'package:flutter/material.dart';
import '../models/task.dart';
import '../models/task_data.dart'; // Global task list
import '../pages/assign_task_page.dart';

class DashboardPage extends StatelessWidget {
  final String username;
  final String role;

  const DashboardPage({super.key, required this.username, required this.role});

  @override
  Widget build(BuildContext context) {
    // Show all tasks if Admin/Team Leader/Super Admin, else only user's assigned tasks
    List<Task> visibleTasks = (role == 'Admin' || role == 'Team Leader' || role == 'Super Admin')
        ? globalTaskList
        : globalTaskList.where((task) => task.assignedTo == username).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('$role Dashboard'),
      ),
      body: visibleTasks.isEmpty
          ? const Center(child: Text('No tasks available'))
          : ListView.builder(
        itemCount: visibleTasks.length,
        itemBuilder: (context, index) {
          Task task = visibleTasks[index];
          return Card(
            margin: const EdgeInsets.all(8),
            child: ListTile(
              title: Text(task.title),
              subtitle: Text(
                'Assigned to: ${task.assignedTo}\n'
                    'Priority: ${task.priority}\n'
                    'Deadline: ${task.deadline.toLocal().toString().split(' ')[0]}',
              ),
              trailing: Text(task.status),
              isThreeLine: true,
            ),
          );
        },
      ),
      floatingActionButton: (role == 'Admin' || role == 'Team Leader' || role == 'Super Admin')
          ? FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AssignTaskPage(assigner: username),
            ),
          );
        },
        child: const Icon(Icons.add),
        tooltip: 'Assign Task',
      )
          : null,
    );
  }
}
