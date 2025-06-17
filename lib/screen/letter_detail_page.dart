import 'package:flutter/material.dart';
import 'package:neverland_flutter/model/letter.dart';

/// 편지 상세 화면
class LetterDetailPage extends StatelessWidget {
  final Letter letter;

  const LetterDetailPage({super.key, required this.letter});

  @override
  Widget build(BuildContext context) {
    final bool isArrived = letter.isArrived; // ✅ 답장 도착 여부

    return Scaffold(
      backgroundColor: const Color(0xFFE9F0F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFFE9F0F9),
        elevation: 0,
        leading: const BackButton(color: Colors.black),
        title: const Text(
          '내게 온 편지',
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
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              const Text(
                'TO. 정동연',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Pretendard',
                ),
              ),
              const SizedBox(height: 24),
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
                    Text(
                      letter.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Pretendard',
                      ),
                    ),
                    const SizedBox(height: 12),
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
              const SizedBox(height: 24),
              Center(
                child: Column(
                  children: [
                    Text(
                      isArrived
                          ? '편지 답장이 도착했어요!'
                          : '답장을 기다리는 중이에요',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Pretendard',
                      ),
                    ),
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.asset(
                        isArrived
                            ? 'asset/image/letter_arrived.jpg'
                            : 'asset/image/letter_waiting.jpg',
                        width: 280,
                        height: 280,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: 200,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () {
                          if (isArrived) {
                            // ✅ 답장이 도착했다면 이동할 화면 연결
                            // Navigator.push(context, MaterialPageRoute(...));
                          } else {
                            // 도착 전이면 비활성 or 무반응
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isArrived
                              ? const Color(0xFF90B4E0)
                              : const Color(0xFFBFBFBF),
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
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
