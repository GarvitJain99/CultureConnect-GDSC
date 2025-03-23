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
  String _communityType = "public"; // Default to Public

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // 🔹 Pick an image from gallery
  Future<void> pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  // 🔹 Upload image to Firebase Storage
  Future<String?> uploadImage() async {
    if (_imageFile == null) return null;

    try {
      String fileName = "community_${DateTime.now().millisecondsSinceEpoch}.jpg";
      Reference storageRef = _storage.ref().child("community_images/$fileName");
      UploadTask uploadTask = storageRef.putFile(_imageFile!);
      TaskSnapshot snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      print("Image upload error: $e");
      return null;
    }
  }

  // 🔹 Create new community
  Future<void> createCommunity() async {
    if (_nameController.text.isEmpty || _descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Please fill all fields")));
      return;
    }
    if (_communityType == "private" && _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Enter a password for private community")));
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
        'password': _communityType == "private" ? _passwordController.text.trim() : null,
      });

      Navigator.pop(context);
    } catch (e) {
      print("Error creating community: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error creating community")));
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Create Community"),
        backgroundColor: Colors.deepPurple,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // 🔹 Community Image
            GestureDetector(
              onTap: pickImage,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey[200],
                  border: Border.all(color: Colors.deepPurple, width: 2),
                ),
                child: _imageFile != null
                    ? ClipOval(
                        child: Image.file(_imageFile!, fit: BoxFit.cover),
                      )
                    : Icon(Icons.camera_alt, size: 40, color: Colors.deepPurple),
              ),
            ),
            SizedBox(height: 20),

            // 🔹 Community Name
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: "Community Name",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                prefixIcon: Icon(Icons.group, color: Colors.deepPurple),
              ),
            ),
            SizedBox(height: 15),

            // 🔹 Community Description
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: "Description",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                prefixIcon: Icon(Icons.description, color: Colors.deepPurple),
              ),
              maxLines: 3,
            ),
            SizedBox(height: 20),

            // 🔹 Public/Private Toggle
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Public Option
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _communityType = "public";
                      });
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: _communityType == "public" ? Colors.deepPurple : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        "Public",
                        style: TextStyle(
                          color: _communityType == "public" ? Colors.white : Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  // Private Option
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _communityType = "private";
                      });
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: _communityType == "private" ? Colors.deepPurple : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        "Private",
                        style: TextStyle(
                          color: _communityType == "private" ? Colors.white : Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),

            // 🔹 Password Field (only for private)
            if (_communityType == "private")
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: "Password",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  prefixIcon: Icon(Icons.lock, color: Colors.deepPurple),
                ),
                obscureText: true,
              ),
            SizedBox(height: 20),

            // 🔹 Create Button
            _isLoading
                ? CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: createCommunity,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: Text(
                      "Create Community",
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}