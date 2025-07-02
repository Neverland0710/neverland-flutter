import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter/scheduler.dart';

enum VoiceState {
  idle,
  speaking,
  listening,
}

class VoiceCallScreen extends StatefulWidget {
  const VoiceCallScreen({super.key});

  @override
  State<VoiceCallScreen> createState() => _VoiceCallScreenState();
}

class _VoiceCallScreenState extends State<VoiceCallScreen> with TickerProviderStateMixin {
  bool _isPressed = false;
  VoiceState _voiceState = VoiceState.idle;
  late final AnimationController _lottieController;
  late final Ticker _ticker;
  Duration _callDuration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _lottieController = AnimationController(vsync: this);
    _ticker = createTicker((elapsed) {
      setState(() {
        _callDuration = elapsed;
      });
    })..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _lottieController.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0x66000000),
      body: Stack(
        children: [
          Column(
            children: [
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.only(top: 24, left: 24, right: 24),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 24,
                        backgroundColor: Color(0xFFBB9DF7),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '정동연',
                            style: TextStyle(
                              fontFamily: 'pretendard',
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            _formatDuration(_callDuration),
                            style: const TextStyle(
                              fontFamily: 'pretendard',
                              fontSize: 14,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(30),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(50),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE9F0F9),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      children: [
                        if (_voiceState == VoiceState.speaking) ...[
                          const Icon(Icons.graphic_eq, size: 36, color: Colors.deepPurple),
                          const SizedBox(height: 12),
                          const Text(
                            '나의 말을 듣고 있습니다.',
                            style: TextStyle(
                              fontFamily: 'pretendard',
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ] else if (_voiceState == VoiceState.listening) ...[
                          SizedBox(
                            width: 60,
                            height: 60,
                            child: Lottie.asset(
                              'asset/animation/voice_wave.json',
                              fit: BoxFit.contain,
                              repeat: true,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            '동연이가 대답을 준비중이에요',
                            style: TextStyle(
                              fontFamily: 'pretendard',
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),
                        Expanded(
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const Text(
                                  '안녕 동연아 잘니?',
                                  style: TextStyle(
                                    fontFamily: 'pretendard',
                                    fontWeight: FontWeight.w600,
                                    fontSize: 18,
                                    color: Colors.black,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  '동연이가 대답을 준비중이에요',
                                  style: TextStyle(
                                    fontFamily: 'pretendard',
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                const Text(
                                  '이번엔 언제까지 오해깟까요',
                                  style: TextStyle(
                                    fontFamily: 'pretendard',
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                    color: Colors.black,
                                  ),
                                ),
                                if (_voiceState == VoiceState.listening) ...[
                                  const SizedBox(height: 20),
                                  const Text(
                                    '몰라 하늘나라에 있는데 어떻게 알아',
                                    style: TextStyle(
                                      fontFamily: 'pretendard',
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16,
                                      color: Colors.black,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 300), // 말풍선 + 버튼 여백 확보
            ],
          ),

          // 💬 말풍선
          if (_voiceState == VoiceState.idle)
            Positioned(
              bottom: 180, // 필요시 더 조절
              left: 0,
              right: 30,
              child: Center(
                child: SizedBox(
                  width: 360, // ⬅️ 기존보다 키운 사이즈 (예: 300 → 360)
                  height: 120, // ⬅️ 높이도 키우고 싶으면 추가
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Image.asset(
                        'asset/image/speech_bubble.png',
                        fit: BoxFit.contain,
                        width: 360, // ⬅️ 말풍선 이미지 크기도 맞춰줌
                      ),
                      const Positioned(
                        top: 35, // 텍스트 위치도 약간 조절 가능
                        child: SizedBox(
                          width: 240, // 텍스트 너비도 키움
                          child: Text(
                            '말하기 버튼을 누르고 말씀해주세요',
                            style: TextStyle(
                              fontFamily: 'Pretendard',
                              fontSize: 14, // 👉 폰트 크기 키움
                              fontWeight: FontWeight.w700, // 👉 굵게 (bold)
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // 🎤 하단 버튼
          Positioned(
            bottom: 32,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(
                  children: [
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        Navigator.pop(context);
                      },
                      child: Container(
                        width: 100,
                        height: 100,
                        child: Lottie.asset(
                          'asset/animation/call_end.json', // 경로 맞게 조정
                          width: 40,
                          height: 40,
                          fit: BoxFit.contain,
                          repeat: true, // 반복 여부
                        ),
                      ),

                    ),
                    const SizedBox(height: 50),
                    Transform.translate(
                      offset: Offset(0, -50), // 음수면 위로 올라감, 원하는 만큼 조절 가능
                      child: const Text(
                        '통화 종료',
                        style: TextStyle(
                          color: Colors.white,
                          fontFamily: 'pretendard',
                          fontSize: 12,
                        ),
                      ),
                    ),

                  ],
                ),
                Column(
                  children: [
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        setState(() {
                          if (_voiceState == VoiceState.idle) {
                            _voiceState = VoiceState.speaking;
                          } else if (_voiceState == VoiceState.speaking) {
                            _voiceState = VoiceState.listening;
                            _lottieController..reset()..forward();
                          } else if (_voiceState == VoiceState.listening) {
                            _voiceState = VoiceState.idle;
                          }
                        });
                      },
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: const BoxDecoration(
                          color: Color(0xFFBB9DF7),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.mic, color: Colors.white, size: 32),
                      ),
                    ),
                    const SizedBox(height: 50),
                    Transform.translate(
                      offset: Offset(0, -40), // 음수면 위로 올라감, 원하는 만큼 조절 가능
                      child: const Text(
                        '통화 종료',
                        style: TextStyle(
                          color: Colors.white,
                          fontFamily: 'pretendard',
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
