import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:cultureconnect/pages/home.dart';
import 'package:cultureconnect/pages/encyclopedia/category_selection.dart';

// Define festival pages (add these in your project)
class DiwaliPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Diwali'),
      ),
      body: Center(
        child: Text('Details about Diwali festival.'),
      ),
    );
  }
}

class EidPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Eid'),
      ),
      body: Center(
        child: Text('Details about Eid festival.'),
      ),
    );
  }
}

class HoliPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Holi'),
      ),
      body: Center(
        child: Text('Details about Holi festival.'),
      ),
    );
  }
}

class ChristmasPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Christmas'),
      ),
      body: Center(
        child: Text('Details about Christmas festival.'),
      ),
    );
  }
}

// List of festival pages
final List<Widget> festivalPages = [
  DiwaliPage(),
  EidPage(),
  HoliPage(),
  ChristmasPage()
];

Widget horizontalScrollList(
    List<String> items, List<String> images, BuildContext context) {
  return SizedBox(
    height: 120, // Set a fixed height for the horizontal ListView
    child: ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: items.length,
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () {
            // Check if the item is a festival
            if (items[index] == "Diwali" ||
                items[index] == "Eid" ||
                items[index] == "Holi" ||
                items[index] == "Christmas") {
              // Navigate to the corresponding festival page
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => festivalPages[index],
                ),
              );
            } else {
              // Call the existing dialog box function for culture items
              showCultureDialog(context, items[index], images[index]);
            }
          },
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 8),
            width: 150,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              image: DecorationImage(
                image: AssetImage(images[index]),
                fit: BoxFit.cover,
              ),
            ),
            child: Center(
              child: Text(
                items[index],
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      color: Colors.black,
                      offset: Offset(1, 1),
                      blurRadius: 3,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    ),
  );
}

final Map<String, String> culturefacts = {
  "Gujarat":
      "Gujarat is famous for its vibrant Navratri celebrations and delicious Dhokla.",
  "Rajasthan":
      "Rajasthan is known for its majestic forts and the colorful Pushkar Camel Fair.",
  "Kerala":
      "Kerala is renowned for its serene backwaters and traditional Kathakali dance.",
  "Uttar Pradesh":
      "Uttar Pradesh is home to the iconic Taj Mahal and the holy city of Varanasi.",
};

void showCultureDialog(
    BuildContext context, String stateName, String imagePath) {
  // Fetch the fact for the given state
  String fact = culturefacts[stateName] ?? "Interesting fact about $stateName";

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        backgroundColor: Colors.transparent,
        content: Container(
          width: double.maxFinite,
          height: 300,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            image: DecorationImage(
              image: AssetImage(imagePath),
              fit: BoxFit.cover,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: Container(
                color: Colors.black.withOpacity(0.3),
                child: Stack(
                  children: [
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            stateName,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              shadows: [
                                Shadow(
                                  color: Colors.black,
                                  offset: Offset(1, 1),
                                  blurRadius: 3,
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 10),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              fact,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                                shadows: [
                                  Shadow(
                                    color: Colors.black,
                                    offset: Offset(1, 1),
                                    blurRadius: 3,
                                  ),
                                ],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Align(
                      alignment: Alignment.bottomRight,
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ElevatedButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => CategorySelectionPage(
                                      culture: stateName,
                                    ),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.blue,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                padding: EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                              ),
                              child: Text("Explore more"),
                            ),
                            SizedBox(width: 10),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.blue,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                padding: EdgeInsets.symmetric(
                                    horizontal: 24, vertical: 12),
                              ),
                              child: Text("OK"),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}
