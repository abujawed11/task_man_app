import 'task.dart';

List<Task> globalTaskList = [
  Task(
    id: '1',
    title: 'Prepare project report',
    description: 'Report for Q1 performance',
    assignedTo: 'Ravi',
    assignedBy: 'Admin',
    priority: 'High',
    deadline: DateTime.now().add(const Duration(days: 2)),
    status: 'Pending',
    createdBy: 'Admin',
  ),
];
