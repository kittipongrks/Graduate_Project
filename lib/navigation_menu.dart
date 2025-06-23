import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:dahcpplication/pages/page.dart';
class NavigationMenu extends StatefulWidget {
  const NavigationMenu({super.key});

  @override
  State<NavigationMenu> createState() => _NavigationMenu();
}

class _NavigationMenu extends State<NavigationMenu> {
  int _selectedIndex = 0;

  void _navigeteBottomBar(int index) {
    setState(() {
      _selectedIndex = index;
      
    });
  }

  final List<Widget> _pages = [
    MyHomePage(),
    MyChatPage(),
    MyMapPage(),
    SettingPage(),
    
  ];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(children: _pages, index: _selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        type:BottomNavigationBarType.fixed,
        onTap: _navigeteBottomBar,
        items: [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Chat'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Map'),
        BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        
      ]),
    );
  }
}