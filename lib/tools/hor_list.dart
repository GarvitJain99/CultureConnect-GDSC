import 'package:flutter/material.dart';
import 'dart:ui';

Widget horizontalScrollList(List<String> items, List<String> imagePaths,
    List<Widget> pages, BuildContext context) {
  return SizedBox(
    height: 120,
    child: ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: items.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => pages[index]),
                );
              },
              child: Stack(
                children: [
                  // Background Image with Blur Effect
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage(imagePaths[index]), // Local Image
                        fit: BoxFit.cover, // Image covers entire container
                      ),
                    ),
                    child: BackdropFilter(
                      filter:
                          ImageFilter.blur(sigmaX: 1, sigmaY: 1), // Blur effect
                      child: Container(
                        color: Colors.black.withOpacity(0.3), // Dark overlay
                      ),
                    ),
                  ),
                  // Centered Text
                  Positioned.fill(
                    child: Center(
                      child: Text(
                        items[index],
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ),
  );
}
