import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cultureconnect/pages/community/info_community.dart';
import 'package:cultureconnect/pages/community/user_profile.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/services.dart';

class CommunityChatScreen extends StatefulWidget {
  final String communityId;

  const CommunityChatScreen({super.key, required this.communityId});

  @override
  _CommunityChatScreenState createState() => _CommunityChatScreenState();
}

class _CommunityChatScreenState extends State<CommunityChatScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _messageController = TextEditingController();
  String currentUserId = "";
  String? _replyingToMessageId;
  Map<String, dynamic>? _replyingToMessage;
  String? _highlightedMessageId;
  Timer? _highlightTimer;
  final ScrollController _scrollController = ScrollController();
  bool _isManualScroll = false;

  String? communityName;
  String? communityImageUrl;

  @override
  void initState() {
    super.initState();
    currentUserId = _auth.currentUser!.uid;
    _loadCommunityDetails();
  }

  Future<void> _loadCommunityDetails() async {
    try {
      DocumentSnapshot communityDoc = await _firestore
          .collection('communities')
          .doc(widget.communityId)
          .get();

      if (communityDoc.exists && communityDoc.data() != null) {
        Map<String, dynamic> data = communityDoc.data() as Map<String, dynamic>;
        setState(() {
          communityName = data['name'] ?? 'Unnamed Community';
          communityImageUrl =
              data['imageUrl']?.isNotEmpty == true ? data['imageUrl'] : null;
        });
      } else {
        setState(() {
          communityName = 'Community not found';
          communityImageUrl = null;
        });
      }
    } catch (e) {
      setState(() {
        communityName = 'Error loading community';
        communityImageUrl = null;
      });
    }
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

  void _highlightMessage(String messageId, int index,
      {bool scrollToMessage = true}) {
    setState(() {
      _highlightedMessageId = messageId;
      _isManualScroll = scrollToMessage;
    });

    _highlightTimer?.cancel();

    if (scrollToMessage) {
      final double itemHeight = 100;
      final double offset = index * itemHeight;
      final double maxScroll = _scrollController.position.maxScrollExtent;
      final double scrollPosition = (offset).clamp(0.0, maxScroll);

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            scrollPosition,
            duration: Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
        }
      });
    }

    _highlightTimer = Timer(Duration(seconds: 3), () {
      setState(() {
        _highlightedMessageId = null;
        _isManualScroll = false;
      });
    });
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients &&
        !_isManualScroll &&
        _highlightedMessageId == null) {
      _scrollController.animateTo(
        0,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _viewImage(BuildContext context, String imageUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            title: GestureDetector(
              onTap: () {
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
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: CircleAvatar(
                        backgroundImage: communityImageUrl != null &&
                                communityImageUrl != ""
                            ? NetworkImage(communityImageUrl!)
                            : AssetImage('assets/images/default_community.png')
                                as ImageProvider,
                        radius: 18,
                      ),
                    ),
                    Text(
                      communityName ?? "Loading...",
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
            backgroundColor: Colors.deepPurple,
            iconTheme: IconThemeData(color: Colors.white),
            centerTitle: true,
          ),
          body: Center(
            child: InteractiveViewer(
              panEnabled: true,
              minScale: 0.5,
              maxScale: 4.0,
              child: Hero(
                tag: imageUrl,
                child: imageUrl.isNotEmpty
                    ? Image.network(imageUrl)
                    : Image.asset('assets/images/default_community.png'),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> sendMessage(
      {String? imageUrl, Map<String, dynamic>? poll}) async {
    try {
      if (_messageController.text.trim().isEmpty &&
          imageUrl == null &&
          poll == null) {
        return;
      }

      String userId = _auth.currentUser?.uid ?? '';
      if (userId.isEmpty) return;

      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) return;

      Map<String, dynamic>? userData = userDoc.data() as Map<String, dynamic>?;
      String userName = userData?['name'] ?? 'Anonymous';
      String profilePic = userData?['profileImage'] ?? '';

      await _firestore
          .collection('communities')
          .doc(widget.communityId)
          .collection('messages')
          .add({
        'text': imageUrl ?? _messageController.text,
        'senderId': userId,
        'senderName': userName,
        'senderProfilePic': profilePic,
        'timestamp': FieldValue.serverTimestamp(),
        'type': imageUrl != null
            ? 'image'
            : poll != null
                ? 'poll'
                : 'text',
        'replyTo': _replyingToMessageId,
        'poll': poll,
      });

      _messageController.clear();
      setState(() {
        _replyingToMessageId = null;
        _replyingToMessage = null;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    } catch (e) {
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to delete message. Please try again.")),
      );
    }
  }

  Future<void> pickImage(ImageSource source) async {
    final pickedFile = await ImagePicker().pickImage(source: source);
    if (pickedFile == null) return;

    File imageFile = File(pickedFile.path);

    String fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    UploadTask uploadTask = FirebaseStorage.instance
        .ref('chat_images/$fileName')
        .putFile(imageFile);
    TaskSnapshot taskSnapshot = await uploadTask;
    String imageUrl = await taskSnapshot.ref.getDownloadURL();

    sendMessage(imageUrl: imageUrl);
  }

  void openPollCreation() {
    TextEditingController questionController = TextEditingController();
    List<TextEditingController> optionControllers = [TextEditingController()];

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
                      controller: questionController,
                      decoration: InputDecoration(
                        labelText: "Poll Question",
                        labelStyle: TextStyle(color: Colors.deepPurple),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.deepPurple),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide:
                              BorderSide(color: Colors.deepPurple, width: 2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    SizedBox(height: 10),
                    ...optionControllers.map((controller) {
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
                              borderSide: BorderSide(
                                  color: Colors.deepPurple, width: 2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      );
                    }),
                    SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          optionControllers.add(TextEditingController());
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding:
                            EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
                    if (questionController.text.trim().isEmpty ||
                        optionControllers.any(
                            (controller) => controller.text.trim().isEmpty)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Please fill all fields.")),
                      );
                      return;
                    }

                    Map<String, dynamic> poll = {
                      'question': questionController.text.trim(),
                      'options': optionControllers
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

  void openCalendar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Calendar feature not yet implemented.")),
    );
  }

  void openEventCreation() {}

  void _startReply(Map<String, dynamic> message, int index) {
    setState(() {
      _replyingToMessageId = message['id'];
      _replyingToMessage = {
        ...message,
        'id': message['id'] ?? '',
        'text': message['type'] == 'image' ? '[Image]' : message['text'],
        'senderName': message['senderName'] ?? 'Unknown',
      };
    });

    if (message['replyTo'] != null) {
      _highlightMessage(message['replyTo'], index, scrollToMessage: false);
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

  void _copyMessage(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Message copied to clipboard')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: () {
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
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 12.0),
                child: CircleAvatar(
                  backgroundImage: (communityImageUrl != null &&
                          communityImageUrl!.isNotEmpty)
                      ? NetworkImage(communityImageUrl!)
                      : AssetImage('assets/images/default_community.png')
                          as ImageProvider,
                  radius: 18,
                ),
              ),
              Flexible(
                child: Text(
                  communityName ?? "Loading...",
                  style: TextStyle(color: Colors.white),
                  overflow: TextOverflow.fade,
                  maxLines: 1,
                  softWrap: false,
                ),
              ),
            ],
          ),
        ),
        backgroundColor: Color(0xFFFC7C79),
        iconTheme: IconThemeData(color: Colors.white),
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFC7C79), Color(0xFFEDC0F9)],
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
                  if (!snapshot.hasData) {
                    return Center(child: CircularProgressIndicator());
                  }

                  var messages = snapshot.data!.docs;

                  return ListView.builder(
                    reverse: true,
                    controller: _scrollController,
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      var message =
                          messages[index].data() as Map<String, dynamic>;
                      bool isMe = message['senderId'] == _auth.currentUser!.uid;
                      Color userColor = getUserColor(message['senderId']);
                      bool isHighlighted =
                          messages[index].id == _highlightedMessageId;

                      return GestureDetector(
                        onTap: () {
                          if (message['replyTo'] != null) {
                            _highlightMessage(message['replyTo'], index);
                          }
                        },
                        child: Align(
                          alignment: isMe
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            constraints: BoxConstraints(
                              maxWidth:
                                  MediaQuery.of(context).size.width * 0.75,
                            ),
                            margin: EdgeInsets.symmetric(
                                vertical: 4, horizontal: 8),
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isMe
                                  ? Color(0xFFF8F8F8).withOpacity(0.9)
                                  : Color(0xFFE6E6FA).withOpacity(0.9),
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(12),
                                topRight: Radius.circular(12),
                                bottomLeft: isMe
                                    ? Radius.circular(12)
                                    : Radius.circular(0),
                                bottomRight: isMe
                                    ? Radius.circular(0)
                                    : Radius.circular(12),
                              ),
                              border: isHighlighted
                                  ? Border.all(
                                      color: Colors.deepPurple,
                                      width: 2,
                                    )
                                  : null,
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
                                      if (snapshot.hasData &&
                                          snapshot.data!.exists) {
                                        var repliedToMessage = snapshot.data!
                                            .data() as Map<String, dynamic>;
                                        return GestureDetector(
                                          onTap: () {
                                            int repliedIndex =
                                                messages.indexWhere((doc) =>
                                                    doc.id ==
                                                    message['replyTo']);
                                            if (repliedIndex != -1) {
                                              _highlightMessage(
                                                  message['replyTo'],
                                                  repliedIndex);
                                            }
                                          },
                                          child: Container(
                                            padding: EdgeInsets.all(8),
                                            margin: EdgeInsets.only(bottom: 8),
                                            decoration: BoxDecoration(
                                              color: userColor.withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(8),
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
                                                  repliedToMessage[
                                                      'senderName'],
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: userColor,
                                                  ),
                                                ),
                                                SizedBox(height: 4),
                                                repliedToMessage['type'] ==
                                                        'image'
                                                    ? Row(
                                                        children: [
                                                          Icon(Icons.image,
                                                              color: userColor),
                                                          SizedBox(width: 8),
                                                          Text(
                                                            '[Image]',
                                                            style: TextStyle(
                                                              fontStyle:
                                                                  FontStyle
                                                                      .italic,
                                                              color: userColor
                                                                  .withOpacity(
                                                                      0.8),
                                                            ),
                                                          ),
                                                        ],
                                                      )
                                                    : Text(
                                                        repliedToMessage[
                                                            'text'],
                                                        style: TextStyle(
                                                          fontStyle:
                                                              FontStyle.italic,
                                                          color: userColor
                                                              .withOpacity(0.8),
                                                        ),
                                                      ),
                                              ],
                                            ),
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
                                    GestureDetector(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                UserProfileScreen(
                                              userId: message['senderId'],
                                            ),
                                          ),
                                        );
                                      },
                                      child: CircleAvatar(
                                        backgroundImage: message[
                                                    'senderProfilePic'] !=
                                                ""
                                            ? NetworkImage(
                                                message['senderProfilePic'])
                                            : AssetImage(
                                                    'assets/images/default_profile.jpg')
                                                as ImageProvider,
                                        radius: 20,
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
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
                                              onTap: () => _viewImage(
                                                  context, message['text']),
                                              child: Hero(
                                                tag: message['text'],
                                                child: ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
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
                                            _buildPollWidget(
                                                message, messages[index].id)
                                          else
                                            Text(message['text']),
                                        ],
                                      ),
                                    ),
                                    PopupMenuButton<String>(
                                      icon: Icon(Icons.more_vert,
                                          color: Colors.grey),
                                      onSelected: (value) {
                                        if (value == 'reply') {
                                          _startReply({
                                            ...message,
                                            'id': messages[index].id,
                                          }, index);
                                        } else if (value == 'copy') {
                                          _copyMessage(message['text']);
                                        } else if (value == 'delete') {
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
                                                    deleteMessage(
                                                        messages[index].id);
                                                    Navigator.pop(context);
                                                  },
                                                  child: Text("Delete",
                                                      style: TextStyle(
                                                          color: Colors.red)),
                                                ),
                                              ],
                                            ),
                                          );
                                        }
                                      },
                                      itemBuilder: (BuildContext context) =>
                                          <PopupMenuEntry<String>>[
                                        const PopupMenuItem<String>(
                                          value: 'reply',
                                          child: Row(
                                            children: [
                                              Icon(Icons.reply),
                                              SizedBox(width: 8),
                                              Text('Reply'),
                                            ],
                                          ),
                                        ),
                                        const PopupMenuItem<String>(
                                          value: 'copy',
                                          child: Row(
                                            children: [
                                              Icon(Icons.copy),
                                              SizedBox(width: 8),
                                              Text('Copy'),
                                            ],
                                          ),
                                        ),
                                        if (isMe)
                                          const PopupMenuItem<String>(
                                            value: 'delete',
                                            child: Row(
                                              children: [
                                                Icon(Icons.delete,
                                                    color: Colors.red),
                                                SizedBox(width: 8),
                                                Text('Delete',
                                                    style: TextStyle(
                                                        color: Colors.red)),
                                              ],
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
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
            if (_replyingToMessage != null)
              if (_replyingToMessage != null)
                Container(
                  padding: EdgeInsets.all(8),
                  color: Colors.deepPurple.shade100,
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Replying to ${_replyingToMessage!['senderName']}:",
                              style: TextStyle(
                                fontStyle: FontStyle.italic,
                                color: Colors.deepPurple.shade700,
                              ),
                            ),
                            SizedBox(height: 4),
                            _replyingToMessage!['type'] == 'image'
                                ? Row(
                                    children: [
                                      Icon(Icons.image,
                                          color: Colors.deepPurple),
                                      SizedBox(width: 8),
                                      Text(
                                        '[Image]',
                                        style: TextStyle(
                                          fontStyle: FontStyle.italic,
                                          color: Colors.deepPurple.shade700,
                                        ),
                                      ),
                                    ],
                                  )
                                : Text(
                                    _replyingToMessage!['text'],
                                    style: TextStyle(
                                      fontStyle: FontStyle.italic,
                                      color: Colors.deepPurple.shade700,
                                    ),
                                  ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close),
                        onPressed: _cancelReply,
                      ),
                    ],
                  ),
                ),
            Container(
              padding: EdgeInsets.all(4.0),
              constraints: BoxConstraints(
                maxHeight: 120,
              ),
              child: Row(
                children: [
                  PopupMenuButton<String>(
                    icon: Icon(Icons.add),
                    onSelected: (value) {
                      if (value == 'poll') {
                        openPollCreation();
                      } else if (value == 'calendar') {
                        openCalendar();
                      } else if (value == 'gallery') {
                        pickImage(ImageSource.gallery);
                      } else if (value == 'camera') {
                        pickImage(ImageSource.camera);
                      }
                    },
                    itemBuilder: (BuildContext context) =>
                        <PopupMenuEntry<String>>[
                      const PopupMenuItem<String>(
                        value: 'poll',
                        child: Row(
                          children: [
                            Icon(Icons.poll),
                            SizedBox(width: 8),
                            Text('Poll'),
                          ],
                        ),
                      ),
                      const PopupMenuItem<String>(
                        value: 'calendar',
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today),
                            SizedBox(width: 8),
                            Text('Calendar'),
                          ],
                        ),
                      ),
                      const PopupMenuItem<String>(
                        value: 'gallery',
                        child: Row(
                          children: [
                            Icon(Icons.image),
                            SizedBox(width: 8),
                            Text('Image from Gallery'),
                          ],
                        ),
                      ),
                      const PopupMenuItem<String>(
                        value: 'camera',
                        child: Row(
                          children: [
                            Icon(Icons.camera_alt),
                            SizedBox(width: 8),
                            Text('Image from Camera'),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      maxLines: 5,
                      minLines: 1,
                      keyboardType: TextInputType.multiline,
                      decoration: InputDecoration(
                        hintText: "Type a message...",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        isDense: true,
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
