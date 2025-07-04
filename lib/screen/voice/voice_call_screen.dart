// voice_call_screen.dart
// 메인 음성 통화 화면 - 이제 훨씬 간단해졌습니다!

// voice_call_screen.dart 파일 상단에서
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/scheduler.dart';

// 이 부분만 수정 (경로에서 폴더명 제거)
import 'voice_state.dart';           // 같은 폴더니까 그냥 파일명만
import 'whisper_service.dart';       // 같은 폴더니까 그냥 파일명만
import 'websocket_service.dart';     // 같은 폴더니까 그냥 파일명만
import 'conversation_model.dart';    // 같은 폴더니까 그냥 파일명만
import 'voice_ui_widgets.dart';      // 같은 폴더니까 그냥 파일명만

class VoiceCallScreen extends StatefulWidget {
  const VoiceCallScreen({super.key});

  @override
  State<VoiceCallScreen> createState() => _VoiceCallScreenState();
}

class _VoiceCallScreenState extends State<VoiceCallScreen> with TickerProviderStateMixin {
  // 상태 관리
  VoiceState _voiceState = VoiceState.idle;
  bool _hasStartedConversation = false;
  String _currentSpeechText = '';

  // 서비스들
  late final WhisperService _whisperService;
  late final WebSocketService _webSocketService;
  late final ConversationManager _conversationManager;

  // 애니메이션 컨트롤러들
  late final AnimationController _recordController;
  late final AnimationController _buttonScaleController;

