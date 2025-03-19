import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'chat_community.dart';
import 'create_community.dart';

class CommunityHomeScreen extends StatefulWidget {
  @override
  _CommunityHomeScreenState createState() => _CommunityHomeScreenState();
}

class _CommunityHomeScreenState extends State<CommunityHomeScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late String currentUserId;

  @override
  void initState() {
    super.initState();
    currentUserId = _auth.currentUser!.uid;
  }

  // 🔹 Function to Join Community (Handles Public & Private)
  Future<void> joinCommunity(String communityId, String communityType) async {
    DocumentSnapshot communitySnapshot =
        await _firestore.collection('communities').doc(communityId).get();

    Map<String, dynamic> communityData =
        communitySnapshot.data() as Map<String, dynamic>;
    String? storedPassword = communityData['password']; // Fetch from Firestore

    if (communityType == "private") {
      String? enteredPassword = await _showPasswordDialog();
      if (enteredPassword == null) return; // User canceled

      // 🔹 Fix: Trim spaces & compare properly
      if (enteredPassword.trim() != storedPassword?.trim()) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Incorrect password! Try again.")),
        );
        return;
      }
    }

    // 🔹 Add user to Firestore member list
    await _firestore.collection('communities').doc(communityId).update({
      'members': FieldValue.arrayUnion([currentUserId])
    });

    setState(() {}); // Refresh UI after joining
  }

  // 🔹 Password Prompt Dialog for Private Communities
  Future<String?> _showPasswordDialog() async {
    String password = "";
    return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Enter Password"),
          content: TextField(
            onChanged: (value) {
              password = value;
            },
            obscureText: true,
            decoration: InputDecoration(labelText: "Password"),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, null), // Cancel
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, password), // Submit
              child: Text("Join"),
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
        title: Text("Communities"),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CreateCommunity()),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('communities').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

          var communities = snapshot.data!.docs;

          return ListView.builder(
            itemCount: communities.length,
            itemBuilder: (context, index) {
              var community = communities[index];
              var data = community.data() as Map<String, dynamic>;
              bool isMember = (data['members'] as List).contains(currentUserId);
              String imageUrl = data['imageUrl'] ?? "";
              bool isPrivate = data['type'] == "private";

              return Card(
                margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: ListTile(
                  leading: imageUrl.isNotEmpty
                      ? CircleAvatar(
                          backgroundImage: NetworkImage(imageUrl),
                          radius: 25,
                        )
                      : CircleAvatar(
                          child: Icon(Icons.group, size: 30),
                          radius: 25,
                        ),
                  title: Text(data['name']),
                  subtitle: Text(data['description']),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isPrivate) Icon(Icons.lock, color: Colors.red), // 🔒 Lock icon
                      SizedBox(width: 5),
                      ElevatedButton(
                        onPressed: () async {
                          if (isMember) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CommunityChatScreen(communityId: community.id),
                              ),
                            );
                          } else {
                            await joinCommunity(community.id, data['type']);
                          }
                        },
                        child: Text(isMember ? "Open" : "Join"),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
     ),
    );
  }
}
