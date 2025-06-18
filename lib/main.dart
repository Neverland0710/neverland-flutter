import 'package:flutter/material.dart';
import 'package:neverland_flutter/screen/login.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart'; // ✅ Firebase Core import

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  ); // ✅ Firebase 초기화
  await initializeDateFormatting('ko');

  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: LoginScreen(),
    ),
  );
}
