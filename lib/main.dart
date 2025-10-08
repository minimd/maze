import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:maze/hi.dart';

void main() {
  runApp(const MainApp());
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,  ]);

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
