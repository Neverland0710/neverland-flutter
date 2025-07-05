import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:neverland_flutter/model/letter.dart';
import 'letter_list_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

/// 편지 작성 화면을 제공하는 StatefulWidget
/// 사용자가 고인에게 보낼 편지를 작성하고 저장할 수 있는 폼을 제공
///
/// 주요 기능:
/// - 편지 제목 및 내용 입력
/// - 2000자 제한 적용
/// - 서버로 편지 데이터 전송
/// - 작성 완료 후 편지 목록 페이지로 이동
class LetterWritePage extends StatefulWidget {
  /// 사용자 ID - 서버에서 사용자 관련 정보를 조회하는 데 사용
  final String userId;

  const LetterWritePage({super.key, required this.userId});

  @override
  State<LetterWritePage> createState() => _LetterWritePageState();
}

class _LetterWritePageState extends State<LetterWritePage> {
  // 텍스트 입력 필드 제어를 위한 컨트롤러들
  /// 편지 제목 입력 필드를 제어하는 컨트롤러
  final TextEditingController _titleController = TextEditingController();

  /// 편지 내용 입력 필드를 제어하는 컨트롤러
  final TextEditingController _contentController = TextEditingController();

  /// 유의사항 및 글자수 제한 정보 표시 여부를 제어하는 변수
  /// 사용자가 내용을 입력하기 시작하면 false로 변경되어 안내 문구가 사라짐
  bool _showInfo = true;

  /// 편지 수신자(고인)의 이름을 저장하는 변수
  /// 초기값은 '...'로 설정되고, 서버에서 실제 이름을 불러온 후 업데이트됨
  String recipientName = '...';

  @override
  void initState() {
    super.initState();
    // 위젯이 생성될 때 수신자 이름을 서버에서 불러옴
    _loadRecipientName();
  }

