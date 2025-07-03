import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:neverland_flutter/model/letter.dart';
import 'package:neverland_flutter/screen/letter_detail_page.dart';
import 'package:neverland_flutter/screen/letter_write_page.dart';
import 'package:neverland_flutter/screen/main_page.dart';

/// 편지 목록을 보여주는 페이지
/// 사용자가 작성한 편지들과 답장이 온 편지들을 확인할 수 있음
class LetterListPage extends StatefulWidget {
  const LetterListPage({super.key});

  @override
  State<LetterListPage> createState() => _LetterListPageState();
}

class _LetterListPageState extends State<LetterListPage> {
  Timer? _timer; // 편지 도착 상태를 실시간으로 업데이트하기 위한 타이머
  List<Letter> _letters = []; // 서버에서 가져온 편지 목록을 저장하는 리스트

  @override
  void initState() {
    super.initState();
    // 페이지 로드 시 서버에서 편지 목록을 가져옴
    _loadLettersFromServer();

    // 1초마다 화면을 갱신하여 편지 도착 시간을 실시간으로 업데이트
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {}); // 위젯이 마운트된 상태에서만 업데이트
    });
  }

  @override
  void dispose() {
    // 메모리 누수 방지를 위해 타이머 해제
    _timer?.cancel();
    super.dispose();
  }

  /// 서버에서 편지 목록을 가져오는 함수
  Future<void> _loadLettersFromServer() async {
    // SharedPreferences에서 인증키 가져오기
    final prefs = await SharedPreferences.getInstance();
    final authKeyId = prefs.getString('auth_key_id');

    // 인증키가 없으면 함수 종료
    if (authKeyId == null || authKeyId.isEmpty) {
      print('❌ auth_key_id 없음');
      return;
    }

    try {
      // 서버 API 호출 - 편지 목록 요청
      final response = await http.get(
        Uri.parse('http://192.168.219.68:8086/letter/list?authKeyId=$authKeyId'),
      );

      // HTTP 응답이 성공(200-299)인 경우
      if (response.statusCode >= 200 && response.statusCode < 300) {
        // JSON 응답을 파싱하여 List<dynamic>으로 변환
        final List<dynamic> jsonList = jsonDecode(response.body);

        // 상태 업데이트 - JSON 데이터를 Letter 객체로 변환
        setState(() {
          _letters = jsonList.map((e) {
            return Letter(
              title: e['title'],           // 편지 제목
              content: e['content'],       // 편지 내용
              createdAt: DateTime.parse(e['createdAt']), // 작성 시간
            );
          }).toList();
        });
      } else {
        // HTTP 에러 응답 처리
        print('❌ 서버 오류: ${response.statusCode}');
      }
    } catch (e) {
      // 네트워크 오류 또는 기타 예외 처리
      print('❌ 네트워크 오류: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF), // 배경색 설정 (흰색)
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFFFFF), // 앱바 배경색
        elevation: 0, // 그림자 제거
        leading: const BackButton(color: Colors.black), // 뒤로 가기 버튼
        title: const Text(
          '하늘에서 온 편지',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            fontFamily: 'Pretendard',
            color: Colors.black,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20), // 전체 여백 설정
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 편지 총 개수 표시
            Text('총 ${_letters.length}건', style: const TextStyle(fontSize: 14)),
            const Divider(height: 20), // 구분선

            // 편지 작성하기 버튼
            ElevatedButton(
              onPressed: () async {
                // 편지 작성 페이지로 이동하고 결과 받기
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LetterWritePage()),
                );

                if (result == true) {
                  _loadLettersFromServer();  // 편지 목록 새로고침
                }

              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFBB9DF7), // 보라색 배경
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                '편지 작성하기',
                style: TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(height: 20), // 간격

            // 편지 목록을 보여주는 리스트뷰
            Expanded(
              child: ListView.builder(
                itemCount: _letters.length, // 편지 개수만큼 리스트 생성
                itemBuilder: (context, index) {
                  final letter = _letters[index]; // 현재 인덱스의 편지
                  final isArrived = letter.isArrived; // 답장 도착 여부 확인

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        // 답장이 도착했으면 흰색, 아니면 회색 배경
                        color: isArrived ? Colors.white : Colors.grey[300],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // 편지 정보 (제목, 날짜)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 편지 제목
                              Text(
                                letter.title,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Pretendard',
                                  // 답장 도착 여부에 따른 텍스트 색상 변경
                                  color: isArrived ? Colors.black : Colors.black45,
                                ),
                              ),
                              const SizedBox(height: 4),
                              // 편지 작성 날짜
                              Text(
                                letter.formattedDate,
                                style: TextStyle(
                                  fontSize: 13,
                                  // 답장 도착 여부에 따른 날짜 색상 변경
                                  color: isArrived ? Colors.grey : Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                          // 답장 확인 버튼
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFBB9DF7), // 보라색 배경
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: () {
                              // 편지 상세 페이지로 이동
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
            const SizedBox(height: 20), // 간격

            // 메인으로 돌아가기 버튼
            Padding(
              padding: const EdgeInsets.only(bottom: 42),
              child: SizedBox(
                width: double.infinity, // 전체 너비 사용
                height: 48, // 버튼 높이
                child: ElevatedButton(
                  onPressed: () {
                    // 모든 이전 페이지를 제거하고 메인 페이지로 이동
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const MainPage(fromLetter: true),
                      ),
                          (route) => false, // 모든 이전 라우트 제거
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFBB9DF7), // 보라색 배경
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    '메인으로 돌아가기',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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