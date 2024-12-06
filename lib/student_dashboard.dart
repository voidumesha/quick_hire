import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StudentDashboard extends StatelessWidget {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseAuth auth = FirebaseAuth.instance;

  StudentDashboard({super.key});

  // Function to handle logout
  void _logout(BuildContext context) async {
    await auth.signOut();
    Navigator.pushReplacementNamed(
        context, '/login'); // Replace '/login' with your login route
  }

  @override
  Widget build(BuildContext context) {
    final user = auth.currentUser; // Current logged-in user
    final username =
        user?.displayName ?? "Student"; // Use Firebase display name or fallback
    final profileImage = user?.photoURL ??
        "https://media.istockphoto.com/id/1437816897/photo/business-woman-manager-or-human-resources-portrait-for-career-success-company-we-are-hiring.jpg?s=1024x1024&w=is&k=20&c=iGtRKCTRSvPVl3eOIpzzse5SvQFfImkV0TZuFh-74ps="; // Default profile image if no URL

    return Scaffold(
      appBar: AppBar(
        title: const Text("Job Listings"),
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
      body: Column(
        children: [
          // Profile Section
          Container(
            color: Colors.blue.shade50,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Row(
              children: [
                // Profile Image
                CircleAvatar(
                  radius: 30,
                  backgroundImage: NetworkImage(profileImage),
                ),
                const SizedBox(width: 16),
                // Username
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
          // Job Listings
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
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("No jobs available."));
                }
                final jobs = snapshot.data!.docs;
                return ListView.builder(
                  itemCount: jobs.length,
                  itemBuilder: (context, index) {
                    final job = jobs[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: ListTile(
                        leading: job['imageUrl'] != null
                            ? Image.network(
                                job['imageUrl'],
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
                          job['title'],
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          job['description'],
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.grey),
                        ),
                        trailing: Text(
                          job['createdAt'] != null
                              ? job['createdAt'].toDate().toString()
                              : "Unknown Date",
                          style: const TextStyle(fontSize: 12),
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
    );
  }
}
