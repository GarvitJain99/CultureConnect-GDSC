import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class CreateCommunity extends StatefulWidget {
  @override
  _CreateCommunityState createState() => _CreateCommunityState();
}

class _CreateCommunityState extends State<CreateCommunity> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  File? _imageFile;
  bool _isLoading = false;
  String _communityType = "public"; 

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<void> pickImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<String?> uploadImage() async {
    if (_imageFile == null) return null;

    try {
      String fileName =
          "community_${DateTime.now().millisecondsSinceEpoch}.jpg";
      Reference storageRef = _storage.ref().child("community_images/$fileName");
      UploadTask uploadTask = storageRef.putFile(_imageFile!);
      TaskSnapshot snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      print("Image upload error: $e");
      return null;
    }
  }

  Future<void> createCommunity() async {
    if (_nameController.text.isEmpty || _descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Please fill all fields")));
      return;
    }
    if (_communityType == "private" && _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Enter a password for private community")));
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      String? imageUrl = await uploadImage();
      String userId = _auth.currentUser!.uid;

      await _firestore.collection("communities").add({
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'imageUrl': imageUrl ?? '',
        'admin': userId,
        'members': [userId],
        'createdAt': FieldValue.serverTimestamp(),
        'type': _communityType,
        'password': _communityType == "private"
            ? _passwordController.text.trim()
            : null,
      });

      Navigator.pop(context);
    } catch (e) {
      print("Error creating community: $e");
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error creating community")));
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Create Community",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: screenWidth * 0.07,
          ),
        ),
        backgroundColor: Color(0xFFFC7C79), 
        elevation: 0,
      ),
      body: Stack(children: [
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFFFC7C79),
                Color(0xFFEDC0F9)
              ], 
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          height: double.infinity,           width: double.infinity, 
          child: SingleChildScrollView(
            padding: EdgeInsets.all(screenWidth * 0.04),
            child: Column(
              children: [
                GestureDetector(
                  onTap: pickImage,
                  child: Container(
                    width: screenWidth * 0.3,
                    height: screenWidth * 0.3,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.85),
                      border: Border.all(
                          color: Color(0xFFFC7C79),
                          width: 2), 
                    ),
                    child: _imageFile != null
                        ? ClipOval(
                            child: Image.file(_imageFile!, fit: BoxFit.cover),
                          )
                        : Icon(Icons.camera_alt,
                            size: screenWidth * 0.12,
                            color: Color(0xFFFC7C79)), 
                  ),
                ),
                SizedBox(height: screenHeight * 0.02),

                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: "Community Name",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.white),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          BorderSide(color: Colors.white.withOpacity(0.7)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Color(0xFFFC7C79)),
                    ),
                    labelStyle: TextStyle(color: Colors.white.withOpacity(0.8)),
                    prefixIcon: Icon(Icons.group,
                        color: Color(0xFFFC7C79)), 
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.3),
                  ),
                  style: TextStyle(color: Colors.white),
                ),
                SizedBox(height: screenHeight * 0.015),

                TextField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    labelText: "Description",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.white),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          BorderSide(color: Colors.white.withOpacity(0.7)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Color(0xFFFC7C79)),
                    ),
                    labelStyle: TextStyle(color: Colors.white.withOpacity(0.8)),
                    prefixIcon: Icon(Icons.description,
                        color: Color(0xFFFC7C79)), 
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.3),
                  ),
                  maxLines: 3,
                  style: TextStyle(color: Colors.white),
                ),
                SizedBox(height: screenHeight * 0.025),

                Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.02,
                      vertical: screenHeight * 0.005),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _communityType = "public";
                          });
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: screenWidth * 0.05,
                              vertical: screenHeight * 0.01),
                          decoration: BoxDecoration(
                            color: _communityType == "public"
                                ? Color(0xFFFC7C79)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            "Public",
                            style: TextStyle(
                              color: _communityType == "public"
                                  ? Colors.white
                                  : Colors.white.withOpacity(0.8),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: screenWidth * 0.01),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _communityType = "private";
                          });
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: screenWidth * 0.05,
                              vertical: screenHeight * 0.01),
                          decoration: BoxDecoration(
                            color: _communityType == "private"
                                ? Color(0xFFFC7C79)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            "Private",
                            style: TextStyle(
                              color: _communityType == "private"
                                  ? Colors.white
                                  : Colors.white.withOpacity(0.8),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: screenHeight * 0.025),

                if (_communityType == "private")
                  TextField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: "Password",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.white),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            BorderSide(color: Colors.white.withOpacity(0.7)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Color(0xFFFC7C79)),
                      ),
                      labelStyle:
                          TextStyle(color: Colors.white.withOpacity(0.8)),
                      prefixIcon: Icon(Icons.lock,
                          color:
                              Color(0xFFFC7C79)),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.3),
                    ),
                    obscureText: true,
                    style: TextStyle(color: Colors.white),
                  ),
                if (_communityType == "private")
                  SizedBox(height: screenHeight * 0.025),

                _isLoading
                    ? CircularProgressIndicator(color: Colors.white)
                    : ElevatedButton(
                        onPressed: createCommunity,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              Color(0xFFFC7C79), 
                          padding: EdgeInsets.symmetric(
                              horizontal: screenWidth * 0.15,
                              vertical: screenHeight * 0.02),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: Text(
                          "Create Community",
                          style: TextStyle(
                              fontSize: screenWidth * 0.045,
                              color: Colors.white,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
              ],
            ),
          ),
        ),
      ]),
    );
  }
}
