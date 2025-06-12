import 'package:flutter/material.dart';
import 'package:neverland_project/screen/home_screen.dart';
import 'package:neverland_project/screen/verification_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/verify',
      routes: {
        '/verify': (context) => const VerificationScreen(),
        '/home': (context) => const HomeScreen(),
      },
    );
  }
}
