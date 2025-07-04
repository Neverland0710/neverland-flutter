import 'package:flutter/material.dart';

/// 편지에 대한 답장 내용을 보여주는 StatelessWidget
/// 고인으로부터 온 답장을 편지지 형태의 카드로 표시
class LetterReplyDetailPage extends StatelessWidget {
  final String replyLetter; // 표시할 답장 내용 텍스트

  const LetterReplyDetailPage({
    super.key,
    required this.replyLetter,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 배경색을 흰색으로 설정
      backgroundColor: const Color(0xFFFFFFFF),

      // 상단 앱바 설정
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFFFFF), // 앱바 배경색 흰색
        elevation: 0, // 그림자 제거
        leading: const BackButton(color: Colors.black), // 뒤로가기 버튼
        title: const Text(
          '답장 보기', // 앱바 제목
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold, // FontWeight.bold 사용
            fontFamily: 'Pretendard',
            color: Colors.black,
          ),
        ),
      ),

      body: Center( // 전체 내용을 중앙 정렬
        child: SingleChildScrollView( // 스크롤 가능한 영역
          // 좌우 24px, 상하 40px 패딩
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Container(
            // 답장 카드의 최대 너비를 320px로 제한 (편지지 느낌)
            constraints: const BoxConstraints(maxWidth: 320),
            padding: const EdgeInsets.all(20), // 카드 내부 패딩 20px

            // 편지지 스타일의 카드 디자인
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8E7), // 연한 크림색 배경 (편지지 느낌)
              borderRadius: BorderRadius.circular(16), // 모서리 둥글게 16px
              border: Border.all(color: Colors.brown.shade200), // 연한 갈색 테두리

              // 그림자 효과로 입체감 추가
              boxShadow: [
                BoxShadow(
                  color: Colors.brown.withOpacity(0.08), // 8% 투명도의 갈색 그림자
                  blurRadius: 8, // 블러 효과 8px
                  offset: const Offset(0, 4), // Y축으로 4px 이동
                ),
              ],
            ),

            child: Column(
              mainAxisSize: MainAxisSize.min, // 카드가 내용 크기만큼만 차지
              crossAxisAlignment: CrossAxisAlignment.start, // 왼쪽 정렬
              children: [
                // 답장 제목 영역
                const Text(
                  '고인으로부터의 답장',
                  style: TextStyle(
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.brown, // 갈색 텍스트로 고급스러운 느낌
                  ),
                ),

                const SizedBox(height: 12), // 제목과 내용 사이 여백

                // 답장 내용 텍스트
                Text(
                  replyLetter.isEmpty ? '답장이 아직 없습니다.' : replyLetter, // 빈 값이면 기본 메시지
                  style: const TextStyle(
                    fontFamily: 'Pretendard',
                    fontSize: 14,
                    height: 1.7, // 줄간격 1.7배로 가독성 향상
                    color: Colors.black87, // 약간 연한 검은색 (부드러운 느낌)
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