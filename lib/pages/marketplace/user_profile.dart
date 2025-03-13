import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'sell_item.dart';

class UserProfilePage extends StatelessWidget {
  const UserProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final String? userId = FirebaseAuth.instance.currentUser?.uid; 

    return Scaffold(
      appBar: AppBar(title: const Text("Your Profile")),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          var userData = snapshot.data!;
          return Column(
            children: [
              CircleAvatar(
                radius: 50,
                backgroundImage: NetworkImage(userData['profileImage'] ?? ""),
              ),
              Text(userData['name'], style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              Text(userData['email']),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const SellItemPage()));
                },
                child: const Text("Sell an Item"),
              ),
              const SizedBox(height: 20),
              const Text("Your Listed Items", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Expanded(
                child: StreamBuilder(
                  stream: FirebaseFirestore.instance.collection('users').doc(userId).collection('listed_items').snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                    var items = snapshot.data!.docs;
                    return ListView.builder(
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        var item = items[index];
                        return ListTile(
                          leading: Image.network(item['imageUrl'], width: 50, height: 50, fit: BoxFit.cover),
                          title: Text(item['name']),
                          subtitle: Text("\$${item['price']}"),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}