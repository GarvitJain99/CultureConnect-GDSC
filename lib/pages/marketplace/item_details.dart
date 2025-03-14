import 'package:cultureconnect/pages/marketplace/checkout_page.dart';
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
        future: FirebaseFirestore.instance
            .collection('marketplace')
            .doc(itemId)
            .get(),
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
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12.0),
                    child: Image.network(
                      item['imageUrl'],
                      height: 250,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  item['name'],
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Text(
                  "₹${item['price']}",
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.green),
                ),
                const SizedBox(height: 15),
                Text(
                  item['description'] ?? "No description available",
                  style: const TextStyle(fontSize: 16, color: Colors.black87),
                ),
                const Spacer(),
                StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .doc(userId)
                      .collection('cart')
                      .doc(itemId)
                      .snapshots(),
                  builder: (context, cartSnapshot) {
                    if (!cartSnapshot.hasData || !cartSnapshot.data!.exists) {
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
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                vertical: 12, horizontal: 24),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                          ),
                          child: const Text("Add to Cart",
                              style: TextStyle(fontSize: 16)),
                        ),
                      );
                    } else {
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
                                  updateCartQuantity(
                                      userId, itemId, quantity - 1);
                                } else {
                                  removeFromCart(userId, itemId);
                                }
                              },
                            ),
                            Text(
                              quantity.toString(),
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.w500),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: () {
                                updateCartQuantity(
                                    userId, itemId, quantity + 1);
                              },
                            ),
                          ],
                        ),
                      );
                    }
                  },
                ),
                const SizedBox(height: 20),
                Center(
                  // Center the button
                  child: ElevatedButton(
                    onPressed: () {
                      buyNow(
                          context,
                          userId,
                          item.id,
                          item['name'],
                          item['imageUrl'],
                          double.parse(item['price'].toString()));
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 24),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    child: const Text("Buy Now",
                        style: TextStyle(fontSize: 16, color: Colors.white)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> addToCart(String userId, String itemId, String name,
      String imageUrl, double price) async {
    var cartRef = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('cart')
        .doc(itemId);

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

  Future<void> updateCartQuantity(
      String userId, String itemId, int newQuantity) async {
    var cartRef = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('cart')
        .doc(itemId);
    cartRef.update({'quantity': newQuantity});
  }

  Future<void> removeFromCart(String userId, String itemId) async {
    var cartRef = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('cart')
        .doc(itemId);
    await cartRef.delete();
  }

  void buyNow(BuildContext context, String userId, String itemId, String name,
      String imageUrl, double price) async {
    // Add the item to the cart if it's not already there
    var cartRef = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('cart')
        .doc(itemId);

    var doc = await cartRef.get();

    if (!doc.exists) {
      await cartRef.set({
        'name': name,
        'imageUrl': imageUrl,
        'price': price,
        'quantity': 1,
      });
    }

    // Navigate to the CartPage
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CheckoutPage(),
      ),
    );
  }
}
