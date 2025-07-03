import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter/scheduler.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

// 음성 통화 상태를 나타내는 열거형
enum VoiceState {
  idle,        // 대기 상태 (말하기 대기중)
  speaking,    // 사용자가 말하는 중
  listening,   // AI가 응답하는 중 (답변 듣는중)
  error,       // 에러 상태
}

// 음성 통화 화면 위젯
class VoiceCallScreen extends StatefulWidget {
  const VoiceCallScreen({super.key});

  @override
  State<VoiceCallScreen> createState() => _VoiceCallScreenState();
}

class _VoiceCallScreenState extends State<VoiceCallScreen> with TickerProviderStateMixin {
  // 현재 음성 상태
  VoiceState _voiceState = VoiceState.idle;

  // 첫 번째 말하기 버튼 클릭 여부
  bool _hasStartedConversation = false;

  // Lottie 애니메이션 컨트롤러들
  late final AnimationController _recordController;
  late final AnimationController _buttonScaleController;

  // 통화 시간 계산을 위한 Ticker
  late final Ticker _ticker;

  // 통화 지속 시간
  Duration _callDuration = Duration.zero;

  // 현재 AI 응답 텍스트
  String _aiResponse = '';

  // 대화 기록
  List<Map<String, dynamic>> _conversations = [];

  @override
  void initState() {
    super.initState();
    // 애니메이션 컨트롤러들 초기화
    _recordController = AnimationController(vsync: this);
    _buttonScaleController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    // 통화 시간을 실시간으로 업데이트하는 Ticker 생성 및 시작
    _ticker = createTicker((elapsed) {
      setState(() {
        _callDuration = elapsed;
      });
    })..start();

    // 마이크 권한 체크 시뮬레이션
    _checkPermissions();
  }

  @override
  void dispose() {
    // 메모리 누수 방지를 위한 리소스 해제
    _ticker.dispose();
    _recordController.dispose();
    _buttonScaleController.dispose();
    super.dispose();
  }

  // 권한 체크 시뮬레이션
  Future<void> _checkPermissions() async {
    try {
      // 실제로는 permission_handler 패키지 사용
      await Future.delayed(Duration(milliseconds: 500));
      // 권한이 있다고 가정
    } catch (e) {
      setState(() {
        _voiceState = VoiceState.error;
      });
    }
  }

  // 통화 시간을 MM:SS 형식으로 포맷팅
  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  // 현재 상태에 따른 버튼 텍스트 반환
  String _getButtonText() {
    switch (_voiceState) {
      case VoiceState.idle:
        return '말하기';
      case VoiceState.listening:
        return '답변 듣는중...';
      case VoiceState.speaking:
        return '그만말하기';
      case VoiceState.error:
        return '다시 시도';
    }
  }

  // 말풍선 메시지 반환
  String _getBubbleMessage() {
    if (!_hasStartedConversation) {
      return '말하기 버튼을 누르고 말씀해주세요';
    }

    switch (_voiceState) {
      case VoiceState.listening:
        return 'AI가 답변하고 있습니다\n잠시만 기다려주세요';
      case VoiceState.speaking:
        return '말씀이 끝나시면\n그만말하기를 눌러주세요';
      case VoiceState.error:
        return '연결에 문제가 발생했습니다\n다시 시도해주세요';
      default:
        return '말하기 버튼을 누르고 말씀해주세요';
    }
  }

  // AI 응답 시뮬레이션
  void _simulateAIResponse() {
    final responses = [
      '안녕하세요! 무엇을 도와드릴까요?',
      '네, 잘 들었습니다. 더 궁금한 것이 있나요?',
      '좋은 질문이네요. 제가 설명해드릴게요.',
      '더 자세히 알고 싶으시면 언제든 말씀해주세요.',
    ];

    setState(() {
      _aiResponse = responses[_conversations.length % responses.length];
      _conversations.add({
        'type': 'ai',
        'message': _aiResponse,
        'timestamp': DateTime.now(),
      });
    });
  }

