import 'package:flutter/material.dart';
import 'package:neverland_flutter/screen/terms_agreement_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  Future<void> handleGoogleLogin(BuildContext context) async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        print("❌ 로그인 취소됨");
        return;
      }

      final GoogleSignInAuthentication googleAuth =
      await googleUser.authentication;

      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);

      final String? idToken =
      await FirebaseAuth.instance.currentUser?.getIdToken(true);

      if (idToken == null) {
        print("❌ idToken 발급 실패");
        return;
      }

      print("✅ 전송할 Firebase idToken (앞부분): ${idToken.substring(0, 50)}");

      final response = await http.
      post(
        Uri.parse("http://192.168.219.68:8000/auth/social-login"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'provider': 'google',
          'access_token': idToken,
        }),
      );

      if (response.statusCode == 200) {
        print("✅ FastAPI 응답 성공: ${response.body}");
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const TermsAgreementScreen(),
          ),
        );
      } else {
        print("❌ FastAPI 오류: ${response.statusCode} ${response.body}");
      }
    } catch (e) {
      print("❌ 로그인 처리 중 예외 발생: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8E4FF),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 200),
              Image.asset(
                'asset/image/neverland_logo.png',
                width: 360,
                height: 120, // 원하면 비율 맞춰서 높이도 직접 지정 가능
                fit: BoxFit.contain, // 이미지가 비율 유지하며 잘 들어오게
              ),

              const SizedBox(height: 12),
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
              const Spacer(),
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
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: () => handleGoogleLogin(context),
                  icon: Image.asset('asset/image/google_icon.png', height: 24),
                  label: const Text(
                    '구글로 계속하기',
                    style: TextStyle(
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
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
