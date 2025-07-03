import 'package:flutter/material.dart';
import 'package:neverland_flutter/model/letter.dart';
import 'package:neverland_flutter/screen/letter_reply_detail_page.dart';
import 'package:lottie/lottie.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

/// 편지 관련 HTTP 요청을 처리하는 서비스 클래스
class LetterService {
  /// 특정 편지의 최신 정보를 서버에서 가져오는 메소드
  /// [id]: 편지의 고유 ID
  /// [authKeyId]: 사용자 인증 키
  /// 반환값: 편지 객체 또는 null (편지를 찾을 수 없는 경우)
  Future<Letter?> fetchLetter(String id, String authKeyId) async {
    // 서버 API 호출하여 편지 목록 요청
    final response = await http.get(
      Uri.parse('http://192.168.219.68:8086/letter/list?authKeyId=$authKeyId'),
    );

    // HTTP 응답 성공 시 (200 상태 코드)
    if (response.statusCode == 200) {
      // JSON 응답을 파싱하여 편지 목록으로 변환
      final List<dynamic> lettersJson = jsonDecode(response.body);
      final letters = lettersJson.map((json) => Letter.fromJson(json)).toList();

      // 요청한 ID와 일치하는 편지를 찾아서 반환
      return letters.firstWhere(
              (letter) => letter.id == id,
          orElse: () => throw Exception('Letter not found with id: $id') // 편지를 찾지 못한 경우 예외 발생
      );
    } else {
      // 서버 오류 시 로그 출력 및 예외 발생
      print('❌ 서버 오류: ${response.statusCode} - ${response.body}');
      throw Exception('Failed to load letters: ${response.statusCode}');
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

  const LetterDetailPage({super.key, required this.letter, required this.authKeyId});

  @override
  State<LetterDetailPage> createState() => _LetterDetailPageState();
}

class _LetterDetailPageState extends State<LetterDetailPage> {
  /// 편지 답장 도착 여부를 나타내는 상태 변수
  late bool isArrived;

  /// 답장 내용을 저장하는 변수
  String? replyContent;

  @override
  void initState() {
    super.initState();
    // 위젯에서 전달받은 편지 정보로 초기 상태 설정
    isArrived = widget.letter.isArrived;
    replyContent = widget.letter.replyContent;

    // 최신 편지 데이터 새로고침
    _refreshLetterData();
  }

  /// 서버에서 최신 편지 데이터를 가져와서 상태를 업데이트하는 메소드
  Future<void> _refreshLetterData() async {
    try {
      // LetterService를 통해 최신 편지 정보 가져오기
      final updatedLetter = await LetterService().fetchLetter(widget.letter.id, widget.authKeyId);

      if (updatedLetter != null) {
        setState(() {
          // 최신 정보로 상태 업데이트
          isArrived = updatedLetter.isArrived;
          replyContent = updatedLetter.replyContent;

          // 답장은 도착했지만 내용이 없는 경우 알림 표시
          if (isArrived && replyContent == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('답장이 도착했지만 내용이 비어 있습니다.')),
            );
          }
        });
        // 데이터 새로고침 완료 로그
        print('데이터 새로고침 완료: isArrived=$isArrived, replyContent=$replyContent');
      } else {
        // 편지를 찾을 수 없는 경우 로그
        print('편지를 찾을 수 없습니다: id=${widget.letter.id}');
      }
    } catch (e) {
      // 오류 발생 시 로그 출력 및 사용자에게 알림
      print('데이터 새로고침 실패: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('데이터를 불러오지 못했습니다: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // 현재 상태 로그 출력 (디버깅용)
    print('현재 상태: isArrived=$isArrived, replyContent=$replyContent');

    return Scaffold(
      // 배경색 설정
      backgroundColor: const Color(0xFFFFFFFF),

      // 앱바 설정
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFFFFF),
        elevation: 0, // 그림자 제거
        leading: const BackButton(color: Colors.black), // 뒤로가기 버튼
        title: const Text(
          '내게 온 편지',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            fontFamily: 'Pretendard',
            color: Colors.black,
          ),
        ),
      ),

      // 메인 콘텐츠 영역
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),

              // 편지 수신자 표시
              const Text(
                'TO. 정동연',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Pretendard',
                ),
              ),
              const SizedBox(height: 24),

              // 편지 내용을 담는 컨테이너
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  // 그림자 효과 추가
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 편지 제목
                    Text(
                      widget.letter.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Pretendard',
                      ),
                    ),
                    const SizedBox(height: 12),

                    // 편지 내용
                    Text(
                      widget.letter.content,
                      style: const TextStyle(
                        fontSize: 14,
                        fontFamily: 'Pretendard',
                        height: 1.7, // 줄 간격 설정
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 답장 상태 표시 및 애니메이션 영역
              Center(
                child: Column(
                  children: [
                    // 답장 상태 메시지
                    Text(
                      isArrived
                          ? '편지 답장이 도착했어요!' // 답장 도착 시
                          : '답장을 기다리는 중이에요', // 답장 대기 시
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Pretendard',
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Lottie 애니메이션 표시
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: isArrived
                          ? Lottie.asset(
                        'asset/animation/letter_open.json', // 편지 열린 애니메이션
                        width: 280,
                        height: 280,
                        fit: BoxFit.cover,
                        repeat: false, // 한 번만 재생
                      )
                          : Lottie.asset(
                        'asset/animation/letter_close.json', // 편지 닫힌 애니메이션
                        width: 280,
                        height: 280,
                        fit: BoxFit.cover,
                        repeat: true, // 반복 재생
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 답장 확인 버튼
                    SizedBox(
                      width: 200,
                      height: 48,
                      child: ElevatedButton(
                        // 답장이 도착했을 때만 버튼 활성화
                        onPressed: isArrived
                            ? () {
                          // 답장 확인 버튼 클릭 시 로그 출력
                          print('답장 확인 버튼 클릭: replyContent=$replyContent');

                          // 답장 상세 페이지로 이동
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => LetterReplyDetailPage(
                                replyLetter: replyContent ?? '답장이 아직 없습니다.',
                              ),
                            ),
                          );
                        }
                            : null, // 답장이 도착하지 않았으면 버튼 비활성화
                        style: ElevatedButton.styleFrom(
                          // 답장 도착 여부에 따라 색상 변경
                          backgroundColor: isArrived
                              ? const Color(0xFFBB9DF7) // 활성화 시 보라색
                              : const Color(0xFFBFBFBF), // 비활성화 시 회색
                          disabledBackgroundColor: const Color(0xFFBFBFBF),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
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
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}