import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:quickhire/login.dart';
import 'package:quickhire/register.dart';
import 'package:quickhire/student_dashboard.dart';
import 'package:quickhire/company_dashboard.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
      // Check the user's authentication state and navigate accordingly
      home: const AuthWrapper(),
      routes: {
        '/register': (context) => const RegisterPage(), // Register Page
        '/student_dashboard': (context) =>
            StudentDashboard(), // Student Dashboard
        '/company_dashboard': (context) =>
            CompanyDashboard(), // Company Dashboard
        '/login': (context) => const LoginPage(), // Login Page
      },
    );
  }
}

// AuthWrapper to determine initial route based on user authentication state
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    // Always navigate to the login screen on app reload
    if (user == null) {
      return const LoginPage();
    }

    // Navigate to the appropriate screen based on the user type
    return FutureBuilder<DocumentSnapshot>(
      future:
          FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
          return const LoginPage(); // Fallback to Login Page
        }
        final userType = snapshot.data!.get('userType');
        if (userType == 'student') {
          return StudentDashboard();
        } else if (userType == 'company') {
          return CompanyDashboard();
        } else {
          return const LoginPage(); // Unknown user type fallback
        }
      },
    );
  }
}
