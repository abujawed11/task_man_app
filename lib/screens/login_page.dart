import 'package:flutter/material.dart';
import 'dashboard_page.dart';
import 'signup_page.dart'; // <-- for navigation to signup

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String _selectedRole = 'Member';

  final List<String> _roles = ['Admin', 'Super Admin', 'Team Leader', 'Member'];

  // 🔒 Mock user database
  final Map<String, Map<String, String>> mockUsers = {
    'Srinivas': {'password': '1234', 'role': 'Admin'},
    'Azim': {'password': '1234', 'role': 'Super Admin'},
    'Venkat': {'password': '1234', 'role': 'Team Leader'},
    'Abubakar': {'password': '1234', 'role': 'Member'},
    'Ayaan': {'password': '1234', 'role': 'Member'},
  };

  void _login() {
    String username = _usernameController.text.trim();
    String password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter both username and password')),
      );
      return;
    }

    if (!mockUsers.containsKey(username)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User does not exist!')),
      );
      return;
    }

    if (mockUsers[username]!['password'] != password) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Incorrect password!')),
      );
      return;
    }

    if (mockUsers[username]!['role'] != _selectedRole) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$username is not a $_selectedRole!')),
      );
      return;
    }

    // ✅ Successful Login
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DashboardPage(
          username: username,
          role: _selectedRole,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(labelText: 'Username'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password'),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: _selectedRole,
              decoration: const InputDecoration(labelText: 'Select Role'),
              items: _roles.map((String role) {
                return DropdownMenuItem(value: role, child: Text(role));
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedRole = value!;
                });
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _login,
              child: const Text('Login'),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SignupPage()),
                );
              },
              child: const Text('Don\'t have an account? Sign up'),
            )
          ],
        ),
      ),
    );
  }
}
