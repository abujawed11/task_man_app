import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'dart:async';



class ApiService {
  static const String baseUrl = 'http://10.20.1.54:5000'; // Updated to your teammate's IP and port


  static Future<String> signupUser(String username, String email, String phone, String password, String role, String fcmToken) async {
    final url = Uri.parse('$baseUrl/signup');

    // 🔍 Debug Print – Shows in your debug console
    print('Sending POST to: $url');
    print('Body: ${jsonEncode({
      'username': username,
      'email': email,
      'phone': phone,
      'password': password,
      'role': role,
      'fcm_token': fcmToken,
    })}');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'email': email,
          'phone': phone,
          'password': password,
          'role': role,
          'fcm_token': fcmToken,
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



  // static Future<Map<String, dynamic>> loginUser(String username, String password, String fcmToken) async {
  //   final url = Uri.parse('$baseUrl/login');
  //
  //   try {
  //     final response = await http.post(
  //       url,
  //       headers: {'Content-Type': 'application/json'},
  //       body: jsonEncode({
  //         'username': username,
  //         'password': password,
  //         'fcm_token': fcmToken,
  //       }),
  //     );
  //
  //     if (response.statusCode == 200) {
  //       final data = jsonDecode(response.body);
  //       return {
  //         'status': 'success',
  //         'username': data['username'],
  //         'role': data['role'],
  //       };
  //     } else if (response.statusCode == 401) {
  //       return {'status': 'error', 'message': 'Incorrect password'};
  //     } else if (response.statusCode == 404) {
  //       return {'status': 'error', 'message': 'User does not exist'};
  //     } else {
  //       return {'status': 'error', 'message': 'Login failed: ${response.body}'};
  //     }
  //   } catch (e) {
  //     return {'status': 'error', 'message': 'Error: $e'};
  //   }
  // }

  static Future<Map<String, dynamic>> loginUser(String username, String password, String fcmToken) async {
    final url = Uri.parse('$baseUrl/login');

    try {
      print('Attempting login to: $url'); // Debug print

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'password': password,
          'fcm_token': fcmToken,
        }),
      ).timeout(const Duration(seconds: 10));

      print('Response status: ${response.statusCode}'); // Debug
      print('Response body: ${response.body}'); // Debug

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'status': 'success',
          'user_id': data['user_id'], // Added user_id
          'username': data['username'],
          'role': data['role'],
        };
      } else {
        return {
          'status': 'error',
          'message': data['message'] ?? 'Login failed'
        };
      }
    } on SocketException catch (e) {
      return {'status': 'error', 'message': 'Network error: ${e.message}'};
    }
    on TimeoutException {
      return {'status': 'error', 'message': 'Connection timeout'};
    } catch (e) {
      return {'status': 'error', 'message': 'Unexpected error: ${e.toString()}'};
    }
  }


}
