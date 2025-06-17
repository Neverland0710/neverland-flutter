import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:neverland_flutter/model/letter.dart';
import 'package:neverland_flutter/screen/letter_list_page.dart'; // ✅ 중복 import 제거

class LetterWritePage extends StatefulWidget {
  const LetterWritePage({super.key});

  @override
  State<LetterWritePage> createState() => _LetterWritePageState();
}

class _LetterWritePageState extends State<LetterWritePage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  bool _showInfo = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE9F0F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFFE9F0F9),
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
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'TO. 엄마',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Pretendard',
                ),
              ),
              const SizedBox(height: 20),

              // 🔤 제목 입력 필드
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  hintText: '제목을 입력하세요',
                  border: UnderlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // 📝 본문 입력 영역
              Expanded(
                child: Container(
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

                      // ℹ️ 안내 문구 (처음에만 보임)
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
              ),
              const SizedBox(height: 24),

              // ✅ 작성 완료 버튼
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF90B4E0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    final title = _titleController.text.trim();
                    final content = _contentController.text.trim();
                    if (title.isEmpty) return;

                    // ✉️ 편지 객체 생성
                    final newLetter = Letter(
                      title: title,
                      content: content,
                      createdAt: DateTime.now(),
                    );

                    // 📬 작성 완료 후 편지 리스트 페이지로 이동
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => LetterListPage(letters: [newLetter]),
                      ),
                    );
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
            ],
          ),
        ),
      ),
    );
  }
}
