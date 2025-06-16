import 'package:flutter/material.dart';
import 'package:neverland_flutter/screen/terms_agreement_screen.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE9F0F9),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 60), // 상단 여백

              // 로고
              Image.asset(
                'asset/image/neverland_logo.png',
                width: 300,
              ),
              const SizedBox(height: 12),

              // 서브 텍스트
              const Text(
                '기억을 잇는 따뜻한 공간',
                style: TextStyle(
                  fontFamily: 'Pretendard',
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  height: 1.35,
                  color: Color(0xFF173560),
                ),
              ),

              const Spacer(), // ✅ 버튼을 아래로 밀어내는 핵심 요소

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
                  icon: Image.asset(
                    'asset/image/kakao_icon.png',
                    height: 24,
                  ),
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
                      borderRadius: BorderRadius.circular(8),
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
                  onPressed: () {},
                  icon: Image.asset(
                    'asset/image/google_icon.png',
                    height: 24,
                  ),
                  label: const Text(
                    '구글로 계속하기',
                    style: TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 16,
                      color: Colors.black,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.black26),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
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
                  icon: Image.asset(
                    'asset/image/apple_icon.png',
                    height: 24,
                  ),
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
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(height: 40), // 하단 여백
            ],
          ),
        ),
      ),
    );
  }

}
