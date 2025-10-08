import 'package:flutter/material.dart';
import 'package:maze/hi.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return  MaterialApp(
      home: Center(
       child: Animated10Print(),
      )
    );
  }
}
