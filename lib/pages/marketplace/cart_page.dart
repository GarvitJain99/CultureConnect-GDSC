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
      ));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Your Cart"),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder(
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
                  return const Center(child: Text("Your cart is empty"));
                }

                var items = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    var item = items[index];
                    return ListTile(
                      leading: Image.network(
                        item['imageUrl'],
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                      ),
                      title: Text(item['name']),
                      subtitle: Text("₹${item['price']} x ${item['quantity']}"),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            onPressed: () {
                              if (item['quantity'] > 1) {
                                FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(userId)
                                    .collection('cart')
                                    .doc(item.id)
                                    .update({
                                  'quantity': item['quantity'] - 1,
                                });
                              } else {
                                FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(userId)
                                    .collection('cart')
                                    .doc(item.id)
                                    .delete();
                              }
                            },
                            color: Colors.red,
                          ),
                          Text(item['quantity'].toString(),
                              style: const TextStyle(fontSize: 18)),
                          IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: () {
                              FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(userId)
                                  .collection('cart')
                                  .doc(item.id)
                                  .update(
                                {
                                  'quantity': item['quantity'] + 1,
                                },
                              );
                            },
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => CheckoutPage()),
                );
              },
              child: const Text('Proceed to Checkout'),
            ),
          ),
        ],
      ),
    );
  }
}