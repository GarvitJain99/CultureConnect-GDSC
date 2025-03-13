import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CartPage extends StatelessWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context) {
    final String? userId =
        FirebaseAuth.instance.currentUser?.uid; // Get current user ID

    if (userId == null) {
      return const Scaffold(
        body: Center(child: Text("User not logged in")),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Your Cart")),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('cart')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          var items = snapshot.data?.docs ?? [];

          if (items.isEmpty) {
            return const Center(child: Text("Your cart is empty"));
          }

          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              var item = items[index];

              return ListTile(
                leading: Image.network(
                  item['imageUrl'],
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.image_not_supported),
                ),
                title: Text(item['name']),
                subtitle: Text("₹${item['price'].toString()}"),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove),
                      onPressed: () {
                        int currentQuantity = item['quantity'];
                        if (currentQuantity > 1) {
                          FirebaseFirestore.instance
                              .collection('users')
                              .doc(userId)
                              .collection('cart')
                              .doc(item.id)
                              .update({'quantity': FieldValue.increment(-1)});
                        } else {
                          FirebaseFirestore.instance
                              .collection('users')
                              .doc(userId)
                              .collection('cart')
                              .doc(item.id)
                              .delete(); // Remove if quantity reaches 0
                        }
                      },
                    ),
                    Text(item['quantity'].toString()), // Display quantity
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () {
                        FirebaseFirestore.instance
                            .collection('users')
                            .doc(userId)
                            .collection('cart')
                            .doc(item.id)
                            .update({'quantity': FieldValue.increment(1)});
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
