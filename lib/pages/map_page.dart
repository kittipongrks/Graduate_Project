import 'package:flutter/material.dart';

class MyMapPage extends StatelessWidget{
  const MyMapPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Map Page'),
      ),
      body: Center(
        child: Text('Map content goes here'),
      ),
    );
  }
}