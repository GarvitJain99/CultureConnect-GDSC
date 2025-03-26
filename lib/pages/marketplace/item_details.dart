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
  final double _imageHeightFactor = 0.4;

  @override
  Widget build(BuildContext context) {
    final String? userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Item Details")),
        body: const Center(child: Text("Please log in to view this page")),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('marketplace')
            .doc(widget.itemId)
            .get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          var item = snapshot.data!;
          Map<String, dynamic> data = item.data() as Map<String, dynamic>;
          List<String> imageUrls = _getImageUrls(data);
          double price = double.tryParse(data['price'].toString()) ?? 0.0;

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight:
                    MediaQuery.of(context).size.height * _imageHeightFactor,
                floating: false,
                pinned: true,
                flexibleSpace: _buildImageGallery(imageUrls),
                backgroundColor: Colors.transparent,
                iconTheme: const IconThemeData(color: Colors.white),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildProductHeader(data, price),
                      const SizedBox(height: 20),
                      _buildProductDescription(data),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: _buildBottomBar(userId),
    );
  }

  List<String> _getImageUrls(Map<String, dynamic> data) {
    if (data.containsKey('imageUrls') && data['imageUrls'] is List) {
      return (data['imageUrls'] as List<dynamic>).cast<String>();
    } else if (data.containsKey('imageUrl') && data['imageUrl'] is String) {
      return [data['imageUrl'] as String];
    }
    return [];
  }

  Widget _buildImageGallery(List<String> imageUrls) {
    return Stack(
      children: [
        PageView.builder(
          itemCount: imageUrls.length,
          onPageChanged: (index) => setState(() => _currentImageIndex = index),
          itemBuilder: (context, index) => Container(
            color: Colors.grey[100],
            child: Center(
              child: GestureDetector(
                onTap: () => _showImageDialog(context, imageUrls[index]),
                child: Hero(
                  tag: 'image_${imageUrls[index]}',
                  child: Image.network(
                    imageUrls[index],
                    fit: BoxFit.contain,
                    width: double.infinity,
                    loadingBuilder: (BuildContext context, Widget child,
                        ImageChunkEvent? loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                      );
                    },
                    errorBuilder: (BuildContext context, Object exception,
                        StackTrace? stackTrace) {
                      return const Icon(Icons.image_not_supported,
                          size: 100, color: Colors.grey);
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
        if (imageUrls.length > 1)
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                imageUrls.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: _currentImageIndex == index ? 24 : 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: _currentImageIndex == index
                        ? Colors.white
                        : Colors.white.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildProductHeader(Map<String, dynamic> data, double price) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          data['name'],
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          '₹${price.toStringAsFixed(2)}',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.deepOrange,
          ),
        ),
        const SizedBox(height: 5),
        const Divider(height: 1, thickness: 1),
      ],
    );
  }

  Widget _buildProductDescription(Map<String, dynamic> data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Description',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          data['description'] ?? 'No description available',
          style: const TextStyle(
            fontSize: 16,
            color: Colors.black54,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar(String userId) {
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('cart')
            .doc(widget.itemId)
            .snapshots(),
        builder: (context, cartSnapshot) {
          int quantity = cartSnapshot.data?.exists ?? false
              ? cartSnapshot.data!['quantity']
              : 0;

          return Row(
            children: [
              if (quantity > 0)
                Expanded(
                  flex: 2,
                  child: _buildQuantityControl(quantity, userId),
                ),
              if (quantity == 0)
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _handleAddToCart(userId),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepOrange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Add to Cart',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _handleBuyNow(userId, quantity),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Buy Now',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildQuantityControl(int quantity, String userId) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.remove, size: 20),
            onPressed: () => quantity > 1
                ? updateCartQuantity(userId, widget.itemId, quantity - 1)
                : removeFromCart(userId, widget.itemId),
          ),
          Text('$quantity', style: const TextStyle(fontSize: 16)),
          IconButton(
            icon: const Icon(Icons.add, size: 20),
            onPressed: () =>
                updateCartQuantity(userId, widget.itemId, quantity + 1),
          ),
        ],
      ),
    );
  }

  void _handleAddToCart(String userId) async {
    final itemSnapshot = await FirebaseFirestore.instance
        .collection('marketplace')
        .doc(widget.itemId)
        .get();

    if (itemSnapshot.exists) {
      final data = itemSnapshot.data() as Map<String, dynamic>;
      final imageUrls = _getImageUrls(data);

      addToCart(
        userId,
        widget.itemId,
        data['name'],
        imageUrls.isNotEmpty ? imageUrls.first : '',
        double.parse(data['price'].toString()),
      );
    }
  }

  void _handleBuyNow(String userId, int quantity) async {
    final itemSnapshot = await FirebaseFirestore.instance
        .collection('marketplace')
        .doc(widget.itemId)
        .get();

    if (!itemSnapshot.exists) return;

    final data = itemSnapshot.data() as Map<String, dynamic>;
    final imageUrls = _getImageUrls(data);
    final cartRef = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('cart')
        .doc(widget.itemId);
    final cartSnapshot = await cartRef.get();

    int buyNowQuantity = quantity > 0 ? quantity : 1;

    if (!cartSnapshot.exists) {
      await addToCart(
        userId,
        widget.itemId,
        data['name'],
        imageUrls.isNotEmpty ? imageUrls.first : '',
        double.parse(data['price'].toString()),
      );
      buyNowQuantity = 1;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CheckoutPage(
          buyNowItemId: widget.itemId,
          buyNowItemName: data['name'],
          buyNowItemImageUrl: imageUrls.isNotEmpty ? imageUrls.first : '',
          buyNowItemPrice: double.parse(data['price'].toString()),
          buyNowItemQuantity: buyNowQuantity,
        ),
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

  void _showImageDialog(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          insetPadding: const EdgeInsets.all(20),
          child: Stack(
            children: <Widget>[
              InteractiveViewer(
                panEnabled: true,
                minScale: 0.5,
                maxScale: 5.0,
                child: Hero(
                  tag: 'image_$imageUrl',
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    loadingBuilder: (BuildContext context, Widget child,
                        ImageChunkEvent? loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                      );
                    },
                    errorBuilder: (BuildContext context, Object exception,
                        StackTrace? stackTrace) {
                      return const Center(child: Text('Could not load image'));
                    },
                  ),
                ),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
