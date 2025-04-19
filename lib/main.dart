import 'package:flutter/material.dart';
import '../screens/signup_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Task Management App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.deepPurple,
      ),
      home: const SignupPage(), // 👈 Start with Signup Page
    );
  }
}
//-----------------------------------------------------------
//Test
// import 'package:flutter/material.dart';
// import '../utils/test_api.dart';
//
// void main() => runApp(MaterialApp(home: TestApiPage()));

