import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';

class VoiceCallScreen extends StatefulWidget {
  const VoiceCallScreen({super.key});

  @override
  State<VoiceCallScreen> createState() => _VoiceCallScreenState();
}

class _VoiceCallScreenState extends State<VoiceCallScreen>
    with TickerProviderStateMixin {
  bool _isPressed = false;
  bool isListening = false;

  late final AnimationController _lottieController;
  bool _hasPlayed = false;

  @override
  void initState() {
    super.initState();
    _lottieController = AnimationController(vsync: this);
  }

  @override
  void dispose() {
    _lottieController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0x66000000),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 24),
            Row(
              children: [
                const SizedBox(width: 24),
                const CircleAvatar(
                  radius: 24,
                  backgroundColor: Color(0xFFBB9DF7),
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
                        fontSize: 18,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '00:58',
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
            Expanded(
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                decoration: BoxDecoration(
                  color: const Color(0xFFE9F0F9),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: SingleChildScrollView( // ✅ 스크롤 추가
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      isListening
                          ? const Icon(
                        Icons.graphic_eq,
                        size: 40,
                        color: Colors.deepPurple,
                      )
                          : SizedBox(
                        width: 80,
                        height: 80,
                        child: Lottie.asset(
                          'asset/animation/voice_wave.json',
                          fit: BoxFit.contain,
                          repeat: true,
                        ),
                      ),
                      const SizedBox(height: 30),
                      const Text(
                        '나의 말을 듣고 있습니다.',
                        style: TextStyle(
                          fontFamily: 'pretendard',
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 30),
                      const Text(
                        '안녕 동연아 여친이랑 언제 헤어지니?\n\n'
                            '동연아 또 술먹고 안나오는거야?\n\n'
                            '그러게 술 조절해야지?\n\n'
                            '자기 몸 관리도 자기 능력이야?\n\n'
                            '그래서 대체 백엔드 연결은 언제할껀데?\n\n'
                            '백엔드가 되야 프론트가 일을하지.\n\n'
                            '나 심심해 일줘 빨리\n\n'
                            '백엔드 연결좀 하자고 제발 빨리와라\n\n'
                            '심심해 심심해 일줘 백엔드 시발아\n\n'
                            '나 이러다 마지막에 일 ㅈㄴ 몰아줄꺼냐고\n\n',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 30),
                      const Text(
                        '동연이가 대답을 준비중이에요',
                        style: TextStyle(
                          fontFamily: 'pretendard',
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 30),
                      const Text(
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
            ),

            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTapDown: (_) => setState(() => _isPressed = true),
                        onTapUp: (_) => setState(() => _isPressed = false),
                        onTapCancel: () => setState(() => _isPressed = false),
                        onTap: () {
                          HapticFeedback.mediumImpact();
                          Navigator.pop(context);
                        },
                        child: AnimatedScale(
                          scale: _isPressed ? 1.0 : 1.0,
                          duration: const Duration(milliseconds: 100),
                          curve: Curves.easeInOut,
                          child: Transform.translate(
                            offset: const Offset(-10, 15),
                            child: SizedBox(
                              width: 100,
                              height: 100,
                              child: Lottie.asset(
                                'asset/animation/call_end.json',
                                controller: _lottieController,
                                onLoaded: (composition) {
                                  _lottieController.duration = composition.duration;
                                  if (!isListening && !_hasPlayed) {
                                    _hasPlayed = true;
                                    _lottieController
                                      ..reset()
                                      ..forward();
                                  }
                                  if (isListening) {
                                    _hasPlayed = false;
                                  }
                                },
                                repeat: false,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Transform.translate(
                        offset: const Offset(-8, 0),
                        child: const Text(
                          '통화 종료',
                          style: TextStyle(
                            fontFamily: 'Pretendard',
                            fontSize: 16,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                blurRadius: 4,
                                offset: Offset(1, 1),
                                color: Colors.black26,
                              )
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  Transform.translate(
                    offset: const Offset(-70, 0),
                    child: Column(
                      children: [
                        Visibility(
                          visible: isListening,
                          maintainSize: true,
                          maintainAnimation: true,
                          maintainState: true,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Transform.translate(
                                offset: Offset(0, 75), // ← 숫자 늘리면 더 아래로 감
                                child: Image.asset(
                                  'asset/image/speech_bubble.png',
                                  width: 240,
                                ),
                              ),

                              Transform.translate(
                                offset: Offset(0, 70), // ← 원하는 만큼 아래로 조절
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
                        InkWell(
                          onTap: () {
                            setState(() {
                              isListening = !isListening;
                              if (!isListening) {
                                _lottieController
                                  ..reset()
                                  ..forward();
                              }
                            });
                          },
                          child: Column(
                            children: [
                              isListening
                                  ? Transform.translate(
                                offset: const Offset(0, 45),
                                child: Lottie.asset(
                                  'asset/animation/record_pulse.json',
                                  width: 160,
                                  height: 160,
                                  fit: BoxFit.contain,
                                ),
                              )
                                  : Transform.translate(
                                offset: Offset(0, -12), // ← y축 -값이면 위로 올라감
                                child: Transform.scale(
                                  scale: 2.5, // ← 크기 조절
                                  child: Lottie.asset(
                                    'asset/animation/voice_playing.json',
                                    width: 48,
                                    height: 48,
                                    repeat: true,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),


                              const SizedBox(height: 8),
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
