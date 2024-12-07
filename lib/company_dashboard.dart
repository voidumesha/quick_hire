import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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

  Future<void> postJob(BuildContext context) async {
    try {
      // Validate the title
      if (titleController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Job title is required.")),
        );
        return;
      }

      // Prompt for image selection
      final image = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (image == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Image selection is required.")),
        );
        return;
      }

      // Upload the image to Cloudinary
      String imageUrl = '';
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

      // Post the job to Firestore
      await firestore.collection('jobs').add({
        'title': titleController.text.trim(),
        'description': descriptionController.text.trim(),
        'imageUrl': imageUrl,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Job posted successfully!")),
      );

      // Clear input fields after successful posting
      titleController.clear();
      descriptionController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  void viewCVs(BuildContext context, String jobId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Submitted CVs"),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.8,
            child: StreamBuilder<QuerySnapshot>(
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
                      leading: FutureBuilder<QuerySnapshot>(
                        future: firestore
                            .collection('users')
                            .where('username', isEqualTo: app['username'])
                            .limit(1)
                            .get(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const CircularProgressIndicator();
                          }
                          if (snapshot.hasError ||
                              !snapshot.hasData ||
                              snapshot.data!.docs.isEmpty) {
                            return const Icon(Icons.person);
                          }

                          final studentData = snapshot.data!.docs.first.data()
                              as Map<String, dynamic>;
                          return CircleAvatar(
                            child: Text(studentData['name'][0]),
                          );
                        },
                      ),
                      title: Text("Student Name: ${app['username']} "),
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
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(150),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF42A5F5), Color(0xFF1976D2)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    "Company Dashboard",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => _logout(context),
                  icon: const Icon(Icons.logout, color: Colors.white, size: 28),
                ),
              ],
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Post a New Job",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
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
                          onPressed: () => postJob(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(
                                vertical: 15, horizontal: 20),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.post_add, size: 20),
                              SizedBox(width: 8),
                              Text(
                                "Post Job",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  "Posted Jobs",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                StreamBuilder<QuerySnapshot>(
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
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: jobs.length,
                      itemBuilder: (context, index) {
                        final job = jobs[index];
                        final jobData = job.data() as Map<String, dynamic>;
                        final jobId = job.id;

                        return Card(
                          elevation: 3,
                          margin: const EdgeInsets.symmetric(
                            horizontal: 0,
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16),
                            leading: jobData['imageUrl'] != null &&
                                    jobData['imageUrl'].isNotEmpty
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Image.network(
                                      jobData['imageUrl'],
                                      width: 50,
                                      height: 50,
                                      fit: BoxFit.cover,
                                    ),
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
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.grey),
                            ),
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
