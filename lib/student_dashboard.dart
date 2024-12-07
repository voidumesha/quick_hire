import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class StudentDashboard extends StatelessWidget {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseAuth auth = FirebaseAuth.instance;

  StudentDashboard({super.key});

  void _logout(BuildContext context) async {
    await auth.signOut();
    Navigator.pushReplacementNamed(context, '/login');
  }

  Future<void> uploadCV(String jobId) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'], // Only allow PDFs
      );

      if (result != null) {
        final file = result.files.single;
        final fileName = file.name;
        final fileBytes = file.bytes;

        if (fileBytes != null) {
          final cloudinaryUrl =
              Uri.parse('https://api.cloudinary.com/v1_1/dzkqsyeeh/upload');

          final request = http.MultipartRequest('POST', cloudinaryUrl)
            ..fields['upload_preset'] = 'quick_hire_preset'
            ..fields['folder'] = 'student_cvs'
            ..files.add(http.MultipartFile.fromBytes(
              'file',
              fileBytes,
              filename: fileName,
              contentType: MediaType('application', 'pdf'),
            ));

          final response = await request.send();
          if (response.statusCode == 200) {
            final responseBody = await response.stream.bytesToString();
            final jsonResponse = jsonDecode(responseBody);
            final fileUrl = jsonResponse['secure_url'];

            await firestore.collection('job_applications').add({
              'jobId': jobId,
              'studentId': auth.currentUser?.uid,
              'cvUrl': fileUrl,
              'uploadedAt': FieldValue.serverTimestamp(),
            });

            print("CV uploaded successfully!");
          } else {
            throw Exception("Failed to upload CV to Cloudinary.");
          }
        }
      }
    } catch (e) {
      print("Error uploading CV: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = auth.currentUser;
    final username = user?.displayName ?? "Student";
    final profileImage = user?.photoURL ??
        "https://media.istockphoto.com/id/1437816897/photo/business-woman-manager-or-human-resources-portrait-for-career-success-company-we-are-hiring.jpg?s=1024x1024&w=is&k=20&c=iGtRKCTRSvPVl3eOIpzzse5SvQFfImkV0TZuFh-74ps=";

    return Scaffold(
      appBar: AppBar(
        title: const Text("Student Dashboard"),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () => _logout(context),
            icon: const Icon(Icons.logout),
            tooltip: "Logout",
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: Colors.blue.shade50,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundImage: NetworkImage(profileImage),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Welcome,",
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      username,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
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
                  return const Center(child: Text("No jobs available."));
                }

                final jobs = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: jobs.length,
                  itemBuilder: (context, index) {
                    final job = jobs[index];
                    final jobId = job.id;
                    final jobData = job.data() as Map<String, dynamic>;

                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: ListTile(
                        leading: jobData['imageUrl'] != null &&
                                jobData['imageUrl'].isNotEmpty
                            ? Image.network(
                                jobData['imageUrl'],
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                              )
                            : const Icon(
                                Icons.work,
                                size: 40,
                                color: Colors.blueAccent,
                              ),
                        title: Text(
                          jobData['title'],
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          jobData['description'],
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.grey),
                        ),
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (context) {
                              return AlertDialog(
                                title: Text(jobData['title']),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (jobData['imageUrl'] != null &&
                                        jobData['imageUrl'].isNotEmpty)
                                      Image.network(
                                        jobData['imageUrl'],
                                        height: 350,
                                        fit: BoxFit.cover,
                                      ),
                                    const SizedBox(height: 10),
                                    Text(jobData['description']),
                                    const SizedBox(height: 50),
                                    ElevatedButton(
                                      onPressed: () async {
                                        await uploadCV(jobId);
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                                'CV uploaded successfully!'),
                                            backgroundColor: Colors.green,
                                          ),
                                        );
                                      },
                                      child: const Text("Submit CV"),
                                    ),
                                  ],
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
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