  // 통화 시간 관리
  late final Ticker _ticker;
  Duration _callDuration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _initializeAnimations();
    _initializeTimer();
  }

  @override
  void dispose() {
    _disposeResources();
    super.dispose();
  }

  // 서비스들 초기화
  void _initializeServices() {
    _whisperService = WhisperService();
    _webSocketService = WebSocketService();
    _conversationManager = ConversationManager();

    // WebSocket 콜백 설정
    _webSocketService.onTextResponse = _handleAIResponse;
    _webSocketService.onAudioStart = _handleAudioStart;
    _webSocketService.onAudioEnd = _handleAudioEnd;
    _webSocketService.onError = _handleError;
    _webSocketService.onConnectionLost = _handleConnectionLost;

    // 초기화 시작
    _initializeWhisperAndConnect();
  }

  // 애니메이션 컨트롤러들 초기화
  void _initializeAnimations() {
    _recordController = AnimationController(vsync: this);
    _buttonScaleController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
  }

  // 타이머 초기화
  void _initializeTimer() {
    _ticker = createTicker((elapsed) {
      setState(() {
        _callDuration = elapsed;
      });
    })..start();
  }

  // Whisper 초기화 및 WebSocket 연결
  Future<void> _initializeWhisperAndConnect() async {
    try {
      await _whisperService.initialize();
      await _webSocketService.connect();
      print('모든 서비스 초기화 완료');
    } catch (e) {
      print('초기화 실패: $e');
      setState(() {
        _voiceState = VoiceState.error;
      });
    }
  }

  // AI 응답 처리
  void _handleAIResponse(String text) {
    setState(() {
      _conversationManager.addAIMessage(text);
    });
  }

  // AI 오디오 시작
  void _handleAudioStart() {
    setState(() {
      _voiceState = VoiceState.listening;
      _recordController.stop();
    });
  }

  // AI 오디오 종료
  void _handleAudioEnd() {
    setState(() {
      _voiceState = VoiceState.idle;
    });
  }

  // 에러 처리
  void _handleError(String error) {
    setState(() {
      _voiceState = VoiceState.error;
    });
    print('에러 발생: $error');
  }

  // 연결 끊김 처리
  void _handleConnectionLost() {
    setState(() {
      _voiceState = VoiceState.error;
    });
  }

  // 버튼 클릭 처리
  void _handleButtonPress() async {
    if (_voiceState == VoiceState.listening || _voiceState == VoiceState.processing) {
      return; // 듣기 또는 처리 상태에서는 버튼 비활성화
    }

    // 버튼 애니메이션
    _buttonScaleController.forward().then((_) {
      _buttonScaleController.reverse();
    });

    HapticFeedback.mediumImpact();

    try {
      if (_voiceState == VoiceState.idle) {
        await _startSpeaking();
      } else if (_voiceState == VoiceState.speaking) {
        await _stopSpeaking();
      } else if (_voiceState == VoiceState.error) {
        await _retryConnection();
      }
    } catch (e) {
      print('Button press error: $e');
      setState(() {
        _voiceState = VoiceState.error;
      });
    }
  }

  // 말하기 시작
  Future<void> _startSpeaking() async {
    setState(() {
      _voiceState = VoiceState.speaking;
      _hasStartedConversation = true;
      _currentSpeechText = '';
      _recordController.repeat();
    });

    await _whisperService.startRecording();
  }

  // 말하기 중지 및 STT 처리
  Future<void> _stopSpeaking() async {
    setState(() {
      _voiceState = VoiceState.processing;
      _recordController.stop();
    });

    try {
      // 녹음 중지
      final audioPath = await _whisperService.stopRecording();
      if (audioPath == null) {
        throw Exception('녹음 파일을 찾을 수 없습니다');
      }

      // STT 처리
      final transcribedText = await _whisperService.transcribeAudio(audioPath);

      if (transcribedText != null && transcribedText.isNotEmpty) {
        setState(() {
          _currentSpeechText = transcribedText;
          _conversationManager.addUserMessage(transcribedText);
          _voiceState = VoiceState.listening;
        });

        // 서버로 텍스트 전송
        await _webSocketService.sendUserMessage(transcribedText);
        print('STT 결과 전송: $transcribedText');
      } else {
        setState(() {
          _voiceState = VoiceState.idle;
        });
        print('인식된 텍스트가 없습니다.');
      }
    } catch (e) {
      print('STT 처리 오류: $e');
      setState(() {
        _voiceState = VoiceState.error;
      });
    }
  }

  // 연결 재시도
  Future<void> _retryConnection() async {
    setState(() {
      _voiceState = VoiceState.idle;
    });
    await _initializeWhisperAndConnect();
  }

  // 통화 종료 처리
  Future<void> _handleCallEnd() async {
    HapticFeedback.heavyImpact();

    // 연결 해제 메시지 전송
    await _webSocketService.sendDisconnect();

    // 녹음 중지
    if (_whisperService.isRecording) {
      await _whisperService.stopRecording();
    }

    Navigator.pop(context);
  }

  // 리소스 해제
  void _disposeResources() {
    _ticker.dispose();
    _recordController.dispose();
    _buttonScaleController.dispose();
    _whisperService.dispose();
    _webSocketService.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0x66000000),
      body: Stack(
        children: [
          // 메인 레이아웃
          Column(
            children: [
              // 상단 사용자 정보
              UserInfoHeader(
                voiceState: _voiceState,
                callDuration: _callDuration,
                whisperEnabled: _whisperService.isInitialized,
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
                        // 상태별 시각화
                        VoiceStateVisualization(
                          voiceState: _voiceState,
                          currentSpeechText: _currentSpeechText,
                        ),

                        const SizedBox(height: 32),

                        // 대화 내용
                        Expanded(
                          child: SingleChildScrollView(
                            child: ConversationContent(
                              hasStartedConversation: _hasStartedConversation,
                              conversations: _conversationManager.conversations,
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

          // 말풍선
          SpeechBubble(
            voiceState: _voiceState,
            hasStartedConversation: _hasStartedConversation,
          ),

          // 하단 버튼들
          BottomButtons(
            voiceState: _voiceState,
            recordController: _recordController,
            buttonScaleController: _buttonScaleController,
            onCallEnd: _handleCallEnd,
            onSpeakButtonPress: _handleButtonPress,
          ),
        ],
      ),
    );
  }
}