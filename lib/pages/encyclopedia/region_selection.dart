import 'package:flutter/material.dart';
import 'culture_selection.dart';

class RegionSelectionPage extends StatelessWidget {
  const RegionSelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    // List of regions with associated images
    final List<Map<String, String>> regions = [
      {"name": "North", "image": "assets/images/north/north.jpg"},
      {"name": "South", "image": "assets/images/south/south.jpg"},
      {"name": "North-East", "image": "assets/images/north_east/north_east.webp"},
      {"name": "West", "image": "assets/images/west/west.jpg"},
      {"name": "Central", "image": "assets/images/central/central.jpg"},
      {"name": "East", "image": "assets/images/east/east.jpg"},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Select a Region"),
        backgroundColor: const Color(0xFFFC7C79), // AppBar Color
        elevation: 0, // Removes shadow for a cleaner look
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFC7C79), Color(0xFFEDC0F9)], // Gradient Background
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ListView.builder(
            itemCount: regions.length,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          CultureSelectionPage(region: regions[index]["name"]!),
                    ),
                  );
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 16), // Spacing between cards
                  height: 160, // Card height
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    image: DecorationImage(
                      image: AssetImage(regions[index]["image"]!),
                      fit: BoxFit.cover,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 8,
                        spreadRadius: 2,
                        offset: const Offset(2, 4),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      // Dark overlay for better text visibility
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: Colors.black.withOpacity(0.4),
                        ),
                      ),
                      // Region name in center
                      Center(
                        child: Text(
                          regions[index]["name"]!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
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
      ),
    );
  }
}
