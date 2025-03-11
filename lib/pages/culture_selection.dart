import 'package:flutter/material.dart';
import 'category_selection.dart';

class CultureSelectionPage extends StatelessWidget {
  final String region;
  CultureSelectionPage({super.key, required this.region});

  final Map<String, List<String>> cultures = {
    "North": ["Jammu & Kashmir", "Uttar Pradesh", "Punjab","Himachal Pradesh","Harayana"],
    "South": ["Tamil Nadu", "Kerala", "Karnataka"],
    "North-East": ["Assam", "Meghalaya", "Nagaland"],
    "West": ["Rajasthan", "Gujarat", "Maharashtra"],
    "Central": ["Madhya Pradesh", "Chhattisgarh"],
  };

  // Mapping states to placeholder images (You should replace these with actual images)
  final Map<String, String> stateImages = {
    "Jammu & Kashmir": "assets/jammu_kashmir.jpg",
    "Uttar Pradesh": "assets/uttar_pradesh.jpg",
    "Punjab": "assets/punjab.jpg",
    "Harayana": "assets/Harayana.jpg",
    "Himachal Pradesh": "assets/Himachal_Pradesh.jpg",
    "Tamil Nadu": "assets/tamil_nadu.jpg",
    "Kerala": "assets/kerala.jpg",
    "Karnataka": "assets/karnataka.jpg",
    "Assam": "assets/assam.jpg",
    "Meghalaya": "assets/meghalaya.jpg",
    "Nagaland": "assets/nagaland.jpg",
    "Rajasthan": "assets/rajasthan.jpg",
    "Gujarat": "assets/gujarat.jpg",
    "Maharashtra": "assets/maharashtra.jpg",
    "Madhya Pradesh": "assets/madhya_pradesh.jpg",
    "Chhattisgarh": "assets/chhattisgarh.jpg",
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Select a Culture in $region")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, // Two columns per row
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1, // Ensures square-shaped cards
          ),
          itemCount: cultures[region]!.length,
          itemBuilder: (context, index) {
            String culture = cultures[region]![index];
            String imagePath = stateImages[culture] ?? "assets/default.jpg";

            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CategorySelectionPage(culture: culture),
                  ),
                );
              },
              child: Stack(
                children: [
                  // Background image
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      image: DecorationImage(
                        image: AssetImage(imagePath),
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
                  ),
                  // Dark overlay for better text visibility
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: Colors.black.withOpacity(0.4),
                    ),
                  ),
                  // State name in center
                  Center(
                    child: Text(
                      culture,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
