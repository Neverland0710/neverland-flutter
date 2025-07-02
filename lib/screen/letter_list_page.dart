import 'dart:async'; // ⏱ 자동 갱신을 위한 타이머
import 'package:flutter/material.dart';
import 'package:neverland_flutter/model/letter.dart';
import 'package:neverland_flutter/screen/letter_detail_page.dart';
import 'package:neverland_flutter/screen/main_page.dart';

/// 편지 목록을 표시하는 StatefulWidget
/// 사용자가 보낸 편지들의 목록을 보여주고, 답장 도착 상태를 실시간으로 업데이트
class LetterListPage extends StatefulWidget {
  final List<Letter> letters; // 표시할 편지 목록

  const LetterListPage({super.key, required this.letters});

  @override
  State<LetterListPage> createState() => _LetterListPageState();
}

class _LetterListPageState extends State<LetterListPage> {
  Timer? _timer; // ✅ 타이머 저장할 변수 (자동 갱신용)

  @override
  void initState() {
    super.initState();

    // ⏱ 편지 답장 도착 여부 체크를 위해 1초마다 화면 갱신
    // 실시간으로 편지 상태 변화를 반영하기 위한 타이머 설정
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      // 위젯이 아직 마운트된 상태인지 확인 (메모리 누수 방지)
      if (mounted) {
        setState(() {}); // 화면 다시 그리기
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel(); // ✅ 위젯이 파괴될 때 타이머 종료 (메모리 누수 방지)
    super.dispose();
  }

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
          '하늘에서 온 편지', // 앱바 제목
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            fontFamily: 'Pretendard',
            color: Colors.black,
          ),
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.all(20), // 전체 패딩 20px
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, // 왼쪽 정렬
          children: [
            // 📦 편지 총 개수 표시
            Text(
                '총 ${widget.letters.length}건',
                style: const TextStyle(fontSize: 14)
            ),
            const Divider(height: 20), // 구분선

            // 📬 편지 목록을 스크롤 가능한 리스트로 표시
            Expanded(
              child: ListView.builder(
                itemCount: widget.letters.length, // 편지 개수만큼 리스트 아이템 생성
                itemBuilder: (context, index) {
                  final letter = widget.letters[index]; // 현재 편지 객체
                  final isArrived = letter.isArrived; // 답장 도착 여부

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0), // 각 아이템 하단 여백
                    child: Container(
                      // 편지 아이템 컨테이너 스타일링
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        // 답장 도착 여부에 따른 배경색 변경
                        color: isArrived
                            ? Colors.white      // 답장 도착: 흰색
                            : Colors.grey[300], // 답장 대기: 회색
                        borderRadius: BorderRadius.circular(12), // 모서리 둥글게
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween, // 양쪽 끝 정렬
                        children: [
                          // 📝 편지 정보 영역 (제목 + 날짜)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start, // 왼쪽 정렬
                            children: [
                              // 편지 제목
                              Text(
                                letter.title,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Pretendard',
                                  // 답장 도착 여부에 따른 텍스트 색상 변경
                                  color: isArrived
                                      ? Colors.black      // 답장 도착: 검은색
                                      : Colors.black45,   // 답장 대기: 연한 검은색
                                ),
                              ),
                              const SizedBox(height: 4), // 제목과 날짜 사이 여백

                              // 편지 작성 날짜
                              Text(
                                letter.formattedDate,
                                style: TextStyle(
                                  fontSize: 13,
                                  // 답장 도착 여부에 따른 날짜 색상 변경
                                  color: isArrived
                                      ? Colors.grey       // 답장 도착: 회색
                                      : Colors.grey[600], // 답장 대기: 진한 회색
                                ),
                              ),
                            ],
                          ),

                          // 📨 편지 상세보기 버튼
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFBB9DF7), // 보라색 배경
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8), // 모서리 둥글게
                              ),
                            ),
                            // 버튼 클릭 시 편지 상세 페이지로 이동
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => LetterDetailPage(letter: letter),
                                ),
                              );
                            },
                            child: const Text(
                              '답장 도착',
                              style: TextStyle(color: Colors.white),
                            ),
                          )
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 20), // 리스트와 버튼 사이 여백

            // 📝 메인 페이지로 돌아가기 버튼
            Padding(
              padding: const EdgeInsets.only(bottom: 42), // 하단 여백 42px
              child: SizedBox(
                width: double.infinity, // 전체 너비 사용
                height: 48, // 버튼 높이 고정
                child: ElevatedButton(
                  onPressed: () {
                    // 모든 이전 페이지를 제거하고 메인 페이지로 이동
                    // 편지 목록에서 왔다는 정보를 전달 (fromLetter: true)
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const MainPage(fromLetter: true)
                      ), // ✅ 편지에서 왔다는 플래그 전달
                          (route) => false, // 모든 이전 라우트 제거
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFBB9DF7), // 보라색 배경
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12), // 모서리 둥글게
                    ),
                  ),
                  child: const Text(
                    '메인으로 돌아가기',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}