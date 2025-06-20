import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:neverland_flutter/screen/login.dart';
import 'package:neverland_flutter/screen/main_page.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart'; // ✅ Firebase Core import

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  ); // ✅ Firebase 초기화
  await initializeDateFormatting('ko'); // ✅ 한국어 날짜 포맷 초기화

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  static const storage = FlutterSecureStorage();

  Future<bool> isLoggedIn() async {
    final token = await storage.read(key: 'jwt');
    return token != null && token.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: FutureBuilder<bool>(
        future: isLoggedIn(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (snapshot.data == true) {
            return const MainPage(); // JWT 있으면 메인페이지로
          } else {
            return const LoginScreen(); // 없으면 로그인페이지로
          }
        },
      ),
    );
  }
}
