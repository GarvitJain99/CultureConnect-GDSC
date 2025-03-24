import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'cart_page.dart';
import 'item_details.dart';
import 'user_profile.dart';

class MarketplaceHome extends StatefulWidget {
  const MarketplaceHome({super.key});

  @override
  State<MarketplaceHome> createState() => _MarketplaceHomeState();
}

class _MarketplaceHomeState extends State<MarketplaceHome> {
  String? _selectedCategory;
  String? _selectedPriceRange;
  String _searchQuery = '';
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  String? _tempSelectedCategory;
  String? _tempSelectedPriceRange;

  final List<String> _categories = [
    'All',
    'Electronics',
    'Clothing',
    'Books',
    'Home Goods',
    'Other',
  ];

  final Map<String, List<double>> _priceRanges = {
    'Under ₹ 1,000': [0, 1000],
    '₹ 1,000 - ₹ 5,000': [1000, 5000],
    '₹ 5,000 - ₹ 10,000': [5000, 10000],
    '₹ 10,000 - ₹ 20,000': [10000, 20000],
    'Over ₹ 20,000': [20000, double.infinity],
  };

  @override
  void initState() {
    super.initState();
    // Initialize temporary variables with current filter values
    _tempSelectedCategory = _selectedCategory;
    _tempSelectedPriceRange = _selectedPriceRange;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFFFA726), Color.fromARGB(176, 184, 48, 20)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: AppBar(
            title: const Text(
              "Marketplace",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 22,
                color: Colors.white,
              ),
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.shopping_cart, color: Colors.white),
                onPressed: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const CartPage()));
                },
              ),
              IconButton(
                icon: const Icon(Icons.person, color: Colors.white),
                onPressed: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const UserProfilePage()));
                },
              ),
            ],
          ),
        ),
      ),
      endDrawer: Drawer(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFB71C1C), Color(0xFFFFA726)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Text("Select a Category",
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                ),
                value: _tempSelectedCategory,
                items: _categories.map((category) {
                  return DropdownMenuItem<String>(
                    value: category == 'All' ? null : category,
                    child: Text(category,
                        style: const TextStyle(color: Colors.black)),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _tempSelectedCategory = newValue;
                  });
                },
              ),
              const SizedBox(height: 15),
              const Text("Price",
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 8),
              Column(
                children: _priceRanges.keys.map((range) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: RadioListTile<String>(
                        title: Text(range,
                            style: const TextStyle(color: Colors.white)),
                        value: range,
                        groupValue: _tempSelectedPriceRange,
                        onChanged: (String? value) {
                          setState(() {
                            if (value == _tempSelectedPriceRange) {
                              print(
                                  "Price range '$value' is being unselected.");
                              _tempSelectedPriceRange = null;
                              print(
                                  "New selected price range: $_tempSelectedPriceRange");
                            } else {
                              print("Price range '$value' is being selected.");
                              _tempSelectedPriceRange = value;
                              print(
                                  "New selected price range: $_tempSelectedPriceRange");
                            }
                          });
                        },
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _selectedCategory = _tempSelectedCategory;
                    _selectedPriceRange = _tempSelectedPriceRange;
                  });
                  Navigator.pop(context);
                },
                child: const Text('Apply Filters'),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _tempSelectedCategory = null;
                    _tempSelectedPriceRange = null;
                  });
                },
                child: const Text(
                  'Clear Filters',
                ),
              ),
            ],
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFB71C1C), Color(0xFFFFA726)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: kToolbarHeight + 35),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(
                        labelText: 'Search for items',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.white70,
                      ),
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.menu, color: Colors.black),
                    onPressed: () {
                      _scaffoldKey.currentState?.openEndDrawer();
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('marketplace')
                    .where('category', isEqualTo: _selectedCategory)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return const Center(child: Text("Error loading items"));
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                        child: Text("No items available with these filters"));
                  }

                  var items = snapshot.data!.docs;

                  if (_selectedPriceRange != null) {
                    final range = _priceRanges[_selectedPriceRange]!;
                    items = items.where((item) {
                      final data = item.data() as Map<String, dynamic>;
                      final price = (data['price'] as num?)?.toDouble() ?? 0;
                      return price >= range[0] && price < range[1];
                    }).toList();
                  }

                  final filteredItems = items.where((item) {
                    final data = item.data() as Map<String, dynamic>;
                    final itemName =
                        (data['name'] as String?)?.toLowerCase() ?? '';
                    final itemDescription =
                        (data['description'] as String?)?.toLowerCase() ?? '';
                    final searchLower = _searchQuery.toLowerCase();
                    return itemName.contains(searchLower) ||
                        itemDescription.contains(searchLower);
                  }).toList();

                  if (filteredItems.isEmpty) {
                    return const Center(
                        child: Text("No items found matching your search"));
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    itemCount: filteredItems.length,
                    itemBuilder: (context, index) {
                      var item = filteredItems[index];
                      Map<String, dynamic> data =
                          item.data() as Map<String, dynamic>;

                      String? firstImageUrl;
                      List<String>? imageUrls =
                          (data['imageUrls'] as List<dynamic>?)?.cast<String>();

                      if (imageUrls != null && imageUrls.isNotEmpty) {
                        firstImageUrl = imageUrls.first;
                      } else {
                        firstImageUrl = data['imageUrl'] as String?;
                      }

                      return AnimatedContainer(
                        duration: Duration(milliseconds: 500 + (index * 100)),
                        curve: Curves.easeInOut,
                        margin: const EdgeInsets.only(bottom: 15),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(4),
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: firstImageUrl != null
                                ? Image.network(
                                    firstImageUrl,
                                    width: 80,
                                    height: 80,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) {
                                      return const Icon(
                                          Icons.image_not_supported,
                                          size: 50);
                                    },
                                  )
                                : const Icon(Icons.image_not_supported,
                                    size: 50),
                          ),
                          title: Text(
                            data['name'] ?? "No name",
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18),
                          ),
                          subtitle: Text(
                            data['price'] != null
                                ? "₹${data['price']}"
                                : "Price not available",
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600),
                          ),
                          trailing: const Icon(Icons.arrow_forward_ios,
                              color: Colors.white),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    ItemDetailsPage(itemId: item.id),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}