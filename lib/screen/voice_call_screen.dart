import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter/scheduler.dart';

enum VoiceState { idle, speaking, listening }

class VoiceCallScreen extends StatefulWidget {
  const VoiceCallScreen({super.key});

  @override
  State<VoiceCallScreen> createState() => _VoiceCallScreenState();
}

class _VoiceCallScreenState extends State<VoiceCallScreen>
    with TickerProviderStateMixin {
  bool _isPressed = false;
  VoiceState _voiceState = VoiceState.idle;

  late final AnimationController _lottieController;
  late final Ticker _ticker;
  Duration _callDuration = Duration.zero;
  bool _hasPlayed = false;

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
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      if (_voiceState == VoiceState.speaking) ...[
                        const Icon(Icons.graphic_eq, size: 40, color: Colors.deepPurple),
                        const SizedBox(height: 30),
                        const Text(
                          '나의 말을 듣고 있습니다.',
                          style: TextStyle(
                            fontFamily: 'pretendard',
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                      ] else if (_voiceState == VoiceState.listening) ...[
                        SizedBox(
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
                          '동연이가 대답을 준비중이에요',
                          style: TextStyle(
                            fontFamily: 'pretendard',
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                      ],
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
                      if (_voiceState == VoiceState.listening)
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
                                  if (_voiceState == VoiceState.listening && !_hasPlayed) {
                                    _hasPlayed = true;
                                    _lottieController..reset()..forward();
                                  }
                                  if (_voiceState != VoiceState.listening) {
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
                        if (_voiceState == VoiceState.speaking)
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              Transform.translate(
                                offset: const Offset(0, 75),
                                child: Image.asset(
                                  'asset/image/speech_bubble.png',
                                  width: 240,
                                ),
                              ),
                              Transform.translate(
                                offset: const Offset(0, 70),
                                child: const Text(
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
                        const SizedBox(height: 16),
                        InkWell(
                          onTap: () {
                            setState(() {
                              if (_voiceState == VoiceState.idle) {
                                _voiceState = VoiceState.speaking;
                              } else if (_voiceState == VoiceState.speaking) {
                                _voiceState = VoiceState.listening;
                                _lottieController..reset()..forward();
                              }
                            });
                          },
                          child: Column(
                              children: [
                                if (_voiceState == VoiceState.idle)
                                  Column(
                                    children: [
                                      GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _voiceState = VoiceState.speaking;
                                          });
                                        },
                                        child: Container(
                                          width: 64,
                                          height: 64,
                                          decoration: const BoxDecoration(
                                            color: Color(0xFFBB9DF7),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(Icons.mic, color: Colors.white, size: 32),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      const Text(
                                        '말하기',
                                        style: TextStyle(
                                          fontFamily: 'Pretendard',
                                          fontSize: 16,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  )
                                else
                                  Column(
                                    children: [
                                      if (_voiceState == VoiceState.speaking)
                                        Transform.translate(
                                          offset: const Offset(0, 45),
                                          child: Lottie.asset(
                                            'asset/animation/record_pulse.json',
                                            width: 160,
                                            height: 160,
                                            fit: BoxFit.contain,
                                          ),
                                        )
                                      else if (_voiceState == VoiceState.listening)
                                        Transform.translate(
                                          offset: const Offset(0, -12),
                                          child: Transform.scale(
                                            scale: 2.5,
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
                                        _voiceState == VoiceState.speaking
                                            ? '그만 말하기'
                                            : '답변 듣는 중',
                                        style: const TextStyle(
                                          fontFamily: 'Pretendard',
                                          fontSize: 16,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                              ]

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
