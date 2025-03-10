import 'package:flutter/material.dart';
import 'generated_content.dart';

class CategorySelectionPage extends StatelessWidget {
  final String culture;
  CategorySelectionPage({super.key, required this.culture});

  final List<String> categories = ["Food", "Festivals", "Rituals", "Art", "Language"];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Select a Category for $culture")),
      body: ListView(
        children: categories.map((category) {
          return ListTile(
            title: Text(category),
            trailing: const Icon(Icons.arrow_forward),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => GeneratedContentPage(culture: culture, category: category),
                ),
              );
            },
          );
        }).toList(),
      ),
    );
  }
}
