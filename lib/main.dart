import 'package:flutter/material.dart';
import 'package:neverland_flutter/screen/main_page.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // ✅ 비동기 초기화를 위해 필요
  await initializeDateFormatting('ko');      // ✅ 한국어 날짜 로케일 초기화
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MainPage(),
    ),
  );
}
