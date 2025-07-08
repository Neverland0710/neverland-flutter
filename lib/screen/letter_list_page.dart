// Dart 및 관련 패키지 임포트
import 'dart:async'; // 비동기 작업 처리를 위한 타이머 및 Future 사용
import 'dart:convert'; // JSON 데이터 인코딩/디코딩
import 'package:flutter/material.dart'; // Flutter의 Material Design 위젯
import 'package:shared_preferences/shared_preferences.dart'; // 로컬 데이터 저장
import 'package:http/http.dart' as http; // HTTP 요청 처리
import 'package:neverland_flutter/model/letter.dart'; // 편지 데이터 모델
import 'package:neverland_flutter/screen/letter_detail_page.dart'; // 편지 상세 페이지
import 'package:neverland_flutter/screen/letter_write_page.dart'; // 편지 작성 페이지
import 'package:neverland_flutter/screen/main_page.dart'; // 메인 페이지

/// 편지 목록을 표시하는 페이지
class LetterListPage extends StatefulWidget {
  const LetterListPage({super.key});

  @override
  State<LetterListPage> createState() => _LetterListPageState();
}

/// LetterListPage의 상태 관리 클래스
class _LetterListPageState extends State<LetterListPage> {
  Timer? _timer; // 주기적 UI 갱신을 위한 타이머
  Timer? _pollingTimer; // 답장 상태 폴링을 위한 타이머
  List<Letter> _letters = []; // 편지 목록
  String? _userId; // 사용자 ID

