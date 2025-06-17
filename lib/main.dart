import 'package:flutter/material.dart';
import 'package:neverland_flutter/screen/login.dart'; // ✅ LoginScreen이 정의된 파일 import
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ko');
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: LoginScreen(), // ✅ 여기를 LoginScreen으로!
    ),
  );
}
