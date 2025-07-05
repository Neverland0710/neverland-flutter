// Flutter 및 관련 패키지 임포트
import 'package:flutter/material.dart'; // Flutter의 Material Design 위젯
import 'package:http/http.dart' as http; // HTTP 요청 처리
import 'dart:convert'; // JSON 데이터 처리
import '../model/letter.dart'; // 편지 데이터 모델 (참조는 있지만 직접 사용되지 않음)

/// 답장 편지 상세 보기 페이지
/// 서버에서 받은 답장 내용을 보여주는 페이지
class LetterReplyDetailPage extends StatefulWidget {
  final String replyLetter; // 표시할 답장 내용
  final String userId; // 사용자 ID

  const LetterReplyDetailPage({
    super.key,
    required this.replyLetter, // 필수: 답장 내용
    required this.userId, // 필수: 사용자 ID
  });

  @override
  State<LetterReplyDetailPage> createState() => _LetterReplyDetailPageState();
}

/// LetterReplyDetailPage의 상태 관리 클래스
class _LetterReplyDetailPageState extends State<LetterReplyDetailPage> {
  // 수신자 이름 상태 변수 (기본값: 로딩 중)
  String recipientName = '...';

  @override
  void initState() {
    super.initState();
    _loadRecipientName(); // 페이지 초기화 시 수신자 이름 로드
  }

  /// 수신자 이름을 서버에서 불러오는 비동기 함수
  Future<void> _loadRecipientName() async {
    try {
      // 서버에서 수신자 이름 가져오기
      final response = await http.get(
        Uri.parse('http://192.168.219.68:8086/chat/relation?userId=${widget.userId}'),
      );

      // HTTP 응답 상태 코드가 200(성공)인 경우
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body); // JSON 디코딩
        if (mounted) { // 위젯이 여전히 마운트 상태인지 확인
          setState(() {
            recipientName = data['relation'] ?? '...'; // 수신자 이름 업데이트, 기본값 '...'
          });
        }
      } else {
        // 서버 오류 발생 시 로그 출력
        print('❌ 이름 불러오기 실패: ${response.statusCode}');
      }
    } catch (e) {
      // 네트워크 오류 발생 시 로그 출력
      print('❌ 네트워크 오류: $e');
    }
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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0), // 전체 패딩
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8), // 상단 여백
              // 수신자 이름 표시
              Text(
                'FROM. $recipientName', // 동적으로 로드된 수신자 이름
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Pretendard',
                ),
              ),
              const SizedBox(height: 24), // 수신자 이름과 답장 내용 간 여백

              // 답장 내용 카드
              Container(
                width: double.infinity, // 전체 너비
                padding: const EdgeInsets.all(20), // 내부 패딩
                decoration: BoxDecoration(
                  color: Colors.white, // 배경색: 흰색
                  borderRadius: BorderRadius.circular(16), // 모서리 둥글게
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05), // 그림자 색상
                      blurRadius: 8, // 그림자 흐림 정도
                      offset: const Offset(0, 4), // 그림자 위치
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '답장', // 답장 제목
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Pretendard',
                      ),
                    ),
                    const SizedBox(height: 12), // 제목과 내용 간 여백
                    Text(
                      widget.replyLetter, // 서버에서 받은 답장 내용
                      style: const TextStyle(
                        fontSize: 14,
                        fontFamily: 'Pretendard',
                        height: 1.7, // 줄 간격
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40), // 답장 내용과 버튼 간 여백

              // 닫기 버튼
              Center(
                child: SizedBox(
                  width: 200, // 버튼 너비
                  height: 48, // 버튼 높이
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context), // 이전 화면으로 돌아가기
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFBB9DF7), // 버튼 색상: 보라색
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12), // 버튼 모서리 둥글게
                      ),
                    ),
                    child: const Text(
                      '닫기',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Pretendard',
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}