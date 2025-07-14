import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
  
  Future<int> getAgePatient(DateTime dateOfBirth) async {
    final age = DateTime.now().difference(dateOfBirth).inDays ~/ 365;
    return age;
  }
  int calculateAge(Timestamp birthdate) {
    // birthdate ควรเป็นรูปแบบ 'yyyy-MM-dd'
    final birth =birthdate.toDate();
    final now = DateTime.now();
    int age = now.year - birth.year;
    if (now.month < birth.month || (now.month == birth.month && now.day < birth.day)) {
      age--;
    }
    return age;
  }