  /// 수신자 이름을 서버에서 불러오는 비동기 함수
  /// GET 요청을 통해 사용자 ID로 관련 정보를 조회
  Future<void> _loadRecipientName() async {
    try {
      // 서버에 GET 요청을 보내 사용자의 관계 정보 조회
      final response = await http.get(
        Uri.parse('http://192.168.219.68:8086/chat/relation?userId=${widget.userId}'),
      );

      // 응답이 성공적일 경우 (HTTP 200)
      if (response.statusCode == 200) {
        // JSON 응답을 파싱하여 Map으로 변환
        final Map<String, dynamic> data = jsonDecode(response.body);

        // 위젯이 아직 마운트되어 있는지 확인 (메모리 누수 방지)
        if (mounted) {
          setState(() {
            // 서버에서 받은 관계 정보를 수신자 이름으로 설정
            // 데이터가 없을 경우 기본값 '...' 유지
            recipientName = data['relation'] ?? '...';
          });
        }
      } else {
        // HTTP 오류 발생 시 콘솔에 오류 메시지 출력
        print('❌ 이름 불러오기 실패: ${response.statusCode}');
      }
    } catch (e) {
      // 네트워크 오류 또는 기타 예외 발생 시 콘솔에 오류 메시지 출력
      print('❌ 네트워크 오류: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 배경색을 흰색으로 설정
      backgroundColor: const Color(0xFFFFFFFF),

      // 앱바 구성
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFFFFF), // 앱바 배경색
        elevation: 0, // 그림자 제거
        leading: const BackButton(color: Colors.black), // 뒤로가기 버튼
        title: const Text(
          '내게 온 편지', // 앱바 제목
          style: TextStyle(
            fontFamily: 'Pretendard',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
      ),

      body: SafeArea(
        child: SingleChildScrollView( // 스크롤 가능한 영역
          padding: const EdgeInsets.all(20), // 전체 패딩
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, // 왼쪽 정렬
            children: [
              // 수신자 이름 표시 영역
              Text(
                'TO. $recipientName', // 동적으로 수신자 이름 표시
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Pretendard',
                ),
              ),

              const SizedBox(height: 20), // 수직 간격

              // 편지 제목 입력 필드
              TextField(
                controller: _titleController, // 제목 입력 컨트롤러 연결
                decoration: const InputDecoration(
                  hintText: '제목을 입력하세요', // 플레이스홀더 텍스트
                  border: UnderlineInputBorder(), // 하단 밑줄 스타일
                ),
              ),

              const SizedBox(height: 16), // 수직 간격

              // 편지 내용 입력 영역을 감싸는 컨테이너
              Container(
                padding: const EdgeInsets.all(16), // 내부 패딩
                decoration: BoxDecoration(
                  color: Colors.white, // 배경색
                  borderRadius: BorderRadius.circular(8), // 모서리 둥글게
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, // 왼쪽 정렬
                  children: [
                    // 편지 내용 입력 필드 (멀티라인 지원)
                    TextField(
                      controller: _contentController, // 내용 입력 컨트롤러 연결
                      maxLines: null, // 무제한 줄 수 (자동 확장)
                      maxLength: 2000, // 최대 글자 수 제한
                      onChanged: (_) {
                        // 사용자가 내용을 입력하기 시작하면 안내 문구 숨김
                        if (_showInfo) {
                          setState(() {
                            _showInfo = false;
                          });
                        }
                      },
                      decoration: const InputDecoration(
                        hintText: '내용을 입력해주세요.', // 플레이스홀더 텍스트
                        border: InputBorder.none, // 테두리 없음
                        counterText: '', // 글자 수 카운터 숨김
                      ),
                    ),

                    const SizedBox(height: 8), // 수직 간격

                    // 유의사항 및 글자수 제한 정보 (조건부 표시)
                    // _showInfo가 true일 때만 표시됨
                    if (_showInfo) ...[
                      // 글자수 제한 안내
                      const Text(
                        '편지는 최대 2,000자 제한합니다.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.black87,
                          fontFamily: 'Pretendard',
                        ),
                      ),
                      const SizedBox(height: 8), // 수직 간격

                      // 유의사항 안내
                      const Text(
                        '유의사항\n'
                            '・ 하늘에서 온 편지 생성되기까지 작성 완료 후 하루 소요될 수 있습니다.\n'
                            '・ 편지 작성 완료 후, 편지 내용 수정은 불가능합니다.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          height: 1.6, // 줄 간격
                          fontFamily: 'Pretendard',
                        ),
                      ),
                    ]
                  ],
                ),
              ),

              const SizedBox(height: 24), // 수직 간격

              // 작성 완료 버튼
              SizedBox(
                width: double.infinity, // 전체 너비
                height: 48, // 고정 높이
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFBB9DF7), // 보라색 배경
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12), // 모서리 둥글게
                    ),
                  ),
                  onPressed: () async {
                    // 제목과 내용에서 앞뒤 공백 제거
                    final title = _titleController.text.trim();
                    final content = _contentController.text.trim();

                    // 제목 또는 내용이 비어있는지 검증
                    if (title.isEmpty || content.isEmpty) {
                      // 스낵바로 오류 메시지 표시
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('제목과 내용을 모두 입력해주세요')),
                      );
                      return; // 함수 종료
                    }

                    // 현재 날짜와 시간 가져오기
                    final now = DateTime.now();

                    // 새로운 편지 객체 생성
                    final newLetter = Letter(
                      id: const Uuid().v4(), // UUID로 고유 ID 생성
                      title: title, // 입력된 제목
                      content: content, // 입력된 내용
                      createdAt: now, // 생성 시간
                      replyContent: null, // 답장 내용 (초기값 null)
                    );

                    // 이전 화면으로 돌아가면서 새로운 편지 데이터 전달
                    Navigator.pop(context, newLetter);
                  },
                  child: const Text(
                    '작성 완료',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Pretendard',
                    ),
                  ),
                ),
              ),

              // 하단 여백 (기기의 하단 안전 영역 + 추가 여백)
              SizedBox(height: MediaQuery.of(context).padding.bottom + 20),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    // 메모리 누수 방지를 위해 컨트롤러 해제
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }
}