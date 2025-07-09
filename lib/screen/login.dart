import 'package:flutter/material.dart';
import 'package:neverland_flutter/screen/terms_agreement_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 로그인 화면을 담당하는 StatefulWidget
/// 구글, 카카오, 애플 로그인 옵션을 제공
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // 로그인 진행 중 상태를 관리하는 변수 (중복 클릭 방지용)
  bool _isSigningIn = false;

  /// 구글 로그인 처리 함수
  /// Firebase Authentication과 백엔드 서버 연동을 통한 완전한 로그인 플로우
  Future<void> handleGoogleLogin(BuildContext context) async {
    // 이미 로그인 중이면 중복 실행 방지
    if (_isSigningIn) return;

    // 로그인 시작 - UI 상태 업데이트
    setState(() {
      _isSigningIn = true;
    });

    try {
      // 기존 Firebase 세션 정리 (깨끗한 로그인을 위해)
      await FirebaseAuth.instance.signOut();

      // Google Sign-In 인스턴스 생성
      final GoogleSignIn googleSignIn = GoogleSignIn();

      // 구글 로그인 팝업 표시 및 사용자 계정 선택
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      // 사용자가 로그인을 취소한 경우
      if (googleUser == null) {
        print("❌ 로그인 취소됨");
        setState(() {
          _isSigningIn = false;
        });
        return;
      }

      // 구글 인증 정보 획득 (accessToken, idToken)
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Firebase용 OAuth 자격증명 생성
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Firebase에 구글 계정으로 로그인
      await FirebaseAuth.instance.signInWithCredential(credential);

      // Firebase에서 JWT ID Token 발급 (백엔드 인증용)
      final String? idToken = await FirebaseAuth.instance.currentUser?.getIdToken(true);

      // ID Token 발급 실패 시 처리
      if (idToken == null) {
        print("❌ idToken 발급 실패");
        setState(() {
          _isSigningIn = false;
        });
        return;
      }

      print("🔥 Firebase ID Token: $idToken");

      // 백엔드 서버에 소셜 로그인 요청
      final response = await http.post(
        Uri.parse("http://52.78.139.47:8086/auth/social-login"), // 백엔드 API 엔드포인트
        headers: {
          'Authorization': 'Bearer $idToken', // Firebase ID Token을 Bearer 토큰으로 전달
          'Content-Type': 'application/json',
        },
        body: jsonEncode({}), // 빈 객체 전송 (ID Token은 헤더에 포함되어 있음)
      );

      // 서버 응답이 성공(200)인 경우
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final jwt = responseData['access_token'];
        final authKeyId = responseData['authKeyId'];
        final userId = responseData['user_id']; // ✅ 추가

        if (authKeyId == null || userId == null) {
          //print('❌ authKeyId 또는 userId 응답에 없음!');
        } else {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('authKeyId', authKeyId); // ✅ 일치시켜야 함
          await prefs.setString('user_id', responseData['user_id']); // ✅ 일치시켜야 함
          print('✅ SharedPreferences 저장 완료: $authKeyId / ${responseData['user_id']}');
        }
        const storage = FlutterSecureStorage();
        await storage.write(key: 'jwt', value: jwt);

        if (!context.mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const TermsAgreementScreen()),
        );
      } else {
        // 서버 오류 응답 처리
        print("❌ FastAPI 오류: ${response.statusCode} ${response.body}");
      }
    } catch (e, stackTrace) {
      // 예외 발생 시 에러 로깅
      print("❌ 로그인 처리 중 예외 발생: $e");
      print("📛 StackTrace: $stackTrace");
    } finally {
      // 로그인 프로세스 완료 - UI 상태 복원
      if (mounted) { // Widget이 여전히 존재하는지 확인
        setState(() {
          _isSigningIn = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8E4FF),
      body: SafeArea(
        child: Container(
          width: double.infinity,
          height: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(flex: 2),

              // 네버랜드 로고 이미지
              Image.asset(
                'asset/image/neverland_logo.png',
                width: 360,
                height: 120,
                fit: BoxFit.contain,
              ),

              const SizedBox(height: 12),

              // 앱 설명 텍스트
              const Text(
                '기억을 잇는 따뜻한 공간',
                style: TextStyle(
                  fontFamily: 'Pretendard',
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                  height: 1.35,
                  color: Color(0xFFBB9DF7),
                ),
              ),

              const Spacer(flex: 3),

              // 로그인 버튼들
              Column(
                children: [
                  // 카카오 로그인 버튼
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const TermsAgreementScreen(),
                          ),
                        );
                      },
                      icon: Image.asset('asset/image/kakao_icon.png', height: 24),
                      label: const Text(
                        '카카오 로그인',
                        style: TextStyle(
                          fontFamily: 'Pretendard',
                          fontSize: 16,
                          color: Colors.black,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFE812),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // 구글 로그인 버튼
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: _isSigningIn
                          ? null
                          : () => handleGoogleLogin(context),
                      icon: Image.asset('asset/image/google_icon.png', height: 24),
                      label: Text(
                        _isSigningIn ? '로그인 중...' : '구글로 계속하기',
                        style: const TextStyle(
                          fontFamily: 'Pretendard',
                          fontSize: 16,
                          color: Colors.black,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white,
                        side: const BorderSide(color: Colors.black26),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // 애플 로그인 버튼
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: () {},
                      icon: Image.asset('asset/image/apple_icon.png', height: 24),
                      label: const Text(
                        'Apple로 계속하기',
                        style: TextStyle(
                          fontFamily: 'Pretendard',
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),

              const Spacer(flex: 1),
            ],
          ),
        ),
      ),
    );
  }
}