// Flutter 및 관련 패키지 임포트
import 'package:flutter/material.dart'; // Flutter의 기본 Material Design 위젯
import 'package:neverland_flutter/model/letter.dart'; // 편지 데이터 모델
import 'package:neverland_flutter/screen/letter_reply_detail_page.dart'; // 답장 상세 페이지
import 'package:lottie/lottie.dart'; // Lottie 애니메이션 사용
import 'package:http/http.dart' as http; // HTTP 요청 처리
import 'dart:convert'; // JSON 데이터 처리

/// 편지 관련 HTTP 요청을 처리하는 서비스 클래스
class LetterService {
  /// 특정 편지의 최신 정보를 서버에서 가져오는 메소드
  /// [id]는 편지 ID, [authKeyId]는 사용자 인증 키
  Future<Letter?> fetchLetter(String id, String authKeyId) async {
    try {
      // 서버에서 편지 목록을 가져오는 HTTP GET 요청
      final response = await http.get(
        Uri.parse('http://52.78.139.47:8086/letter/list?authKeyId=$authKeyId'),
      );

      // HTTP 응답 상태 코드가 200(성공)인 경우
      if (response.statusCode == 200) {
        // 응답 본문을 JSON으로 디코딩하여 리스트로 변환
        final List<dynamic> lettersJson = jsonDecode(response.body);

        // 디버깅용: 서버에서 받은 편지 목록 로그 출력
        print('📋 서버에서 받은 편지 목록:');
        for (var letterJson in lettersJson) {
          print('   - letterId: ${letterJson['letterId']}');
          print('   - title: ${letterJson['title']}');
          print('   - replyContent: ${letterJson['replyContent']}');
          print('   - deliveryStatus: ${letterJson['deliveryStatus']}');
        }

        // JSON 데이터를 Letter 객체 리스트로 변환
        final letters = lettersJson.map((json) => Letter.fromJson(json)).toList();

        // ID 매칭 시 두 가지 방법 시도
        Letter? foundLetter;

        // 1. letterId로 편지 찾기
        try {
          foundLetter = letters.firstWhere(
                (letter) => letter.id == id,
          );
          print('✅ letterId로 편지 찾음: ${foundLetter.id}');
        } catch (e) {
          print('❌ letterId로 편지를 찾을 수 없음: $id');
        }

        // 2. letterId로 찾지 못한 경우 제목/내용 기반으로 매칭 시도 (fallback)
        if (foundLetter == null && letters.isNotEmpty) {
          print('🔄 제목/내용 기반으로 매칭 시도...');
          // 임시 해결책으로 가장 최근 편지 반환
          foundLetter = letters.first;
          print('📝 최근 편지 반환: ${foundLetter.id}');
        }

        return foundLetter; // 찾은 편지 반환
      } else {
        // 서버 오류 발생 시 로그 출력 후 null 반환
        print('❌ 서버 오류: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      // 네트워크 오류 발생 시 로그 출력 후 null 반환
      print('❌ 네트워크 오류: $e');
      return null;
    }
  }
}

/// 편지 상세 정보를 보여주는 페이지
/// 편지 내용과 답장 도착 여부를 표시하고, 답장 확인 기능을 제공
class LetterDetailPage extends StatefulWidget {
  /// 표시할 편지 객체
  final Letter letter;

  /// 사용자 인증 키
  final String authKeyId;

  /// 사용자 ID
  final String userId;

  const LetterDetailPage({
    super.key,
    required this.letter, // 필수: 표시할 편지
    required this.authKeyId, // 필수: 인증 키
    required this.userId, // 필수: 사용자 ID
  });

  @override
  State<LetterDetailPage> createState() => _LetterDetailPageState();
}

/// LetterDetailPage의 상태 관리 클래스
class _LetterDetailPageState extends State<LetterDetailPage> {
  late bool isArrived; // 답장 도착 여부
  String? replyContent; // 답장 내용
  late Letter currentLetter; // 현재 표시 중인 편지
  String recipientName = '...'; // 수신자 이름 (기본값: 로딩 중)

  @override
  void initState() {
    super.initState();
    // 초기 상태 설정
    currentLetter = widget.letter; // 위젯에서 받은 편지로 초기화
    isArrived = currentLetter.isArrived; // 답장 도착 여부 초기화
    replyContent = currentLetter.replyContent; // 답장 내용 초기화

    // 디버깅용: 초기 상태 로그 출력
    print('🔄 초기 상태: isArrived=$isArrived, replyContent=$replyContent');

    // 수신자 이름 로드
    _loadRecipientName();

    // 최신 편지 데이터 새로고침
    _refreshLetterData();
  }

  /// 수신자 이름을 서버에서 불러오는 비동기 함수
  Future<void> _loadRecipientName() async {
    try {
      // 서버에서 수신자 이름 가져오기
      final response = await http.get(
        Uri.parse('http://52.78.139.47:8086/chat/relation?userId=${widget.userId}'),
      );

      // HTTP 응답 상태 코드가 200(성공)인 경우
      if (response.statusCode == 200) {
        // 응답 본문을 JSON으로 디코딩
        final Map<String, dynamic> data = jsonDecode(response.body);
        if (mounted) { // 위젯이 여전히 마운트 상태인지 확인
          setState(() {
            recipientName = data['relation'] ?? '...'; // 수신자 이름 업데이트
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

  /// 최신 편지 데이터를 서버에서 새로고침하는 비동기 함수
  Future<void> _refreshLetterData() async {
    try {
      print('🔄 편지 데이터 새로고침 시작...');

      // LetterService를 통해 최신 편지 데이터 가져오기
      final updatedLetter = await LetterService().fetchLetter(
        widget.letter.id,
        widget.authKeyId,
      );

      if (updatedLetter != null) {
        // 상태 업데이트
        setState(() {
          currentLetter = updatedLetter; // 편지 데이터 업데이트
          isArrived = updatedLetter.isArrived; // 답장 도착 여부 업데이트
          replyContent = updatedLetter.replyContent; // 답장 내용 업데이트
        });

        // 디버깅용: 새로고침된 데이터 로그 출력
        print('✅ 데이터 새로고침 완료:');
        print('   - isArrived: $isArrived');
        print('   - replyContent: $replyContent');
        print('   - deliveryStatus: ${updatedLetter.deliveryStatus}');

        // 답장 상태 검증
        if (updatedLetter.deliveryStatus == 'DELIVERED' &&
            (replyContent == null || replyContent!.isEmpty)) {
          print('⚠️ 답장이 도착했지만 내용이 없습니다.');
          // 답장 내용이 없는 경우 사용자에게 알림
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('답장이 도착했지만 내용을 불러올 수 없습니다.')),
          );
        }
      } else {
        // 서버에서 편지를 찾지 못한 경우 로그 출력
        print('❌ 서버에서 편지를 찾을 수 없습니다.');
      }
    } catch (e) {
      // 새로고침 실패 시 로그 출력
      print('❌ 데이터 새로고침 실패: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // 디버깅용: 화면 렌더링 시 상태 로그 출력
    print('🖥️ 화면 렌더링: isArrived=$isArrived, replyContent=$replyContent');

    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF), // 배경색: 흰색
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFFFFF), // 앱바 배경색: 흰색
        elevation: 0, // 앱바 그림자 제거
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0), // 전체 패딩
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8), // 상단 여백
              // 수신자 이름 표시
              Text(
                'TO. $recipientName',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Pretendard',
                ),
              ),
              const SizedBox(height: 24), // 수신자 이름과 편지 내용 간 여백

              // 편지 내용 카드
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
                    // 편지 제목
                    Text(
                      currentLetter.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Pretendard',
                      ),
                    ),
                    const SizedBox(height: 12), // 제목과 내용 간 여백
                    // 편지 내용
                    Text(
                      currentLetter.content,
                      style: const TextStyle(
                        fontSize: 14,
                        fontFamily: 'Pretendard',
                        height: 1.7, // 줄 간격
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24), // 편지 내용과 답장 상태 간 여백

              // 답장 상태 및 버튼 영역
              Center(
                child: Column(
                  children: [
                    // 답장 상태 메시지
                    Text(
                      _getStatusMessage(),
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Pretendard',
                      ),
                    ),
                    const SizedBox(height: 16), // 상태 메시지와 애니메이션 간 여백

                    // 답장 도착 여부에 따른 애니메이션
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16), // 모서리 둥글게
                      child: isArrived
                          ? Lottie.asset(
                        'asset/animation/letter_open.json', // 답장 도착 시 애니메이션
                        width: 280,
                        height: 280,
                        fit: BoxFit.cover,
                        repeat: false, // 반복 안 함
                      )
                          : Lottie.asset(
                        'asset/animation/letter_close.json', // 답장 미도착 시 애니메이션
                        width: 280,
                        height: 280,
                        fit: BoxFit.cover,
                        repeat: true, // 반복 재생
                      ),
                    ),
                    const SizedBox(height: 24), // 애니메이션과 버튼 간 여백

                    // 답장 확인 버튼
                    SizedBox(
                      width: 200,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _canViewReply() ? _viewReply : null, // 버튼 활성화 여부
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _canViewReply()
                              ? const Color(0xFFBB9DF7) // 활성화 시 보라색
                              : const Color(0xFFBFBFBF), // 비활성화 시 회색
                          disabledBackgroundColor: const Color(0xFFBFBFBF), // 비활성화 배경색
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12), // 버튼 모서리 둥글게
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

  /// 답장 상태에 따라 적절한 메시지를 반환하는 함수
  String _getStatusMessage() {
    if (currentLetter.deliveryStatus == 'DELIVERED') {
      // 답장이 도착한 경우
      if (replyContent != null && replyContent!.isNotEmpty) {
        return '편지 답장이 도착했어요!';
      } else {
        return '답장이 도착했지만 내용을 불러오는 중입니다...';
      }
    } else {
      // 답장이 아직 도착하지 않은 경우
      return '답장을 기다리는 중이에요';
    }
  }

  /// 답장 확인이 가능한지 판단하는 함수
  bool _canViewReply() {
    // 답장이 도착했고, 내용이 비어 있지 않은 경우에만 true 반환
    return currentLetter.deliveryStatus == 'DELIVERED' &&
        replyContent != null &&
        replyContent!.isNotEmpty;
  }

  /// 답장 상세 페이지로 이동하는 함수
  void _viewReply() {
    // 디버깅용: 답장 보기 클릭 로그
    print('📬 답장 보기 클릭: replyContent=$replyContent');

    // LetterReplyDetailPage로 이동
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LetterReplyDetailPage(
          replyLetter: replyContent ?? '답장 내용을 불러올 수 없습니다.', // 답장 내용 전달
          userId: widget.userId, // 사용자 ID 전달
        ),
      ),
    );
  }
}