  // 버튼 클릭 처리
  void _handleButtonPress() async {
    if (_voiceState == VoiceState.listening) {
      return; // 듣기 상태에서는 버튼 비활성화
    }

    // 버튼 애니메이션
    _buttonScaleController.forward().then((_) {
      _buttonScaleController.reverse();
    });

    HapticFeedback.mediumImpact();

    try {
      setState(() {
        if (_voiceState == VoiceState.idle) {
          // 첫 번째 또는 새로운 대화 시작
          _voiceState = VoiceState.listening;
          _hasStartedConversation = true;
          _recordController.stop();

          // 사용자 입력 시뮬레이션
          _conversations.add({
            'type': 'user',
            'message': '사용자가 말한 내용',
            'timestamp': DateTime.now(),
          });

        } else if (_voiceState == VoiceState.speaking) {
          // 말하기 중단
          _voiceState = VoiceState.listening;
          _recordController.stop();
        } else if (_voiceState == VoiceState.error) {
          // 에러 상태에서 재시도
          _voiceState = VoiceState.idle;
          _checkPermissions();
        }
      });

      // 듣기 상태에서 자동으로 말하기 상태로 전환
      if (_voiceState == VoiceState.listening) {
        // AI 응답 시뮬레이션
        _simulateAIResponse();

        // 동적 대기 시간 (2-5초 랜덤)
        final waitTime = Duration(seconds: 2 + (DateTime.now().millisecond % 3));

        await Future.delayed(waitTime);

        if (mounted && _voiceState == VoiceState.listening) {
          setState(() {
            _voiceState = VoiceState.speaking;
            _recordController.repeat();
          });
        }
      }
    } catch (e) {
      setState(() {
        _voiceState = VoiceState.error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 반투명 검은색 배경
      backgroundColor: const Color(0x66000000),
      body: Stack(
        children: [
          // 메인 레이아웃
          Column(
            children: [
              // 상단 사용자 정보 영역
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.only(top: 24, left: 24, right: 24),
                  child: Row(
                    children: [
                      // 사용자 프로필 아바타 (상태에 따른 테두리 색상)
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _voiceState == VoiceState.speaking
                                ? Colors.red.withOpacity(0.8)
                                : _voiceState == VoiceState.listening
                                ? Colors.green.withOpacity(0.8)
                                : Colors.transparent,
                            width: 3,
                          ),
                        ),
                        child: const CircleAvatar(
                          radius: 24,
                          backgroundColor: Color(0xFFBB9DF7),
                          child: Icon(
                            Icons.person,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // 사용자 이름과 통화 시간
                      Expanded(
                        child: Column(
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
                            Row(
                              children: [
                                // 연결 상태 인디케이터
                                Container(
                                  width: 8,
                                  height: 8,
                                  margin: const EdgeInsets.only(right: 6),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: _voiceState == VoiceState.error
                                        ? Colors.red
                                        : Colors.green,
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
                      color: const Color(0xFFE9F0F9),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // 상태별 애니메이션 및 텍스트
                        if (_voiceState == VoiceState.listening) ...[
                          SizedBox(
                            width: 80,
                            height: 80,
                            child: Lottie.asset(
                              'asset/animation/voice_wave.json',
                              fit: BoxFit.contain,
                              repeat: true,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'AI가 답변하고 있습니다.',
                            style: TextStyle(
                              fontFamily: 'pretendard',
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.blue,
                            ),
                          ),
                        ] else if (_voiceState == VoiceState.speaking) ...[
                          // 말하기 상태 시각화
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.red.withOpacity(0.1),
                              border: Border.all(
                                color: Colors.red.withOpacity(0.3),
                                width: 2,
                              ),
                            ),
                            child: const Icon(
                              Icons.mic,
                              color: Colors.red,
                              size: 40,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            '음성을 인식하고 있습니다.',
                            style: TextStyle(
                              fontFamily: 'pretendard',
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.red,
                            ),
                          ),
                        ] else if (_voiceState == VoiceState.error) ...[
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.red.withOpacity(0.1),
                            ),
                            child: const Icon(
                              Icons.error_outline,
                              color: Colors.red,
                              size: 40,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            '연결에 문제가 발생했습니다.',
                            style: TextStyle(
                              fontFamily: 'pretendard',
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.red,
                            ),
                          ),
                        ],

                        const SizedBox(height: 32),

                        // 대화 내용 스크롤 영역
                        Expanded(
                          child: SingleChildScrollView(
                            child: Column(
                              children: [
                                // 기본 대화 내용
                                if (!_hasStartedConversation) ...[
                                  const Text(
                                    '안녕하세요! 😊',
                                    style: TextStyle(
                                      fontFamily: 'pretendard',
                                      fontWeight: FontWeight.w600,
                                      fontSize: 20,
                                      color: Colors.black87,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 12),
                                  const Text(
                                    '무엇을 도와드릴까요?',
                                    style: TextStyle(
                                      fontFamily: 'pretendard',
                                      fontSize: 16,
                                      color: Colors.grey,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ] else ...[
                                  // 실제 대화 내용 표시
                                  ...List.generate(_conversations.length, (index) {
                                    final conversation = _conversations[index];
                                    final isUser = conversation['type'] == 'user';

                                    return Container(
                                      margin: const EdgeInsets.symmetric(vertical: 8),
                                      child: Row(
                                        mainAxisAlignment: isUser
                                            ? MainAxisAlignment.end
                                            : MainAxisAlignment.start,
                                        children: [
                                          if (!isUser) ...[
                                            CircleAvatar(
                                              radius: 12,
                                              backgroundColor: Colors.blue.shade100,
                                              child: const Icon(
                                                Icons.smart_toy,
                                                size: 16,
                                                color: Colors.blue,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                          ],
                                          Flexible(
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 16,
                                                vertical: 12,
                                              ),
                                              decoration: BoxDecoration(
                                                color: isUser
                                                    ? Colors.blue.shade500
                                                    : Colors.grey.shade200,
                                                borderRadius: BorderRadius.circular(18),
                                              ),
                                              child: Text(
                                                conversation['message'],
                                                style: TextStyle(
                                                  fontFamily: 'pretendard',
                                                  fontSize: 14,
                                                  color: isUser
                                                      ? Colors.white
                                                      : Colors.black87,
                                                ),
                                              ),
                                            ),
                                          ),
                                          if (isUser) ...[
                                            const SizedBox(width: 8),
                                            CircleAvatar(
                                              radius: 12,
                                              backgroundColor: Colors.purple.shade100,
                                              child: const Icon(
                                                Icons.person,
                                                size: 16,
                                                color: Colors.purple,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    );
                                  }),
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
              const SizedBox(height: 300),
            ],
          ),

          // 말풍선 (상태에 따른 메시지)
          if (_voiceState != VoiceState.speaking)
            Positioned(
              bottom: 180,
              left: 0,
              right: 30,
              child: Center(
                child: SizedBox(
                  width: 360,
                  height: 120,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Image.asset(
                        'asset/image/speech_bubble.png',
                        fit: BoxFit.contain,
                        width: 360,
                      ),
                      Positioned(
                        top: 25,
                        child: SizedBox(
                          width: 240,
                          child: Text(
                            _getBubbleMessage(),
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
            bottom: 32,
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
                        HapticFeedback.heavyImpact();
                        Navigator.pop(context);
                      },
                      child: Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.red.withOpacity(0.2),
                          border: Border.all(
                            color: Colors.red.withOpacity(0.3),
                            width: 5,
                          ),
                        ),
                        child: const Icon(
                          Icons.call_end,
                          color: Colors.red,
                          size: 36,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Transform.translate(
                      offset: const Offset(0, 0),
                      child: const Text(
                        '통화 종료',
                        style: TextStyle(
                          color: Colors.white,
                          fontFamily: 'pretendard',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),

                // 말하기 버튼
                Column(
                  children: [
                    ScaleTransition(
                      scale: Tween<double>(begin: 1.0, end: 0.95).animate(
                        CurvedAnimation(
                          parent: _buttonScaleController,
                          curve: Curves.easeInOut,
                        ),
                      ),
                      child: GestureDetector(
                        onTap: _handleButtonPress,
                        child: Container(
                          width: 150,
                          height: 150,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: _voiceState == VoiceState.speaking
                                    ? Colors.red.withOpacity(0.3)
                                    : _voiceState == VoiceState.listening
                                    ? Colors.grey.withOpacity(0.3)
                                    : Colors.blue.withOpacity(0.3),
                                blurRadius: 20,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: Lottie.asset(
                            'asset/animation/record_pulse.json',
                            controller: _recordController,
                            fit: BoxFit.contain,
                            repeat: false,
                            onLoaded: (composition) {
                              _recordController.duration = composition.duration;
                              if (_voiceState == VoiceState.speaking) {
                                _recordController.repeat();
                              }
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Transform.translate(
                      offset: const Offset(0, -30),
                      child: Text(
                        _getButtonText(),
                        style: TextStyle(
                          color: _voiceState == VoiceState.listening
                              ? Colors.grey
                              : _voiceState == VoiceState.error
                              ? Colors.red.shade300
                              : Colors.white,
                          fontFamily: 'pretendard',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
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