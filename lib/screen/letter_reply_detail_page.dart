import 'package:flutter/material.dart';

class LetterReplyDetailPage extends StatelessWidget {
  final String originalLetter;
  final String replyLetter;

  const LetterReplyDetailPage({
    super.key,
    required this.originalLetter,
    required this.replyLetter,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE9F0F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFFE9F0F9),
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
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            _buildLetterCard(
              title: '내가 쓴 편지',
              content: originalLetter,
              backgroundColor: Colors.white,
            ),
            const SizedBox(height: 24),
            _buildLetterCard(
              title: '고인으로부터의 답장',
              content: replyLetter,
              backgroundColor: const Color(0xFFDEE6EF), // 감성적인 하늘빛 카드
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLetterCard({
    required String title,
    required String content,
    required Color backgroundColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: backgroundColor,
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
            title,
            style: const TextStyle(
              fontFamily: 'Pretendard',
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: const TextStyle(
              fontFamily: 'Pretendard',
              fontSize: 14,
              height: 1.6,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
