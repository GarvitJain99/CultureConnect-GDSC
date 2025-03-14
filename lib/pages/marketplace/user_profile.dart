import 'package:cultureconnect/pages/marketplace/item_details.dart';
import 'package:cultureconnect/pages/marketplace/sell_item.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfilePage extends StatelessWidget {
  const UserProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final String? userId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(title: const Text("Your Profile")),
      body: userId == null
          ? const Center(child: Text("User not logged in"))
          : FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                var userData = snapshot.data!;
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 50,
                              backgroundImage: NetworkImage(userData['profileImage'] ?? ""),
                            ),
                            const SizedBox(height: 10),
                            Text(userData['name'], style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                            Text(userData['email'], style: const TextStyle(fontSize: 16, color: Colors.grey)),
                            const SizedBox(height: 20),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const SellItemPage()),
                                );
                              },
                              child: const Text("Sell an Item"),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Listed Items Section
                      const Text("Your Listed Items", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      StreamBuilder(
                        stream: FirebaseFirestore.instance.collection('users').doc(userId).collection('listed_items').snapshots(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                          var items = snapshot.data!.docs;
                          if (items.isEmpty) return const Text("No items listed yet.");
                          return SizedBox(
                            height: 200,
                            child: ListView.builder(
                              itemCount: items.length,
                              itemBuilder: (context, index) {
                                var item = items[index];
                                return ListTile(
                                  leading: Image.network(item['imageUrl'], width: 50, height: 50, fit: BoxFit.cover),
                                  title: Text(item['name']),
                                  subtitle: Text("₹${item['price']}"),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ItemDetailsPage(itemId: item.id),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 20),

                      // Previous Orders Section
                      const Text("Previous Orders", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      StreamBuilder(
                        stream: FirebaseFirestore.instance
                            .collection('users')
                            .doc(userId)
                            .collection('previous_orders')
                            .orderBy('timestamp', descending: true)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                          var orders = snapshot.data!.docs;
                          if (orders.isEmpty) return const Text("No previous orders.");
                          return SizedBox(
                            height: 300,
                            child: ListView.builder(
                              itemCount: orders.length,
                              itemBuilder: (context, index) {
                                var order = orders[index];
                                var items = List<Map<String, dynamic>>.from(order['items']);
                                return Card(
                                  elevation: 2,
                                  margin: const EdgeInsets.symmetric(vertical: 5),
                                  child: Padding(
                                    padding: const EdgeInsets.all(10.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text("Order ID: ${order.id}", style: const TextStyle(fontWeight: FontWeight.bold)),
                                        Text("Total Price: ₹${order['total_price']}"),
                                        Text("Date: ${order['timestamp'].toDate()}"),
                                        const SizedBox(height: 5),
                                        const Text("Items:", style: TextStyle(fontWeight: FontWeight.bold)),
                                        ...items.map((item) => Text("- ${item['name']} (x${item['quantity']})")).toList(),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
