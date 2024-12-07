import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;

class StudentDashboard extends StatelessWidget {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseAuth auth = FirebaseAuth.instance;

  StudentDashboard({super.key});

  void _logout(BuildContext context) async {
    await auth.signOut();
    Navigator.pushReplacementNamed(context, '/login');
  }

Future<String> _getUsername() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    return 'Unknown User';
  }

  final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
  if (userDoc.exists) {
    return userDoc['username'] ?? 'Unknown User';
  } else {
    print("User document not found.");
    return 'Unknown User';
  }
}

  Future<void> uploadCV(String jobId, BuildContext context) async {
    try {
      // Open image picker for the user to select an image
      final image = await ImagePicker().pickImage(source: ImageSource.gallery);

      if (image != null) {
        // Cloudinary URL for image upload
        final cloudinaryUrl =
            Uri.parse('https://api.cloudinary.com/v1_1/dzkqsyeeh/image/upload');

        // Create a multipart request
        final request = http.MultipartRequest('POST', cloudinaryUrl)
          ..fields['upload_preset'] = 'quick_hire_preset'
          ..fields['folder'] = 'job_images/student_cvs'
          ..files.add(await http.MultipartFile.fromPath('file', image.path));

        // Send the request
        final response = await request.send();

        if (response.statusCode == 200) {
          final responseBody = await response.stream.bytesToString();
          final jsonResponse = jsonDecode(responseBody);
          final fileUrl =
              jsonResponse['secure_url']; // File URL from Cloudinary

          // Get the current username from the users collection
          String username = await _getUsername();
          print("User: ${auth.currentUser}");
          print("Username: $username");
          print("Saving CV with username: $username");

          // Save the file URL, username, and related data in Firestore
          await firestore.collection('job_applications').add({
            'jobId': jobId,
            'username': username,
            'cvUrl': fileUrl,
            'uploadedAt': FieldValue.serverTimestamp()
          });

          print("CV uploaded successfully: $fileUrl");

          // Show a success message and navigate back to the dashboard
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('CV uploaded successfully!'),
              backgroundColor: Colors.green,
            ),
          );

          // Navigate back to the previous screen (StudentDashboard)
          Navigator.pop(context);
        } else {
          final responseBody = await response.stream.bytesToString();
          print(
              "Cloudinary upload failed: ${response.statusCode}, $responseBody");
          throw Exception("Failed to upload CV to Cloudinary.");
        }
      } else {
        print("No image selected for upload.");
      }
    } catch (e) {
      print("Error during CV upload: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = auth.currentUser;
    final profileImage = user?.photoURL ??
        "https://media.istockphoto.com/id/1437816897/photo/business-woman-manager-or-human-resources-portrait-for-career-success-company-we-are-hiring.jpg?s=1024x1024&w=is&k=20&c=iGtRKCTRSvPVl3eOIpzzse5SvQFfImkV0TZuFh-74ps=";

    return Scaffold(
      appBar: AppBar(
        title: const Text("Student Dashboard"),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () => _logout(context),
            icon: SizedBox(
              width: 30,
              height: 30,
              child: Image.asset('assets/logout.png'),
            ),
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
                FutureBuilder<String>(
                  future: _getUsername(), // Call to fetch the username
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Text(
                        "Loading...",
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    }
                    if (snapshot.hasError) {
                      return const Text(
                        "Error fetching username",
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    }
                    if (snapshot.hasData) {
                      return Column(
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
                            snapshot.data!,
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      );
                    } else {
                      return const Text(
                        "Silva !",
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    }
                  },
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
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              jobData['description'],
                              maxLines: 4,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.grey),
                            ),
                            Text(
                              'Upload Your CV ${jobData['username'] ?? "Silva !"}',
                              style:
                                  TextStyle(color: Colors.black, fontSize: 14),
                            ),
                          ],
                        ),
                        onTap: () {
                          showDialog(
                            barrierDismissible: false,
                            context: context,
                            builder: (context) {
                              return AlertDialog(
                                title: Text(jobData['title']),
                                content: SingleChildScrollView(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // Ensure the image has constraints
                                      if (jobData['imageUrl'] != null &&
                                          jobData['imageUrl'].isNotEmpty)
                                        Container(
                                          width: double
                                              .infinity, // Make the image stretch within available width
                                          constraints: const BoxConstraints(
                                            maxHeight: 500,
                                            maxWidth: double.infinity,
                                          ),
                                          height:
                                              250, // Fixed height for the image
                                          decoration: BoxDecoration(
                                            image: DecorationImage(
                                              image: NetworkImage(
                                                  jobData['imageUrl']),
                                              fit: BoxFit.cover,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                        )
                                      else
                                        Container(
                                          width: double.infinity,
                                          height: 150,
                                          color: Colors.grey.shade200,
                                          child: const Icon(
                                            Icons.work,
                                            size: 40,
                                            color: Colors.blueAccent,
                                          ),
                                        ),
                                      const SizedBox(height: 10),
                                      // Display job description
                                      Text(
                                        jobData['description'],
                                        style: const TextStyle(fontSize: 16),
                                      ),
                                      const SizedBox(height: 10),
                                      // Button to upload CV
                                      ElevatedButton(
                                        onPressed: () {
                                          uploadCV(jobId, context);
                                        },
                                        child: const Text('Upload CV'),
                                      ),
                                    ],
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    child: const Text('Close'),
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
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
