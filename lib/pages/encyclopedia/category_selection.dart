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

  final Map<String, String> categoryImages = {
    "Food": "assets/images/food.jpg",
    "Festivals": "assets/images/festivals.png",
    "Rituals": "assets/images/rituals.jpeg",
    "Art": "assets/images/art.webp",
    "Language": "assets/images/language.jpeg",
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFFC7C79),
        elevation: 0,
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
            const SizedBox(height: 80),
            const Text(
              "Choose a category",
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                color: Colors.white, 
              ),
            ),
            const SizedBox(height: 20),
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
                  String imagePath = categoryImages[category] ?? "assets/images/default.jpg";

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
                      height: 100,
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
                          ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Image.asset(
                              imagePath,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              color: Colors.black.withOpacity(0.4),
                            ),
                          ),
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
      ),
    );
  }
}
