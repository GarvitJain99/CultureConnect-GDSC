import 'package:cultureconnect/pages/community/home.dart';
import 'package:cultureconnect/pages/home.dart';
import 'package:cultureconnect/pages/marketplace/home.dart';
import 'package:cultureconnect/pages/profile/viewprofile.dart';
import 'package:flutter/material.dart';

class NavBar extends StatefulWidget {
  const NavBar({super.key});

  @override
  _NavBarState createState() => _NavBarState();
}

class _NavBarState extends State<NavBar> {
  int _selectedIndex = 0;

  void _onNavItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  final List<Widget> _pages = [
    HomePage(),
    CommunityHomeScreen(),
    MarketplaceHome(),
    ViewProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onNavItemTapped,
        backgroundColor: const Color.fromARGB(255, 15, 15, 16),
        selectedItemColor: Color(0xFFFC7C79),
        unselectedItemColor: Color(0xFFEDC0F9),
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: "Community"),
          BottomNavigationBarItem(
              icon: Icon(Icons.shopping_bag), label: "Marketplace"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }
}
