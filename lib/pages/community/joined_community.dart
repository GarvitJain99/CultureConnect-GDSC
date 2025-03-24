import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'chat_community.dart';

class JoinedCommunityScreen extends StatefulWidget {
  @override
  _JoinedCommunityScreenState createState() => _JoinedCommunityScreenState();
}

class _JoinedCommunityScreenState extends State<JoinedCommunityScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late String currentUserId;

  @override
  void initState() {
    super.initState();
    currentUserId = _auth.currentUser!.uid;
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Joined Communities",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: screenWidth * 0.05,
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('communities')
            .where('members', arrayContains: currentUserId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

          var joinedCommunities = snapshot.data!.docs;
          if (joinedCommunities.isEmpty) {
            return Center(
              child: Text(
                "You haven't joined any communities yet.",
                style: TextStyle(fontSize: screenWidth * 0.045, color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.symmetric(
              horizontal: screenWidth * 0.04,
              vertical: screenHeight * 0.02,
            ),
            itemCount: joinedCommunities.length,
            itemBuilder: (context, index) {
              var community = joinedCommunities[index];
              var data = community.data() as Map<String, dynamic>;
              String imageUrl = data['imageUrl'] ?? "";

              return Card(
                margin: EdgeInsets.symmetric(vertical: screenHeight * 0.01),
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: EdgeInsets.all(screenWidth * 0.04),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        backgroundImage: imageUrl.isNotEmpty
                            ? NetworkImage(imageUrl)
                            : AssetImage('assets/default_community.png')
                                as ImageProvider,
                        radius: screenWidth * 0.08,
                      ),
                      SizedBox(width: screenWidth * 0.04),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              data['name'],
                              style: TextStyle(
                                fontSize: screenWidth * 0.045,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
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
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CommunityChatScreen(communityId: community.id),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: EdgeInsets.symmetric(
                            horizontal: screenWidth * 0.05,
                            vertical: screenHeight * 0.015,
                          ),
                        ),
                        child: Text(
                          "Open",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: screenWidth * 0.04,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pop(context),
        backgroundColor: Colors.blue,
        label: Text(
          "Explore",
          style: TextStyle(fontSize: screenWidth * 0.04, fontWeight: FontWeight.bold),
        ),
        icon: Icon(Icons.explore, size: screenWidth * 0.07),
      ),
    );
  }
}
