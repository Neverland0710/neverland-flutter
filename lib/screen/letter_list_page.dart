import 'dart:async'; // ⏱ 자동 갱신을 위한 타이머
import 'package:flutter/material.dart';
import 'package:neverland_flutter/model/letter.dart';
import 'package:neverland_flutter/screen/letter_detail_page.dart';


class LetterListPage extends StatefulWidget {
  final List<Letter> letters;

  const LetterListPage({super.key, required this.letters});

  @override
  State<LetterListPage> createState() => _LetterListPageState();
}

class _LetterListPageState extends State<LetterListPage> {
  @override
  void initState() {
    super.initState();

    // ⏱ 1초마다 setState 호출 → isArrived 상태 반영을 위해 강제 갱신
    Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {});
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
            // 📦 전체 편지 수
            Text('총 ${widget.letters.length}건', style: const TextStyle(fontSize: 14)),
            const Divider(height: 20),

            // 📬 편지 목록
            Expanded(
              child: ListView.builder(
                itemCount: widget.letters.length,
                itemBuilder: (context, index) {
                  final letter = widget.letters[index];
                  final isArrived = letter.isArrived;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: isArrived ? Colors.white : Colors.grey[300], // 도착 여부에 따라 배경색
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // 📝 제목 + 날짜
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                letter.title,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Pretendard',
                                  color: isArrived ? Colors.black : Colors.black45,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                letter.formattedDate,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isArrived ? Colors.grey : Colors.grey[600],
                                ),
                              ),
                            ],
                          ),

                          // 📨 답장 도착 버튼
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFBB9DF7),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => LetterDetailPage(letter: letter),
                                ),
                              );
                            },

                            child: const Text(
                              '답장 도착',
                              style: TextStyle(color: Colors.white),
                            ),
                          )
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 20),

            // 📝 작성하러 돌아가기 버튼
            Padding(
              padding: const EdgeInsets.only(bottom: 42),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // 뒤로가기 (편지 작성 화면)
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFBB9DF7),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    '내 마음을 전해보기',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
