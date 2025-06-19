import 'package:flutter/material.dart';
import 'package:neverland_flutter/model/letter.dart';
import 'package:neverland_flutter/screen/letter_list_page.dart';
import 'package:neverland_flutter/screen/letter_write_page.dart';
import 'package:neverland_flutter/screen/voice_call_screen.dart';
import 'package:neverland_flutter/screen/chat_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class MainPage extends StatefulWidget {
  final bool fromLetter;
  const MainPage({super.key, this.fromLetter = false});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  List<Letter> _letters = [];
  bool _hasArrivedLetter = false;

  @override
  void initState() {
    super.initState();
    _loadLetters();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // 👉 다른 화면(편지쓰기/리스트 등)에서 돌아왔을 때만 불러오기
    if (widget.fromLetter) {
      _loadLetters();
    }
  }

  void _loadLetters() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString('savedLetter');

    if (jsonStr != null) {
      final map = jsonDecode(jsonStr);
      final createdAt = DateTime.parse(map['createdAt']);

      final letter = Letter(
        title: map['title'],
        content: map['content'],
        createdAt: createdAt,
        replyContent: map['replyContent'],
      );

      setState(() {
        _letters = [letter];
        _hasArrivedLetter = letter.hasReply;
      });
    } else {
      setState(() {
        _letters = [];
        _hasArrivedLetter = false;
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // ✅ 상단 배경 이미지
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 375 / 200,
                  child: Image.asset(
                    'asset/image/main_header.png',
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 30,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(40),
                        topRight: Radius.circular(40),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),
                    const Center(
                      child: Text(
                        '오늘은 어떤 기억을 함께 나눠볼까요?',
                        style: TextStyle(
                          fontFamily: 'Pretendard',
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ✅ 당신에게 온 편지
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 30),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8E4FF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                '당신에게 온 편지',
                                style: TextStyle(
                                  fontFamily: 'Pretendard',
                                  fontWeight: FontWeight.w700,
                                  fontSize: 18,
                                  color: Colors.black,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                '도착한 편지가 있어요!',
                                style: TextStyle(
                                  fontFamily: 'Pretendard',
                                  fontSize: 14,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                          ElevatedButton(
                            onPressed: _hasArrivedLetter
                                ? () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => LetterListPage(letters: _letters),
                                ),
                              );
                            }
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _hasArrivedLetter ? const Color(0xFFBB9DF7) : Colors.grey[300],
                              minimumSize: const Size(72, 36),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              '바로 읽기',
                              style: TextStyle(
                                fontFamily: 'Pretendard',
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ✅ 메뉴 카드 3개 - 이미지 포함
                    _buildCardMenu(
                      context,
                      imagePath: 'asset/image/call_icon.png',
                      title: '실시간 통화',
                      description: '그리운 사람의 목소리를 다시 들어보세요',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const VoiceCallScreen(),
                          ),
                        );
                      },
                    ),
                    _buildCardMenu(
                      context,
                      imagePath: 'asset/image/chat_icon.png',
                      title: '실시간 채팅',
                      description: '그때 못다 한 이야기를 전할 수 있어요',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const RealTimeChatPage(),
                          ),
                        );
                      },
                    ),
                    _buildCardMenu(
                      context,
                      imagePath: 'asset/image/letter_icon.png',
                      title: '내게 온 편지',
                      description: '하늘에서 도착한 마음을 읽어보세요',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LetterWritePage(),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardMenu(
      BuildContext context, {
        required String imagePath,
        required String title,
        required String description,
        required VoidCallback onTap,
      }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.black12),
          ),
          child: Row(
            children: [
              Image.asset(
                imagePath,
                width: 36,
                height: 36,
                color: const Color(0xFFBB9DF7),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontFamily: 'Pretendard',
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: const TextStyle(
                        fontFamily: 'Pretendard',
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
