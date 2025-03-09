import 'package:flutter/material.dart';
import 'package:cultureconnect/tools/horList.dart';
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

  List<String> festivalitems = ["Diwali", "EId", "Holi", "Christmas"];
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
      backgroundColor: Color.fromARGB(255, 62, 30, 67),
      appBar: AppBar(
        title: Text("CultureConnect",
            style: TextStyle(fontWeight: FontWeight.bold , color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.notifications, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Bar
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                decoration: InputDecoration(
                  hintText: "Search Cultures, Festivals, or Marketplace",
                  prefixIcon: Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30)),
                ),
              ),
            ),

            // Banner
            Padding(
                padding: EdgeInsets.all(16),
                child: Container(
                  width: 400,
                  height: 200,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage('assets/images/banner.png'),
                      fit: BoxFit.cover,
                    ),
                  ),
                )),

            // Cultures Section
            _sectionTitle("Cultures"),
            horizontalScrollList(
                cultureitems, cultureimages, culturepages, context),

            // Events & Festivals Section
            _sectionTitle("Upcoming Festivals"),
            horizontalScrollList(
                festivalitems, festivalimages, festivalpages, context),

            // Fun Fact
            _funFactCard(),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Button
                CustomButton(
                  text: "Encyclopedia",
                  onPressed: () {
                    // print("Button Pressed!");
                  },
                  backgroundColor: Colors.purple,
                  textColor: Colors.white,
                  borderColor: Colors.black,
                  borderRadius: 20.0,
                  elevation: 15.0,
                  width: 300.0,
                  fontSize: 18.0,
                  fontWeight: FontWeight.w600,
                  icon: Icons.book,
                  iconColor: Colors.white,
                  iconSize: 28.0,
                  isLoading: false, // Set to true to show loading
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  // Section Title Widget
  Widget _sectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        title,
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold ,  color: Colors.white),
      ),
    );
  }

  // 📌 Fun Fact Card
  Widget _funFactCard() {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 3,
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            "Did you know? The Kumbh Mela is the world's largest peaceful gathering, with millions of pilgrims attending!",
            style: TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

class PageOne extends StatelessWidget {
  const PageOne({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Page One")),
      body: Center(child: Text("Welcome to Page One!")),
    );
  }
}

class PageTwo extends StatelessWidget {
  const PageTwo({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Page Two")),
      body: Center(child: Text("Welcome to Page Two!")),
    );
  }
}

class PageThree extends StatelessWidget {
  const PageThree({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Page One")),
      body: Center(child: Text("Welcome to Page One!")),
    );
  }
}

class PageFour extends StatelessWidget {
  const PageFour({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Page One")),
      body: Center(child: Text("Welcome to Page One!")),
    );
  }
}
