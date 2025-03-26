import 'package:flutter/material.dart';
import 'package:cultureconnect/pages/encyclopedia/region_selection.dart';
import 'package:cultureconnect/tools/hor_list.dart';
import 'package:cultureconnect/tools/button.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<String> cultureitems = [
    "Gujarat",
    "Rajasthan",
    "Kerala",
    "Uttar Pradesh"
  ];
  List<String> cultureimages = [
    "assets/images/west/gujarat.jpg",
    "assets/images/west/rajasthan.webp",
    "assets/images/south/kerala.webp",
    "assets/images/north/uttarpradesh.jpg",
  ];

  final List<Map<String, String>> events = [
    {'date': 'March 14, 2025', 'name': 'Holi'},
    {'date': 'March 30, 2025', 'name': 'Ugadi'},
    {'date': 'March 31, 2025', 'name': 'Ramadan'},
    {'date': 'April 6, 2025', 'name': 'Ram Navami'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(  
  colors: [Color(0xFFFC7C79), Color(0xFFEDC0F9)],  
  begin: Alignment.topCenter,  
  end: Alignment.bottomCenter, 
),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 20),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "CultureConnect",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            color: Colors.black38,
                            offset: Offset(1, 1),
                            blurRadius: 3,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.message_rounded,
                          color: const Color.fromARGB(255, 247, 241, 241),
                          size: 28),
                      onPressed: () {
                        print("Message icon clicked");
                      },
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: GestureDetector(
                  onTap: () {
                    _showBannerDialog(context);
                  },
                  child: Container(
                    width: double.infinity,
                    height: 180,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 8,
                          spreadRadius: 2,
                          offset: Offset(2, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.asset(
                        'assets/images/banner.webp',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 20),
              _sectionTitle("Cultures"),
              _cardContainer(
                horizontalScrollList(cultureitems, cultureimages, context),
              ),
              _sectionTitle("Upcoming Festivals"),
              _cardContainer(
                _buildEventButtons(),
              ),
              _funFactCard(),
              Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: CustomButton(
                    text: "Encyclopedia",
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RegionSelectionPage(),
                        ),
                      );
                    },
                    backgroundColor: Color(0xFF005F6B),
                    textColor: Colors.white,
                    borderColor: Colors.white,
                    borderRadius: 30.0,
                    elevation: 10.0,
                    width: 280.0,
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                    icon: Icons.book,
                    iconColor: Colors.white,
                    iconSize: 30.0,
                    isLoading: false,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEventButtons() {
    return Column(
      children: events.map((event) {
        return Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: ElevatedButton(
            onPressed: () {
              print('${event['name']} clicked');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.8),
              foregroundColor: Colors.black87,
              padding: EdgeInsets.symmetric(vertical: 16, horizontal: 24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  event['name']!,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  event['date']!,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          shadows: [
            Shadow(
              color: Colors.black38,
              offset: Offset(1, 1),
              blurRadius: 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _cardContainer(Widget child) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.4),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: EdgeInsets.all(8),
        child: child,
      ),
    );
  }

  Widget _funFactCard() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Card(
        color: Colors.white.withOpacity(0.9),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 5,
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            "✨ Did you know? The Kumbh Mela is the world's largest peaceful gathering with millions of pilgrims attending!",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  void _showBannerDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: Colors.white,
          title:
              Text("Welcome to CultureConnect!", textAlign: TextAlign.center),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Discover and explore different cultures and festivals from all over the world!",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 10),
              Image.asset("assets/images/banner.webp",
                  height: 100, fit: BoxFit.cover),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("OK", style: TextStyle(color: Colors.blue)),
            ),
          ],
        );
      },
    );
  }
}
