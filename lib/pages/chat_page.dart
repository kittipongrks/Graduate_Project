import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
class MyChatPage extends StatefulWidget {
  const MyChatPage({super.key});

  @override
  State<MyChatPage> createState() => _MyChatPageState();
}

class _MyChatPageState extends State<MyChatPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(
              Icons.person,
              size: 30,
              
            ),
            const Text(" Docter"),
          ]
          
          ),

        // actions: [
        //   IconButton(
        //     icon: const Icon(
        //       Icons.document_scanner_rounded,
        //       size : 30,
        //       ),
        //     onPressed: (){
              
        //     },
        //   ),
        // ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Container(
          color: const Color.fromARGB(255, 167, 167, 167), //------------ change color to theme
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              
            ),
          ),
        ),
      ),
    );
  }
}