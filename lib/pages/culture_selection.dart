import 'package:flutter/material.dart';
import 'category_selection.dart';

class CultureSelectionPage extends StatelessWidget {
  final String region;
  CultureSelectionPage({super.key, required this.region});

  final Map<String, List<String>> cultures = {
    "North": ["Jammu & Kashmir", "Uttar Pradesh", "Punjab"],
    "South": ["Tamil Nadu", "Kerala", "Karnataka"],
    "North-East": ["Assam", "Meghalaya", "Nagaland"],
    "West": ["Rajasthan", "Gujarat", "Maharashtra"],
    "Central": ["Madhya Pradesh", "Chhattisgarh"],
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Select a Culture in $region")),
      body: ListView(
        children: cultures[region]!.map((culture) {
          return ListTile(
            title: Text(culture),
            trailing: const Icon(Icons.arrow_forward),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CategorySelectionPage(culture: culture),
                ),
              );
            },
          );
        }).toList(),
      ),
    );
  }
}
