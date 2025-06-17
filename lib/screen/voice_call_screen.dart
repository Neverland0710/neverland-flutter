import 'package:flutter/material.dart';

class VoiceCallScreen extends StatelessWidget {
  const VoiceCallScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0x66000000), // 반투명 블랙
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 24),

            // 프로필
            Row(
              children: [
                const SizedBox(width: 24),
                const CircleAvatar(
                  radius: 24,
                  backgroundColor: Color(0xFFABC9E8),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '정동연',
                      style: TextStyle(
                        fontFamily: 'pretendard',
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '00:58',
                      style: TextStyle(
                        fontFamily: 'pretendard',
                        fontSize: 12,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 24),

            // 대화 영역
            Expanded(
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                decoration: BoxDecoration(
                  color: const Color(0xFFE9F0F9),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(Icons.graphic_eq, size: 40, color: Colors.grey),
                    SizedBox(height: 30),
                    Text(
                      '나의 말을 듣고 있습니다.',
                      style: TextStyle(
                        fontFamily: 'pretendard',
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                    SizedBox(height: 30),
                    Text(
                      '안녕 동연아 여친이랑 언제 헤어지니?',
                      style: TextStyle(
                        fontFamily: 'pretendard',
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                        color: Colors.black,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 30),
                    Text(
                      '동연이가 대답을 준비중이에요',
                      style: TextStyle(
                        fontFamily: 'pretendard',
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                    SizedBox(height: 30),
                    Text(
                      '몰라 하늘나라에 있는데 어떻게 알아',
                      style: TextStyle(
                        fontFamily: 'pretendard',
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),
            const SizedBox(height: 16),

            // 하단 버튼 영역
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 통화 종료
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      InkWell(
                        onTap: () {
                          Navigator.pop(context);
                        },
                        child: const CircleAvatar(
                          radius: 30,
                          backgroundColor: Colors.red,
                          child: Icon(Icons.call_end, color: Colors.white),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '통화 종료',
                        style: TextStyle(
                          fontFamily: 'pretendard',
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),

                  // 그만 말하기
                  Transform.translate(
                    offset: const Offset(-70, 0),
                    child: Column(
                      children: [
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            Image.asset(
                              'asset/image/speech_bubble.png',
                              width: 220,
                            ),
                            const Padding(
                              padding: EdgeInsets.only(bottom: 15),
                              child: Text(
                                '말씀을 멈추고 답변을 들으시려면\n버튼을 눌러주세요.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: 'pretendard',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        InkWell(
                          onTap: () {
                            // TODO
                          },
                          child: const CircleAvatar(
                            radius: 30,
                            backgroundColor: Color(0xFF7FA8D7),
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.all(Radius.circular(6)),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          '그만 말하기',
                          style: TextStyle(
                            fontFamily: 'pretendard',
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
