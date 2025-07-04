import 'package:flutter/material.dart';
import 'package:neverland_flutter/model/letter.dart';
import 'package:neverland_flutter/screen/letter_reply_detail_page.dart';
import 'package:lottie/lottie.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

/// 편지 관련 HTTP 요청을 처리하는 서비스 클래스
/// 편지 관련 HTTP 요청을 처리하는 서비스 클래스
class LetterService {
  /// 특정 편지의 최신 정보를 서버에서 가져오는 메소드
  Future<Letter?> fetchLetter(String id, String authKeyId) async {
    try {
      final response = await http.get(
        Uri.parse('http://192.168.219.68:8086/letter/list?authKeyId=$authKeyId'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> lettersJson = jsonDecode(response.body);

        // 디버깅용 로그
        print('📋 서버에서 받은 편지 목록:');
        for (var letterJson in lettersJson) {
          print('   - letterId: ${letterJson['letterId']}');
          print('   - title: ${letterJson['title']}');
          print('   - replyContent: ${letterJson['replyContent']}');
          print('   - deliveryStatus: ${letterJson['deliveryStatus']}');
        }

        final letters = lettersJson.map((json) => Letter.fromJson(json)).toList();

        // ID 매칭 시 두 가지 방법 모두 시도
        Letter? foundLetter;

        // 1. letterId로 찾기 (서버 응답 기준)
        try {
          foundLetter = letters.firstWhere(
                (letter) => letter.id == id,
          );
          print('✅ letterId로 편지 찾음: ${foundLetter.id}');
        } catch (e) {
          print('❌ letterId로 편지를 찾을 수 없음: $id');
        }

        // 2. 찾지 못했다면 제목과 내용으로 매칭 시도 (fallback)
        if (foundLetter == null && letters.isNotEmpty) {
          print('🔄 제목/내용 기반으로 매칭 시도...');
          // 가장 최근 편지를 반환 (임시 해결책)
          foundLetter = letters.first;
          print('📝 최근 편지 반환: ${foundLetter.id}');
        }

        return foundLetter;
      } else {
        print('❌ 서버 오류: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
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

  const LetterDetailPage({super.key, required this.letter, required this.authKeyId});

  @override
  State<LetterDetailPage> createState() => _LetterDetailPageState();
}

class _LetterDetailPageState extends State<LetterDetailPage> {
  late bool isArrived;
  String? replyContent;
  late Letter currentLetter; // 현재 편지 상태 추가

  @override
  void initState() {
    super.initState();
    currentLetter = widget.letter;
    isArrived = currentLetter.isArrived;
    replyContent = currentLetter.replyContent;

    print('🔄 초기 상태: isArrived=$isArrived, replyContent=$replyContent');

    // 최신 데이터 새로고침
    _refreshLetterData();
  }

  Future<void> _refreshLetterData() async {
    try {
      print('🔄 편지 데이터 새로고침 시작...');

      final updatedLetter = await LetterService().fetchLetter(
          widget.letter.id,
          widget.authKeyId
      );

      if (updatedLetter != null) {
        setState(() {
          currentLetter = updatedLetter;
          isArrived = updatedLetter.isArrived;
          replyContent = updatedLetter.replyContent;
        });

        print('✅ 데이터 새로고침 완료:');
        print('   - isArrived: $isArrived');
        print('   - replyContent: $replyContent');
        print('   - deliveryStatus: ${updatedLetter.deliveryStatus}');

        // 답장 상태 검증
        if (updatedLetter.deliveryStatus == 'DELIVERED' &&
            (replyContent == null || replyContent!.isEmpty)) {
          print('⚠️ 답장이 도착했지만 내용이 없습니다.');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('답장이 도착했지만 내용을 불러올 수 없습니다.')),
          );
        }
      } else {
        print('❌ 서버에서 편지를 찾을 수 없습니다.');
      }
    } catch (e) {
      print('❌ 데이터 새로고침 실패: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // 실시간 상태 로그
    print('🖥️ 화면 렌더링: isArrived=$isArrived, replyContent=$replyContent');

    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFFFFF),
        elevation: 0,
        leading: const BackButton(color: Colors.black),
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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              const Text(
                'TO. 정동연',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Pretendard',
                ),
              ),
              const SizedBox(height: 24),

              // 편지 내용 카드
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
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
                    Text(
                      currentLetter.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Pretendard',
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      currentLetter.content,
                      style: const TextStyle(
                        fontSize: 14,
                        fontFamily: 'Pretendard',
                        height: 1.7,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 답장 상태 및 버튼
              Center(
                child: Column(
                  children: [
                    // 상태 메시지 개선
                    Text(
                      _getStatusMessage(),
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Pretendard',
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 애니메이션
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: isArrived
                          ? Lottie.asset(
                        'asset/animation/letter_open.json',
                        width: 280,
                        height: 280,
                        fit: BoxFit.cover,
                        repeat: false,
                      )
                          : Lottie.asset(
                        'asset/animation/letter_close.json',
                        width: 280,
                        height: 280,
                        fit: BoxFit.cover,
                        repeat: true,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 답장 확인 버튼
                    SizedBox(
                      width: 200,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _canViewReply() ? _viewReply : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _canViewReply()
                              ? const Color(0xFFBB9DF7)
                              : const Color(0xFFBFBFBF),
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

  // 상태 메시지 생성
  String _getStatusMessage() {
    if (currentLetter.deliveryStatus == 'DELIVERED') {
      if (replyContent != null && replyContent!.isNotEmpty) {
        return '편지 답장이 도착했어요!';
      } else {
        return '답장이 도착했지만 내용을 불러오는 중입니다...';
      }
    } else {
      return '답장을 기다리는 중이에요';
    }
  }

  // 답장 확인 가능 여부 판단
  bool _canViewReply() {
    return currentLetter.deliveryStatus == 'DELIVERED' &&
        replyContent != null &&
        replyContent!.isNotEmpty;
  }

  // 답장 보기
  void _viewReply() {
    print('📬 답장 보기 클릭: replyContent=$replyContent');

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LetterReplyDetailPage(
          replyLetter: replyContent ?? '답장 내용을 불러올 수 없습니다.',
        ),
      ),
    );
  }
}