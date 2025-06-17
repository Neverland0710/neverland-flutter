import 'package:flutter/material.dart';
import 'package:neverland_flutter/model/letter.dart';

/// 편지 상세 화면
class LetterDetailPage extends StatelessWidget {
  final Letter letter;

  const LetterDetailPage({super.key, required this.letter});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE9F0F9), // 배경 연한 블루
      appBar: AppBar(
        backgroundColor: const Color(0xFFE9F0F9), // 앱바도 동일 배경색
        elevation: 0,
        leading: const BackButton(color: Colors.black), // 뒤로가기 버튼
        title: const Text(
          '내게 온 편지', // 상단 제목
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            fontFamily: 'Pretendard',
            color: Colors.black,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0), // 전체 패딩
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),

              // 수신자 정보
              const Text(
                'TO. 정동연',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Pretendard',
                ),
              ),

              const SizedBox(height: 24),

              // 편지 내용 카드 UI
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 편지 제목
                    Text(
                      letter.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Pretendard',
                      ),
                    ),
                    const SizedBox(height: 12),

                    // 편지 내용
                    Text(
                      letter.content,
                      style: const TextStyle(
                        fontSize: 14,
                        fontFamily: 'Pretendard',
                        height: 1.7,
                      ),
                    ),
                  ],
                ),
              ),

              // 카드 하단 간격
              const SizedBox(height: 0),

              // 하단 시스템 패딩 고려
              SizedBox(height: MediaQuery.of(context).padding.bottom + 20),

              // 답장 대기 UI
              Center(
                child: Column(
                  children: [
                    // 안내 텍스트
                    const Text(
                      '답장을 기다리는 중이에요',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Pretendard',
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 대기 이미지
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.asset(
                        'asset/image/letter_waiting.jpg',
                        width: 280,
                        height: 280,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 답장 보기 버튼
                    SizedBox(
                      width: 200,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () {
                          // 답장 열람 액션 (추후 연결)
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xBFBFBF), // 연한 회색 (비활성 느낌)
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          '지금 답장 열어보기',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Pretendard',
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 하단 여백
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
