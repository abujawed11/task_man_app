import 'package:http/http.dart' as http;
import 'dart:convert';

class ApiService {
  static const String baseUrl = 'http://192.168.1.5:3000'; // teammate's IP

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
}
