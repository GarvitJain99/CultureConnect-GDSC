import 'package:flutter/material.dart';

class CultureDetailsPage extends StatelessWidget {
  final String title;
  final String imagePath;
  final String description;

  const CultureDetailsPage({
    super.key,
    required this.title,
    required this.imagePath,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.asset(imagePath, fit: BoxFit.cover, width: double.infinity),
            Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                title,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(16),
              child: Text(description, style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}
