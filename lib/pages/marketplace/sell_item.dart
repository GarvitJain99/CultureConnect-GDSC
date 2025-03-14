import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class SellItemPage extends StatefulWidget {
  const SellItemPage({super.key});

  @override
  _SellItemPageState createState() => _SellItemPageState();
}

class _SellItemPageState extends State<SellItemPage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController categoryController = TextEditingController();
  
  File? _selectedImage;
  bool _isUploading = false;

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await ImagePicker().pickImage(source: source);
    if (pickedFile != null) {
      setState(() => _selectedImage = File(pickedFile.path));
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Wrap(
        children: [
          ListTile(
            leading: const Icon(Icons.camera_alt),
            title: const Text("Take a Photo"),
            onTap: () {
              Navigator.pop(context);
              _pickImage(ImageSource.camera);
            },
          ),
          ListTile(
            leading: const Icon(Icons.image),
            title: const Text("Choose from Gallery"),
            onTap: () {
              Navigator.pop(context);
              _pickImage(ImageSource.gallery);
            },
          ),
        ],
      ),
    );
  }

  Future<void> sellItem() async {
    if (nameController.text.isEmpty ||
        priceController.text.isEmpty ||
        descriptionController.text.isEmpty ||
        categoryController.text.isEmpty ||
        _selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields and select an image")),
      );
      return;
    }

    setState(() => _isUploading = true);
    final String? userId = FirebaseAuth.instance.currentUser?.uid;

    try {
      // Upload image to Firebase Storage
      String filePath = 'marketplace_images/${DateTime.now().millisecondsSinceEpoch}.jpg';
      UploadTask uploadTask = FirebaseStorage.instance.ref(filePath).putFile(_selectedImage!);
      TaskSnapshot snapshot = await uploadTask;
      String imageUrl = await snapshot.ref.getDownloadURL();

      // Store item in Firestore
      DocumentReference docRef = await FirebaseFirestore.instance.collection('marketplace').add({
        'name': nameController.text,
        'price': double.parse(priceController.text),
        'description': descriptionController.text,
        'imageUrl': imageUrl,
        'category': categoryController.text,
        'sellerId': userId,
      });

      // Add item to user's listed items
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('listed_items')
          .doc(docRef.id)
          .set({
        'name': nameController.text,
        'price': double.parse(priceController.text),
        'imageUrl': imageUrl,
        'status': 'active',
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Item listed successfully!")),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}")),
      );
    }

    setState(() => _isUploading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Sell an Item")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            GestureDetector(
              onTap: _showImageSourceDialog,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey),
                ),
                child: _selectedImage == null
                    ? const Icon(Icons.add_a_photo, size: 50, color: Colors.grey)
                    : ClipOval(child: Image.file(_selectedImage!, fit: BoxFit.cover)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(controller: nameController, decoration: const InputDecoration(labelText: "Item Name")),
            TextField(controller: priceController, decoration: const InputDecoration(labelText: "Price"), keyboardType: TextInputType.number),
            TextField(controller: descriptionController, decoration: const InputDecoration(labelText: "Description")),
            TextField(controller: categoryController, decoration: const InputDecoration(labelText: "Category")),
            const SizedBox(height: 20),
            _isUploading
                ? const CircularProgressIndicator()
                : ElevatedButton(onPressed: sellItem, child: const Text("Sell Item")),
          ],
        ),
      ),
    );
  }
}
