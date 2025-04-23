import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/task.dart';
import '../screens/assign_task_page.dart';
import 'login_page.dart';
import 'package:intl/intl.dart';


const admin = 'Admin';
const superAdmin = 'Super Admin';
class DashboardPage extends StatefulWidget {
  final String username;
  final String role;

  const DashboardPage({super.key, required this.username, required this.role});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {

  static const String baseUrl = 'http://10.20.1.54:5000';
  List<Task> _allTasks = [];
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final List<String> _notifications = [];
  bool _showNotifications = false;
  bool _isLoading = true;
  final _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();

  @override
  void initState() {
    super.initState();
    _setupFirebaseMessaging();
    _requestNotificationPermissions();
    _getFCMToken();
    _loadTasks();
  }

  List<Task> get _visibleTasks {
    if (widget.role == admin || widget.role == superAdmin)
    {
      return _allTasks;
    }
    else
    {
      return _allTasks.where((task) =>
      (task.assignedTo == widget.username
          || task.assignedBy == widget.username)).toList();
    }
  }

  Future<void> _requestNotificationPermissions() async {
    try {
      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        print('User granted permission');
      } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
        print('User granted provisional permission');
      } else {
        print('User declined or has not accepted permission');
      }
    } catch (e) {
      print('Error requesting notification permissions: $e');
    }
  }


  Future<void> _loadTasks() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/tasks?username=${widget.username}&role=${widget.role}'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> responseData = jsonDecode(response.body);
        setState(() {
          _allTasks = responseData.map((task) => Task.fromJson(task)).toList();
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load tasks');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading tasks: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _getFCMToken() async {
    String? token = await _firebaseMessaging.getToken();
    if (token != null) {
      await http.post(
        Uri.parse('$baseUrl/update_fcm_token'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': widget.username,
          'fcm_token': token,
        }),
      );
    }
  }

  void _setupFirebaseMessaging() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.data['type'] == 'new_task') {
        _loadTasks();
      }
      final notification = message.notification;
      if (notification != null) {
        _addNotification(
          notification.title ?? 'New Task',
          notification.body ?? 'You have a new task',
        );
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((_) => _loadTasks());
  }

  void _addNotification(String title, String body) {
    setState(() {
      _notifications.insert(0, '$title: $body');
      if (_notifications.length > 10) {
        _notifications.removeLast();
      }
    });
  }

  void _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text('${widget.role} Dashboard'),
        centerTitle: true,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue[700]!, Colors.blue[500]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              _refreshIndicatorKey.currentState?.show();
              _loadTasks();
            },
          ),
          _buildNotificationIcon(),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () => _logout(context),
          ),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(),
      body: Column(
        children: [
          _buildWelcomeCard(),
          Expanded(
            child: RefreshIndicator(
              key: _refreshIndicatorKey,
              onRefresh: _loadTasks,
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _visibleTasks.isEmpty
                  ? _buildEmptyState()
                  : _buildTaskList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationIcon() {
    return Stack(
      children: [
        IconButton(
          icon: const Icon(Icons.notifications, color: Colors.white),
          onPressed: () => setState(() => _showNotifications = !_showNotifications),
        ),
        if (_notifications.isNotEmpty)
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: Text(
                _notifications.length.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildWelcomeCard() {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome back, ${widget.username}! 👋',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.verified_user, size: 16, color: Colors.blue),
                const SizedBox(width: 4),
                Text(
                  'Role: ${widget.role}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            if (_showNotifications) _buildNotificationsPanel(),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationsPanel() {
    return Column(
      children: [
        const Divider(height: 24),
        const Text(
          'Notifications',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ..._notifications.map((notification) => ListTile(
          dense: true,
          leading: const Icon(Icons.notifications_active, color: Colors.blue),
          title: Text(notification),
          onTap: () => _loadTasks(),
        )),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No tasks available',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          if (widget.role == 'Admin' || widget.role == 'Super Admin')
            TextButton(
              onPressed: () => _refreshIndicatorKey.currentState?.show(),
              child: const Text('Refresh'),
            ),
        ],
      ),
    );
  }

  Widget _buildTaskList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _visibleTasks.length,
      itemBuilder: (context, index) {
        final task = _visibleTasks[index];
        return _buildTaskCard(task);
      },
    );
  }

  Widget _buildTaskCard(Task task) {
    final deadline = DateFormat('MMM dd, yyyy').format(task.deadline);
    final isUrgent = task.priority == 'High';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {}, // Add task details navigation if needed
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      task.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _buildPriorityBadge(task.priority),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                task.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.person, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    'Assigned by: ${task.assignedBy}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
             // if (widget.role == admin || widget.role == superAdmin)
                ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.person_outline, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      'Assigned to: ${task.assignedTo}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        deadline,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  _buildStatusChip(task.status),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPriorityBadge(String priority) {
    Color color;
    switch (priority) {
      case 'High':
        color = Colors.red;
        break;
      case 'Medium':
        color = Colors.orange;
        break;
      case 'Low':
        color = Colors.green;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        priority,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    return Chip(
      label: Text(
        status,
        style: const TextStyle(fontSize: 12),
      ),
      backgroundColor: _getStatusColor(status),
      labelPadding: const EdgeInsets.symmetric(horizontal: 4),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  Widget? _buildFloatingActionButton() {
  //  if (widget.role == 'admin' || widget.role == 'Super Admin')
    {
      return FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AssignTaskPage(assigner: widget.username),
            ),
          );
          if (result == true) _loadTasks();
        },
        child: const Icon(Icons.add),
        backgroundColor: Colors.blue,
        elevation: 4,
      );
    }
    return null;
  }

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