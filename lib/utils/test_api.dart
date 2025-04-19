import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class TestApiPage extends StatefulWidget {
  @override
  _TestApiPageState createState() => _TestApiPageState();
}

class _TestApiPageState extends State<TestApiPage> {
  String apiResult = "Press the button to call API";

  Future<void> callApi() async {
    final url = Uri.parse('https://jsonplaceholder.typicode.com/todos/1');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          apiResult = data.toString();
        });
      } else {
        setState(() {
          apiResult = "Error: ${response.statusCode}";
        });
      }
    } catch (e) {
      setState(() {
        apiResult = "Exception: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Test API Call')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Text(apiResult),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: callApi,
              child: Text('Call API'),
            ),
          ],
        ),
      ),
    );
  }
}
