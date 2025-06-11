import 'package:flutter/material.dart';
import 'package:neverland_project/screen/home_screen.dart';  //lib에 있는 파일을 불러옴

void main() {
  runApp(
    MaterialApp(
        home: HomeScreen()  // import 없이 Show context Action을 이용하면 import 자동완성
    ),

  );
}

