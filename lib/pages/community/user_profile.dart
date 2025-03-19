import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class UserProfileScreen extends StatelessWidget {
  final String userId;
  const UserProfileScreen({required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("User Profile")),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

          var userData = snapshot.data!.data() as Map<String, dynamic>?;

          if (userData == null) return Center(child: Text("User not found"));

          return Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundImage: userData['profileImage'] != null
                      ? NetworkImage(userData['profileImage'])
                      : AssetImage('assets/default_profile.png') as ImageProvider,
                ),
                SizedBox(height: 10),
                Text(userData['name'] ?? "No Name", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                SizedBox(height: 5),
                Text(userData['email'] ?? "No Email", style: TextStyle(fontSize: 16, color: Colors.grey)),
                SizedBox(height: 10),
                Text("Location: ${userData['location'] ?? "Unknown"}"),
                SizedBox(height: 10),
                Text("Status: ${userData['status'] ?? "No Status"}"),
              ],
            ),
          );
        },
      ),
    );
  }
}
