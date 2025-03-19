import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'user_profile.dart';

class CommunityInfoScreen extends StatefulWidget {
  final String communityId;
  final String currentUserId; // Pass the logged-in user ID

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
      var communityDoc = await _firestore.collection('communities').doc(widget.communityId).get();

      if (communityDoc.exists) {
        var data = communityDoc.data() as Map<String, dynamic>;

        setState(() {
          communityName = data['name'] ?? 'Community';
          communityDescription = data['description'] ?? 'No description available';
          members = List<String>.from(data['members'] ?? []);
          adminId = data['admin'] ?? '';

          // ✅ Fix: Correctly check if user is the admin
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
    if (memberId == adminId) return; // Admin can't remove themselves

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
    Navigator.pop(context); // Go back after deleting
    print("✅ Community deleted: $communityName");
  }

  Future<void> leaveCommunity() async {
    if (isAdmin) return; // Admin should not leave the community

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
        title: Text("Community Info"),
        actions: isAdmin
            ? [
                IconButton(
                  icon: Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text("Delete Community"),
                        content: Text("Are you sure you want to delete this community?"),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context), child: Text("Cancel")),
                          TextButton(
                            onPressed: () {
                              deleteCommunity();
                              Navigator.pop(context);
                            },
                            child: Text("Delete", style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ]
            : [],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(communityName, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Text(communityDescription, style: TextStyle(fontSize: 16)),
            SizedBox(height: 20),
            Text("Members:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Expanded(
              child: members.isEmpty
                  ? Center(child: Text("No members in this community"))
                  : ListView.builder(
                      itemCount: members.length,
                      itemBuilder: (context, index) {
                        String memberId = members[index];

                        return FutureBuilder<String>(
                          future: getUserName(memberId),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return ListTile(title: Text("Loading..."));
                            }
                            if (snapshot.hasError || snapshot.data == "Error loading user") {
                              return ListTile(title: Text("Error loading user ($memberId)"));
                            }

                            String userName = snapshot.data ?? 'Unknown User';

                            return ListTile(
                              title: Text(userName),
                              subtitle: memberId == adminId ? Text("Admin", style: TextStyle(color: Colors.red)) : null,
                              trailing: isAdmin && memberId != adminId
                                  ? IconButton(
                                      icon: Icon(Icons.remove_circle, color: Colors.red),
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: Text("Remove Member"),
                                            content: Text("Are you sure you want to remove $userName?"),
                                            actions: [
                                              TextButton(onPressed: () => Navigator.pop(context), child: Text("Cancel")),
                                              TextButton(
                                                onPressed: () {
                                                  removeMember(memberId);
                                                  Navigator.pop(context);
                                                },
                                                child: Text("Remove", style: TextStyle(color: Colors.red)),
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
                                    builder: (context) => UserProfileScreen(userId: memberId),
                                  ),
                                );
                              },
                            );
                          },
                        );
                      },
                    ),
            ),
            if (isMember && !isAdmin) // ✅ Fix: Admin should not see the "Leave Community" button
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text("Leave Community"),
                        content: Text("Are you sure you want to leave this community?"),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context), child: Text("Cancel")),
                          TextButton(
                            onPressed: () {
                              leaveCommunity();
                              Navigator.pop(context);
                            },
                            child: Text("Leave", style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: Text("Leave Community"),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
