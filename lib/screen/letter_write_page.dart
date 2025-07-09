import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:neverland_flutter/model/letter.dart';
import 'letter_list_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import 'package:neverland_flutter/screen/main_page.dart';

class LetterWritePage extends StatefulWidget {
  final String userId;

  const LetterWritePage({super.key, required this.userId});

  @override
  State<LetterWritePage> createState() => _LetterWritePageState();
}

class _LetterWritePageState extends State<LetterWritePage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();

  bool _showInfo = true;
  bool _isLoading = false;
  String recipientName = '...';

  @override
  void initState() {
    super.initState();
    _loadRecipientName();
  }

  Future<void> _loadRecipientName() async {
    try {
      final response = await http.get(
        Uri.parse('http://52.78.139.47:8086/chat/relation?userId=${widget.userId}'),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            recipientName = data['relation'] ?? '...';
          });
        }
      } else {
        print('❌ 이름 불러오기 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ 네트워크 오류: $e');
    }
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
          '내게 온 편지',
          style: TextStyle(
            fontFamily: 'Pretendard',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'TO. $recipientName',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Pretendard',
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  hintText: '제목을 입력하세요',
                  border: UnderlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _contentController,
                      maxLines: null,
                      maxLength: 2000,
                      onChanged: (_) {
                        if (_showInfo) {
                          setState(() {
                            _showInfo = false;
                          });
                        }
                      },
                      decoration: const InputDecoration(
                        hintText: '내용을 입력해주세요.',
                        border: InputBorder.none,
                        counterText: '',
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_showInfo) ...[
                      const Text(
                        '편지는 최대 2,000자 제한합니다.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.black87,
                          fontFamily: 'Pretendard',
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '유의사항\n'
                            '・ 하늘에서 온 편지 생성되기까지 작성 완료 후 하루 소요될 수 있습니다.\n'
                            '・ 편지 작성 완료 후, 편지 내용 수정은 불가능합니다.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          height: 1.6,
                          fontFamily: 'Pretendard',
                        ),
                      ),
                    ]
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFBB9DF7),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _isLoading
                      ? null
                      : () async {
                    final title = _titleController.text.trim();
                    final content = _contentController.text.trim();

                    if (title.isEmpty || content.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('제목과 내용을 모두 입력해주세요')),
                      );
                      return;
                    }

                    final prefs = await SharedPreferences.getInstance();
                    final authKeyId = prefs.getString('authKeyId');
                    final userId = prefs.getString('user_id');
                    final now = DateTime.now().toIso8601String();

                    if (authKeyId == null || userId == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('인증 정보가 없습니다. 다시 로그인해주세요.')),
                      );
                      return;
                    }

                    setState(() {
                      _isLoading = true;
                    });

                    final requestBody = {
                      "title": title,
                      "content": content,
                      "authKeyId": authKeyId,
                      "user_id": userId,
                      "created_at": now,
                    };

                    print('📦 전송할 데이터: ${jsonEncode(requestBody)}');

                    // 전송 작업을 백그라운드에서 실행
                    unawaited(http.post(
                      Uri.parse('http://52.78.139.47:8086/letter/send'),
                      headers: {"Content-Type": "application/json"},
                      body: jsonEncode(requestBody),
                    ));

                    // 5초 후 자동으로 이동
                    await Future.delayed(const Duration(seconds: 3));

                    if (!mounted) return;

                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => const LetterListPage()),
                          (route) => false,
                    );
                  },
                  child: _isLoading
                      ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      ),
                      SizedBox(width: 12),
                      Text(
                        '편지를 전송 중이에요...',
                        style: TextStyle(color: Colors.white, fontFamily: 'Pretendard'),
                      ),
                    ],
                  )
                      : const Text(
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
              SizedBox(height: MediaQuery.of(context).padding.bottom + 20),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }
}
