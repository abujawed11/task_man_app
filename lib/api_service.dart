import 'package:http/http.dart' as http;
import 'dart:convert';

class ApiService {
  static const String baseUrl = 'http://172.20.10.3:5000'; // Updated to your teammate's IP and port

  static Future<String> signupUser(String username, String password, String role) async {
    final url = Uri.parse('$baseUrl/signup');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'password': password,
          'role': role,
        }),
      );

      if (response.statusCode == 200) {
        return 'Signup successful';
      } else if (response.statusCode == 409) {
        return 'User already exists';
      } else {
        return 'Signup failed: ${response.body}';
      }
    } catch (e) {
      return 'Error: $e';
    }
  }

  static Future<String> loginUser(String username, String password, String role) async {
    final url = Uri.parse('$baseUrl/login');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'password': password,
          'role': role,
        }),
      );

      if (response.statusCode == 200) {
        return 'Login successful';
      } else if (response.statusCode == 401) {
        return 'Incorrect password';
      } else if (response.statusCode == 404) {
        return 'User does not exist';
      } else {
        return 'Login failed: ${response.body}';
      }
    } catch (e) {
      return 'Error: $e';
    }
  }
}
