import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class UserProfileScreen extends StatelessWidget {
  final String userId;
  const UserProfileScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("User Profile", style: TextStyle(color: Colors.white)),
        backgroundColor: Color(0xFFFC7C79),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future:
            FirebaseFirestore.instance.collection('users').doc(userId).get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(
              child: CircularProgressIndicator(),
            );
          }

          var userData = snapshot.data!.data() as Map<String, dynamic>?;

          if (userData == null) {
            return Center(
              child: Text("User not found",
                  style: TextStyle(fontSize: 18, color: Colors.red)),
            );
          }

          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFFC7C79), Color(0xFFEDC0F9)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Card(
                    elevation: 5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundImage: userData['profileImage'] != ""
                                ? NetworkImage(userData['profileImage'])
                                : AssetImage(
                                        'assets/images/default_profile.jpg')
                                    as ImageProvider,
                          ),
                          SizedBox(height: 10),
                          Text(
                            userData['name'] ?? "No Name",
                            style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFFC7C79)),
                          ),
                          SizedBox(height: 5),
                          Text(
                            userData['email'] ?? "No Email",
                            style: TextStyle(
                                fontSize: 16, color: Colors.grey[700]),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  Card(
                    elevation: 5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ListTile(
                            leading: Icon(Icons.location_on,
                                color: Color(0xFFFC7C79)),
                            title: Text("Location"),
                            subtitle: Text(userData['location'] ?? "Unknown",
                                style: TextStyle(fontSize: 16)),
                          ),
                          Divider(),
                          ListTile(
                            leading: Icon(Icons.info, color: Color(0xFFFC7C79)),
                            title: Text("Status"),
                            subtitle: Text(userData['status'] ?? "No Status",
                                style: TextStyle(fontSize: 16)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
