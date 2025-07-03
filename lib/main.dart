// Flutter와 Material Design 위젯을 사용하기 위한 패키지 임포트
import 'package:flutter/material.dart';
// 보안 스토리지에 데이터를 저장/읽기 위한 패키지 임포트
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
// 앱의 지역화(로컬라이제이션)를 지원하기 위한 패키지 임포트
import 'package:flutter_localizations/flutter_localizations.dart';
// 로그인 화면으로 이동하기 위해 필요한 파일 임포트
import 'package:neverland_flutter/screen/login.dart';
// 메인 페이지로 이동하기 위해 필요한 파일 임포트
import 'package:neverland_flutter/screen/main_page.dart';
// 날짜 형식을 지역화하기 위한 패키지 임포트
import 'package:intl/date_symbol_data_local.dart';
// Firebase 초기화를 위한 패키지 임포트
import 'package:firebase_core/firebase_core.dart';
// Firebase 설정 옵션을 포함한 파일 임포트
import 'firebase_options.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';


// 앱의 진입점(main 함수)
void main() async {
  // Flutter 엔진과 위젯 바인딩 초기화
  WidgetsFlutterBinding.ensureInitialized();
  // Firebase 초기화 (Firebase 설정 옵션 사용)
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // 한국어 날짜 포맷 데이터 초기화
  await initializeDateFormatting('ko');

  await dotenv.load(fileName: ".env");
  // 앱 실행
  runApp(const MyApp());
}

// 앱의 루트 위젯을 정의하는 StatelessWidget
class MyApp extends StatelessWidget {
  const MyApp({super.key});
  // 보안 스토리지 인스턴스 생성 (JWT 토큰 저장/읽기용)
  static const storage = FlutterSecureStorage();

  // 로그인 상태를 확인하는 비동기 함수
  Future<bool> isLoggedIn() async {
    // JWT 토큰을 보안 스토리지에서 읽어옴
    final token = await storage.read(key: 'jwt');
    // 토큰이 null이 아니고 빈 문자열이 아닌 경우 로그인 상태로 간주
    return token != null && token.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // 디버그 배너 비활성화
      locale: const Locale('ko'), // 앱의 기본 언어를 한국어로 설정
      supportedLocales: const [Locale('ko')], // 지원하는 언어 목록 (한국어만)
      localizationsDelegates: const [
        // Material 위젯의 지역화 지원
        GlobalMaterialLocalizations.delegate,
        // 기본 위젯의 지역화 지원
        GlobalWidgetsLocalizations.delegate,
        // Cupertino(iOS 스타일) 위젯의 지역화 지원
        GlobalCupertinoLocalizations.delegate,
      ],
      home: FutureBuilder<bool>(
        // 로그인 상태 확인을 위해 isLoggedIn 함수 호출
        future: isLoggedIn(),
        builder: (context, snapshot) {
          // Future가 아직 완료되지 않은 경우 로딩 인디케이터 표시
          if (snapshot.connectionState != ConnectionState.done) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          // 로그인 상태에 따라 화면 분기
          if (snapshot.data == true) {
            // 로그인된 경우 MainPage로 이동
            return const MainPage();
          } else {
            // 로그인되지 않은 경우 LoginScreen으로 이동
            return const LoginScreen();
          }
        },
      ),
    );
  }
}