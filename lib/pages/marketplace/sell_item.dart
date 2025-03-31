import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cultureconnect/pages/marketplace/pickup_location.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';

class SellItemPage extends StatefulWidget {
  const SellItemPage({super.key});

  @override
  _SellItemPageState createState() => _SellItemPageState();
}

class _SellItemPageState extends State<SellItemPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  List<File> _selectedImages = [];
  bool _isUploading = false;
  LatLng? selectedLocation;
  String? selectedAddress;
  double? _latitude;
  double? _longitude;

  final List<String> _categories = [
    'Electronics',
    'Clothing',
    'Books',
    'Home Goods',
    'Other',
  ];
  String? _selectedCategory;

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedFiles = await ImagePicker().pickMultiImage();
    setState(() {
      _selectedImages.addAll(pickedFiles.map((file) => File(file.path)));
    });
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
    if (_nameController.text.isEmpty ||
        _priceController.text.isEmpty ||
        _descriptionController.text.isEmpty ||
        _selectedCategory == null ||
        selectedAddress == null ||
        _selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Please fill all fields and select at least one image")),
      );
      return;
    }

    setState(() => _isUploading = true);
    final String? userId = FirebaseAuth.instance.currentUser?.uid;
    List<String> imageUrls = [];

    try {
      for (int i = 0; i < _selectedImages.length; i++) {
        File image = _selectedImages[i];
        String filePath =
            'marketplace_images/$userId/${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
        UploadTask uploadTask =
            FirebaseStorage.instance.ref(filePath).putFile(image);
        TaskSnapshot snapshot = await uploadTask;
        String imageUrl = await snapshot.ref.getDownloadURL();
        imageUrls.add(imageUrl);
      }

      DocumentReference docRef =
          await FirebaseFirestore.instance.collection('marketplace').add({
        'name': _nameController.text,
        'price': double.parse(_priceController.text),
        'description': _descriptionController.text,
        'imageUrls': imageUrls, // Store list of image URLs
        'category': _selectedCategory,
        'sellerId': userId,
        'location': {
          'latitude': _latitude,
          'longitude': _longitude,
          'address': selectedAddress,
        },
      });

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('listed_items')
          .doc(docRef.id)
          .set({
        'name': _nameController.text,
        'price': double.parse(_priceController.text),
        'imageUrls': imageUrls, // Store list of image URLs
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

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Sell an Item")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _selectedImages.length + 1, // +1 for the add button
                itemBuilder: (context, index) {
                  if (index == _selectedImages.length) {
                    return Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: GestureDetector(
                        onTap: _showImageSourceDialog,
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.grey),
                          ),
                          child: const Icon(Icons.add_a_photo,
                              size: 40, color: Colors.grey),
                        ),
                      ),
                    );
                  }
                  return Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: Stack(
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.grey),
                            image: DecorationImage(
                              image: FileImage(_selectedImages[index]),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                          top: -5,
                          right: -5,
                          child: IconButton(
                            icon: const Icon(Icons.cancel, color: Colors.red),
                            iconSize: 20,
                            onPressed: () => _removeImage(index),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: "Item Name")),
            TextField(
                controller: _priceController,
                decoration: const InputDecoration(labelText: "Price"),
                keyboardType: TextInputType.number),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: "Description"),
              maxLines: null,
              minLines: 3,
            ),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: "Category"),
              value: _selectedCategory,
              items: _categories.map((category) {
                return DropdownMenuItem<String>(
                  value: category,
                  child: Text(
                    category,
                    style: const TextStyle(fontWeight: FontWeight.normal),
                  ),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedCategory = newValue;
                  _categoryController.text = newValue ?? '';
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please select a category';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _locationController,
              readOnly: true,
              decoration: InputDecoration(
                labelText: "Pickup Location",
                suffixIcon: IconButton(
                  icon: const Icon(Icons.location_on),
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PickupLocationPage(),
                      ),
                    );

                    if (result != null && result is Map) {
                      setState(() {
                        _latitude = result['latitude'];
                        _longitude = result['longitude'];
                        selectedAddress = result['address'];
                        _locationController.text = selectedAddress ?? '';
                      });
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),
            _isUploading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: sellItem, child: const Text("Sell Item")),
          ],
        ),
      ),
     );
  }
}
