import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'checkout_page.dart';

class ItemDetailsPage extends StatefulWidget {
  final String itemId;
  const ItemDetailsPage({super.key, required this.itemId});

  @override
  State<ItemDetailsPage> createState() => _ItemDetailsPageState();
}

class _ItemDetailsPageState extends State<ItemDetailsPage> {
  int _currentImageIndex = 0;

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
          future: FirebaseFirestore.instance.collection('marketplace').doc(widget.itemId).get(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            var item = snapshot.data!;
            Map<String, dynamic> data = item.data() as Map<String, dynamic>;

            List<String> imageUrls = [];
            if (data.containsKey('imageUrls') && data['imageUrls'] is List) {
              imageUrls = (data['imageUrls'] as List<dynamic>).cast<String>();
            } else if (data.containsKey('imageUrl') && data['imageUrl'] is String) {
              imageUrls = [data['imageUrl'] as String];
            }

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
                            if (imageUrls.isNotEmpty)
                              SizedBox(
                                height: MediaQuery.of(context).size.height * 0.4,
                                width: double.infinity,
                                child: Stack(
                                  alignment: Alignment.bottomCenter,
                                  children: [
                                    PageView.builder(
                                      itemCount: imageUrls.length,
                                      onPageChanged: (index) {
                                        setState(() {
                                          _currentImageIndex = index;
                                        });
                                      },
                                      itemBuilder: (context, index) {
                                        return GestureDetector(
                                          onTap: () {
                                            _showImageDialog(context, imageUrls[index]);
                                          },
                                          child: Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: ClipRRect(
                                              borderRadius: BorderRadius.circular(16.0),
                                              child: Image.network(
                                                imageUrls[index],
                                                fit: BoxFit.contain, // Changed BoxFit.cover to BoxFit.contain
                                                errorBuilder: (context, error, stackTrace) {
                                                  return const Icon(Icons.image_not_supported, size: 100, color: Colors.white);
                                                },
                                                loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
                                                  if (loadingProgress == null) return child;
                                                  return Center(
                                                    child: CircularProgressIndicator(
                                                      value: loadingProgress.expectedTotalBytes != null
                                                          ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                                          : null,
                                                    ),
                                                  );
                                                },
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                    if (imageUrls.length > 1)
                                      Positioned(
                                        bottom: 10,
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: imageUrls.asMap().entries.map((entry) {
                                            int index = entry.key;
                                            return Container(
                                              width: 8.0,
                                              height: 8.0,
                                              margin: const EdgeInsets.symmetric(horizontal: 4.0),
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: _currentImageIndex == index ? Colors.white : Colors.white.withOpacity(0.5),
                                              ),
                                            );
                                          }).toList(),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: MediaQuery.of(context).size.width * 0.05,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 20),
                                  Text(
                                    data['name'],
                                    style: TextStyle(
                                      fontSize: MediaQuery.of(context).size.width * 0.07,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    "₹${data['price']}",
                                    style: TextStyle(
                                      fontSize: MediaQuery.of(context).size.width * 0.06,
                                      fontWeight: FontWeight.w600,
                                      color: const Color.fromARGB(255, 0, 17, 9),
                                    ),
                                  ),
                                  const SizedBox(height: 15),
                                  Text(
                                    data['description'] ?? "No description available",
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
                                  .doc(widget.itemId)
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
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: quantity == 0
                                            ? ElevatedButton(
                                                onPressed: () => addToCart(userId, item.id, data['name'], imageUrls.isNotEmpty ? imageUrls.first : '', double.parse(data['price'].toString())),
                                                style: ElevatedButton.styleFrom(
                                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                                  backgroundColor: Colors.white,
                                                ),
                                                child: const Text(
                                                  "Add to Cart",
                                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
                                                ),
                                              )
                                            : Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                                children: [
                                                  IconButton(
                                                    icon: const Icon(Icons.remove, color: Colors.white),
                                                    onPressed: () {
                                                      if (quantity > 1) {
                                                        updateCartQuantity(userId, item.id, quantity - 1);
                                                      } else {
                                                        removeFromCart(userId, item.id);
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
                                                      updateCartQuantity(userId, item.id, quantity + 1);
                                                    },
                                                  ),
                                                ],
                                              ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: ElevatedButton(
                                          onPressed: () async {
                                            final String? userId = FirebaseAuth.instance.currentUser?.uid;
                                            if (userId == null) return;

                                            final cartRef = FirebaseFirestore.instance
                                                .collection('users')
                                                .doc(userId)
                                                .collection('cart')
                                                .doc(item.id);
                                            final cartSnapshot = await cartRef.get();

                                            int buyNowQuantity = quantity > 0 ? quantity : 1;

                                            if (!cartSnapshot.exists) {
                                              // Item not in cart, add it
                                              await addToCart(
                                                userId,
                                                item.id,
                                                data['name'],
                                                imageUrls.isNotEmpty ? imageUrls.first : '',
                                                double.parse(data['price'].toString()),
                                              );
                                              buyNowQuantity = 1; // Set quantity to 1 for buy now if not in cart
                                            } else {
                                              // Item in cart, update quantity to current selected quantity
                                              await updateCartQuantity(userId, item.id, quantity);
                                              buyNowQuantity = quantity;
                                            }

                                            // Navigate to CheckoutPage
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => CheckoutPage(
                                                  buyNowItemId: item.id,
                                                  buyNowItemName: data['name'],
                                                  buyNowItemImageUrl: imageUrls.isNotEmpty ? imageUrls.first : '',
                                                  buyNowItemPrice: double.parse(data['price'].toString()),
                                                  buyNowItemQuantity: buyNowQuantity,
                                                ),
                                              ),
                                            );
                                          },
                                          style: ElevatedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(vertical: 14),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                            backgroundColor: Colors.green,
                                          ),
                                          child: const Text(
                                            "Buy Now",
                                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                                          ),
                                        ),
                                      ),
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

  void _showImageDialog(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          contentPadding: EdgeInsets.zero,
          content: Stack(
            children: <Widget>[
              InteractiveViewer(
                panEnabled: true, // Enable panning
                minScale: 0.5,
                maxScale: 5.0,
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    );
                  },
                  errorBuilder: (BuildContext context, Object exception, StackTrace? stackTrace) {
                    return const Center(child: Text('Could not load image'));
                  },
                ),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: IconButton(
                  color: Colors.white,
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}