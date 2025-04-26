import 'dart:async'; // Required for Timer
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../models/task.dart';
import '../screens/assign_task_page.dart';
import 'login_page.dart';

// Global base URL
const String baseUrl = 'http://192.168.1.120:5000';

class DashboardPage extends StatefulWidget {
  final String username;
  final String role;

  const DashboardPage({super.key, required this.username, required this.role});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late List<Task> _visibleTasks; // Declare _visibleTasks
  Timer? _pollingTimer; // Declare _pollingTimer
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final List<String> _notifications = [];
  bool _showNotifications = false;

  @override
  void initState() {
    super.initState();
    _visibleTasks = []; // Initialize _visibleTasks
    _setupFirebaseMessaging();
    _requestNotificationPermissions();
    _getFCMToken();
    _loadTasks();
    _startPolling(); // Start polling for task updates
  }

  @override
  void dispose() {
    _pollingTimer?.cancel(); // Cancel polling timer to prevent memory leaks
    super.dispose();
  }

  // Start polling to periodically refresh tasks
  void _startPolling() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _loadTasks();
    });
  }

  // Load tasks from backend
  Future<void> _loadTasks() async {
    final url = Uri.parse('$baseUrl/tasks/${widget.username}?role=${widget.role}');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _visibleTasks = data.map((json) => Task.fromJson(json)).toList();
        });
        print('Tasks loaded: ${data.length}'); // Debug
      } else {
        print('Failed to load tasks: ${response.statusCode} ${response.body}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load tasks: ${response.statusCode}')),
        );
      }
    } catch (e) {
      print('Error loading tasks: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading tasks: $e')),
      );
    }
  }

  // Get FCM token and send to backend
  Future<void> _getFCMToken() async {
    String? token = await _firebaseMessaging.getToken();
    if (token != null) {
      print('FCM token: $token'); // Debug
      final url = Uri.parse('$baseUrl/update_fcm_token');
      try {
        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'username': widget.username,
            'fcm_token': token,
          }),
        );
        if (response.statusCode != 200) {
          print('Failed to update FCM token: ${response.statusCode} ${response.body}');
        }
      } catch (e) {
        print('Error updating FCM token: $e');
      }
    }
  }

  // Request notification permissions
  Future<void> _requestNotificationPermissions() async {
    await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  // Setup FCM listeners
  void _setupFirebaseMessaging() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notification = message.notification;
      if (notification != null) {
        print('Foreground notification: ${notification.title}'); // Debug
        _addNotification(
          notification.title ?? 'New Task',
          notification.body ?? 'You have a new notification',
        );
        _loadTasks(); // Refresh tasks
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      final notification = message.notification;
      if (notification != null) {
        print('Notification opened: ${notification.title}'); // Debug
        _addNotification(
          notification.title ?? 'New Task',
          notification.body ?? 'You have a new notification',
        );
        _loadTasks();
      }
    });
  }

  // Add notification to list
  void _addNotification(String title, String body) {
    setState(() {
      _notifications.insert(0, '$title: $body');
      if (_notifications.length > 10) {
        _notifications.removeLast();
      }
    });
  }

  // Logout user
  void _logout(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
          (route) => false,
    );
  }

  // Toggle notifications panel
  void _toggleNotifications() {
    setState(() {
      _showNotifications = !_showNotifications;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.role} Dashboard'),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications),
                onPressed: _toggleNotifications,
              ),
              if (_notifications.isNotEmpty)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      _notifications.length.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_showNotifications) _buildNotificationsPanel(),
          Container(
            padding: const EdgeInsets.all(16),
            alignment: Alignment.centerLeft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome, ${widget.username} 👋',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Role: ${widget.role}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadTasks,
              child: _visibleTasks.isEmpty
                  ? const Center(
                child: Text(
                  'No tasks assigned yet',
                  style: TextStyle(fontSize: 16),
                ),
              )
                  : ListView.builder(
                itemCount: _visibleTasks.length,
                itemBuilder: (context, index) {
                  final task = _visibleTasks[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    child: ListTile(
                      title: Text(task.title),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Assigned by: ${task.assignedBy}'),
                          Text('Priority: ${task.priority}'),
                          Text('Deadline: ${task.deadline.toLocal().toString().split(' ')[0]}'),
                        ],
                      ),
                      trailing: Chip(
                        label: Text(task.status),
                        backgroundColor: _getStatusColor(task.status),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: (widget.role == 'Admin' ||
          widget.role == 'Team Leader' ||
          widget.role == 'Super Admin')
          ? FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  AssignTaskPage(assigner: widget.username),
            ),
          );
          if (result == true) {
            _loadTasks();
          }
        },
        child: const Icon(Icons.add),
        tooltip: 'Assign Task',
      )
          : null,
    );
  }

  // Build notifications panel
  Widget _buildNotificationsPanel() {
    return Container(
      color: Colors.grey[200],
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              'Notifications',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          if (_notifications.isEmpty)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text('No new notifications'),
            )
          else
            ..._notifications.map((notification) => ListTile(
              title: Text(notification),
              dense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 8),
            )),
        ],
      ),
    );
  }

  // Get status color for task chip
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green[100]!;
      case 'in progress':
        return Colors.blue[100]!;
      case 'pending':
        return Colors.orange[100]!;
      default:
        return Colors.grey[100]!;
    }
  }
}