import 'package:flutter/material.dart';
import 'generated_content.dart';

class CategorySelectionPage extends StatefulWidget {
  final String culture;
  const CategorySelectionPage({super.key, required this.culture});

  @override
  _CategorySelectionPageState createState() => _CategorySelectionPageState();
}

class _CategorySelectionPageState extends State<CategorySelectionPage> {
  final List<String> categories = ["Food", "Festivals", "Rituals", "Art", "Language"];
  final PageController _pageController = PageController(viewportFraction: 0.8);
  int _currentIndex = 0;

  // Mapping categories to images (Replace these with actual assets)
  final Map<String, String> categoryImages = {
    "Food": "assets/food.jpg",
    "Festivals": "assets/festivals.jpg",
    "Rituals": "assets/rituals.jpg",
    "Art": "assets/art.jpg",
    "Language": "assets/language.jpg",
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const SizedBox(height: 80),
          // Static "Select" text
          const Text(
            "Select",
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 20), // Keeps space between text and cards
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: categories.length,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              itemBuilder: (context, index) {
                String category = categories[index];
                String imagePath = categoryImages[category] ?? "assets/default.jpg";

                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => GeneratedContentPage(
                          culture: widget.culture,
                          category: category,
                        ),
                      ),
                    );
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeInOut,
                    margin: EdgeInsets.symmetric(vertical: _currentIndex == index ? 2 : 12, horizontal: 10),
                    height: 100, // *Smaller card height*
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 8,
                          spreadRadius: 2,
                          offset: const Offset(2, 6),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        // Background image
                        ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.asset(
                            imagePath,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                          ),
                        ),
                        // Dark overlay
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            color: Colors.black.withOpacity(0.4),
                          ),
                        ),
                        // Category name in the center
                        Center(
                          child: Text(
                            category,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.1,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 120),
        ],
     ),
    );
  }
}
