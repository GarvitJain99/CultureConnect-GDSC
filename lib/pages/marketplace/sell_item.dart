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

  final List<File> _selectedImages = [];
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
            title: const Text("Take a Photo", style: TextStyle(fontSize: 16)),
            onTap: () {
              Navigator.pop(context);
              _pickImage(ImageSource.camera);
            },
          ),
          ListTile(
            leading: const Icon(Icons.image),
            title: const Text("Choose from Gallery", style: TextStyle(fontSize: 16)),
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
            content: Text("Please fill all fields and select at least one image",
                style: TextStyle(color: Colors.white))),
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
        'imageUrls': imageUrls,
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
        'imageUrls': imageUrls,
        'status': 'active',
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Item listed successfully!",
                style: TextStyle(color: Colors.white))),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text("Error: ${e.toString()}",
                style: const TextStyle(color: Colors.white))),
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
       extendBodyBehindAppBar: false,
      appBar: AppBar(
        title: const Text("Sell an Item", style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.white
          )
          ),
        backgroundColor: Color(0xFFFC7C79),
        elevation: 0,
        
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFC7C79), Color(0xFFEDC0F9)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _selectedImages.length + 1,
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
                              color: Colors.grey[200],
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
              const SizedBox(height: 24),
              TextFormField(
                controller: _nameController,
                style: const TextStyle(fontSize: 16),
                decoration: InputDecoration(
                  labelText: "Item Name",
                  labelStyle: const TextStyle(fontSize: 16, color: Colors.black87),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    borderSide: const BorderSide(color: Colors.black),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                   
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                style: const TextStyle(fontSize: 16),
                decoration: InputDecoration(
                  labelText: "Price",
                  labelStyle: const TextStyle(fontSize: 16, color: Colors.black87),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    borderSide: const BorderSide(color: Colors.black),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                maxLines: null,
                minLines: 3,
                style: const TextStyle(fontSize: 16),
                decoration: InputDecoration(
                  labelText: "Description",
                  labelStyle: const TextStyle(fontSize: 16, color: Colors.black87),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    borderSide: const BorderSide(color: Colors.black),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: "Category",
                  labelStyle: const TextStyle(fontSize: 16, color: Colors.black87),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    borderSide: const BorderSide(color: Colors.black),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    
                        
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                value: _selectedCategory,
                items: _categories.map((category) {
                  return DropdownMenuItem<String>(
                    value: category,
                    child: Text(
                      category,
                      style: const TextStyle(
                          fontWeight: FontWeight.normal, fontSize: 16),
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
              TextFormField(
                controller: _locationController,
                readOnly: true,
                style: const TextStyle(fontSize: 16),
                decoration: InputDecoration(
                  labelText: "Pickup Location",
                  labelStyle: const TextStyle(fontSize: 16, color: Colors.black87),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    borderSide: const BorderSide(color: Colors.black),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.location_on, color: Color(0xFFFC7C79)),
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
              const SizedBox(height: 32),
              _isUploading
                  ? const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFC7C79)),
                    )
                  : ElevatedButton(
                      onPressed: sellItem,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFFFC7C79),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: const TextStyle(fontSize: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                      ),
                      child: const Text("Sell Item"),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}