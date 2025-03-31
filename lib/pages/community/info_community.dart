import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cultureconnect/pages/community/home.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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
  final FirebaseStorage _storage = FirebaseStorage.instance;
  String communityName = "";
  String communityDescription = "";
  List<String> members = [];
  String adminId = "";
  bool isAdmin = false;
  String communityImageUrl = "";

  TextEditingController _searchController = TextEditingController();
  List<String> _filteredMembers = [];
  TextEditingController _descriptionController = TextEditingController();
  bool _isEditingDescription = false;
  File? _newImageFile;

  @override
  void initState() {
    super.initState();
    fetchCommunityDetails();
    _searchController.addListener(_onSearchChanged);
    _descriptionController.text = communityDescription;
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _filteredMembers = members
          .where((memberId) =>
              communityMembersMap.containsKey(memberId) &&
              (communityMembersMap[memberId] ?? 'Unknown User')
                  .toLowerCase()
                  .contains(_searchController.text.toLowerCase()))
          .toList();
      print("Filtered Members: $_filteredMembers"); // Added log
    });
  }

  Map<String, String> communityMembersMap = {};

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
          communityImageUrl = data['imageUrl'] ?? '';
          _descriptionController.text = communityDescription;
          print("Fetched members: $members"); // Added log
        });

        for (String memberId in members) {
          await getUserName(memberId);
        }
        print("Community Members Map: $communityMembersMap"); // Added log
        _onSearchChanged(); // Call this after fetching and populating map
      } else {
        print("❌ Community document does not exist.");
      }
    } catch (e) {
      print("❌ Error fetching community details: $e");
    }
  }

  Future<String> getUserName(String userId) async {
    if (communityMembersMap.containsKey(userId)) {
      return communityMembersMap[userId]!;
    }
    try {
      var userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists && userDoc.data() != null) {
        communityMembersMap[userId] = userDoc.data()!['name'] ?? 'Unknown User';
        print(
            "Fetched user name for $userId: ${communityMembersMap[userId]}"); // Added log
        if (_searchController.text.isNotEmpty) {
          _onSearchChanged();
        }
        return communityMembersMap[userId]!;
      }
      communityMembersMap[userId] = "Unknown User";
      return "Unknown User";
    } catch (e) {
      communityMembersMap[userId] = "Error loading user";
      return "Error loading user";
    }
  }

  Future<void> removeMember(String memberId) async {
    if (memberId == adminId) return;

    setState(() {
      members.remove(memberId);
      _filteredMembers.remove(memberId);
      communityMembersMap.remove(memberId);
    });

    await _firestore.collection('communities').doc(widget.communityId).update({
      'members': members,
    });

    print("✅ Member removed: $memberId");
  }

  Future<void> deleteCommunity() async {
    await _firestore.collection('communities').doc(widget.communityId).delete();
    print("✅ Community deleted: $communityName");
    // Navigation will now happen from the AlertDialog
  }

  Future<void> leaveCommunity() async {
    if (isAdmin) return;

    setState(() {
      members.remove(widget.currentUserId);
      _filteredMembers.remove(widget.currentUserId);
      communityMembersMap.remove(widget.currentUserId);
    });

    await _firestore.collection('communities').doc(widget.communityId).update({
      'members': members,
    });

    print("✅ User left community: ${widget.currentUserId}");
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _newImageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _uploadImage() async {
    if (_newImageFile == null) return;

    try {
      final Reference storageRef = _storage
          .ref()
          .child('community_images/${widget.communityId}/${DateTime.now()}.png');
      final UploadTask uploadTask = storageRef.putFile(_newImageFile!);
      final TaskSnapshot snapshot = await uploadTask.whenComplete(() => {});
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      await _firestore.collection('communities').doc(widget.communityId).update({
        'imageUrl': downloadUrl,
      });

      setState(() {
        communityImageUrl = downloadUrl;
        _newImageFile = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Community image updated successfully!')),
      );
    } catch (e) {
      print("❌ Error uploading image: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update community image.')),
      );
    }
  }

  Future<void> _saveDescription() async {
    setState(() {
      communityDescription = _descriptionController.text;
      _isEditingDescription = false;
    });
    try {
      await _firestore.collection('communities').doc(widget.communityId).update({
        'description': communityDescription,
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Community description updated successfully!')),
      );
    } catch (e) {
      print("❌ Error updating description: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update community description.')),
      );
    }
  }

  Future<List<String>> _fetchCommunityImages() async {
    List<String> imageUrls = [];
    try {
      var messagesSnapshot = await _firestore
          .collection('communities')
          .doc(widget.communityId)
          .collection('messages')
          .where('type', isEqualTo: 'image')
          .orderBy('timestamp', descending: true)
          .get();

      for (var doc in messagesSnapshot.docs) {
        var data = doc.data();
        if (data.containsKey('text')) {
          imageUrls.add(data['text']);
        }
      }
    } catch (e) {
      print("❌ Error fetching community images: $e");
    }
    return imageUrls;
  }

  void _openMedia(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          contentPadding: EdgeInsets.zero,
          content: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            child: Image.network(imageUrl, fit: BoxFit.contain),
          ),
          actions: [
            TextButton(
              child: Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _cancelEditDescription() {
    setState(() {
      _descriptionController.text = communityDescription;
      _isEditingDescription = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    bool isMember = members.contains(widget.currentUserId);

    return Scaffold(
      appBar: AppBar(
        title: Text("Community Info", style: TextStyle(color: Colors.white)),
        backgroundColor: Color(0xFFFC7C79),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: BoxDecoration(
         gradient: LinearGradient(
        colors: [Color(0xFFFC7C79), Color(0xFFEDC0F9)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundImage: _newImageFile != null
                            ? FileImage(_newImageFile!)
                            : communityImageUrl.isNotEmpty
                                ? NetworkImage(
                                    communityImageUrl,
                                  ) as ImageProvider<Object>?
                                : AssetImage(
                                    'assets/images/default_community.png'),
                        onBackgroundImageError: (exception, stackTrace) {
                          setState(() {
                            communityImageUrl = "";
                          });
                        },
                      ),
                      if (isAdmin)
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: InkWell(
                            onTap: _pickImage,
                            child: Container(
                              padding: EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                color: Color(0xFFFC7C79),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.edit, color: Colors.white, size: 20),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                SizedBox(height: 20),
                Center(
                  child: Text(
                    communityName,
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 0.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Description",
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black),
                      ),
                      if (isAdmin)
                        Row(
                          children: [
                            if (_isEditingDescription)
                              IconButton(
                                icon: Icon(
                                  Icons.close,
                                  color: Color(0xFFFC7C79),
                                ),
                                onPressed: _cancelEditDescription,
                              ),
                            IconButton(
                              icon: Icon(
                                _isEditingDescription ? Icons.check : Icons.edit,
                                color: Color(0xFFFC7C79),
                              ),
                              onPressed: () {
                                if (_isEditingDescription) {
                                  _saveDescription();
                                } else {
                                  setState(() {
                                    _isEditingDescription = true;
                                  });
                                }
                              },
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                if (_isEditingDescription)
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: null,
                    keyboardType: TextInputType.multiline,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                  )
                else if (communityDescription.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(0),
                    child: Text(
                      communityDescription,
                      style: TextStyle(fontSize: 16, color: const Color.fromARGB(255, 229, 224, 224)),
                      textAlign: TextAlign.start,
                    ),
                  ),
                SizedBox(height: 15),
                Text(
                  "Community Media",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 10),
                FutureBuilder<List<String>>(
                  future: _fetchCommunityImages(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text("Error loading media"));
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Center(child: Text("No media files in this community yet."));
                    }

                    List<String> imageUrls = snapshot.data!;
                    return SizedBox(
                      height: 100,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: imageUrls.length,
                        itemBuilder: (context, index) {
                          String imageUrl = imageUrls[index];
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: InkWell(
                              onTap: () {
                                _openMedia(context, imageUrl);
                              },
                              child: Container(
                                width: 100, // Adjust width as needed
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  image: DecorationImage(
                                    image: NetworkImage(imageUrl),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(
                      "${members.length}",
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      "Members",
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black),
                    ),
                  ],
                ),
                SizedBox(height: 5),
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search members...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                SizedBox(height: 5),
                _filteredMembers.isEmpty
                    ? Center(
                        child: Text(
                          _searchController.text.isNotEmpty
                              ? "No members found matching your search"
                              : "No members in this community",
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemCount: _filteredMembers.length,
                        itemBuilder: (context, index) {
                          String memberId = _filteredMembers[index];

                          return FutureBuilder<DocumentSnapshot>(
                            future: _firestore
                                .collection('users')
                                .doc(memberId)
                                .get(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return ListTile(
                                  leading: CircularProgressIndicator(),
                                  title: Text("Loading..."),
                                );
                              }
                              if (snapshot.hasError ||
                                  !snapshot.hasData ||
                                  snapshot.data!.data() == null) {
                                return ListTile(
                                  leading:
                                      Icon(Icons.error, color: Colors.red),
                                  title: Text("Error loading user ($memberId)"),
                                );
                              }

                              var userData =
                                  snapshot.data!.data() as Map<String, dynamic>;
                              String userName =
                                  userData['name'] ?? 'Unknown User';
                              bool isCurrentUser =
                                  memberId == widget.currentUserId;

                              return Card(
                                elevation: 3,
                                margin: EdgeInsets.symmetric(vertical: 5),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundImage: userData['profileImage'] !=
                                            ""
                                        ? NetworkImage(userData['profileImage'])
                                        : AssetImage(
                                                'assets/images/default_profile.jpg')
                                            as ImageProvider,
                                  ),
                                  title: Text(userName +
                                      (isCurrentUser ? " (You)" : "")),
                                  subtitle: memberId == adminId
                                      ? Text("Admin",
                                          style: TextStyle(color: Color(0xFFFC7C79)))
                                      : null,
                                  trailing: isAdmin && memberId != adminId
                                      ? IconButton(
                                          icon: Icon(Icons.remove_circle,
                                              color: Color(0xFFFC7C79)),
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
                                                          Navigator.pop(context),
                                                      child: Text("Cancel")),
                                                  TextButton(
                                                    onPressed: () {
                                                      removeMember(memberId);
                                                      Navigator.pop(context);
                                                    },
                                                    child: Text("Remove",
                                                        style: TextStyle(
                                                            color: Color(0xFFFC7C79))),
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
                SizedBox(height: 20),
                if (isAdmin && _newImageFile != null)
                  Center(
                    child: ElevatedButton(
                      onPressed: _uploadImage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFFFC7C79),
                        padding:
                            EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text("Save Image", style: TextStyle(fontSize: 16)),
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
                                  Navigator.pop(context); // Close the dialog
                                  Navigator.pushAndRemoveUntil(
                                    context,
                                    MaterialPageRoute(builder: (context) => CommunityHomeScreen()),
                                    (Route<dynamic> route) => false,
                                  );
                                },
                                child: Text("Leave",
                                    style: TextStyle(color: Color(0xFFFC7C79))),
                              ),
                            ],
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFFFC7C79),
                        padding:
                            EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text("Leave Community",
                          style: TextStyle(fontSize: 16)),
                    ),
                  ),
                if (isAdmin)
                  Center(
                    child: ElevatedButton(
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
                                  Navigator.pop(context); // Close the dialog
                                  Navigator.pushAndRemoveUntil(
                                    context,
                                    MaterialPageRoute(builder: (context) => CommunityHomeScreen()),
                                    (Route<dynamic> route) => false,
                                  );
                                },
                                child: Text("Delete Community",
                                    style: TextStyle(color: Color(0xFFFC7C79))),
                              ),
                            ],
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFFFC7C79),
                        padding:
                            EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text("Delete Community",
                          style: TextStyle(fontSize: 16)),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}