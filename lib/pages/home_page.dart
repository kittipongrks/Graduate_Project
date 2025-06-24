import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:dahcpplication/pages/page.dart';
class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 0;

  void _navigeteBottomBar(int index) {
    setState(() {
      _selectedIndex = index;
      
    });
  }

  final List<Widget> _pages = [
    MyChatPage(),
    MyMapPage(),
    SettingPage(),
    
  ];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Home Page"),
        
      ),
      body: Center(
        child: Text("Welcome to Home Page!"),
        ),
    );
  }
}