import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';

// Global base URL for easy updates
const String baseUrl = 'http://10.20.1.54:5000';

class AssignTaskPage extends StatefulWidget {
  final String assigner;
  const AssignTaskPage({super.key, required this.assigner});

  @override
  State<AssignTaskPage> createState() => _AssignTaskPageState();
}

class _AssignTaskPageState extends State<AssignTaskPage> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  String? _selectedUser;
  DateTime? _deadline;
  String _priority = 'Medium';
  bool _isCreating = false;

  List<String> _users = [];
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    final response = await http.get(Uri.parse('$baseUrl/users'));
    if (response.statusCode == 200) {
      final List<dynamic> usernames = jsonDecode(response.body);
      setState(() {
        _users = usernames.cast<String>();
      });
    }
  }

  Future<void> _createTask() async {
    if (_selectedUser == null || _deadline == null || _titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all fields')));
      return;
    }

    setState(() => _isCreating = true);

    try {
      // First create the task
      final body = {
        'title': _titleController.text,
        'description': _descController.text,
        'assigned_by': widget.assigner,
        'assigned_to': _selectedUser,
        'deadline': _deadline!.toIso8601String().split('T')[0],
        'priority': _priority,
      };

      final response = await http.post(
        Uri.parse('$baseUrl/create_task'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Failed to create task: ${response.statusCode} ${response.body}');
      }

      // Then send notification
      await _sendNotificationToUser();

      Navigator.pop(context, true); // Return true to indicate success
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      setState(() => _isCreating = false);
    }
  }

  Future<void> _sendNotificationToUser() async {
    // 1. Get the FCM token of the assigned user from your backend
    final tokenResponse = await http.get(
      Uri.parse('$baseUrl/user_fcm_token?username=$_selectedUser'),
    );

    if (tokenResponse.statusCode == 200) {
      final tokenData = jsonDecode(tokenResponse.body);
      final fcmToken = tokenData['fcm_token'];

      if (fcmToken != null) {
        // 2. Send push notification via FCM
        await _sendPushNotification(fcmToken);
      }
    }
  }

  Future<void> _sendPushNotification(String token) async {
    // Replace with your Firebase Server Key from Firebase Console (Project Settings > Cloud Messaging)
    const String serverKey = 'YOUR_FIREBASE_SERVER_KEY'; // TODO: Store securely, preferably on backend

    final response = await http.post(
      Uri.parse('https://fcm.googleapis.com/fcm/send'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'key=$serverKey',
      },
      body: jsonEncode({
        'notification': {
          'title': 'New Task Assigned',
          'body': '${widget.assigner} assigned you a new task: ${_titleController.text}',
        },
        'to': token,
        'data': {
          'type': 'new_task',
          'assigned_by': widget.assigner,
          'task_title': _titleController.text,
        },
      }),
    );

    if (response.statusCode != 200) {
      print('Failed to send FCM message: ${response.body}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Assign Task')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Task Title'),
            ),
            TextField(
              controller: _descController,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField(
              value: _selectedUser,
              items: _users.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
              onChanged: (value) => setState(() => _selectedUser = value),
              decoration: const InputDecoration(labelText: 'Assign To'),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('Deadline: '),
                TextButton(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now().add(const Duration(days: 1)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      setState(() => _deadline = picked);
                    }
                  },
                  child: Text(
                    _deadline == null
                        ? 'Select Date'
                        : '${_deadline!.day}/${_deadline!.month}/${_deadline!.year}',
                  ),
                )
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _priority,
              items: ['High', 'Medium', 'Low']
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (val) => setState(() => _priority = val!),
              decoration: const InputDecoration(labelText: 'Priority'),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isCreating ? null : _createTask,
              child: _isCreating
                  ? const CircularProgressIndicator()
                  : const Text('Create Task'),
            ),
          ],
        ),
      ),
    );
  }
}