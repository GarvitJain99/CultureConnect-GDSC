import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cultureconnect/pages/community/info_community.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'user_profile.dart';

class CommunityChatScreen extends StatefulWidget {
  final String communityId;

  CommunityChatScreen({required this.communityId});

  @override
  _CommunityChatScreenState createState() => _CommunityChatScreenState();
}

class _CommunityChatScreenState extends State<CommunityChatScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _messageController = TextEditingController();
  File? _selectedImage;
  String currentUserId = ""; // Store logged-in user ID

  @override
  void initState() {
    super.initState();
    currentUserId = _auth.currentUser!.uid; // Get current user's ID
  }

  Future<void> sendMessage({String? imageUrl}) async {
    if (_messageController.text.trim().isEmpty && imageUrl == null) return;

    String userId = _auth.currentUser!.uid;
    DocumentSnapshot userDoc = await _firestore.collection('users').doc(userId).get();
    String userName = userDoc['name'];

    await _firestore.collection('communities').doc(widget.communityId).collection('messages').add({
      'text': imageUrl ?? _messageController.text,
      'senderId': userId,
      'senderName': userName,
      'timestamp': FieldValue.serverTimestamp(),
      'type': imageUrl != null ? 'image' : 'text',
    });

    _messageController.clear();
  }

  Future<void> pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    File imageFile = File(pickedFile.path);
    setState(() {
      _selectedImage = imageFile;
    });

    String fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    UploadTask uploadTask = FirebaseStorage.instance.ref('chat_images/$fileName').putFile(imageFile);
    TaskSnapshot taskSnapshot = await uploadTask;
    String imageUrl = await taskSnapshot.ref.getDownloadURL();

    sendMessage(imageUrl: imageUrl);
  }

  void openPollCreation() {
    // Implement poll creation logic
  }

  void openEventCreation() {
    // Implement event creation logic
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Community Chat"),
        actions: [
          IconButton(
            icon: Icon(Icons.info_outline), // ℹ Info Icon
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CommunityInfoScreen(
                    communityId: widget.communityId,
                    currentUserId: currentUserId, // Pass logged-in user ID
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('communities')
                  .doc(widget.communityId)
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

                var messages = snapshot.data!.docs;

                return ListView.builder(
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    var message = messages[index].data() as Map<String, dynamic>;
                    bool isMe = message['senderId'] == _auth.currentUser!.uid;

                    return ListTile(
                      leading: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => UserProfileScreen(userId: message['senderId']),
                            ),
                          );
                        },
                        child: Text(
                          message['senderName'],
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                        ),
                      ),
                      title: message['type'] == 'image'
                          ? Image.network(message['text'])
                          : Text(message['text']),
                      subtitle: Text(isMe ? "You" : message['senderName']),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                IconButton(icon: Icon(Icons.poll), onPressed: openPollCreation),
                IconButton(icon: Icon(Icons.event), onPressed: openEventCreation),
                IconButton(icon: Icon(Icons.image), onPressed: pickImage),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(hintText: "Type a message..."),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: () => sendMessage(),
                ),
              ],
            ),
          ),
        ],
     ),
    );
  }
}
