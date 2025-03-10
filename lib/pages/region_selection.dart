import 'package:flutter/material.dart';
import 'culture_selection.dart';

class RegionSelectionPage extends StatelessWidget {
  const RegionSelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    List<String> regions = ["North", "South", "North-East", "West", "Central"];

    return Scaffold(
      appBar: AppBar(title: const Text("Select a Region")),
      body: ListView.builder(
        itemCount: regions.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(regions[index]),
            trailing: const Icon(Icons.arrow_forward),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CultureSelectionPage(region: regions[index]),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
