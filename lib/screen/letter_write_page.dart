import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:neverland_flutter/model/letter.dart';
import 'letter_list_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

/// 편지 작성 화면을 제공하는 StatefulWidget
/// 사용자가 고인에게 보낼 편지를 작성하고 저장할 수 있는 폼을 제공
///
/// 주요 기능:
/// - 편지 제목 및 내용 입력
/// - 2000자 제한 적용
/// - 서버로 편지 데이터 전송
/// - 작성 완료 후 편지 목록 페이지로 이동
class LetterWritePage extends StatefulWidget {
  const LetterWritePage({super.key});

  @override
  State<LetterWritePage> createState() => _LetterWritePageState();
}

class _LetterWritePageState extends State<LetterWritePage> {
  // 텍스트 입력 필드 제어를 위한 컨트롤러들
  final TextEditingController _titleController = TextEditingController(); // 편지 제목 입력 컨트롤러
  final TextEditingController _contentController = TextEditingController(); // 편지 내용 입력 컨트롤러

  // 유의사항 및 글자수 제한 정보 표시 여부를 제어하는 변수
  // 초기값 true로 설정하여 처음에는 정보를 보여주고, 사용자가 입력을 시작하면 숨김
  bool _showInfo = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 전체 화면 배경색을 흰색으로 설정
      backgroundColor: const Color(0xFFFFFFFF),

