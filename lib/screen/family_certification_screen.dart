import 'package:flutter/material.dart';
import 'package:neverland_flutter/screen/code_input_screen.dart';

class FamilyCertificationScreen extends StatelessWidget {
  const FamilyCertificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE9F0F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFFE9F0F9),
        elevation: 0,
        leading: const BackButton(color: Colors.black),
        title: const Text(
          '가족 인증',
          style: TextStyle(
            fontFamily: 'Pretendard',
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            const Text(
              '서비스의 원활한 이용을 위해\n가족관계증명서를 첨부해주세요',
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 60),

            // 원형 업로드 버튼 (임시 파란 원)
            Center(
              child: Container(
                width: 150,
                height: 150,
                decoration: const BoxDecoration(
                  color: Color(0xFF7FA8D7),
                  shape: BoxShape.circle,
                ),
              ),
            ),

            const Spacer(),

            // 다음 버튼
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CodeInputScreen(), // 여기 연결
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7FA8D7),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  '다음',
                  style: TextStyle(
                    fontFamily: 'Pretendard',
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }
}
