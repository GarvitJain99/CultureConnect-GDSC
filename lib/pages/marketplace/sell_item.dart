import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SellItemPage extends StatefulWidget {
  const SellItemPage({super.key});

  @override
  _SellItemPageState createState() => _SellItemPageState();
}

class _SellItemPageState extends State<SellItemPage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController imageUrlController = TextEditingController();
  final TextEditingController categoryController = TextEditingController();

  void sellItem() {
    final String? userId = FirebaseAuth.instance.currentUser?.uid;
    FirebaseFirestore.instance.collection('marketplace').add({
      'name': nameController.text,
      'price': double.parse(priceController.text),
      'description': descriptionController.text,
      'imageUrl': imageUrlController.text,
      'category': categoryController.text,
      'sellerId': userId,
    }).then((docRef) {
      FirebaseFirestore.instance.collection('users').doc(userId).collection('listed_items').doc(docRef.id).set({
        'name': nameController.text,
        'price': double.parse(priceController.text),
        'imageUrl': imageUrlController.text,
        'status': 'active',
      });
      Navigator.pop(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Sell an Item")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: "Item Name")),
            TextField(controller: priceController, decoration: const InputDecoration(labelText: "Price"), keyboardType: TextInputType.number),
            TextField(controller: descriptionController, decoration: const InputDecoration(labelText: "Description")),
            TextField(controller: imageUrlController, decoration: const InputDecoration(labelText: "Image URL")),
            TextField(controller: categoryController, decoration: const InputDecoration(labelText: "Category")),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: sellItem, child: const Text("Sell Item")),
          ],
        ),
      ),
    );
  }
}
