import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ItemDetailsPage extends StatelessWidget {
  final String itemId;
  const ItemDetailsPage({super.key, required this.itemId});

  @override
  Widget build(BuildContext context) {
    final String? userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Item Details")),
        body: const Center(
          child: Text("Please log in to view this page"),
        ),
      );
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("Item Details"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFB71C1C), Color(0xFFFFA726)], // Deep red to saffron gradient
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance.collection('marketplace').doc(itemId).get(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            var item = snapshot.data!;
            return SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: constraints.maxHeight),
                      child: IntrinsicHeight(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: MediaQuery.of(context).size.width * 0.05,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Center(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(16.0),
                                      child: Image.network(
                                        item['imageUrl'],
                                        height: MediaQuery.of(context).size.height * 0.35,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return const Icon(Icons.image_not_supported, size: 100, color: Colors.white);
                                        },
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  Text(
                                    item['name'],
                                    style: TextStyle(
                                      fontSize: MediaQuery.of(context).size.width * 0.07,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    "₹${item['price']}",
                                    style: TextStyle(
                                      fontSize: MediaQuery.of(context).size.width * 0.06,
                                      fontWeight: FontWeight.w600,
                                      color: const Color.fromARGB(255, 0, 17, 9),
                                    ),
                                  ),
                                  const SizedBox(height: 15),
                                  Text(
                                    item['description'] ?? "No description available",
                                    style: TextStyle(
                                      fontSize: MediaQuery.of(context).size.width * 0.045,
                                      color: Colors.white70,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                  const SizedBox(height: 30),
                                ],
                              ),
                            ),
                            const Spacer(), // Ensures buttons stay at the bottom

                            StreamBuilder<DocumentSnapshot>(
                              stream: FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(userId)
                                  .collection('cart')
                                  .doc(itemId)
                                  .snapshots(),
                              builder: (context, cartSnapshot) {
                                int quantity = 0;
                                if (cartSnapshot.hasData && cartSnapshot.data!.exists) {
                                  quantity = cartSnapshot.data!['quantity'];
                                }

                                return Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: MediaQuery.of(context).size.width * 0.05,
                                    vertical: MediaQuery.of(context).size.height * 0.02,
                                  ),
                                  child: Column(
                                    children: [
                                      quantity == 0
                                          ? ElevatedButton(
                                              onPressed: () => addToCart(userId, item.id, item['name'], item['imageUrl'], double.parse(item['price'].toString())),
                                              style: ElevatedButton.styleFrom(
                                                padding: EdgeInsets.symmetric(
                                                    vertical: 14,
                                                    horizontal: MediaQuery.of(context).size.width * 0.3),
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                                backgroundColor: Colors.white,
                                              ),
                                              child: const Text(
                                                "Add to Cart",
                                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
                                              ),
                                            )
                                          : Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                IconButton(
                                                  icon: const Icon(Icons.remove, color: Colors.white),
                                                  onPressed: () {
                                                    if (quantity > 1) {
                                                      updateCartQuantity(userId, itemId, quantity - 1);
                                                    } else {
                                                      removeFromCart(userId, itemId);
                                                    }
                                                  },
                                                ),
                                                Text(
                                                  quantity.toString(),
                                                  style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
                                                ),
                                                IconButton(
                                                  icon: const Icon(Icons.add, color: Colors.white),
                                                  onPressed: () {
                                                    updateCartQuantity(userId, itemId, quantity + 1);
                                                  },
                                                ),
                                              ],
                                            ),
                                      const SizedBox(height: 10),
                                      
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> addToCart(String userId, String itemId, String name, String imageUrl, double price) async {
    var cartRef = FirebaseFirestore.instance.collection('users').doc(userId).collection('cart').doc(itemId);
    var doc = await cartRef.get();

    if (doc.exists) {
      cartRef.update({'quantity': FieldValue.increment(1)});
    } else {
      cartRef.set({
        'name': name,
        'imageUrl': imageUrl,
        'price': price,
        'quantity': 1,
      });
    }
  }

  Future<void> updateCartQuantity(String userId, String itemId, int newQuantity) async {
    var cartRef = FirebaseFirestore.instance.collection('users').doc(userId).collection('cart').doc(itemId);
    cartRef.update({'quantity': newQuantity});
  }

  Future<void> removeFromCart(String userId, String itemId) async {
    var cartRef = FirebaseFirestore.instance.collection('users').doc(userId).collection('cart').doc(itemId);
    await cartRef.delete();
  }

//   void buyNow(BuildContext context, String userId, String itemId, String name, String imageUrl, double price) async {
//     Navigator.pushNamed(context, '/checkout');
//   }
 }
