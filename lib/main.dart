import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:quickhire/login.dart';
import 'package:quickhire/register.dart';
import 'package:quickhire/student_dashboard.dart';
import 'package:quickhire/company_dashboard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'QuickHire',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const LoginPage(), // Login Page
        '/register': (context) => RegisterPage(), // Register Page
        '/student_dashboard': (context) =>
            student_dashboard(), // Student Dashboard
        '/company_dashboard': (context) =>
            company_dashboard(), // Company Dashboard
      },
    );
  }
}
