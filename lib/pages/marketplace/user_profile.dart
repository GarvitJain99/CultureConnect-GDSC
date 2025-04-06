import 'package:cultureconnect/pages/marketplace/item_details.dart';
import 'package:cultureconnect/pages/marketplace/sell_item.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class UserProfilePage extends StatelessWidget {
  const UserProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final String? userId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
          title: const Text("Your Profile"),
          centerTitle: true,
          backgroundColor: const Color(0xFFFC7C79)),
      body: userId == null
          ? const Center(child: Text("User not logged in"))
          : FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(userId)
                  .get(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                var userData = snapshot.data!;
                return Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFFC7C79), Color(0xFFEDC0F9)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  height: double.infinity,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Column(
                            children: [
                              CircleAvatar(
                                radius: 50,
                                backgroundImage: userData['profileImage'] != ""
                                    ? NetworkImage(userData['profileImage'])
                                    : AssetImage(
                                            'assets/images/default_profile.jpg')
                                        as ImageProvider,
                              ),
                              const SizedBox(height: 10),
                              Text(userData['name'],
                                  style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,color: Colors.white),),
                              Text(userData['email'],
                                  style: const TextStyle(
                                      fontSize: 16, color: Colors.white70)),
                              const SizedBox(height: 20),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            const SellItemPage()),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFFC7C79),
                                ),
                                child: const Text("Sell an Item", style: TextStyle(color: Colors.white)),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text("Your Listed Items",
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 10),
                        StreamBuilder(
                          stream: FirebaseFirestore.instance
                              .collection('users')
                              .doc(userId)
                              .collection('listed_items')
                              .snapshots(),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return const Center(
                                  child: CircularProgressIndicator());
                            }
                            var items = snapshot.data!.docs;
                            if (items.isEmpty) {
                              return const Text("No items listed yet.", style: TextStyle(color: Colors.white),);
                            }
                            return ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: items.length,
                                itemBuilder: (context, index) {
                                  var item = items[index];
                                  List<String>? imageUrls =
                                      (item['imageUrls'] as List<dynamic>?)
                                          ?.cast<String>();
                                  String? firstImageUrl;

                                  if (imageUrls != null &&
                                      imageUrls.isNotEmpty) {
                                    firstImageUrl = imageUrls.first;
                                  }

                                  return ListTile(
                                    leading: firstImageUrl != null
                                        ? Image.network(firstImageUrl,
                                            width: 50,
                                            height: 50,
                                            fit: BoxFit.cover)
                                        : const SizedBox(
                                            width: 50,
                                            height: 50,
                                            child: Icon(
                                                Icons.image_not_supported)),
                                    title: Text(item['name']),
                                    subtitle: Text("₹${item['price']}"),
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              ItemDetailsPage(itemId: item.id),
                                        ),
                                      );
                                    },
                                  );
                                });
                          },
                        ),
                        const SizedBox(height: 20),
                        const Text("Ongoing Orders",
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 10),
                        StreamBuilder(
                          stream: FirebaseFirestore.instance
                              .collection('users')
                              .doc(userId)
                              .collection('ongoing_orders')
                              .orderBy('timestamp', descending: true)
                              .snapshots(),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData ||
                                snapshot.data!.docs.isEmpty) {
                              return const Text("No ongoing orders.",
                                  style: TextStyle(color: Colors.white70));
                            }
                            var orders = snapshot.data!.docs;
                            return ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: orders.length,
                              itemBuilder: (context, index) {
                                var order = orders[index];
                                var items = List<Map<String, dynamic>>.from(
                                    order['items']);
                                final DateTime orderDate =
                                    (order['timestamp'] as Timestamp).toDate();
                                final String formattedDate =
                                    DateFormat('dd-MM-yyyy').format(orderDate);

                                return Card(
                                  elevation: 2,
                                  margin: const EdgeInsets.symmetric(vertical: 5),
                                  child: Padding(
                                    padding: const EdgeInsets.all(10.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text("Items:",
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold)),
                                        ...items.map((item) => Text(
                                            "- ${item['name']} (x${item['quantity']})")),
                                        const SizedBox(height: 5),
                                        Text(
                                            "Total Price: ₹${order['total_price']}",
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold)),
                                        Text("Date: $formattedDate",
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold)),
                                        Text("Order ID: ${order.id}",
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 5),
                                        const SizedBox(height: 10),
                                        ElevatedButton(
                                          onPressed: () =>
                                              _markOrderAsCompleted(
                                                  userId, order),
                                          child: const Text("Mark as Completed"),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                        const SizedBox(height: 20),
                        const Text("Previous Orders",
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 10),
                        StreamBuilder(
                          stream: FirebaseFirestore.instance
                              .collection('users')
                              .doc(userId)
                              .collection('previous_orders')
                              .orderBy('timestamp', descending: true)
                              .snapshots(),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData ||
                                snapshot.data!.docs.isEmpty) {
                              return const Text("No previous orders.",
                                  style: TextStyle(color: Colors.white70));
                            }
                            var orders = snapshot.data!.docs;
                            return ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: orders.length,
                              itemBuilder: (context, index) {
                                var order = orders[index];
                                var items = List<Map<String, dynamic>>.from(
                                    order['items'] ?? []);
                                final DateTime orderDate =
                                    (order['timestamp'] as Timestamp).toDate();
                                final String formattedDate =
                                    DateFormat('dd-MM-yyyy').format(orderDate);

                                return Card(
                                  elevation: 2,
                                  margin: const EdgeInsets.symmetric(vertical: 5),
                                  child: Padding(
                                    padding: const EdgeInsets.all(10.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text("Items:",
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold)),
                                        ...(items)
                                            .map((item) => Text(
                                                "- ${item['name']} (x${item['quantity']})"))
                                            .toList(),
                                        const SizedBox(height: 5),
                                        Text(
                                            "Total Price: ₹${order['total_price']}",
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold)),
                                        Text("Date: $formattedDate",
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold)),
                                        Text("Order ID: ${order.id}",
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 5),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  void _markOrderAsCompleted(String userId, QueryDocumentSnapshot order) async {
    final userRef = FirebaseFirestore.instance.collection('users').doc(userId);

    try {
      await userRef
          .collection('previous_orders')
          .add(Map<String, dynamic>.from(order.data() as Map));

      await userRef.collection('ongoing_orders').doc(order.id).delete();
    } catch (e) {
      print("Error marking order as completed: $e");
    }
  }
}