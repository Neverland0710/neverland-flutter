import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class VoiceCallScreen extends StatefulWidget {
  const VoiceCallScreen({super.key});

  @override
  State<VoiceCallScreen> createState() => _VoiceCallScreenState();
}

class _VoiceCallScreenState extends State<VoiceCallScreen> {
  bool _isPressed = false; // 통화 종료 버튼 눌렀을 때 애니메이션용
  bool isListening = true; // true: 말하는 중 / false: 듣는 중

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0x66000000), // 배경 반투명 블랙
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 24),

            // ✅ 상단 프로필 영역
            Row(
              children: [
                const SizedBox(width: 24),
                const CircleAvatar(
                  radius: 24,
                  backgroundColor: Color(0xFFABC9E8), // 프로필 이미지 자리
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '정동연', // 고인 이름
                      style: TextStyle(
                        fontFamily: 'pretendard',
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '00:58', // 통화 시간
                      style: TextStyle(
                        fontFamily: 'pretendard',
                        fontSize: 14,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 24),

            // ✅ 대화 내용 박스
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
                    Icon(Icons.graphic_eq, size: 40, color: Colors.grey), // 마이크 파형 아이콘
                    SizedBox(height: 30),
                    Text(
                      '나의 말을 듣고 있습니다.', // 인식 상태 문구
                      style: TextStyle(
                        fontFamily: 'pretendard',
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                    SizedBox(height: 30),
                    Text(
                      '안녕 동연아 여친이랑 언제 헤어지니?', // 유족 질문
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
                      '동연이가 대답을 준비중이에요', // AI 응답 준비중
                      style: TextStyle(
                        fontFamily: 'pretendard',
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                    SizedBox(height: 30),
                    Text(
                      '몰라 하늘나라에 있는데 어떻게 알아', // AI 응답
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

            // ✅ 하단 버튼 영역
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 🔴 통화 종료 버튼
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTapDown: (_) => setState(() => _isPressed = true),
                        onTapUp: (_) => setState(() => _isPressed = false),
                        onTapCancel: () => setState(() => _isPressed = false),
                        onTap: () {
                          HapticFeedback.mediumImpact(); // 진동
                          Navigator.pop(context);        // 화면 닫기
                        },
                        child: AnimatedScale(
                          scale: _isPressed ? 0.9 : 1.0, // 누를 때 작아짐
                          duration: const Duration(milliseconds: 100),
                          curve: Curves.easeInOut,
                          child: CircleAvatar(
                            radius: 36,
                            backgroundColor: Colors.red,
                            child: const Icon(
                              Icons.call_end,
                              color: Colors.white,
                              size: 36,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '통화 종료',
                        style: TextStyle(
                          fontFamily: 'Pretendard',
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(
                              blurRadius: 4,
                              offset: Offset(1, 1),
                              color: Colors.black26,
                            )
                          ],
                        ),
                      ),
                    ],
                  ),

                  // 🔊 그만 말하기 / 답변 듣는 중 버튼
                  Transform.translate(
                    offset: const Offset(-70, 0), // 위치 조정
                    child: Column(
                      children: [
                        // 💬 말풍선 안내 (말하는 중에만 보임)
                        Visibility(
                          visible: isListening,
                          maintainSize: true,
                          maintainAnimation: true,
                          maintainState: true,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Image.asset(
                                'asset/image/speech_bubble.png',
                                width: 240,
                              ),
                              const Padding(
                                padding: EdgeInsets.only(bottom: 15),
                                child: Text(
                                  '말씀을 멈추고 답변을 들으시려면\n버튼을 눌러주세요.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontFamily: 'pretendard',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // ⭕ 버튼: 정지 / 재생
                        InkWell(
                          onTap: () {
                            setState(() {
                              isListening = !isListening; // 상태 반전
                            });
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF7FA8D7).withOpacity(0.4),
                                  blurRadius: 12,
                                  spreadRadius: 2,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: CircleAvatar(
                              radius: 36,
                              backgroundColor: const Color(0xFF7FA8D7),
                              child: isListening
                              // 말하는 중: 네모 버튼
                                  ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.all(Radius.circular(6)),
                                  ),
                                ),
                              )
                              // 듣는 중: 볼륨 아이콘
                                  : const Icon(
                                Icons.volume_up,
                                color: Colors.white,
                                size: 36,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 8),

                        // 텍스트 상태
                        Text(
                          isListening ? '그만 말하기' : '답변 듣는 중',
                          style: const TextStyle(
                            fontFamily: 'Pretendard',
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
