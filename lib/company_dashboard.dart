import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class PostJobPage extends StatelessWidget {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseStorage storage = FirebaseStorage.instance;

  Future<void> postJob() async {
    try {
      final image = await ImagePicker().pickImage(source: ImageSource.gallery);
      String imageUrl = '';

      if (image != null) {
        final ref = storage.ref().child('jobs/${image.name}');
        await ref.putFile(File(image.path));
        imageUrl = await ref.getDownloadURL();
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
      appBar: AppBar(title: Text("Post a Job")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: titleController,
              decoration: InputDecoration(labelText: "Job Title"),
            ),
            TextField(
              controller: descriptionController,
              decoration: InputDecoration(labelText: "Job Description"),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: postJob,
              child: Text("Post Job"),
            ),
          ],
        ),
      ),
    );
  }
}
