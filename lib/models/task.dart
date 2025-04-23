class Task {
  final String taskId;
  final String title;
  final String description;
  final String assignedBy;
  final String assignedTo;
  final DateTime deadline;
  final String priority;
  final String status;

  Task({
    required this.taskId,
    required this.title,
    required this.description,
    required this.assignedBy,
    required this.assignedTo,
    required this.deadline,
    required this.priority,
    required this.status,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      taskId: json['task_id'],
      title: json['title'],
      description: json['description'] ?? '',
      assignedBy: json['assigned_by'],
      assignedTo: json['assigned_to'],
      deadline: DateTime.parse(json['deadline']),
      priority: json['priority'],
      status: json['status'],
    );
  }
}