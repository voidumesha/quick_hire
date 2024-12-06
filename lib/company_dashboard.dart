import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

class CompanyDashboard extends StatelessWidget {
  final FirebaseAuth auth = FirebaseAuth.instance;
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseStorage storage = FirebaseStorage.instance;

  CompanyDashboard({super.key});

  // Function to handle logout
  void _logout(BuildContext context) async {
    await auth.signOut();
    Navigator.pushReplacementNamed(
        context, '/login'); // Replace '/login' with your login route
  }

  Future<void> postJob() async {
    try {
      final image = await ImagePicker().pickImage(source: ImageSource.gallery);
      String imageUrl = '';

      if (image != null) {
        final cloudinaryUrl =
            Uri.parse('https://api.cloudinary.com/v1_1/dzkqsyeeh/image/upload');

        final request = http.MultipartRequest('POST', cloudinaryUrl)
          ..fields['upload_preset'] =
              'quick_hire_preset' // Set up an unsigned preset in Cloudinary
          ..files.add(await http.MultipartFile.fromPath('file', image.path));

        final response = await request.send();
        if (response.statusCode == 200) {
          final responseBody = await response.stream.bytesToString();
          final jsonResponse = jsonDecode(responseBody);
          imageUrl = jsonResponse['secure_url'];
        } else {
          throw Exception("Failed to upload image to Cloudinary");
        }
      }

      await firestore.collection('jobs').add({
        'title': titleController.text.trim(),
        'description': descriptionController.text.trim(),
        'imageUrl': imageUrl,
        'createdAt': FieldValue.serverTimestamp(),
      });

      print("Job posted successfully!");
    } catch (e) {
      print("Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Post a Job"),
        centerTitle: true,
        actions: [
          // Logout Button
          IconButton(
            onPressed: () => _logout(context),
            icon: const Icon(Icons.logout),
            tooltip: "Logout",
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Job Title Input
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: "Job Title",
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
            const SizedBox(height: 16),

            // Job Description Input
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: "Job Description",
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              maxLines: 5,
            ),
            const SizedBox(height: 20),

            // Post Job Button
            ElevatedButton(
              onPressed: postJob,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent, // Button color
                padding:
                    const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                textStyle:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              child: const Text("Post Job"),
            ),
          ],
        ),
      ),
    );
  }
}
