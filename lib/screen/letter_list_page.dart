import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:neverland_flutter/model/letter.dart';
import 'package:neverland_flutter/screen/letter_detail_page.dart';
import 'package:neverland_flutter/screen/letter_write_page.dart';
import 'package:neverland_flutter/screen/main_page.dart';

/// 편지 목록을 표시하는 페이지
/// 사용자가 작성한 편지들의 목록을 보여주고, 편지 작성 및 상세 조회 기능을 제공
class LetterListPage extends StatefulWidget {
  const LetterListPage({super.key});

  @override
  State<LetterListPage> createState() => _LetterListPageState();
}

class _LetterListPageState extends State<LetterListPage> {
  /// 1초마다 화면 업데이트를 위한 타이머
  Timer? _timer;

  /// 서버에서 가져온 편지 목록을 저장하는 리스트
  List<Letter> _letters = [];

  @override
  void initState() {
    super.initState();
    // 페이지 초기화 시 서버에서 편지 목록 로드
    _loadLettersFromServer();

    // 1초마다 화면을 업데이트하는 타이머 시작
    // 편지 도착 시간 표시를 실시간으로 업데이트하기 위함
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    // 페이지 종료 시 타이머 정리
    _timer?.cancel();
    super.dispose();
  }

  /// 서버에서 편지 목록을 가져오는 비동기 함수
  Future<void> _loadLettersFromServer() async {
    // SharedPreferences에서 사용자 인증 키 가져오기
    final prefs = await SharedPreferences.getInstance();
    final authKeyId = prefs.getString('auth_key_id') ?? 'default_user_id';

    try {
      // 서버 API 호출하여 편지 목록 요청
      final response = await http.get(
        Uri.parse('http://192.168.219.68:8086/letter/list?authKeyId=$authKeyId'),
      );

      // HTTP 응답 성공 시 (200-299 상태 코드)
      if (response.statusCode >= 200 && response.statusCode < 300) {
        // JSON 응답을 파싱하여 편지 목록으로 변환
        final List<dynamic> jsonList = jsonDecode(response.body);
        setState(() {
          _letters = jsonList.map((e) => Letter.fromJson(e)).toList();
        });
      } else {
        // 서버 오류 시 로그 출력
        print('❌ 서버 오류: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      // 네트워크 오류 시 로그 출력
      print('❌ 네트워크 오류: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 배경색 설정
      backgroundColor: const Color(0xFFFFFFFF),

      // 앱바 설정
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFFFFF),
        elevation: 0, // 그림자 제거
        leading: const BackButton(color: Colors.black), // 뒤로가기 버튼
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

      // 메인 콘텐츠 영역
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 편지 총 개수 표시
            Text('총 ${_letters.length}건', style: const TextStyle(fontSize: 14)),
            const Divider(height: 20), // 구분선

            // 편지 작성 버튼
            ElevatedButton(
              onPressed: () async {
                // 편지 작성 페이지로 이동
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LetterWritePage()),
                );
                // 편지 작성 완료 후 목록 새로고침
                if (result == true) _loadLettersFromServer();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFBB9DF7), // 보라색 배경
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('편지 작성하기', style: TextStyle(color: Colors.white)),
            ),
            const SizedBox(height: 20),

            // 편지 목록 표시 영역
            Expanded(
              child: ListView.builder(
                itemCount: _letters.length,
                itemBuilder: (context, index) {
                  final letter = _letters[index];
                  final isArrived = letter.isArrived; // 편지 도착 여부 확인

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        // 도착한 편지는 흰색, 도착하지 않은 편지는 회색 배경
                        color: isArrived ? Colors.white : Colors.grey[300],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // 편지 정보 표시 (제목, 날짜)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 편지 제목
                              Text(
                                letter.title,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Pretendard',
                                  // 도착 여부에 따라 색상 변경
                                  color: isArrived ? Colors.black : Colors.black45,
                                ),
                              ),
                              const SizedBox(height: 4),
                              // 편지 날짜
                              Text(
                                letter.formattedDate,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isArrived ? Colors.grey : Colors.grey[600],
                                ),
                              ),
                            ],
                          ),

                          // 답장 도착 버튼
                          Row(
                            children: [
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFBB9DF7),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                onPressed: () async {
                                  // 사용자 인증 키 가져오기
                                  final prefs = await SharedPreferences.getInstance();
                                  final authKeyId = prefs.getString('auth_key_id') ?? 'default_user_id';

                                  // 편지 상세 페이지로 이동
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => LetterDetailPage(letter: letter, authKeyId: authKeyId),
                                    ),
                                  );
                                },
                                child: const Text('답장 도착', style: TextStyle(color: Colors.white)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),

            // 메인 페이지로 돌아가는 버튼
            Padding(
              padding: const EdgeInsets.only(bottom: 42),
              child: ElevatedButton(
                onPressed: () {
                  // 메인 페이지로 이동하면서 이전 페이지 스택 모두 제거
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const MainPage(fromLetter: true)),
                        (route) => false, // 모든 이전 라우트 제거
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFBB9DF7),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  minimumSize: const Size(double.infinity, 48), // 전체 너비 사용
                ),
                child: const Text(
                  '메인으로 돌아가기',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}