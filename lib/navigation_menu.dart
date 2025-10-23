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
    ChatDiagnosisPage(),
    ChatDiagnosisPage(),
    AccountPage(),
    
  ];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _pages),
      bottomNavigationBar: Container(
        margin: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Theme.of(context).bottomNavigationBarTheme.backgroundColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 2), // changes position of shadow
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BottomNavigationBar(
            currentIndex: _selectedIndex,
            type: BottomNavigationBarType.fixed,
            onTap: _navigeteBottomBar,
            
            items: [
              BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Home'),
              BottomNavigationBarItem(icon : Icon(Icons.chat_rounded),label: 'Chat',),
              BottomNavigationBarItem(icon: Icon(Icons.add_location_rounded), label: 'Map'),
              BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Account'),
            ],
          ),
        ),
      ),
    );
  }
}