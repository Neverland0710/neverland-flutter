import 'package:flutter/material.dart';
import 'package:neverland_flutter/screen/letter_write_page.dart';
import 'package:neverland_flutter/screen/voice_call_screen.dart';
import 'package:neverland_flutter/screen/chat_page.dart';

class MainPage extends StatelessWidget {
  const MainPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ✅ 상단 배경 이미지
// 수정 코드
            Container(
              width: double.infinity,
              height: 250,
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
                image: DecorationImage(
                  image: AssetImage('asset/image/main_header.png'),
                  fit: BoxFit.cover,
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: 20,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Image.asset(
                        'asset/image/neverland_logo.png',
                        width: 200,
                      ),
                    ),
                  ),
                  const Positioned(
                    bottom: 16,
                    left: 16,
                    child: Text(
                      '안녕하세요\n기억을 잇는 따뜻한 공간 네버랜드입니다',
                      style: TextStyle(
                        fontFamily: 'Pretendard',
                        fontSize: 20,
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ✅ 메뉴 영역
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 32),
                  const Text(
                    '오늘은 어떤 기억을 함께 나눠볼까요?',
                    style: TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 40),

                  _buildMenuButton(context, '실시간 통화'),
                  _buildMenuButton(context, '실시간 채팅'),
                  _buildMenuButton(context, '내게 온 편지'),
                  _buildMenuButton(context, '설정'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuButton(BuildContext context, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 40),
      child: InkWell(
        onTap: () {
          if (label == '실시간 통화') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const VoiceCallScreen(),
              ),
            );
          } else if (label == '실시간 채팅') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const RealTimeChatPage(),
              ),
            );
          } else if (label == '내게 온 편지') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const LetterWritePage(),
              ),
            );
          }
          // ⚠️ 설정 누를 때는 아직 아무 작업 없음
        },
        child: Container(
          height: 65,
          decoration: BoxDecoration(
            color: const Color(0xFFBB9DF7),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  label,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1.5,
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Icon(Icons.arrow_forward_ios_rounded,
                    color: Colors.black, size: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
