import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class JobListingPage extends StatelessWidget {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Job Listings")),
      body: StreamBuilder<QuerySnapshot>(
        stream: firestore.collection('jobs').orderBy('createdAt', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData) {
            return Center(child: Text("No jobs available."));
          }
          final jobs = snapshot.data!.docs;
          return ListView.builder(
            itemCount: jobs.length,
            itemBuilder: (context, index) {
              final job = jobs[index];
              return Card(
                child: ListTile(
                  leading: job['imageUrl'] != null
                      ? Image.network(job['imageUrl'])
                      : Icon(Icons.work),
                  title: Text(job['title']),
                  subtitle: Text(job['description']),
                  trailing: Text(job['createdAt'].toDate().toString()),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
