import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';

// Global base URL for easy updates
const String baseUrl = 'https://task-man-app-2.onrender.com';

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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all fields'),
          backgroundColor: Colors.redAccent,
        ),
      );
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
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.redAccent,
        ),
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
    // Replace with your Firebase Server Key from Firebase Console
    const String serverKey = 'YOUR_FIREBASE_SERVER_KEY'; // TODO: Store securely

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
      appBar: AppBar(
        title: const Text(
          'Assign Task',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        elevation: 0,
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).primaryColor.withOpacity(0.1),
              Colors.white,
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Card(
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: ListView(
                children: [
                  _buildTextField(
                    controller: _titleController,
                    label: 'Task Title',
                    icon: Icons.title,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _descController,
                    label: 'Description',
                    icon: Icons.description,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  _buildDropdownField(
                    value: _selectedUser,
                    items: _users,
                    label: 'Assign To',
                    icon: Icons.person,
                    onChanged: (value) => setState(() => _selectedUser = value),
                  ),
                  const SizedBox(height: 16),
                  _buildDatePickerField(),
                  const SizedBox(height: 16),
                  _buildPriorityDropdown(),
                  const SizedBox(height: 24),
                  _buildCreateButton(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Theme.of(context).primaryColor),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.grey[100],
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  Widget _buildDropdownField({
    required String? value,
    required List<String> items,
    required String label,
    required IconData icon,
    required Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      items: items.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Theme.of(context).primaryColor),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.grey[100],
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  Widget _buildDatePickerField() {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: DateTime.now().add(const Duration(days: 1)),
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365)),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: ColorScheme.light(
                  primary: Theme.of(context).primaryColor,
                  onPrimary: Colors.white,
                  surface: Colors.white,
                ),
                dialogBackgroundColor: Colors.white,
              ),
              child: child!,
            );
          },
        );
        if (picked != null) {
          setState(() => _deadline = picked);
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Deadline',
          prefixIcon: Icon(Icons.calendar_today, color: Theme.of(context).primaryColor),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: Colors.grey[100],
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _deadline == null
                  ? 'Select Date'
                  : '${_deadline!.day}/${_deadline!.month}/${_deadline!.year}',
              style: TextStyle(
                color: _deadline == null ? Colors.grey : Colors.black87,
              ),
            ),
            const Icon(Icons.arrow_drop_down, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildPriorityDropdown() {
    return DropdownButtonFormField<String>(
      value: _priority,
      items: ['High', 'Medium', 'Low']
          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
          .toList(),
      onChanged: (val) => setState(() => _priority = val!),
      decoration: InputDecoration(
        labelText: 'Priority',
        prefixIcon: Icon(Icons.priority_high, color: Theme.of(context).primaryColor),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.grey[100],
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  Widget _buildCreateButton() {
    return ElevatedButton(
      onPressed: _isCreating ? null : _createTask,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 4,
        shadowColor: Theme.of(context).primaryColor.withOpacity(0.3),
      ),
      child: _isCreating
          ? const SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      )
          : const Text(
        'Create Task',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    );
  }
}