import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
      appBar: AppBar(title: const Text("Item Details")),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('marketplace').doc(itemId).get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          var item = snapshot.data!;
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Image.network(
                    item['imageUrl'],
                    height: 200,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  item['name'],
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 5),
                Text(
                  "₹${item['price']}",
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 10),
                Text(
                  item['description'] ?? "No description available",
                  style: const TextStyle(fontSize: 16, color: Colors.black54),
                ),
                const SizedBox(height: 20),

                // 🔥 Cart Buttons (Add to Cart / + - Buttons)
                StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .doc(userId)
                      .collection('cart')
                      .doc(itemId)
                      .snapshots(),
                  builder: (context, cartSnapshot) {
                    if (!cartSnapshot.hasData || !cartSnapshot.data!.exists) {
                      // Show "Add to Cart" button if item is not in the cart
                      return Center(
                        child: ElevatedButton(
                          onPressed: () {
                            addToCart(
                              userId,
                              item.id,
                              item['name'],
                              item['imageUrl'],
                              double.parse(item['price'].toString()),
                            );
                          },
                          child: const Text("Add to Cart"),
                        ),
                      );
                    } else {
                      // Show "+" and "-" buttons if item is in the cart
                      var cartItem = cartSnapshot.data!;
                      int quantity = cartItem['quantity'];

                      return Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove),
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
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: () {
                                updateCartQuantity(userId, itemId, quantity + 1);
                              },
                            ),
                          ],
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// 🔥 Function to Add Item to Cart
  Future<void> addToCart(String userId, String itemId, String name, String imageUrl, double price) async {
    var cartRef = FirebaseFirestore.instance.collection('users').doc(userId).collection('cart').doc(itemId);

    var doc = await cartRef.get();

    if (doc.exists) {
      cartRef.update({
        'quantity': FieldValue.increment(1),
      });
    } else {
      cartRef.set({
        'name': name,
        'imageUrl': imageUrl,
        'price': price,
        'quantity': 1,
      });
    }
  }

  /// 🔥 Function to Update Cart Quantity
  Future<void> updateCartQuantity(String userId, String itemId, int newQuantity) async {
    var cartRef = FirebaseFirestore.instance.collection('users').doc(userId).collection('cart').doc(itemId);
    cartRef.update({'quantity': newQuantity});
  }

  /// 🔥 Function to Remove Item from Cart
  Future<void> removeFromCart(String userId, String itemId) async {
    var cartRef = FirebaseFirestore.instance.collection('users').doc(userId).collection('cart').doc(itemId);
    await cartRef.delete();
  }
}
