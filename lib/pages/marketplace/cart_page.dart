import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'checkout_page.dart';

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
        title: const Text("Your Cart", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFC7C79), Color(0xFFEDC0F9)],
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
                    return const Center(child: CircularProgressIndicator(color: Colors.white));
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Text(
                        "Your cart is empty",
                        style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    );
                  }

                  var items = snapshot.data!.docs;

                  return ListView.builder(
                    padding: const EdgeInsets.all(10),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      var item = items[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: Colors.white.withOpacity(0.2), // Slightly more opaque
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3), // Slightly darker shadow
                            
                            ),
                          ],
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(12), // Increased padding
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(15), // More rounded image
                            child: Image.network(
                              item['imageUrl'],
                              width: 100, // Slightly larger image
                              height: 100,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return const SizedBox(
                                  width: 90,
                                  height: 90,
                                  child: Center(child: Icon(Icons.image_not_supported, color: Colors.white)),
                                );
                              },
                            ),
                          ),
                          title: Text(
                            item['name'],
                            style: const TextStyle(
                              fontSize: 18, // Slightly larger title
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 8),
                              Text(
                                "₹${item['price']}",
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove, color: Colors.white),
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
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.add, color: Colors.white),
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
                      );
                    },
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(userId)
                    .collection('cart')
                    .snapshots(),
                builder: (context, snapshot) {
                  return AnimatedOpacity(
                    duration: const Duration(milliseconds: 300),
                    opacity: snapshot.hasData && snapshot.data!.docs.isNotEmpty ? 1.0 : 0.5,
                    child: ElevatedButton(
                      onPressed: snapshot.hasData && snapshot.data!.docs.isNotEmpty
                          ? () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => CheckoutPage()),
                              );
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.9), // Slightly transparent white
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), // More rounded button
                        shadowColor: Colors.black.withOpacity(0.3),
                        elevation: 7, // Slightly higher elevation
                      ),
                      child: const Center(
                        child: Text(
                          'Proceed to Checkout',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ),
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