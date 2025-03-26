import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'cart_page.dart';
import 'item_details.dart';
import 'user_profile.dart';


final _sectionTitleStyle = TextStyle(
  fontWeight: FontWeight.bold,
  fontSize: 16,
  color: Colors.white,
);

final _glassEffectDecoration = BoxDecoration(
  color: Colors.white.withOpacity(0.1),
  borderRadius: BorderRadius.circular(12),
  border: Border.all(color: Colors.white.withOpacity(0.3)),
);

final _inputDecoration = InputDecoration(
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide(color: Colors.white.withOpacity(0.5)),
  ),
  filled: true,
  fillColor: Colors.white.withOpacity(0.2),
  contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 10),
);

final _buttonStyle = ElevatedButton.styleFrom(
  backgroundColor: Colors.white,
  foregroundColor: Colors.black,
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  padding: EdgeInsets.symmetric(vertical: 14),
);

final _clearButtonStyle = ElevatedButton.styleFrom(
  backgroundColor: Colors.transparent,
  foregroundColor: Colors.white,
  side: BorderSide(color: Colors.white),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  padding: EdgeInsets.symmetric(vertical: 14),
);


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
              colors: [Color(0xFFFC7C79), Color(0xFFFC7C79)],
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
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (context) => const CartPage())),
              ),
              IconButton(
                icon: const Icon(Icons.person, color: Colors.white),
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (context) => const UserProfilePage())),
              ),
            ],
          ),
        ),
      ),
      endDrawer: Drawer(
  child: Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [Color(0xFFFC7C79), Color(0xFFEDC0F9)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
    ),
    child: SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(
                "Filter Options",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Category Dropdown
            Text("Select a Category", style: _sectionTitleStyle),
            const SizedBox(height: 4),
            Container(
              decoration: _glassEffectDecoration,
              child: DropdownButtonFormField<String>(
                decoration: _inputDecoration,
                value: _tempSelectedCategory,
                items: _categories.map((category) {
                  return DropdownMenuItem<String>(
                    value: category == 'All' ? null : category,
                    child: Text(category, style: const TextStyle(color: Colors.black)),
                  );
                }).toList(),
                onChanged: (String? newValue) => setState(() => _tempSelectedCategory = newValue),
              ),
            ),

            const SizedBox(height: 10),

            // Price Section
            Text("Price Range", style: _sectionTitleStyle),
            const SizedBox(height: 8),
            Column(
              children: _priceRanges.keys.map((range) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Container(
                    decoration: _glassEffectDecoration,
                    child: RadioListTile<String>(
                      activeColor: Colors.white,
                      title: Text(range, style: const TextStyle(color: Colors.white)),
                      value: range,
                      groupValue: _tempSelectedPriceRange,
                      onChanged: (String? value) => setState(() {
                        _tempSelectedPriceRange = value == _tempSelectedPriceRange ? null : value;
                      }),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 15),

            // Buttons Row
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: _buttonStyle,
                    onPressed: () {
                      setState(() {
                        _selectedCategory = _tempSelectedCategory;
                        _selectedPriceRange = _tempSelectedPriceRange;
                      });
                      Navigator.pop(context);
                    },
                    child: const Text('Apply Filters', style: TextStyle(fontSize: 16)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    style: _clearButtonStyle,
                    onPressed: () => setState(() {
                      _tempSelectedCategory = null;
                      _tempSelectedPriceRange = null;
                    }),
                    child: const Text('Clear Filters', style: TextStyle(fontSize: 16)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
   ),
  ),
),

      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFC7C79), Color(0xFFEDC0F9)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: kToolbarHeight + 35),
            Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search for items...',
                  prefixIcon: Icon(Icons.search, color: Colors.grey.shade600),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 14),
                ),
                onChanged: (value) => setState(() => _searchQuery = value),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.black,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.tune, color: Colors.white),
              onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
            ),
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
                    return const Center(child: Text("No items available with these filters"));
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
                    final itemName = (data['name'] as String?)?.toLowerCase() ?? '';
                    final itemDescription = (data['description'] as String?)?.toLowerCase() ?? '';
                    final searchLower = _searchQuery.toLowerCase();
                    return itemName.contains(searchLower) || itemDescription.contains(searchLower);
                  }).toList();

                  if (filteredItems.isEmpty) {
                    return const Center(child: Text("No items found matching your search"));
                  }

                  return GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.85,
                    ),
                    itemCount: filteredItems.length,
                    itemBuilder: (context, index) {
                      final item = filteredItems[index];
                      final data = item.data() as Map<String, dynamic>;
                      final imageUrls = (data['imageUrls'] as List<dynamic>?)?.cast<String>();
                      final firstImageUrl = imageUrls?.isNotEmpty == true 
                          ? imageUrls!.first 
                          : data['imageUrl'] as String?;

                      return GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ItemDetailsPage(itemId: item.id)),
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 6,
                                offset: const Offset(0, 3),
                              )
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                flex: 5,
                                child: ClipRRect(
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                                  child: _buildImageWidget(firstImageUrl),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(4.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      data['name'] ?? "No name",
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 0),
                                    Text(
                                      _getBriefDescription(data['description'] as String?),
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                        height: 1.2,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      data['price'] != null ? "₹${data['price']}" : "Price not available",
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageWidget(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return Container(
        color: Colors.grey[300],
        child: const Center(child: Icon(Icons.image_not_supported)),
      );
    }
    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => Container(
        color: Colors.grey[300],
        child: const Center(child: Icon(Icons.image_not_supported)),
      ),
    );
  }

  String _getBriefDescription(String? fullDescription) {
    if (fullDescription == null || fullDescription.isEmpty) return 'No description available';
    return fullDescription.length > 75 
        ? '${fullDescription.substring(0, 75)}...' 
        : fullDescription;
}
}
