import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatDiagnosisPage extends StatelessWidget{
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Diagnosis Page'),
        
      ),
      
      body: Center(
        child: Text('diagnosis content goes here'),
      ),
    );
  }
}