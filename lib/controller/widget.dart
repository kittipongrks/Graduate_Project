import 'package:flutter/material.dart';

const textInputDecoration = InputDecoration(
  enabledBorder: OutlineInputBorder(
    borderSide: BorderSide(color: Colors.grey, width: 2.0),
    borderRadius: BorderRadius.all(Radius.circular(12)),
  ),
  focusedBorder: OutlineInputBorder(
    borderSide: BorderSide(color: Colors.blue, width: 2.0),
    borderRadius: BorderRadius.all(Radius.circular(12)),
  ),
  errorBorder:OutlineInputBorder(
    borderSide: BorderSide(color: Colors.red, width: 2.0),
    borderRadius: BorderRadius.all(Radius.circular(12)),
  ),
);

void nextScreen(context , page){
  Navigator.push(context, MaterialPageRoute(
    builder: (context) => page,
  ));
}

void nextScreenReplace(context , page){
  Navigator.pushReplacement(context, MaterialPageRoute(
    builder: (context) => page,
  ));
}