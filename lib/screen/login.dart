import 'package:flutter/material.dart';
import 'package:neverland_flutter/screen/terms_agreement_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isSigningIn = false;

  Future<void> handleGoogleLogin(BuildContext context) async {
    if (_isSigningIn) return;
    setState(() {
      _isSigningIn = true;
    });

    try {
      await FirebaseAuth.instance.signOut();

      final GoogleSignIn googleSignIn = GoogleSignIn();
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        print("❌ 로그인 취소됨");
        setState(() {
          _isSigningIn = false;
        });
        return;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);
      final String? idToken = await FirebaseAuth.instance.currentUser?.getIdToken(true);

      if (idToken == null) {
        print("❌ idToken 발급 실패");
        setState(() {
          _isSigningIn = false;
        });
        return;
      }

      print("🔥 Firebase ID Token: $idToken");

      final response = await http.post(
        Uri.parse("http://192.168.219.68:8086/auth/social-login"),
        headers: {
          'Authorization': 'Bearer $idToken', // ✅ 헤더로 전달해야 Firebase 검증됨!
          'Content-Type': 'application/json',
        },
        body: jsonEncode({}), // ✅ 내용 없이 보내도 OK (ID Token은 헤더에 있음)

      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final jwt = responseData['access_token'];

        final storage = FlutterSecureStorage();
        await storage.write(key: 'jwt', value: jwt);

        if (!context.mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const TermsAgreementScreen()),
        );
      } else {
        print("❌ FastAPI 오류: ${response.statusCode} ${response.body}");
      }
    } catch (e, stackTrace) {
      print("❌ 로그인 처리 중 예외 발생: $e");
      print("📛 StackTrace: $stackTrace");
    } finally {
      if (mounted) {
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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 200),
              Image.asset(
                'asset/image/neverland_logo.png',
                width: 360,
                height: 120,
                fit: BoxFit.contain,
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
