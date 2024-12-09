import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class StudentRegisterPage extends StatefulWidget {
  const StudentRegisterPage({super.key});

  @override
  _StudentRegisterPageState createState() => _StudentRegisterPageState();
}

class _StudentRegisterPageState extends State<StudentRegisterPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  bool isLoading = false;
  bool _isPasswordVisible = false;

  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  Future<void> registerStudent() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Create user with Firebase Auth
      UserCredential userCredential = await auth.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      // Update user profile with username
      await userCredential.user
          ?.updateProfile(displayName: usernameController.text.trim());
      await userCredential.user?.reload();

      // Save user details to Firestore
      await firestore.collection('users').doc(userCredential.user!.uid).set({
        'username': usernameController.text.trim(),
        'email': emailController.text.trim(),
        'userType': 'student',
      });

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Student registered successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      // Clear input fields
      emailController.clear();
      passwordController.clear();
      usernameController.clear();
    } catch (e) {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
      print("Error: $e");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
    print("Current user's display name: ${auth.currentUser?.displayName}");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Student Registration"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: usernameController,
              decoration: const InputDecoration(
                labelText: "Username", // Placeholder text
                floatingLabelBehavior:
                    FloatingLabelBehavior.never, // Keeps label inside
                border: OutlineInputBorder(), // Adds border
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: "Email", // Placeholder text
                floatingLabelBehavior:
                    FloatingLabelBehavior.never, // Keeps label inside
                border: OutlineInputBorder(), // Adds border
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: passwordController,
              decoration: InputDecoration(
                suffixIcon: IconButton(
                  icon: Icon(
                    _isPasswordVisible
                        ? Icons.visibility
                        : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _isPasswordVisible = !_isPasswordVisible;
                    });
                  },
                ),
                labelText: "Password", // Placeholder text
                floatingLabelBehavior:
                    FloatingLabelBehavior.never, // Keeps label inside
                border: const OutlineInputBorder(), // Adds border
              ),
              obscureText: true, // Hides the text for password
            ),
            const SizedBox(height: 20),
            isLoading
                ? const Center(child: CircularProgressIndicator())
                : SizedBox(
                    width: double.infinity, // Make the button full-width
                    child: ElevatedButton(
                      onPressed: registerStudent,
                      child: const Text("Register"),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
