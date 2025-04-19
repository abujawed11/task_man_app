import 'package:flutter/material.dart';
import '../models/task.dart';
import '../models/user.dart';
import '../data/user_data.dart'; // Contains list of users
import '../models/task_data.dart'; // ✅ To use globalTaskList

class AssignTaskPage extends StatefulWidget {
  final String assigner;
  const AssignTaskPage({super.key, required this.assigner});

  @override
  State<AssignTaskPage> createState() => _AssignTaskPageState();
}

class _AssignTaskPageState extends State<AssignTaskPage> {
  final _formKey = GlobalKey<FormState>();

  String _title = '';
  String _description = '';
  String _priority = 'Medium';
  DateTime? _deadline;
  String? _assignee;

  @override
  Widget build(BuildContext context) {
    // Filter members from the user list (only those with role 'Member')
    List<User> members = users.where((u) => u.role == 'Member').toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Assign Task')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Task Title
              TextFormField(
                decoration: const InputDecoration(labelText: 'Title'),
                onSaved: (value) => _title = value!,
                validator: (value) =>
                value!.isEmpty ? 'Please enter a title' : null,
              ),
              const SizedBox(height: 10),

              // Task Description
              TextFormField(
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
                onSaved: (value) => _description = value!,
                validator: (value) =>
                value!.isEmpty ? 'Please enter a description' : null,
              ),
              const SizedBox(height: 10),

              // Priority Dropdown
              DropdownButtonFormField<String>(
                value: _priority,
                decoration: const InputDecoration(labelText: 'Priority'),
                items: ['Low', 'Medium', 'High']
                    .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _priority = value!;
                  });
                },
              ),
              const SizedBox(height: 10),

              // Deadline Picker
              ListTile(
                title: Text(
                    _deadline == null ? 'Select Deadline' : 'Deadline: ${_deadline!.toLocal().toString().split(' ')[0]}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now().add(const Duration(days: 1)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2100),
                  );
                  if (date != null) {
                    setState(() {
                      _deadline = date;
                    });
                  }
                },
              ),
              const SizedBox(height: 10),

              // Assignee Dropdown
              DropdownButtonFormField<String>(
                value: _assignee,
                decoration: const InputDecoration(labelText: 'Assign To'),
                items: members
                    .map((u) => DropdownMenuItem(value: u.username, child: Text(u.username)))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _assignee = value;
                  });
                },
                validator: (value) =>
                value == null ? 'Please select a user' : null,
              ),
              const SizedBox(height: 20),

              // Submit Button
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate() && _deadline != null && _assignee != null) {
                    _formKey.currentState!.save();

                    // Create the task object
                    final task = Task(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      title: _title,
                      description: _description,
                      priority: _priority,
                      deadline: _deadline!,
                      assignedTo: _assignee!,
                      assignedBy: widget.assigner,
                      createdBy: widget.assigner,
                      status: 'Assigned',
                    );

                    // ✅ Add to global in-memory task list
                    globalTaskList.add(task);

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Task assigned successfully!')),
                    );

                    Navigator.pop(context); // Go back to the dashboard page
                  } else if (_deadline == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please select a deadline')),
                    );
                  }
                },
                child: const Text('Assign Task'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
