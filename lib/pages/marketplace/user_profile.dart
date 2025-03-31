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
        title: const Text("Your Profile", style: TextStyle(color: Colors.white)),
        backgroundColor: Color(0xFFFC7C79),
        elevation: 0,
      ),
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
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      //  crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        
                        // User Profile Info
                        Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15)),
                          child: Padding(
                            padding: const EdgeInsets.all(40.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                CircleAvatar(
                                  radius: 60,
                                  backgroundImage: NetworkImage(
                                      userData['profileImage'] ?? ""),
                                  backgroundColor: Colors.grey.shade300,
                                ),
                                const SizedBox(height: 15),
                                Text(
                                  userData['name'],
                                  style: const TextStyle(
                                      fontSize: 22, fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  userData['email'],
                                  style: const TextStyle(
                                      fontSize: 16, color: Colors.grey),
                                  textAlign: TextAlign.center,
                                ),
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
                                    backgroundColor: Color(0xFFFC7C79),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10)),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 30, vertical: 12),
                                  ),
                                  child: const Text("Sell an Item",
                                      style: TextStyle(fontSize: 16)),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                  
                        Text("Your Listed Items",
                            style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.indigo.shade700)),
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
                              return const Text("No items listed yet.",
                                  style: TextStyle(color: Colors.grey));
                            }
                            return ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: items.length,
                              separatorBuilder: (context, index) =>
                                  const Divider(height: 1, color: Colors.grey),
                              itemBuilder: (context, index) {
                                var item = items[index];
                                List<String>? imageUrls =
                                    (item['imageUrls'] as List<dynamic>?)
                                        ?.cast<String>();
                                String? firstImageUrl;
                  
                                if (imageUrls != null && imageUrls.isNotEmpty) {
                                  firstImageUrl = imageUrls.first;
                                }
                  
                                return ListTile(
                                  leading: SizedBox(
                                    width: 60,
                                    height: 60,
                                    child: firstImageUrl != null
                                        ? ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            child: Image.network(firstImageUrl,
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error,
                                                        stackTrace) =>
                                                    const Icon(Icons
                                                        .image_not_supported)),
                                          )
                                        : Container(
                                            decoration: BoxDecoration(
                                              color: Colors.grey.shade300,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: const Icon(
                                                Icons.image_not_supported,
                                                color: Colors.grey),
                                          ),
                                  ),
                                  title: Text(item['name'],
                                      style:
                                          const TextStyle(fontWeight: FontWeight.w500)),
                                  subtitle: Text("₹${item['price']}"),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ItemDetailsPage(
                                            itemId: item.id),
                                      ),
                                    );
                                  },
                                );
                              },
                            );
                          },
                        ),
                  
                        const SizedBox(height: 20),
                  
                        Text("Ongoing Orders",
                            style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.indigo.shade700)),
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
                                  style: TextStyle(color: Colors.grey));
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
                                final DateTime orderDate = (order['timestamp']
                                        as Timestamp)
                                    .toDate();
                                final String formattedDate =
                                    DateFormat('dd-MM-yyyy').format(orderDate);
                  
                                return Card(
                                  elevation: 3,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10)),
                                  margin:
                                      const EdgeInsets.symmetric(vertical: 8),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text("Order ID: ${order.id}",
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16)),
                                        const SizedBox(height: 8),
                                        const Text("Items:",
                                            style: TextStyle(
                                                fontWeight: FontWeight.w600)),
                                        ...items
                                            .map((item) => Text(
                                                "- ${item['name']} (x${item['quantity']})"))
                                            .toList(),
                                        const SizedBox(height: 8),
                                        Text(
                                            "Total Price: ₹${order['total_price']}",
                                            style: const TextStyle(
                                                fontWeight: FontWeight.w600)),
                                        Text("Date: $formattedDate",
                                            style: const TextStyle(
                                                color: Colors.grey)),
                                        const SizedBox(height: 10),
                                        Align(
                                          alignment: Alignment.bottomRight,
                                          child: ElevatedButton(
                                            onPressed: () =>
                                                _markOrderAsCompleted(
                                                    userId, order),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  Colors.orange.shade400,
                                              foregroundColor: Colors.white,
                                              shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(8)),
                                              padding: const EdgeInsets.symmetric(
                                                  horizontal: 15, vertical: 8),
                                            ),
                                            child: const Text("Mark as Completed",
                                                style: TextStyle(fontSize: 14)),
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
                  
                        const SizedBox(height: 20),
                  
                        Text("Previous Orders",
                            style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.indigo.shade700)),
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
                                  style: TextStyle(color: Colors.grey));
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
                                final DateTime orderDate = (order['timestamp']
                                        as Timestamp)
                                    .toDate();
                                final String formattedDate =
                                    DateFormat('dd-MM-yyyy').format(orderDate);
                  
                                return Card(
                                  elevation: 3,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10)),
                                  margin:
                                      const EdgeInsets.symmetric(vertical: 8),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text("Order ID: ${order.id}",
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16)),
                                        const SizedBox(height: 8),
                                        const Text("Items:",
                                            style: TextStyle(
                                                fontWeight: FontWeight.w600)),
                                        ...items
                                            .map((item) => Text(
                                                "- ${item['name']} (x${item['quantity']})"))
                                            .toList(),
                                        const SizedBox(height: 8),
                                        Text(
                                            "Total Price: ₹${order['total_price']}",
                                            style: const TextStyle(
                                                fontWeight: FontWeight.w600)),
                                        Text("Date: $formattedDate",
                                            style: const TextStyle(
                                                color: Colors.grey)),
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
      // Move order to "previous_orders"
      await userRef
          .collection('previous_orders')
          .add(Map<String, dynamic>.from(order.data() as Map));

      // Remove order from "ongoing_orders"
      await userRef.collection('ongoing_orders').doc(order.id).delete();
    } catch (e) {
      print("Error marking order as completed: $e");
    }
  }
}