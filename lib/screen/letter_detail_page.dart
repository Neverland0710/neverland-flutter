import 'package:flutter/material.dart';
import 'package:neverland_flutter/model/letter.dart';
import 'package:neverland_flutter/screen/letter_reply_detail_page.dart';
import 'package:lottie/lottie.dart';

/// 편지 상세 화면을 보여주는 StatelessWidget
/// 사용자가 받은 편지의 내용을 표시하고, 답장 도착 여부에 따라 다른 UI를 제공
class LetterDetailPage extends StatelessWidget {
  final Letter letter; // 표시할 편지 객체

  const LetterDetailPage({super.key, required this.letter});

  @override
  Widget build(BuildContext context) {
    // 편지에 대한 답장이 도착했는지 확인
    final bool isArrived = letter.isArrived; // ✅ 답장 도착 여부

    return Scaffold(
      // 배경색을 흰색으로 설정
      backgroundColor: const Color(0xFFFFFFFF),

      // 상단 앱바 설정
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFFFFF), // 앱바 배경색 흰색
        elevation: 0, // 그림자 제거
        leading: const BackButton(color: Colors.black), // 뒤로가기 버튼
        title: const Text(
          '내게 온 편지', // 앱바 제목
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            fontFamily: 'Pretendard',
            color: Colors.black,
          ),
        ),
      ),

      body: SafeArea(
        child: SingleChildScrollView( // 스크롤 가능한 영역
          padding: const EdgeInsets.all(24.0), // 전체 패딩 24px
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, // 왼쪽 정렬
            children: [
              const SizedBox(height: 8), // 상단 여백

              // 편지 수신자 표시 (TO. 정동연)
              const Text(
                'TO. 정동연',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Pretendard',
                ),
              ),

              const SizedBox(height: 24), // 여백

              // 편지 내용을 담는 카드형 컨테이너
              Container(
                width: double.infinity, // 전체 너비 사용
                padding: const EdgeInsets.all(20), // 내부 패딩 20px
                decoration: BoxDecoration(
                  color: Colors.white, // 배경색 흰색
                  borderRadius: BorderRadius.circular(16), // 모서리 둥글게 16px
                  // 그림자 효과 추가
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05), // 5% 투명도의 검은 그림자
                      blurRadius: 8, // 블러 효과 8px
                      offset: const Offset(0, 4), // Y축으로 4px 이동
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, // 왼쪽 정렬
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
                    const SizedBox(height: 12), // 제목과 내용 사이 여백

                    // 편지 내용
                    Text(
                      letter.content,
                      style: const TextStyle(
                        fontSize: 14,
                        fontFamily: 'Pretendard',
                        height: 1.7, // 줄간격 1.7배
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24), // 여백

              // 하단 중앙 정렬 영역 (애니메이션과 버튼)
              Center(
                child: Column(
                  children: [
                    // 답장 도착 상태에 따른 메시지 표시
                    Text(
                      isArrived
                          ? '편지 답장이 도착했어요!' // 답장이 도착한 경우
                          : '답장을 기다리는 중이에요', // 답장을 기다리는 경우
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Pretendard',
                      ),
                    ),

                    const SizedBox(height: 16), // 여백

                    // Lottie 애니메이션 영역
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16), // 모서리 둥글게
                      child: isArrived
                      // 답장이 도착한 경우: 편지 열기 애니메이션
                          ? Lottie.asset(
                        'asset/animation/letter_open.json',
                        width: 280,
                        height: 280,
                        fit: BoxFit.cover,
                        repeat: false, // 한 번만 재생
                      )
                      // 답장을 기다리는 경우: 편지 닫기 애니메이션
                          : Lottie.asset(
                        'asset/animation/letter_close.json',
                        width: 280,
                        height: 280,
                        fit: BoxFit.cover,
                        repeat: true, // 반복 재생
                      ),
                    ),

                    const SizedBox(height: 24), // 여백

                    // 답장 열어보기 버튼
                    SizedBox(
                      width: 200, // 버튼 너비 고정
                      height: 48, // 버튼 높이 고정
                      child: ElevatedButton(
                        // 답장이 도착한 경우에만 버튼 활성화
                        onPressed: isArrived
                            ? () {
                          // 답장 상세 페이지로 이동
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => LetterReplyDetailPage(
                                // 답장 내용 전달 (없으면 기본 메시지)
                                replyLetter: letter.replyContent ?? '나도 외롭다 시발아',
                              ),
                            ),
                          );
                        }
                            : null, // 답장이 없으면 버튼 비활성화
                        style: ElevatedButton.styleFrom(
                          // 답장 도착 여부에 따른 버튼 색상 변경
                          backgroundColor: isArrived
                              ? const Color(0xFFBB9DF7) // 활성화: 보라색
                              : const Color(0xFFBFBFBF), // 비활성화: 회색
                          disabledBackgroundColor: const Color(0xFFBFBFBF), // 비활성화 색상
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12), // 모서리 둥글게
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

              const SizedBox(height: 20), // 하단 여백
            ],
          ),
        ),
      ),
    );
  }
}