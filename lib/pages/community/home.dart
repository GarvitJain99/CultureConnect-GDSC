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

  Future<void> joinCommunity(String communityId, String communityType) async {
    DocumentSnapshot communitySnapshot =
        await _firestore.collection('communities').doc(communityId).get();

    Map<String, dynamic> communityData =
        communitySnapshot.data() as Map<String, dynamic>;
    String? storedPassword = communityData['password'];

    if (communityType == "private") {
      String? enteredPassword = await _showPasswordDialog();
      if (enteredPassword == null) return;

      if (enteredPassword.trim() != storedPassword?.trim()) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Incorrect password! Try again.")),
        );
        return;
      }
    }

    await _firestore.collection('communities').doc(communityId).update({
      'members': FieldValue.arrayUnion([currentUserId])
    });

    setState(() {});
  }

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
              onPressed: () => Navigator.pop(context, null),
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, password),
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
        title:
            Text("Communities", style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: Icon(Icons.add, color: const Color.fromARGB(255, 26, 18, 18)),
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
          if (!snapshot.hasData)
            return Center(child: CircularProgressIndicator());

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
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: InkWell(
                  onTap: () {
                    if (isMember) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              CommunityChatScreen(communityId: community.id),
                        ),
                      );
                    }
                  },
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Row(
                      children: [
                        // Community Image
                        CircleAvatar(
                          backgroundImage: imageUrl.isNotEmpty
                              ? NetworkImage(imageUrl)
                              : AssetImage('assets/default_community.png')
                                  as ImageProvider,
                          radius: 30,
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Community Name and Lock Icon
                              Row(
                                children: [
                                  Text(
                                    data['name'],
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  if (isPrivate)
                                    Icon(Icons.lock,
                                        color: Colors.red, size: 16),
                                ],
                              ),
                              SizedBox(height: 4),
                              // Community Description
                              Text(
                                data['description'],
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Join/Open Button
                        ElevatedButton(
                          onPressed: () async {
                            if (isMember) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => CommunityChatScreen(
                                      communityId: community.id),
                                ),
                              );
                            } else {
                              await joinCommunity(community.id, data['type']);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                isMember ? Colors.blue : Colors.green,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: Text(
                            isMember ? "Open" : "Join",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
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
