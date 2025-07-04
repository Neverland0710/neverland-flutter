import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:neverland_flutter/model/letter.dart';
import 'package:neverland_flutter/screen/letter_detail_page.dart';
import 'package:neverland_flutter/screen/letter_write_page.dart';
import 'package:neverland_flutter/screen/main_page.dart';

class LetterListPage extends StatefulWidget {
  const LetterListPage({super.key});

  @override
  State<LetterListPage> createState() => _LetterListPageState();
}

class _LetterListPageState extends State<LetterListPage> {
  Timer? _timer;
  List<Letter> _letters = [];

  @override
  void initState() {
    super.initState();
    _loadLettersFromServer();

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadLettersFromServer() async {
    final prefs = await SharedPreferences.getInstance();
    final authKeyId = prefs.getString('authKeyId') ?? 'default_user_id';

    try {
      final response = await http.get(
        Uri.parse('http://192.168.219.68:8086/letter/list?authKeyId=$authKeyId'),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final List<dynamic> jsonList = jsonDecode(response.body);
        setState(() {
          _letters = jsonList.map((e) => Letter.fromJson(e)).toList();
        });
      } else {
        print('❌ 서버 오류: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('❌ 네트워크 오류: $e');
    }
  }

  // 편지를 서버에 전송하는 함수
  Future<Letter?> _sendLetterToServer(Letter letter) async {
    final prefs = await SharedPreferences.getInstance();
    final authKeyId = prefs.getString('auth_key_id') ?? '';
    final userId = prefs.getString('user_id') ?? '';

    print('📦 전송 전 authKeyId: $authKeyId');
    print('📦 전송 전 userId: $userId');

    if (authKeyId.isEmpty || userId.isEmpty) {
      print('❗ authKeyId 또는 userId가 비어있습니다.');
      return null;
    }

    // 성공한 방식: snake_case 사용
    final requestBody = {
      'user_id': userId,
      'auth_key_id': authKeyId,
      'title': letter.title,
      'content': letter.content,
      'created_at': letter.createdAt.toIso8601String(),
    };

    print('📦 전송할 데이터: ${jsonEncode(requestBody)}');

    try {
      final response = await http.post(
        Uri.parse('http://192.168.219.68:8086/letter/send'),
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Accept': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      print('📦 응답 상태 코드: ${response.statusCode}');
      print('📦 응답 본문: ${response.body}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        print('✅ 편지 전송 성공');

        // 응답이 비어있거나 JSON이 아닐 수 있으므로 안전하게 처리
        try {
          if (response.body.isNotEmpty && response.body.trim().startsWith('{')) {
            final responseData = jsonDecode(response.body);
            return Letter.fromJson(responseData);
          } else {
            // 응답이 JSON이 아니라면 기본 Letter 객체 반환
            print('📦 응답이 JSON 형식이 아님, 기본 편지 객체 생성');
            return Letter(
              id: letter.id,
              title: letter.title,
              content: letter.content,
              createdAt: letter.createdAt,
              deliveryStatus: 'SENT',
              replyContent: null,
            );
          }
        } catch (parseError) {
          print('📦 응답 파싱 오류: $parseError');
          // 파싱 실패해도 기본 편지 객체 반환
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
        print('❌ 편지 전송 실패: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('❌ 편지 전송 오류: $e');
      return null;
    }
  }

  // 답장 생성 API 호출 함수
  Future<void> _generateReply(String letterId) async {
    final prefs = await SharedPreferences.getInstance();
    final authKeyId = prefs.getString('auth_key_id') ?? '';
    final userId = prefs.getString('user_id') ?? '';

    print('📨 답장 생성 요청 - letterId: $letterId, authKeyId: $authKeyId, userId: $userId');

    if (authKeyId.isEmpty || userId.isEmpty) {
      print('❗ _generateReply: authKeyId 또는 userId가 비어있습니다.');
      return;
    }

    final requestBody = {
      'letterId': letterId,
      'authKeyId': authKeyId,
      'userId': userId,
    };

    print('📨 답장 생성 요청 데이터: ${jsonEncode(requestBody)}');

    try {
      final response = await http.post(
        Uri.parse('http://192.168.219.68:8086/letter/reply'),
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Accept': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      print('📨 답장 생성 응답 상태: ${response.statusCode}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        print('✅ 답장 생성 요청 성공');
      } else {
        print('❌ 답장 생성 요청 실패: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('❌ 답장 생성 오류: $e');
    }
  }

  // 주기적으로 답장 상태 확인하는 함수
  void _startPollingForReply(String letterId) {
    Timer.periodic(const Duration(seconds: 5), (timer) async {
      if (!mounted) {
        timer.cancel();
        return;
      }

      // 서버에서 최신 편지 정보 가져오기
      await _loadLettersFromServer();

      // 답장이 도착했는지 확인
      try {
        final updatedLetter = _letters.firstWhere(
              (letter) => letter.id == letterId,
        );

        if (updatedLetter.deliveryStatus == 'DELIVERED') {
          timer.cancel(); // 답장 도착 시 폴링 중단
          print('✅ 답장 도착 확인됨');
        }
      } catch (e) {
        print('편지를 찾을 수 없습니다: $letterId');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFFFFF),
        elevation: 0,
        leading: const BackButton(color: Colors.black),
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
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('총 ${_letters.length}건', style: const TextStyle(fontSize: 14)),
            const Divider(height: 20),
            ElevatedButton(
              onPressed: () async {
                final result = await Navigator.push<Letter>(
                  context,
                  MaterialPageRoute(builder: (_) => const LetterWritePage()),
                );

                if (result != null) {
                  // 1. 먼저 회색 카드로 리스트에 추가
                  setState(() {
                    _letters.insert(0, result);
                  });

                  // 2. 서버에 편지 전송 (서버에서 편지 전송과 답장 생성을 한 번에 처리)
                  final serverLetter = await _sendLetterToServer(result);
                  if (serverLetter != null) {
                    setState(() {
                      _letters[0] = serverLetter;
                    });

                    print('✅ 편지 전송 완료! 서버에서 답장 생성도 함께 처리됨');

                    // 답장 상태 확인을 위한 폴링 시작
                    _startPollingForReply(serverLetter.id);
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFBB9DF7),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('편지 작성하기', style: TextStyle(color: Colors.white)),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: _letters.length,
                itemBuilder: (context, index) {
                  final letter = _letters[index];

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: letter.isArrived ? Colors.white : Colors.grey[300],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                letter.title,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Pretendard',
                                  color: letter.isArrived ? Colors.black : Colors.black45,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                letter.formattedDate,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: letter.isArrived ? Colors.grey : Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFBB9DF7),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                onPressed: letter.isArrived
                                    ? () async {
                                  final prefs = await SharedPreferences.getInstance();
                                  final authKeyId = prefs.getString('auth_key_id') ?? 'default_user_id';
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          LetterDetailPage(letter: letter, authKeyId: authKeyId),
                                    ),
                                  );
                                }
                                    : null,
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
            Padding(
              padding: const EdgeInsets.only(bottom: 42),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const MainPage(fromLetter: true)),
                        (route) => false,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFBB9DF7),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  minimumSize: const Size(double.infinity, 48),
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