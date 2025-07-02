import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:neverland_flutter/model/letter.dart';
import 'letter_list_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// 편지 작성 화면을 제공하는 StatefulWidget
/// 사용자가 고인에게 보낼 편지를 작성하고 저장할 수 있는 폼을 제공
class LetterWritePage extends StatefulWidget {
  const LetterWritePage({super.key});

  @override
  State<LetterWritePage> createState() => _LetterWritePageState();
}

class _LetterWritePageState extends State<LetterWritePage> {
  // 텍스트 입력 필드 제어를 위한 컨트롤러들
  final TextEditingController _titleController = TextEditingController(); // 편지 제목 입력 컨트롤러
  final TextEditingController _contentController = TextEditingController(); // 편지 내용 입력 컨트롤러

  bool _showInfo = true; // 유의사항 및 글자수 제한 정보 표시 여부 (처음엔 보여주기)

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 배경색을 흰색으로 설정
      backgroundColor: const Color(0xFFFFFFFF),

      // 상단 앱바 설정
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFFFFF), // 앱바 배경색 흰색
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
          padding: const EdgeInsets.all(20), // 전체 패딩 20px
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, // 왼쪽 정렬
            children: [
              // 편지 수신자 표시 (TO. 엄마)
              const Text(
                'TO. 엄마',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Pretendard',
                ),
              ),

              const SizedBox(height: 20), // 여백

              // 편지 제목 입력 필드
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  hintText: '제목을 입력하세요',
                  border: UnderlineInputBorder(), // 밑줄 스타일 테두리
                ),
              ),

              const SizedBox(height: 16), // 여백

              // 편지 내용 입력 영역 컨테이너
              Container(
                padding: const EdgeInsets.all(16), // 내부 패딩 16px
                decoration: BoxDecoration(
                  color: Colors.white, // 배경색 흰색
                  borderRadius: BorderRadius.circular(8), // 모서리 둥글게 8px
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, // 왼쪽 정렬
                  children: [
                    // 편지 내용 입력 필드 (멀티라인)
                    TextField(
                      controller: _contentController,
                      maxLines: null, // 줄 수 제한 없음 (자동 늘어남)
                      maxLength: 2000, // 최대 2000자 제한
                      // 텍스트 입력 시 유의사항 숨기기
                      onChanged: (_) {
                        if (_showInfo) {
                          setState(() {
                            _showInfo = false; // 사용자가 타이핑 시작하면 정보 숨김
                          });
                        }
                      },
                      decoration: const InputDecoration(
                        hintText: '내용을 입력해주세요.',
                        border: InputBorder.none, // 테두리 없음
                        counterText: '', // 글자수 카운터 숨김
                      ),
                    ),

                    const SizedBox(height: 8), // 여백

                    // 유의사항 및 글자수 제한 정보 (조건부 표시)
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
                      const SizedBox(height: 8), // 여백

                      // 유의사항 텍스트
                      const Text(
                        '유의사항\n'
                            '・ 하늘에서 온 편지 생성되기까지 작성 완료 후 하루 소요될 수 있습니다.\n'
                            '・ 편지 작성 완료 후, 편지 내용 수정은 불가능합니다.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          height: 1.6, // 줄간격 1.6배
                          fontFamily: 'Pretendard',
                        ),
                      ),
                    ]
                  ],
                ),
              ),

              const SizedBox(height: 24), // 여백

              // 작성 완료 버튼
              SizedBox(
                width: double.infinity, // 전체 너비 사용
                height: 48, // 버튼 높이 고정
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFBB9DF7), // 보라색 배경
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12), // 모서리 둥글게
                    ),
                  ),
                  // 버튼 클릭 시 편지 저장 및 목록 페이지로 이동
                  onPressed: () async {
                    // 제목 입력 검증 (공백 제거 후 빈 값 체크)
                    final title = _titleController.text.trim();
                    if (title.isEmpty) return; // 제목이 없으면 아무것도 안 함

                    // 현재 시간과 내용 가져오기
                    final now = DateTime.now();
                    final content = _contentController.text.trim();

                    // 새로운 편지 객체 생성
                    final newLetter = Letter(
                      title: title,
                      content: content,
                      createdAt: now,
                      replyContent: '하늘에서 온 AI 답장이에요 ', // 임시 답장 내용
                    );

                    // ✅ SharedPreferences를 사용하여 로컬 저장소에 편지 저장
                    final prefs = await SharedPreferences.getInstance();

                    // 편지 객체를 Map으로 변환 (JSON 저장을 위해)
                    final letterMap = {
                      'title': newLetter.title,
                      'content': newLetter.content,
                      'createdAt': newLetter.createdAt.toIso8601String(), // ISO 8601 형식으로 변환
                      'replyContent': newLetter.replyContent ?? '',
                    };

                    // JSON 문자열로 인코딩하여 저장
                    await prefs.setString('savedLetter', jsonEncode(letterMap));

                    // ✅ 편지 등록 완료 후 편지 목록 페이지로 이동
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

              // 하단 여백 (기기의 안전 영역 + 추가 20px)
              SizedBox(height: MediaQuery.of(context).padding.bottom + 20),
            ],
          ),
        ),
      ),
    );
  }
}