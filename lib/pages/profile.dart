import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImagePicker _picker = ImagePicker();

  User? _user;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _statusController = TextEditingController();
  final TextEditingController _aboutController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  String _email = "";
  String _profileImageUrl = "";
  File? _imageFile;

  @override
  void initState() {
    super.initState();
    _getUserData();
  }

  Future<void> _getUserData() async {
    _user = _auth.currentUser;
    if (_user != null) {
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(_user!.uid).get();
      if (userDoc.exists) {
        setState(() {
          _nameController.text = userDoc['name'] ?? "";
          _statusController.text = userDoc['status'] ?? "";
          _aboutController.text = userDoc['about'] ?? "";
          _locationController.text = userDoc['location'] ?? "";
          _email = _user!.email ?? "";
          _profileImageUrl = userDoc['profileImage'] ?? "";
        });
      }
    }
  }

  Future<void> _pickImage() async {
    // Request permissions
    var cameraStatus = await Permission.camera.request();
    var storageStatus = await Permission.storage.request();

    // Check if permissions are granted
    if (cameraStatus.isGranted && storageStatus.isGranted) {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
        await _uploadProfileImage();
      }
    } else if (cameraStatus.isPermanentlyDenied ||
        storageStatus.isPermanentlyDenied) {
      // Show settings dialog if permissions are permanently denied
      openAppSettings();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                "Camera & Storage permissions are required to upload a profile picture.")),
      );
    }
  }

  Future<void> _uploadProfileImage() async {
    if (_imageFile == null || _user == null) return;
    Reference storageRef =
        FirebaseStorage.instance.ref().child('profile_pics/${_user!.uid}.jpg');
    await storageRef.putFile(_imageFile!);
    String downloadUrl = await storageRef.getDownloadURL();

    await _firestore
        .collection('users')
        .doc(_user!.uid)
        .update({'profileImage': downloadUrl});

    setState(() {
      _profileImageUrl = downloadUrl;
    });
  }

  Future<void> _saveProfile() async {
    if (_user == null) return;
    await _firestore.collection('users').doc(_user!.uid).set({
      'name': _nameController.text,
      'status': _statusController.text,
      'about': _aboutController.text,
      'location': _locationController.text,
      'profileImage': _profileImageUrl,
    }, SetOptions(merge: true));

    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text("Profile Updated")));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.purple.shade200,
      appBar: AppBar(
        title: Text('CultureConnect'),
        backgroundColor: Colors.purple,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Column(
            children: [
              // Profile Image
              // Profile Image
              Stack(
                alignment: Alignment.center,
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor:
                        Colors.white, // Background for icon if no image
                    backgroundImage: _profileImageUrl.isNotEmpty
                        ? NetworkImage(_profileImageUrl)
                        : null,
                    child: _profileImageUrl.isEmpty
                        ? Icon(Icons.person,
                            size: 60, color: Colors.grey) // Default icon
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.blue, // Background color for visibility
                          shape: BoxShape.circle,
                        ),
                        padding: EdgeInsets.all(5),
                        child: Icon(Icons.edit, color: Colors.white, size: 20),
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 10),

              // Name
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: "Name",
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
              SizedBox(height: 10),

              // Status
              TextField(
                controller: _statusController,
                decoration: InputDecoration(
                  labelText: "Status",
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
              SizedBox(height: 10),

              // About
              TextField(
                controller: _aboutController,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: "About",
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
              SizedBox(height: 10),

              // Location
              TextField(
                controller: _locationController,
                decoration: InputDecoration(
                  labelText: "Location",
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
              SizedBox(height: 10),

              // Email (Read-only)
              TextField(
                controller: TextEditingController(text: _email),
                readOnly: true,
                decoration: InputDecoration(
                  labelText: "Email Address",
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
              SizedBox(height: 20),

              // Save Button
              ElevatedButton(
                onPressed: _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                  textStyle: TextStyle(fontSize: 18),
                ),
                child: Text("Save"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
