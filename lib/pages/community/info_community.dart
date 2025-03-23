import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'user_profile.dart';

class CommunityInfoScreen extends StatefulWidget {
  final String communityId;
  final String currentUserId;

  CommunityInfoScreen({required this.communityId, required this.currentUserId});

  @override
  _CommunityInfoScreenState createState() => _CommunityInfoScreenState();
}

class _CommunityInfoScreenState extends State<CommunityInfoScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String communityName = "";
  String communityDescription = "";
  List<String> members = [];
  String adminId = "";
  bool isAdmin = false;

  @override
  void initState() {
    super.initState();
    fetchCommunityDetails();
  }

  Future<void> fetchCommunityDetails() async {
    try {
      var communityDoc = await _firestore
          .collection('communities')
          .doc(widget.communityId)
          .get();

      if (communityDoc.exists) {
        var data = communityDoc.data() as Map<String, dynamic>;

        setState(() {
          communityName = data['name'] ?? 'Community';
          communityDescription =
              data['description'] ?? 'No description available';
          members = List<String>.from(data['members'] ?? []);
          adminId = data['admin'] ?? '';
          isAdmin = widget.currentUserId == adminId;
        });

        print("✅ Community loaded: $communityName | Admin: $adminId");
      } else {
        print("❌ Community document does not exist.");
      }
    } catch (e) {
      print("❌ Error fetching community details: $e");
    }
  }

  Future<String> getUserName(String userId) async {
    try {
      var userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists && userDoc.data() != null) {
        return userDoc.data()!['name'] ?? 'Unknown User';
      }
      return "Unknown User";
    } catch (e) {
      return "Error loading user";
    }
  }

  Future<void> removeMember(String memberId) async {
    if (memberId == adminId) return;

    setState(() {
      members.remove(memberId);
    });

    await _firestore.collection('communities').doc(widget.communityId).update({
      'members': members,
    });

    print("✅ Member removed: $memberId");
  }

  Future<void> deleteCommunity() async {
    await _firestore.collection('communities').doc(widget.communityId).delete();
    Navigator.pop(context);
    print("✅ Community deleted: $communityName");
  }

  Future<void> leaveCommunity() async {
    if (isAdmin) return;

    setState(() {
      members.remove(widget.currentUserId);
    });

    await _firestore.collection('communities').doc(widget.communityId).update({
      'members': members,
    });

    Navigator.pop(context);
    print("✅ User left community: ${widget.currentUserId}");
  }

  @override
  Widget build(BuildContext context) {
    bool isMember = members.contains(widget.currentUserId);

    return Scaffold(
      appBar: AppBar(
        title: Text("Community Info", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.deepPurple,
        iconTheme: IconThemeData(color: Colors.white),
        actions: isAdmin
            ? [
                IconButton(
                  icon: Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text("Delete Community"),
                        content: Text(
                            "Are you sure you want to delete this community?"),
                        actions: [
                          TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text("Cancel")),
                          TextButton(
                            onPressed: () {
                              deleteCommunity();
                              Navigator.pop(context);
                            },
                            child: Text("Delete",
                                style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ]
            : [],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.deepPurple.shade100, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                elevation: 5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        communityName,
                        style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple),
                      ),
                      SizedBox(height: 10),
                      Text(
                        communityDescription,
                        style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20),
              Text(
                "Members:",
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple),
              ),
              SizedBox(height: 10),
              Expanded(
                child: members.isEmpty
                    ? Center(
                        child: Text(
                          "No members in this community",
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        itemCount: members.length,
                        itemBuilder: (context, index) {
                          String memberId = members[index];

                          return FutureBuilder<String>(
                            future: getUserName(memberId),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return ListTile(
                                  leading: CircularProgressIndicator(),
                                  title: Text("Loading..."),
                                );
                              }
                              if (snapshot.hasError ||
                                  snapshot.data == "Error loading user") {
                                return ListTile(
                                  leading: Icon(Icons.error, color: Colors.red),
                                  title: Text("Error loading user ($memberId)"),
                                );
                              }

                              String userName = snapshot.data ?? 'Unknown User';

                              return Card(
                                elevation: 3,
                                margin: EdgeInsets.symmetric(vertical: 5),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: Colors.deepPurple,
                                    child: Text(
                                      userName[0].toUpperCase(),
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
                                  title: Text(userName),
                                  subtitle: memberId == adminId
                                      ? Text("Admin",
                                          style: TextStyle(color: Colors.red))
                                      : null,
                                  trailing: isAdmin && memberId != adminId
                                      ? IconButton(
                                          icon: Icon(Icons.remove_circle,
                                              color: Colors.red),
                                          onPressed: () {
                                            showDialog(
                                              context: context,
                                              builder: (context) => AlertDialog(
                                                title: Text("Remove Member"),
                                                content: Text(
                                                    "Are you sure you want to remove $userName?"),
                                                actions: [
                                                  TextButton(
                                                      onPressed: () =>
                                                          Navigator.pop(
                                                              context),
                                                      child: Text("Cancel")),
                                                  TextButton(
                                                    onPressed: () {
                                                      removeMember(memberId);
                                                      Navigator.pop(context);
                                                    },
                                                    child: Text("Remove",
                                                        style: TextStyle(
                                                            color: Colors.red)),
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
                                        )
                                      : null,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            UserProfileScreen(userId: memberId),
                                      ),
                                    );
                                  },
                                ),
                              );
                            },
                          );
                        },
                      ),
              ),
              if (isMember && !isAdmin)
                Center(
                  child: ElevatedButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text("Leave Community"),
                          content: Text(
                              "Are you sure you want to leave this community?"),
                          actions: [
                            TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: Text("Cancel")),
                            TextButton(
                              onPressed: () {
                                leaveCommunity();
                                Navigator.pop(context);
                              },
                              child: Text("Leave",
                                  style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding:
                          EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child:
                        Text("Leave Community", style: TextStyle(fontSize: 16)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