  @override
  void initState() {
    super.initState();
    // 초기화: 사용자 ID와 편지 목록 로드
    _loadUserId();
    _loadLettersFromServer();
    _startAutoRefresh();
    // 1초마다 UI 갱신을 위한 타이머 설정
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {}); // UI 갱신
      }
    });
  }
  /// 일정 간격으로 편지 목록을 자동 갱신하는 함수
  void _startAutoRefresh() {
    Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      _loadLettersFromServer(); // 🔄 편지 목록 서버 갱신
    });
  }
  @override
  void dispose() {
    // 모든 타이머를 명시적으로 취소하여 메모리 누수 방지
    _timer?.cancel();
    _pollingTimer?.cancel();
    super.dispose();
  }

  /// SharedPreferences에서 사용자 ID를 로드하는 함수
  Future<void> _loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _userId = prefs.getString('user_id') ?? ''; // 사용자 ID 로드, 기본값은 빈 문자열
      });
    }
  }

  /// 서버에서 편지 목록을 가져오는 함수
  Future<void> _loadLettersFromServer() async {
    final prefs = await SharedPreferences.getInstance();
    final authKeyId = prefs.getString('authKeyId') ?? 'default_user_id'; // 인증 키 로드

    try {
      // 서버에서 편지 목록 가져오기
      final response = await http.get(
        Uri.parse('http://52.78.139.47:8086/letter/list?authKeyId=$authKeyId'),
      );

      // HTTP 응답 상태 코드가 200~299인 경우 (성공)
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final List<dynamic> jsonList = jsonDecode(response.body); // JSON 디코딩
        if (mounted) {
          setState(() {
            _letters = jsonList.map((e) => Letter.fromJson(e)).toList(); // JSON을 Letter 객체로 변환
          });
        }
      } else {
        // 서버 오류 발생 시 로그 출력
        print('❌ 서버 오류: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      // 네트워크 오류 발생 시 로그 출력
      print('❌ 네트워크 오류: $e');
    }
  }

  /// 편지를 서버로 전송하는 함수
  Future<Letter?> _sendLetterToServer(Letter letter) async {
    final prefs = await SharedPreferences.getInstance();
    final authKeyId = prefs.getString('authKeyId') ?? ''; // 인증 키
    final userId = prefs.getString('user_id') ?? ''; // 사용자 ID

    // 디버깅용: 전송 전 데이터 로그
    print('📦 전송 전 authKeyId: $authKeyId');
    print('📦 전송 전 userId: $userId');

    // 인증 키 또는 사용자 ID가 없는 경우
    if (authKeyId.isEmpty || userId.isEmpty) {
      print('❗ authKeyId 또는 userId가 비어있습니다.');
      return null;
    }

    // 서버로 전송할 요청 본문
    final requestBody = {
      'user_id': userId,
      'authKeyId': authKeyId,
      'title': letter.title,
      'content': letter.content,
      'created_at': letter.createdAt.toIso8601String(), // 생성 시간 ISO 포맷
    };

    // 디버깅용: 전송 데이터 로그
    print('📦 전송할 데이터: ${jsonEncode(requestBody)}');

    try {
      // 서버로 편지 전송 (POST 요청)
      final response = await http.post(
        Uri.parse('http://52.78.139.47:8086/letter/send'),
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Accept': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      // 디버깅용: 응답 로그
      print('📦 응답 상태 코드: ${response.statusCode}');
      print('📦 응답 본문: ${response.body}');

      // HTTP 응답 상태 코드가 200~299인 경우 (성공)
      if (response.statusCode >= 200 && response.statusCode < 300) {
        print('✅ 편지 전송 성공');

        try {
          // 응답 본문이 JSON 형식인 경우
          if (response.body.isNotEmpty && response.body.trim().startsWith('{')) {
            final responseData = jsonDecode(response.body);
            return Letter.fromJson(responseData); // 서버 응답으로 Letter 객체 생성
          } else {
            // JSON 형식이 아닌 경우 기본 Letter 객체 반환
            print('📦 응답이 JSON 형식이 아님, 기본 편지 객체 생성');
            return Letter(
              id: letter.id,
              title: letter.title,
              content: letter.content,
              createdAt: letter.createdAt,
              deliveryStatus: 'SENT', // 기본 상태: 전송됨
              replyContent: null,
            );
          }
        } catch (parseError) {
          // JSON 파싱 오류 발생 시 기본 Letter 객체 반환
          print('📦 응답 파싱 오류: $parseError');
          return Letter(
            id: letter.id,
            title: letter.title,
            content: letter.content,
            createdAt: letter.createdAt,
            deliveryStatus: 'SENT',
            replyContent: null,
          );
        }
      } else {
        // 전송 실패 시 로그 출력
        print('❌ 편지 전송 실패: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      // 네트워크 오류 발생 시 로그 출력
      print('❌ 편지 전송 오류: $e');
      return null;
    }
  }

  /// 답장 생성 요청을 서버로 보내는 함수
  Future<void> _generateReply(String letterId) async {
    final prefs = await SharedPreferences.getInstance();
    final authKeyId = prefs.getString('authKeyId') ?? '';
    final userId = prefs.getString('user_id') ?? '';

    // 디버깅용: 요청 데이터 로그
    print('📨 답장 생성 요청 - letterId: $letterId, authKeyId: $authKeyId, userId: $userId');

    // 인증 키 또는 사용자 ID가 없는 경우
    if (authKeyId.isEmpty || userId.isEmpty) {
      print('❗ _generateReply: authKeyId 또는 userId가 비어있습니다.');
      return;
    }

    // 서버로 전송할 요청 본문
    final requestBody = {
      'letterId': letterId,
      'authKeyId': authKeyId,
      'userId': userId,
    };

    // 디버깅용: 요청 데이터 로그
    print('📨 답장 생성 요청 데이터: ${jsonEncode(requestBody)}');

    try {
      // 서버로 답장 생성 요청 (POST 요청)
      final response = await http.post(
        Uri.parse('http://52.78.139.47:8086/letter/reply'),
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Accept': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      // 디버깅용: 응답 상태 로그
      print('📨 답장 생성 응답 상태: ${response.statusCode}');

      // HTTP 응답 상태 코드가 200~299인 경우 (성공)
      if (response.statusCode >= 200 && response.statusCode < 300) {
        print('✅ 답장 생성 요청 성공');
      } else {
        // 요청 실패 시 로그出力
        print('❌ 답장 생성 요청 실패: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      // 네트워크 오류 발생 시 로그 출력
      print('❌ 답장 생성 오류: $e');
    }
  }

  /// 답장 상태를 주기적으로 확인하는 폴링 시작 함수
  void _startPollingForReply(String letterId) {
    // 기존 폴링 타이머가 있으면 취소
    _pollingTimer?.cancel();

    // 3초마다 편지 목록을 갱신하여 답장 상태 확인
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      if (!mounted) {
        timer.cancel(); // 위젯이 마운트 해제된 경우 타이머 취소
        return;
      }

      // 서버에서 최신 편지 목록 로드
      await _loadLettersFromServer();

      if (!mounted) {
        timer.cancel(); // 위젯이 마운트 해제된 경우 타이머 취소
        return;
      }

      try {
        // 특정 편지의 최신 상태 확인
        final updatedLetter = _letters.firstWhere(
              (letter) => letter.id == letterId,
        );

        // 답장이 도착한 경우 (DELIVERED 상태)
        if (updatedLetter.deliveryStatus == 'DELIVERED') {
          timer.cancel(); // 폴링 종료
          print('✅ 답장 도착 확인됨');
        }
      } catch (e) {
        // 편지를 찾지 못한 경우 로그 출력
        print('편지를 찾을 수 없습니다: $letterId');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF), // 배경색: 흰색
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFFFFF), // 앱바 배경색: 흰색
        elevation: 0, // 앱바 그림자 제거
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
        padding: const EdgeInsets.all(20), // 전체 패딩
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
        // 편지 개수 표시
        Text('총 ${_letters.length}건', style: const TextStyle(fontSize: 14)),
        const Divider(height: 20), // 구분선
        // 편지 작성 버튼
        ElevatedButton(
          onPressed: () async {
            // LetterWritePage로 이동하여 편지 작성
            final result = await Navigator.push<Letter>(
              context,
              MaterialPageRoute(
                builder: (_) => LetterWritePage(userId: _userId ?? ''),
              ),
            );

            // 작성된 편지가 반환된 경우
            // 작성된 편지가 반환된 경우
            if (result != null && mounted) {
              // 서버로 편지 전송
              final serverLetter = await _sendLetterToServer(result);
              if (serverLetter != null && mounted) {
                setState(() {
                  _letters.insert(0, serverLetter); // 서버 응답으로만 목록에 반영
                });

                print('✅ 편지 전송 완료! 서버에서 답장 생성도 함께 처리됨');
                _startPollingForReply(serverLetter.id); // 답장 폴링 시작
              }
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFBB9DF7), // 버튼 색상: 보라색
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('편지 작성하기', style: TextStyle(color: Colors.white)),
        ),
        const SizedBox(height: 20), // 버튼과 목록 간 여백
        // 편지 목록
        Expanded(
          child: ListView.builder(
            itemCount: _letters.length, // 편지 개수
            itemBuilder: (context, index) {
              final letter = _letters[index]; // 현재 편지
              final createdAt = letter.createdAt;
              final elapsed = DateTime.now().difference(createdAt);
              final bool isElapsed = elapsed.inSeconds >= 30;  // 답장 딜레이
              final bool isButtonEnabled = letter.isArrived && isElapsed;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0), // 각 항목 하단 여백
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), // 내부 패딩
                  decoration: BoxDecoration(
                    color: letter.isArrived ? Colors.white : Colors.grey[300], // 답장 여부에 따라 배경색
                    borderRadius: BorderRadius.circular(12), // 모서리 둥글게
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // 편지 제목과 날짜
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            letter.title,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Pretendard',
                              color: letter.isArrived ? Colors.black : Colors.black45, // 답장 여부에 따라 색상
                            ),
                          ),
                          const SizedBox(height: 4), // 제목과 날짜 간 여백
                          Text(
                            letter.formattedDate, // 포맷된 날짜
                            style: TextStyle(
                              fontSize: 13,
                              color: letter.isArrived ? Colors.grey : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      // 답장 확인 버튼
                      Row(
                        children: [
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isButtonEnabled ? const Color(0xFFBB9DF7) : Colors.grey,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: isButtonEnabled
                                ? () async {
                              final prefs = await SharedPreferences.getInstance();
                              final authKeyId = prefs.getString('authKeyId') ?? 'default_user_id';

                              if (_userId == null || _userId!.isEmpty) {
                                print('❗ userId 없음');
                                return;
                              }


                              if (mounted) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => LetterDetailPage(
                                      letter: letter,
                                      authKeyId: authKeyId,
                                      userId: _userId!,
                                    ),
                                  ),
                                );
                              }
                            }
                                : null,
                            child: Text(
                              letter.isArrived ? '답장 도착' : '전송 중',
                              style: const TextStyle(color: Colors.white),
                            ),
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
        const SizedBox(height: 20), // 목록과 하단 버튼 간 여백
        // 메인으로 돌아가기 버튼
        Padding(
          padding: const EdgeInsets.only(bottom: 42), // 하단 여백
          child: ElevatedButton(
              onPressed: () {
                // 메인 페이지로 이동하고 스택 초기화
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const MainPage(fromLetter: true)),
                      (route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFBB9DF7), // 버튼 색상: 보라색
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          minimumSize: const Size(double.infinity, 48), // 버튼 크기
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