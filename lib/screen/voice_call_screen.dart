import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter/scheduler.dart';

// 음성 통화 상태를 나타내는 열거형
enum VoiceState {
  idle,        // 대기 상태
  speaking,    // 사용자가 말하는 중
  listening,   // AI가 응답하는 중
}

// 음성 통화 화면 위젯
class VoiceCallScreen extends StatefulWidget {
  const VoiceCallScreen({super.key});

  @override
  State<VoiceCallScreen> createState() => _VoiceCallScreenState();
}

class _VoiceCallScreenState extends State<VoiceCallScreen> with TickerProviderStateMixin {
  // 버튼 눌림 상태 (현재 사용되지 않음)
  bool _isPressed = false;

  // 현재 음성 상태
  VoiceState _voiceState = VoiceState.idle;

  // Lottie 애니메이션 컨트롤러
  late final AnimationController _lottieController;

  // 통화 시간 계산을 위한 Ticker
  late final Ticker _ticker;

  // 통화 지속 시간
  Duration _callDuration = Duration.zero;

  @override
  void initState() {
    super.initState();
    // Lottie 애니메이션 컨트롤러 초기화
    _lottieController = AnimationController(vsync: this);

    // 통화 시간을 실시간으로 업데이트하는 Ticker 생성 및 시작
    _ticker = createTicker((elapsed) {
      setState(() {
        _callDuration = elapsed;
      });
    })..start();
  }

  @override
  void dispose() {
    // 메모리 누수 방지를 위한 리소스 해제
    _ticker.dispose();
    _lottieController.dispose();
    super.dispose();
  }

  // 통화 시간을 MM:SS 형식으로 포맷팅
  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 반투명 검은색 배경
      backgroundColor: const Color(0x66000000),
      body: Stack(
        children: [
          // 메인 레이아웃 (Column 구조)
          Column(
            children: [
              // 상단 사용자 정보 영역
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.only(top: 24, left: 24, right: 24),
                  child: Row(
                    children: [
                      // 사용자 프로필 아바타
                      const CircleAvatar(
                        radius: 24,
                        backgroundColor: Color(0xFFBB9DF7), // 보라색 배경
                      ),
                      const SizedBox(width: 12),
                      // 사용자 이름과 통화 시간
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 사용자 이름
                          const Text(
                            '정동연',
                            style: TextStyle(
                              fontFamily: 'pretendard',
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                              color: Colors.white,
                            ),
                          ),
                          // 통화 시간 표시
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

              // 중앙 대화 내용 영역
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(30),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(50),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE9F0F9), // 연한 파란색 배경
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      children: [
                        // 말하는 중일 때 음성 파형 애니메이션 표시
                        if (_voiceState == VoiceState.speaking) ...[
                          SizedBox(
                            width: 60,
                            height: 60,
                            child: Lottie.asset(
                              'asset/animation/voice_wave.json',
                              fit: BoxFit.contain,
                              repeat: true,
                              controller: _lottieController,
                              onLoaded: (composition) {
                                // ✅ speaking 상태일 때만 재생되도록 duration만 설정
                                _lottieController.duration = composition.duration;

                                // ✅ 현재 상태가 speaking인 경우만 재생
                                if (_voiceState == VoiceState.speaking) {
                                  _lottieController
                                    ..reset()
                                    ..forward();
                                }
                              },
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            '나의 말을 듣고 있습니다.',
                            style: TextStyle(
                              fontFamily: 'pretendard',
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ],

                        const SizedBox(height: 24),

                        // 대화 내용을 표시하는 스크롤 가능한 영역
                        Expanded(
                          child: SingleChildScrollView(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // 사용자 질문
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
                                // 응답 준비 중 안내
                                const Text(
                                  '동연이가 대답을 준비중이에요',
                                  style: TextStyle(
                                    fontFamily: 'pretendard',
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                // 추가 사용자 질문
                                const Text(
                                  '이번엔 언제까지 오해깟까요',
                                  style: TextStyle(
                                    fontFamily: 'pretendard',
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                    color: Colors.black,
                                  ),
                                ),
                                // 듣기 상태일 때만 AI 응답 표시
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
              // 말풍선과 버튼을 위한 여백 확보
              const SizedBox(height: 300),
            ],
          ),

          // 말풍선 (대기 상태 또는 듣기 상태일 때 표시)
          if (_voiceState == VoiceState.idle || _voiceState == VoiceState.listening)
            Positioned(
              bottom: 180, // 화면 하단에서 180픽셀 위
              left: 0,
              right: 30,
              child: Center(
                child: SizedBox(
                  width: 360,
                  height: 120,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // 말풍선 배경 이미지
                      Image.asset(
                        'asset/image/speech_bubble.png',
                        fit: BoxFit.contain,
                        width: 360,
                      ),
                      // 대기 상태일 때 안내 텍스트
                      if (_voiceState == VoiceState.idle)
                        Positioned(
                          top: 35,
                          child: SizedBox(
                            width: 240,
                            child: Text(
                              '말하기 버튼을 누르고 말씀해주세요',
                              style: const TextStyle(
                                fontFamily: 'Pretendard',
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        )
                      // 듣기 상태일 때 안내 텍스트
                      else if (_voiceState == VoiceState.listening)
                        Positioned(
                          top: 25,
                          child: SizedBox(
                            width: 240,
                            child: Text(
                              '말씀을 멈추고 답변을 들으시려면\n그만 말하기를 눌러주세요.',
                              style: const TextStyle(
                                fontFamily: 'Pretendard',
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
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

          // 하단 버튼 영역
          Positioned(
            bottom: 32, // 화면 하단에서 32픽셀 위
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // 통화 종료 버튼
                Column(
                  children: [
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.mediumImpact(); // 햅틱 피드백
                        Navigator.pop(context); // 화면 종료
                      },
                      child: Container(
                        width: 100,
                        height: 100,
                        child: Lottie.asset(
                          'asset/animation/call_end.json', // 통화 종료 애니메이션
                          width: 40,
                          height: 40,
                          fit: BoxFit.contain,
                          repeat: true, // 반복 재생
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // 버튼 라벨을 위로 이동
                    Transform.translate(
                      offset: Offset(0, -10), // 10픽셀 위로 이동
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

                // 말하기 버튼
// 말하기 버튼
                Column(
                  children: [
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        setState(() {
                          if (_voiceState == VoiceState.idle) {
                            // ▶️ idle → speaking
                            _voiceState = VoiceState.speaking;
                          } else if (_voiceState == VoiceState.speaking) {
                            // ▶️ speaking → listening
                            _voiceState = VoiceState.listening;

                            // ✅ 애니메이션은 여기서만 재생
                            _lottieController
                              ..reset()
                              ..forward();
                          } else if (_voiceState == VoiceState.listening) {
                            // ▶️ listening → idle
                            _voiceState = VoiceState.idle;

                            // ✅ 대기 상태로 돌아가면 애니메이션 중지
                            _lottieController.stop();
                          }
                        });
                      },

                      child: Container(
                        width: 150,
                        height: 150,
                        child: Lottie.asset(
                          'asset/animation/record_pulse.json', // 🔁 마이크 애니메이션
                          controller: _lottieController,
                          fit: BoxFit.contain,
                          repeat: false, // 재생은 수동 제어
                          onLoaded: (composition) {
                            // ✅ duration 설정만 수행, 재생은 setState에서만!
                            _lottieController.duration = composition.duration;
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Transform.translate(
                      offset: Offset(0, -30),
                      child: const Text(
                        '말하기',
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