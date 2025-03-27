import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cultureconnect/pages/community/chat_community.dart';
import 'package:cultureconnect/pages/community/create_community.dart';
import 'package:cultureconnect/pages/community/joined_community.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

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
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Communities",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: screenWidth * 0.07,
          ),
        ),
        backgroundColor: Color(0xFFFC7C79),
        actions: [
          IconButton(
            icon:
                Icon(Icons.add, size: screenWidth * 0.07, color: Colors.black),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CreateCommunity()),
              );
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFC7C79), Color(0xFFEDC0F9)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: StreamBuilder<QuerySnapshot>(
          stream: _firestore.collection('communities').snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Center(child: CircularProgressIndicator());
            }

            var communities = snapshot.data!.docs;

            return ListView.builder(
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.04,
                vertical: screenHeight * 0.02,
              ),
              itemCount: communities.length,
              itemBuilder: (context, index) {
                var community = communities[index];
                var data = community.data() as Map<String, dynamic>;
                bool isMember =
                    (data['members'] as List).contains(currentUserId);
                String imageUrl = data['imageUrl'] ?? "";
                bool isPrivate = data['type'] == "private";

                return Card(
                  margin: EdgeInsets.symmetric(vertical: screenHeight * 0.01),
                  elevation: 4,
                  color: Colors.white.withOpacity(0.85),
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
                      padding: EdgeInsets.all(screenWidth * 0.04),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            backgroundImage: imageUrl.isNotEmpty
                                ? NetworkImage(imageUrl)
                                : AssetImage(
                                        'assets/images/default_community.png')
                                    as ImageProvider,
                            radius: screenWidth * 0.08,
                          ),
                          SizedBox(width: screenWidth * 0.04),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        data['name'],
                                        style: TextStyle(
                                          fontSize: screenWidth * 0.045,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (isPrivate)
                                      if (!isMember)
                                        Icon(Icons.lock,
                                            color: Colors.red,
                                            size: screenWidth * 0.04)
                                      else
                                        Icon(Icons.lock_open,
                                            color: Colors.green,
                                            size: screenWidth * 0.04)
                                  ],
                                ),
                                SizedBox(height: screenHeight * 0.005),
                                Text(
                                  data['description'],
                                  style: TextStyle(
                                    fontSize: screenWidth * 0.035,
                                    color: Colors.grey[600],
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 2,
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: screenWidth * 0.02),
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
                              backgroundColor: isMember
                                  ? Color(0xFFFF8A87)
                                  : const Color.fromARGB(255, 155, 215, 86),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              padding: EdgeInsets.symmetric(
                                horizontal: screenWidth * 0.05,
                                vertical: screenHeight * 0.015,
                              ),
                            ),
                            child: Text(
                              isMember ? "Open" : "Join",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: screenWidth * 0.04,
                              ),
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
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue,
        child: Icon(Icons.group, color: Colors.white, size: screenWidth * 0.07),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => JoinedCommunityScreen()),
          );
        },
      ),
    );
  }
}
