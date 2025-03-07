import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFD1A3FF),
      appBar: AppBar(
        title: Text("CultureConnect",
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.notifications, color: Colors.black),
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
                  width: 200,
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
            _horizontalScrollList(["Gujarat", "Odisha", "Chennai", "Mumbai"]),

            // Events & Festivals Section
            _sectionTitle("Upcoming Festivals"),
            _horizontalScrollList(["Diwali", "Holi", "Navratri", "Pongal"]),

            // Fun Fact
            _funFactCard(),
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
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  // Horizontal Scrollable List
  Widget _horizontalScrollList(List<String> items) {
    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 100,
                color: Colors.white,
                child: Center(
                    child: Text(items[index],
                        style: TextStyle(fontWeight: FontWeight.bold))),
              ),
            ),
          );
        },
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
  // BottomNavigationBarItem _navBarItem(IconData icon, String label, int index) {
  //   return BottomNavigationBarItem(
  //     icon: AnimatedContainer(
  //       duration: Duration(milliseconds: 0),
  //       curve: Curves.easeInOut,
  //       padding: EdgeInsets.all(_selectedIndex == index ? 6.0 : 0.0),
  //       decoration: BoxDecoration(
  //         shape: BoxShape.circle,
  //         color: _selectedIndex == index ? Colors.deepPurple.shade100 : Colors.transparent,
  //       ),
  //       child: Icon(icon),
  //     ),
  //     label: label,
  //   );
  // }
}
