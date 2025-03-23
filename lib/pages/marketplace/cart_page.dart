import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'checkout_page.dart'; // Import your CheckoutPage file

class CartPage extends StatelessWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context) {
    final String? userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) {
      return const Scaffold(
        body: Center(
          child: Text(
            "Please log in to view your cart.",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
      );
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("Your Cart"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFB71C1C), Color(0xFFFFA726)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: kToolbarHeight + 20),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(userId)
                    .collection('cart')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Text(
                        "Your cart is empty",
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
                    );
                  }

                  var items = snapshot.data!.docs;

                  return ListView.builder(
                    padding: const EdgeInsets.all(10),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      var item = items[index];
                      return Card(
                        color: Colors.black87.withOpacity(0.15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        elevation: 0,
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  item['imageUrl'],
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              const SizedBox(width: 15),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item['name'],
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      "₹${item['price']}",
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.green,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                                          onPressed: () {
                                            if (item['quantity'] > 1) {
                                              FirebaseFirestore.instance
                                                  .collection('users')
                                                  .doc(userId)
                                                  .collection('cart')
                                                  .doc(item.id)
                                                  .update({'quantity': item['quantity'] - 1});
                                            } else {
                                              FirebaseFirestore.instance
                                                  .collection('users')
                                                  .doc(userId)
                                                  .collection('cart')
                                                  .doc(item.id)
                                                  .delete();
                                            }
                                          },
                                        ),
                                        Text(
                                          item['quantity'].toString(),
                                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.add_circle_outline, color: Colors.blue),
                                          onPressed: () {
                                            FirebaseFirestore.instance
                                                .collection('users')
                                                .doc(userId)
                                                .collection('cart')
                                                .doc(item.id)
                                                .update({'quantity': item['quantity'] + 1});
                                          },
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
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
            Padding(
              padding: const EdgeInsets.all(10),
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(userId)
                    .collection('cart')
                    .snapshots(),
                builder: (context, snapshot) {
                  return ElevatedButton(
                    onPressed: snapshot.hasData && snapshot.data!.docs.isNotEmpty
                        ? () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => CheckoutPage()),
                            );
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 40),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text(
                      'Proceed to Checkout',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}