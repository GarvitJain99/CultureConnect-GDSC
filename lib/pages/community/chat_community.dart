import 'dart:async';
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
  String currentUserId = "";
  String? _replyingToMessageId;
  Map<String, dynamic>? _replyingToMessage;
  String? _highlightedMessageId;
  Timer? _highlightTimer;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    currentUserId = _auth.currentUser!.uid;
  }

  @override
  void dispose() {
    _highlightTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  Color getUserColor(String userId) {
    int hash = userId.hashCode;
    return Colors.primaries[hash % Colors.primaries.length].withOpacity(0.8);
  }

  void _highlightMessage(String messageId, int index) {
    setState(() {
      _highlightedMessageId = messageId;
    });

    _highlightTimer?.cancel();

    _scrollToIndex(index);

    _highlightTimer = Timer(Duration(seconds: 3), () {
      setState(() {
        _highlightedMessageId = null;
      });
    });
  }

  void _scrollToIndex(int index) {
    final double itemHeight = 100;
    final double offset = index * itemHeight;

    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent - offset,
      duration: Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  void _viewImage(BuildContext context, String imageUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: Center(
            child: InteractiveViewer(
              panEnabled: true,
              minScale: 0.5,
              maxScale: 4.0,
              child: Hero(
                tag: imageUrl,
                child: Image.network(imageUrl),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> sendMessage({String? imageUrl, Map<String, dynamic>? poll}) async {
    try {
      if (_messageController.text.trim().isEmpty && imageUrl == null && poll == null) {
        return;
      }

      String userId = _auth.currentUser!.uid;
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(userId).get();
      String userName = userDoc['name'];

      await _firestore
          .collection('communities')
          .doc(widget.communityId)
          .collection('messages')
          .add({
        'text': imageUrl ?? _messageController.text,
        'senderId': userId,
        'senderName': userName,
        'timestamp': FieldValue.serverTimestamp(),
        'type': imageUrl != null ? 'image' : poll != null ? 'poll' : 'text',
        'replyTo': _replyingToMessageId,
        'poll': poll,
      });

      _messageController.clear();
      setState(() {
        _replyingToMessageId = null;
        _replyingToMessage = null;
      });
    } catch (e) {
      print("Error sending message: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to send message. Please try again.")),
      );
    }
  }

  Future<void> deleteMessage(String messageId) async {
    try {
      await _firestore
          .collection('communities')
          .doc(widget.communityId)
          .collection('messages')
          .doc(messageId)
          .delete();
    } catch (e) {
      print("Error deleting message: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to delete message. Please try again.")),
      );
    }
  }

  Future<void> pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    File imageFile = File(pickedFile.path);
    setState(() {
      _selectedImage = imageFile;
    });

    String fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    UploadTask uploadTask = FirebaseStorage.instance
        .ref('chat_images/$fileName')
        .putFile(imageFile);
    TaskSnapshot taskSnapshot = await uploadTask;
    String imageUrl = await taskSnapshot.ref.getDownloadURL();

    sendMessage(imageUrl: imageUrl);
  }

  void openPollCreation() {
    TextEditingController _questionController = TextEditingController();
    List<TextEditingController> _optionControllers = [TextEditingController()];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 10,
              title: Center(
                child: Text(
                  "Create Poll",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _questionController,
                      decoration: InputDecoration(
                        labelText: "Poll Question",
                        labelStyle: TextStyle(color: Colors.deepPurple),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.deepPurple),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.deepPurple, width: 2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    SizedBox(height: 10),
                    ..._optionControllers.map((controller) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: TextField(
                          controller: controller,
                          decoration: InputDecoration(
                            labelText: "Option",
                            labelStyle: TextStyle(color: Colors.deepPurple),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.deepPurple),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.deepPurple, width: 2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                    SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _optionControllers.add(TextEditingController());
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      ),
                      child: Text(
                        "Add Option",
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    "Cancel",
                    style: TextStyle(color: Colors.red, fontSize: 16),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (_questionController.text.trim().isEmpty ||
                        _optionControllers.any(
                            (controller) => controller.text.trim().isEmpty)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Please fill all fields.")),
                      );
                      return;
                    }

                    Map<String, dynamic> poll = {
                      'question': _questionController.text.trim(),
                      'options': _optionControllers
                          .map((controller) => {
                                'text': controller.text.trim(),
                                'votes': [],
                              })
                          .toList(),
                    };

                    sendMessage(poll: poll);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  ),
                  child: Text(
                    "Create",
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void openEventCreation() {
    // Implement event creation logic
  }

  void _startReply(Map<String, dynamic> message, int index) {
    setState(() {
      _replyingToMessageId = message['id'];
      _replyingToMessage = message;
    });

    if (message['replyTo'] != null) {
      _highlightMessage(message['replyTo'], index);
    }
  }

  void _cancelReply() {
    setState(() {
      _replyingToMessageId = null;
      _replyingToMessage = null;
    });
  }

  Future<void> voteOnPoll(String messageId, int optionIndex) async {
    try {
      String userId = _auth.currentUser!.uid;
      DocumentReference messageRef = _firestore
          .collection('communities')
          .doc(widget.communityId)
          .collection('messages')
          .doc(messageId);

      DocumentSnapshot messageDoc = await messageRef.get();
      Map<String, dynamic>? poll = messageDoc['poll'];

      if (poll != null) {
        List<dynamic> options = poll['options'];

        for (var option in options) {
          option['votes'].remove(userId);
        }

        options[optionIndex]['votes'].add(userId);

        await messageRef.update({'poll': poll});
      }
    } catch (e) {
      print("Error voting on poll: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Community Chat", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.deepPurple,
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(Icons.info_outline),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CommunityInfoScreen(
                    communityId: widget.communityId,
                    currentUserId: currentUserId,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.deepPurple.shade100, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
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
                  if (!snapshot.hasData)
                    return Center(child: CircularProgressIndicator());

                  var messages = snapshot.data!.docs;

                  return ListView.builder(
                    reverse: true,
                    controller: _scrollController,
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      var message = messages[index].data() as Map<String, dynamic>;
                      bool isMe = message['senderId'] == _auth.currentUser!.uid;
                      Color userColor = getUserColor(message['senderId']);
                      bool isHighlighted = messages[index].id == _highlightedMessageId;

                      return GestureDetector(
                        onTap: () {
                          if (message['replyTo'] != null) {
                            _highlightMessage(message['replyTo'], index);
                          }
                        },
                        child: Container(
                          margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isMe
                                ? userColor.withOpacity(0.2)
                                : userColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: isHighlighted
                                ? Border.all(
                                    color: Colors.deepPurple,
                                    width: 2,
                                  )
                                : null,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 4,
                                offset: Offset(2, 2),
                              )
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (message['replyTo'] != null)
                                FutureBuilder<DocumentSnapshot>(
                                  future: _firestore
                                      .collection('communities')
                                      .doc(widget.communityId)
                                      .collection('messages')
                                      .doc(message['replyTo'])
                                      .get(),
                                  builder: (context, snapshot) {
                                    if (snapshot.hasData && snapshot.data!.exists) {
                                      var repliedToMessage = snapshot.data!
                                          .data() as Map<String, dynamic>;
                                      return Container(
                                        padding: EdgeInsets.all(8),
                                        margin: EdgeInsets.only(bottom: 8),
                                        decoration: BoxDecoration(
                                          color: userColor.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border(
                                            left: BorderSide(
                                              color: userColor,
                                              width: 3,
                                            ),
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              repliedToMessage['senderName'],
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: userColor,
                                              ),
                                            ),
                                            SizedBox(height: 4),
                                            Text(
                                              repliedToMessage['text'],
                                              style: TextStyle(
                                                fontStyle: FontStyle.italic,
                                                color: userColor.withOpacity(0.8),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    } else {
                                      return SizedBox.shrink();
                                    }
                                  },
                                ),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CircleAvatar(
                                    backgroundImage: message['senderProfilePic'] != null
                                        ? NetworkImage(message['senderProfilePic'])
                                        : AssetImage('assets/default_profile.png')
                                            as ImageProvider,
                                    radius: 20,
                                  ),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          message['senderName'],
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: userColor,
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        if (message['type'] == 'image')
                                          GestureDetector(
                                            onTap: () => _viewImage(context, message['text']),
                                            child: Hero(
                                              tag: message['text'],
                                              child: ClipRRect(
                                                borderRadius: BorderRadius.circular(8),
                                                child: Image.network(
                                                  message['text'],
                                                  width: 200,
                                                  height: 200,
                                                  fit: BoxFit.cover,
                                                ),
                                              ),
                                            ),
                                          )
                                        else if (message['type'] == 'poll')
                                          _buildPollWidget(message, messages[index].id)
                                        else
                                          Text(message['text']),
                                      ],
                                    ),
                                  ),
                                  if (isMe)
                                    IconButton(
                                      icon: Icon(Icons.delete, color: userColor),
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: Text("Delete Message"),
                                            content: Text(
                                                "Are you sure you want to delete this message?"),
                                            actions: [
                                              TextButton(
                                                onPressed: () =>
                                                    Navigator.pop(context),
                                                child: Text("Cancel"),
                                              ),
                                              TextButton(
                                                onPressed: () {
                                                  deleteMessage(messages[index].id);
                                                  Navigator.pop(context);
                                                },
                                                child: Text("Delete",
                                                    style: TextStyle(
                                                        color: Colors.red)),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  IconButton(
                                    icon: Icon(Icons.reply, size: 20),
                                    onPressed: () => _startReply({
                                      ...message,
                                      'id': messages[index].id,
                                    }, index),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            if (_replyingToMessage != null)
              Container(
                padding: EdgeInsets.all(8),
                color: Colors.deepPurple.shade100,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        "Replying to ${_replyingToMessage!['senderName']}: ${_replyingToMessage!['text']}",
                        style: TextStyle(
                          fontStyle: FontStyle.italic,
                          color: Colors.deepPurple.shade700,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close),
                      onPressed: _cancelReply,
                    ),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.poll),
                    onPressed: openPollCreation,
                  ),
                  IconButton(
                    icon: Icon(Icons.event),
                    onPressed: openEventCreation,
                  ),
                  IconButton(
                    icon: Icon(Icons.image),
                    onPressed: pickImage,
                  ),
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: "Type a message...",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.send),
                    onPressed: sendMessage,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPollWidget(Map<String, dynamic> message, String messageId) {
    Map<String, dynamic> poll = message['poll'];
    String userId = _auth.currentUser!.uid;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          poll['question'],
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        ...poll['options'].asMap().entries.map((entry) {
          int index = entry.key;
          Map<String, dynamic> option = entry.value;
          List<dynamic> votes = option['votes'];
          bool isVoted = votes.contains(userId);

          return GestureDetector(
            onTap: () => voteOnPoll(messageId, index),
            child: Container(
              margin: EdgeInsets.symmetric(vertical: 4),
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isVoted
                    ? Colors.deepPurple.shade200
                    : Colors.deepPurple.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(option['text']),
                  ),
                  if (isVoted)
                    Icon(
                      Icons.check_circle,
                      color: const Color.fromARGB(255, 5, 56, 36),
                    ),
                  SizedBox(width: 8),
                  Text("${votes.length} votes"),
                ],
              ),
            ),
          );
        }).toList(),
      ],
    );
  }
}
