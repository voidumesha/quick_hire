import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';

class CompanyDashboard extends StatelessWidget {
  final FirebaseAuth auth = FirebaseAuth.instance;
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  CompanyDashboard({super.key});

  void _logout(BuildContext context) async {
    await auth.signOut();
    Navigator.pushReplacementNamed(context, '/login');
  }

  Future<void> postJob() async {
    try {
      final image = await ImagePicker().pickImage(source: ImageSource.gallery);
      String imageUrl = '';

      if (image != null) {
        final cloudinaryUrl =
            Uri.parse('https://api.cloudinary.com/v1_1/dzkqsyeeh/image/upload');

        final request = http.MultipartRequest('POST', cloudinaryUrl)
          ..fields['upload_preset'] = 'quick_hire_preset'
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

  void viewCVs(BuildContext context, String jobId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Submitted CVs"),
          content: StreamBuilder<QuerySnapshot>(
            stream: firestore
                .collection('job_applications')
                .where('jobId', isEqualTo: jobId)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text("No CVs submitted yet."));
              }

              final applications = snapshot.data!.docs;

              return ListView.builder(
                shrinkWrap: true,
                itemCount: applications.length,
                itemBuilder: (context, index) {
                  final app =
                      applications[index].data() as Map<String, dynamic>;

                  return ListTile(
                    title: Text("Student ID: ${app['studentId']}"),
                    subtitle: app['cvUrl'] != null
                        ? InkWell(
                            onTap: () {
                              // Open the CV URL in a browser
                              launchUrl(Uri.parse(app['cvUrl']));
                            },
                            child: const Text(
                              "View CV",
                              style: TextStyle(
                                color: Colors.blue,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          )
                        : const Text("No CV uploaded"),
                  );
                },
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Close"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Company Dashboard"),
        titleTextStyle: const TextStyle(
            fontWeight: FontWeight.bold, fontSize: 20, color: Colors.black),
        centerTitle: true,
        actions: [
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
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: "Job Title",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: "Job Description",
                border: OutlineInputBorder(),
              ),
              maxLines: 5,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: postJob,
              child: const Text("Post Job"),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: firestore
                    .collection('jobs')
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text("No jobs posted yet."));
                  }

                  final jobs = snapshot.data!.docs;

                  return ListView.builder(
                    itemCount: jobs.length,
                    itemBuilder: (context, index) {
                      final job = jobs[index];
                      final jobData = job.data() as Map<String, dynamic>;
                      final jobId = job.id;

                      return Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        child: ListTile(
                          title: Text(jobData['title']),
                          subtitle: Text(jobData['description']),
                          trailing: IconButton(
                            icon: const Icon(Icons.folder_open),
                            onPressed: () => viewCVs(context, jobId),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
