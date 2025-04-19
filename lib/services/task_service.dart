import '../models/task.dart';

class TaskService {
  static final List<Task> _tasks = [];

  static void addTask(Task task) {
    _tasks.add(task);
  }

  static List<Task> getTasksForUser(String username) {
    return _tasks.where((task) => task.assignedTo == username).toList();
  }

  static List<Task> getAllTasks() => _tasks;
}