      // 상단 네비게이션 바 구성
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFFFFF), // 앱바 배경색을 흰색으로 설정
        elevation: 0, // 앱바 아래 그림자 제거 (플랫 디자인)
        leading: const BackButton(color: Colors.black), // 왼쪽에 검은색 뒤로가기 버튼 배치
        title: const Text(
          '내게 온 편지', // 앱바 제목 텍스트
          style: TextStyle(
            fontFamily: 'Pretendard', // 커스텀 폰트 적용
            fontSize: 18, // 제목 폰트 크기
            fontWeight: FontWeight.w700, // 볼드체 적용
            color: Colors.black, // 제목 텍스트 색상을 검은색으로 설정
          ),
        ),
      ),

      // 메인 컨텐츠 영역
      body: SafeArea( // 기기의 안전 영역(상태바, 노치 등) 고려
        child: SingleChildScrollView( // 세로 스크롤 가능한 영역으로 설정
          padding: const EdgeInsets.all(20), // 전체 컨텐츠에 20px 패딩 적용
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, // 모든 자식 위젯을 왼쪽 정렬
            children: [
              // 편지 수신자 표시 영역
              const Text(
                'TO. 엄마', // 편지 수신자 정보 (하드코딩됨)
                style: TextStyle(
                  fontSize: 18, // 수신자 표시 폰트 크기
                  fontWeight: FontWeight.bold, // 볼드체 적용
                  fontFamily: 'Pretendard', // 커스텀 폰트 적용
                ),
              ),

              const SizedBox(height: 20), // 수직 여백 20px 추가

              // 편지 제목 입력 필드
              TextField(
                controller: _titleController, // 제목 입력을 관리하는 컨트롤러 연결
                decoration: const InputDecoration(
                  hintText: '제목을 입력하세요', // 플레이스홀더 텍스트
                  border: UnderlineInputBorder(), // 밑줄 스타일의 테두리 적용
                ),
              ),

              const SizedBox(height: 16), // 수직 여백 16px 추가

              // 편지 내용 입력 영역을 감싸는 컨테이너
              Container(
                padding: const EdgeInsets.all(16), // 컨테이너 내부에 16px 패딩 적용
                decoration: BoxDecoration(
                  color: Colors.white, // 컨테이너 배경색을 흰색으로 설정
                  borderRadius: BorderRadius.circular(8), // 모서리를 8px 둥글게 처리
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, // 컬럼 내 위젯들을 왼쪽 정렬
                  children: [
                    // 편지 내용 입력 필드 (멀티라인 지원)
                    TextField(
                      controller: _contentController, // 내용 입력을 관리하는 컨트롤러 연결
                      maxLines: null, // 줄 수 제한 없음 (텍스트 양에 따라 자동으로 높이 조절)
                      maxLength: 2000, // 최대 입력 가능한 글자 수를 2000자로 제한

                      // 텍스트 입력 시 실행되는 콜백 함수
                      onChanged: (_) {
                        // 사용자가 타이핑을 시작하면 유의사항 정보를 숨김
                        if (_showInfo) {
                          setState(() {
                            _showInfo = false; // 정보 표시 상태를 false로 변경
                          });
                        }
                      },
                      decoration: const InputDecoration(
                        hintText: '내용을 입력해주세요.', // 플레이스홀더 텍스트
                        border: InputBorder.none, // 텍스트 필드 테두리 제거
                        counterText: '', // 기본 글자수 카운터 숨김 (커스텀 UI 사용)
                      ),
                    ),

                    const SizedBox(height: 8), // 수직 여백 8px 추가

                    // 유의사항 및 글자수 제한 정보 (조건부 표시)
                    // _showInfo가 true일 때만 아래 위젯들을 표시
                    if (_showInfo) ...[
                      // 글자수 제한 안내 텍스트
                      const Text(
                        '편지는 최대 2,000자 제한합니다.',
                        style: TextStyle(
                          fontSize: 13, // 안내 텍스트 폰트 크기
                          color: Colors.black87, // 진한 회색 텍스트 색상
                          fontFamily: 'Pretendard', // 커스텀 폰트 적용
                        ),
                      ),
                      const SizedBox(height: 8), // 수직 여백 8px 추가

                      // 상세 유의사항 텍스트
                      const Text(
                        '유의사항\n'
                            '・ 하늘에서 온 편지 생성되기까지 작성 완료 후 하루 소요될 수 있습니다.\n'
                            '・ 편지 작성 완료 후, 편지 내용 수정은 불가능합니다.',
                        style: TextStyle(
                          fontSize: 12, // 유의사항 텍스트 폰트 크기
                          color: Colors.grey, // 회색 텍스트 색상
                          height: 1.6, // 줄간격을 1.6배로 설정 (가독성 향상)
                          fontFamily: 'Pretendard', // 커스텀 폰트 적용
                        ),
                      ),
                    ]
                  ],
                ),
              ),

              const SizedBox(height: 24), // 수직 여백 24px 추가

              // 작성 완료 버튼
              SizedBox(
                width: double.infinity, // 버튼 너비를 화면 전체 너비로 설정
                height: 48, // 버튼 높이를 48px로 고정
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFBB9DF7), // 버튼 배경색을 보라색으로 설정
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12), // 버튼 모서리를 12px 둥글게 처리
                    ),
                  ),

                  // 버튼 클릭 시 실행되는 비동기 함수
                  onPressed: () async {
                    // 입력된 제목과 내용에서 앞뒤 공백 제거
                    final title = _titleController.text.trim();
                    final content = _contentController.text.trim();

                    // 제목 또는 내용이 비어있는지 검증
                    if (title.isEmpty || content.isEmpty) {
                      // 입력값이 부족한 경우 스낵바로 에러 메시지 표시
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('제목과 내용을 모두 입력해주세요')),
                      );
                      return; // 함수 실행 중단
                    }

                    // SharedPreferences에서 저장된 인증 정보 가져오기
                    final prefs = await SharedPreferences.getInstance();
                    final authKeyId = prefs.getString('auth_key_id'); // 인증 키 ID
                    final userId = prefs.getString('user_id'); // 사용자 ID

                    // 디버깅용 로그 출력
                    print('📛 authKeyId: $authKeyId');
                    print('📛 userId: $userId');

                    // 인증 정보가 없거나 비어있는 경우 에러 처리
                    if (authKeyId == null || authKeyId.isEmpty || userId == null || userId.isEmpty) {
                      print('❌ 인증 정보 누락됨');
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('로그인 상태가 유효하지 않습니다')),
                      );
                      return; // 함수 실행 중단
                    }

                    // 현재 시간 객체 생성 (편지 작성 시간 기록용)
                    final now = DateTime.now();

                    // 서버로 전송할 JSON 데이터 구성
                    final body = jsonEncode({
                      'auth_key_id': authKeyId, // 인증 키 ID
                      'user_id': userId, // 사용자 ID
                      'title': title, // 편지 제목
                      'content': content, // 편지 내용
                      'created_at': now.toIso8601String(), // ISO 8601 형식의 생성 시간
                    });

                    try {
                      // 디버깅용: 전송할 데이터 로그 출력
                      print('📦 전송할 바디: $body');

                      // HTTP POST 요청으로 편지 데이터를 서버에 전송
                      final response = await http.post(
                        Uri.parse('http://192.168.219.68:8086/letter/send'), // 서버 엔드포인트 URL
                        headers: {'Content-Type': 'application/json'}, // JSON 형식임을 명시
                        body: body, // 요청 본문에 JSON 데이터 포함
                      );

                      // HTTP 응답 상태 코드가 성공 범위(200-299)인지 확인
                      if (response.statusCode >= 200 && response.statusCode < 300) {
                        // 성공 시 로그 출력
                        print('✅ 편지 전송 성공');
                        print('LetterListPage로 이동 중...');

                        // 편지 작성 완료 상태를 SharedPreferences에 저장
                        final prefs = await SharedPreferences.getInstance();
                        prefs.setBool('isLetterWritten', true);  // 편지 작성 완료 상태 저장

                        // 위젯이 여전히 마운트되어 있는지 확인 (메모리 안전성)
                        if (!mounted) return;

                        // 편지 목록 페이지로 이동 (현재 페이지를 스택에서 제거하고 교체)
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => const LetterListPage()),
                        );

                      } else {
                        // 서버 에러 시 로그 출력 및 에러 메시지 표시
                        print('❌ 서버 오류: ${response.statusCode}');
                        print(response.body); // 서버 응답 본문 출력
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('서버 오류가 발생했습니다')),
                        );
                      }
                    } catch (e) {
                      // 네트워크 에러나 기타 예외 발생 시 처리
                      print('❌ 네트워크 오류: $e');
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('네트워크 오류가 발생했습니다')),
                      );
                    }
                  },

                  // 버튼 텍스트 스타일링
                  child: const Text(
                    '작성 완료',
                    style: TextStyle(
                      fontSize: 16, // 버튼 텍스트 폰트 크기
                      color: Colors.white, // 흰색 텍스트
                      fontWeight: FontWeight.bold, // 볼드체 적용
                      fontFamily: 'Pretendard', // 커스텀 폰트 적용
                    ),
                  ),
                ),
              ),

              // 하단 여백 (기기의 안전 영역 하단 패딩 + 추가 20px)
              // 기기마다 다른 하단 안전 영역을 고려하여 동적으로 여백 계산
              SizedBox(height: MediaQuery.of(context).padding.bottom + 20),
            ],
          ),
        ),
      ),
    );
  }

  // 위젯이 dispose될 때 메모리 누수 방지를 위해 컨트롤러들을 정리
  @override
  void dispose() {
    _titleController.dispose(); // 제목 컨트롤러 메모리 해제
    _contentController.dispose(); // 내용 컨트롤러 메모리 해제
    super.dispose();
  }
}