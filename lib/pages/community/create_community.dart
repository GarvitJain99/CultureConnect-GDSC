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
      appBar: AppBar(title: Text("Create Community")),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            GestureDetector(
              onTap: pickImage,
              child: CircleAvatar(
                radius: 50,
                backgroundImage: _imageFile != null ? FileImage(_imageFile!) : null,
                child: _imageFile == null ? Icon(Icons.camera_alt, size: 40) : null,
              ),
            ),
            SizedBox(height: 10),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: "Community Name"),
            ),
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(labelText: "Description"),
              maxLines: 3,
            ),
            SizedBox(height: 10),

            // Public/Private Selection
            Row(
              children: [
                Text("Type:"),
                Radio(
                  value: "public",
                  groupValue: _communityType,
                  onChanged: (value) {
                    setState(() {
                      _communityType = value.toString();
                    });
                  },
                ),
                Text("Public"),
                Radio(
                  value: "private",
                  groupValue: _communityType,
                  onChanged: (value) {
                    setState(() {
                      _communityType = value.toString();
                    });
                  },
                ),
                Text("Private"),
              ],
            ),

            // Password Field (only for private)
            if (_communityType == "private")
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(labelText: "Password"),
                obscureText: true,
              ),

            SizedBox(height: 20),
            _isLoading
                ? CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: createCommunity,
                    child: Text("Create"),
                  ),
          ],
        ),
      ),
    );
  }
}
