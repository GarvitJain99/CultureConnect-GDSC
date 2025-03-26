import 'package:flutter/material.dart';
import 'category_selection.dart';

class CultureSelectionPage extends StatelessWidget {
  final String region;
  CultureSelectionPage({super.key, required this.region});

  final Map<String, List<String>> cultures = {
    "North": ["Jammu & Kashmir", "Himachal Pradesh", "Punjab","Haryana","Uttarakhand","Uttar Pradesh","Delhi"],
    "South": ["Tamil Nadu", "Kerala", "Karnataka", "Andhra Pradesh", "Telangana"],
    "North-East": ["Assam", "Arunachal Pradesh", "Nagaland", "Manipur", "Meghalaya", "Mizoram", "Tripura", "Sikkim"],
    "West": ["Rajasthan", "Gujarat", "Maharashtra", "Goa"],
    "Central": ["Madhya Pradesh", "Chhattisgarh"],
    "East": ["West Bengal", "Jharkand", "Odisha", "Bihar"],
  };

  final Map<String, String> stateImages = {
    "Jammu & Kashmir": "assets/images/north/jammuandkashmir.jpg",
    "Himachal Pradesh": "assets/images/north/himachalpradesh.jpeg",
    "Punjab": "assets/images/north/punjab.jpg",
    "Haryana": "assets/images/north/haryana.jpeg",
    "Uttarakhand": "assets/images/north/uttarakhand.jpg",
    "Uttar Pradesh": "assets/images/north/uttarpradesh.jpg",
    "Delhi": "assets/images/north/delhi.jpg",
    
    "Tamil Nadu": "assets/images/south/tamilnadu.webp",
    "Kerala": "assets/images/south/kerala.webp",
    "Karnataka": "assets/images/south/karnataka.jpg",
    "Andhra Pradesh": "assets/images/south/andhrapradesh.jpg",
    "Telangana": "assets/images/south/telangana.jpg",

    "Assam": "assets/images/north_east/assam.jpg",
    "Arunachal Pradesh": "assets/images/north_east/arunachalpradesh.jpg",
    "Nagaland": "assets/images/north_east/nagaland.jpg",
    "Manipur": "assets/images/north_east/manipur.webp",
    "Meghalaya": "assets/images/north_east/meghalaya.jpg",
    "Mizoram": "assets/images/north_east/mizoram.jpg",
    "Tripura": "assets/images/north_east/tripura.jpg",
    "Sikkim": "assets/images/north_east/sikkim.jpg",

    "Rajasthan": "assets/images/west/rajasthan.webp",
    "Gujarat": "assets/images/west/gujarat.jpg",
    "Maharashtra": "assets/images/west/maharashtra.jpg",
    "Goa": "assets/images/west/goa.jpeg",

    "Madhya Pradesh": "assets/images/central/madhyapradesh.webp",
    "Chhattisgarh": "assets/images/central/chhattisgarh.jpg",

    "West Bengal": "assets/images/east/westbengal.jpeg",
    "Odisha": "assets/images/east/odisha.webp",
    "Jharkand": "assets/images/east/jharkand.jpg",
    "Bihar": "assets/images/east/bihar.webp",
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Select a Culture in $region"),
        backgroundColor: const Color(0xFFFC7C79), // AppBar Color
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFC7C79), Color(0xFFEDC0F9)], // Background Gradient
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Padding(
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
      ),
    );
  }
}
