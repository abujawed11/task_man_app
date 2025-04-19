class Task {
  String id;
  String title;
  String description;
  String priority;
  DateTime deadline;
  String assignedTo;  // The member assigned to this task (can be empty initially)
  String assignedBy;  // Who assigned the task (can be 'Client', 'Admin', etc.)
  String status;      // 'Pending' or 'Assigned'
  String createdBy;   // The client, admin, or superadmin who created the task

  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.priority,
    required this.deadline,
    required this.assignedTo,
    required this.assignedBy,
    required this.status,
    required this.createdBy,
  });
}
