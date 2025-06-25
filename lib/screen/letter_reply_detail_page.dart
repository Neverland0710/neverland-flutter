import 'package:flutter/material.dart';

class LetterReplyDetailPage extends StatelessWidget {
  final String replyLetter;

  const LetterReplyDetailPage({
    super.key,
    required this.replyLetter,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFFFFF),
        elevation: 0,
        leading: const BackButton(color: Colors.black),
        title: const Text(
          '답장 보기',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            fontFamily: 'Pretendard',
            color: Colors.black,
          ),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 320),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8E7),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.brown.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.brown.withOpacity(0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min, // ✅ 카드가 내용 크기만큼만
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '고인으로부터의 답장',
                  style: TextStyle(
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.brown,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  replyLetter,
                  style: const TextStyle(
                    fontFamily: 'Pretendard',
                    fontSize: 14,
                    height: 1.7,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
