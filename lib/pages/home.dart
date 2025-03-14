import 'package:cultureconnect/pages/encyclopedia/region_selection.dart';
import 'package:flutter/material.dart';
import 'package:cultureconnect/tools/hor_list.dart';
import 'package:cultureconnect/tools/button.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<String> cultureitems = ["Gujarat", "Rajasthan", "Sikh", "Jain"];
  List<String> cultureimages = [
    "assets/images/banner.png",
    "assets/images/banner.png",
    "assets/images/banner.png",
    "assets/images/banner.png",
  ];
  List<Widget> culturepages = [PageOne(), PageTwo(), PageThree(), PageFour()];

  List<String> festivalitems = ["Diwali", "Eid", "Holi", "Christmas"];
  List<String> festivalimages = [
    "assets/images/banner.png",
    "assets/images/banner.png",
    "assets/images/banner.png",
    "assets/images/banner.png",
  ];
  List<Widget> festivalpages = [PageOne(), PageTwo(), PageThree(), PageFour()];

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
  colors: [Color(0xFFB71C1C), Color(0xFFFFA726)], // Deep red to vibrant saffron
  begin: Alignment.centerLeft,  // Start from the left
  end: Alignment.centerRight,   // End at the right
),

        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 20), // Space for status bar
  
              // Custom Title Bar (Replaces AppBar)
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
                      icon: Icon(Icons.notifications, color: Colors.white, size: 28),
                      onPressed: () {},
                    ),
                  ],
                ),
              ),

              // Search Bar
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: "Search Cultures, Festivals, or Marketplace",
                    prefixIcon: Icon(Icons.search, color: Colors.black87),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),

              SizedBox(height: 16),

              // Banner
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
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
                      'assets/images/banner.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),

              SizedBox(height: 20),

              // Cultures Section
              _sectionTitle("Cultures"),
              _cardContainer(
                horizontalScrollList(cultureitems, cultureimages, culturepages, context),
              ),

              // Events & Festivals Section
              _sectionTitle("Upcoming Festivals"),
              _cardContainer(
                horizontalScrollList(festivalitems, festivalimages, festivalpages, context),
              ),

              // Fun Fact
              _funFactCard(),

              // Encyclopedia Button
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

  // Section Title Widget
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

  // Card Container
  Widget _cardContainer(Widget child) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 6,
              offset: Offset(2, 3),
            ),
          ],
        ),
        padding: EdgeInsets.all(8),
        child: child,
      ),
    );
  }

  // Fun Fact Card
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
}

// Dummy Pages
class PageOne extends StatelessWidget {
  const PageOne({super.key});

  @override
  Widget build(BuildContext context) {
    return _dummyPage("Page One");
  }
}

class PageTwo extends StatelessWidget {
  const PageTwo({super.key});

  @override
  Widget build(BuildContext context) {
    return _dummyPage("Page Two");
  }
}

class PageThree extends StatelessWidget {
  const PageThree({super.key});

  @override
  Widget build(BuildContext context) {
    return _dummyPage("Page Three");
  }
}

class PageFour extends StatelessWidget {
  const PageFour({super.key});

  @override
  Widget build(BuildContext context) {
    return _dummyPage("Page Four");
  }
}

Widget _dummyPage(String title) {
  return Scaffold(
    appBar: AppBar(title: Text(title)),
    body: Center(child: Text("Welcome to $title!")),
  );
}
