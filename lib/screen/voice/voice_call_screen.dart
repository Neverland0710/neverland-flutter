// Flutter, HTTP 요청, 공유 저장소 및 사용자 정의 서비스를 위한 필수 패키지 가져오기
import 'dart:convert'; // JSON 인코딩/디코딩을 위해
import 'package:flutter/material.dart'; // UI를 위한 핵심 Flutter 프레임워크
import 'package:flutter/services.dart'; // 햅틱 피드백을 위해
import 'package:http/http.dart' as http; // HTTP 요청을 위해
import 'package:shared_preferences/shared_preferences.dart'; // 영구 저장소를 위해
import 'package:flutter/scheduler.dart'; // 티커 기반 애니메이션을 위해
import 'voice_state.dart'; // 음성 통화 상태를 관리하는 사용자 정의 enum 또는 클래스
import 'whisper_service.dart'; // 오디오 녹음 및 텍스트 변환을 처리하는 사용자 정의 서비스
import 'websocket_service.dart'; // 실시간 통신을 위한 WebSocket 사용자 정의 서비스
import 'conversation_model.dart'; // 대화 데이터를 관리하는 모델
import 'voice_ui_widgets.dart'; // 음성 통화 화면을 위한 사용자 정의 UI 위젯

// 음성 통화 인터페이스를 위한 상태ful 위젯인 VoiceCallScreen 정의
class VoiceCallScreen extends StatefulWidget {
  const VoiceCallScreen({super.key}); // 선택적 key를 포함한 생성자

  @override
  State<VoiceCallScreen> createState() => _VoiceCallScreenState(); // 상태 객체 생성
}

// VoiceCallScreen의 상태 클래스, 위젯의 상태와 라이프사이클 관리
class _VoiceCallScreenState extends State<VoiceCallScreen> with TickerProviderStateMixin {
  // 현재 음성 통화 상태(예: 대기, 말하기, 듣기 등)를 추적
  VoiceState _voiceState = VoiceState.idle;
  // 대화가 시작되었는지 여부를 나타냄
  bool _hasStartedConversation = false;
  // 현재 변환된 음성 텍스트를 저장
  String _currentSpeechText = '';
  // 서버에서 가져온 관계 상태를 저장
  String _relation = "...";
  // 전체 음성 통화 UI와 채팅 전용 UI 간 전환을 제어
  bool _showOnlyChat = false; // 🔹 오디오 수신 시 채팅 전용 화면으로 전환

  // 오디오 처리, WebSocket 통신, 대화 관리를 위한 서비스 인스턴스
  late final WhisperService _whisperService; // 오디오 녹음 및 텍스트 변환 처리
  late final WebSocketService _webSocketService; // 실시간 통신을 위한 WebSocket 연결 관리
  late final ConversationManager _conversationManager; // 대화 데이터 관리

  // 애니메이션 컨트롤러: 녹음 및 버튼 크기 조절 애니메이션
  late final AnimationController _recordController; // 녹음 애니메이션 제어
  late final AnimationController _buttonScaleController; // 버튼 크기 조절 애니메이션 제어

  // 통화 시간 추적을 위한 티커
  late final Ticker _ticker;
  // 통화 지속 시간을 저장
  Duration _callDuration = Duration.zero;

  // 대화 내용을 스크롤하기 위한 컨트롤러
  final ScrollController _scrollController = ScrollController();

  // 위젯 초기화 시 호출되는 메서드
  @override
  void initState() {
    super.initState();
    _initializeServices(); // 서비스 초기화
    _initializeAnimations(); // 애니메이션 초기화
    _initializeTimer(); // 타이머 초기화
    _fetchRelation(); // 관계 정보 가져오기
  }

  // 위젯이 제거될 때 호출되어 리소스 해제
  @override
  void dispose() {
    _disposeResources(); // 리소스 해제
    super.dispose();
  }

  // 서비스 초기화: WhisperService, WebSocketService, ConversationManager 설정
  void _initializeServices() {
    _whisperService = WhisperService(); // 오디오 녹음 및 변환 서비스
    _webSocketService = WebSocketService(); // WebSocket 통신 서비스
    _conversationManager = ConversationManager(); // 대화 관리 모델

    // WebSocketService의 콜백 설정
    _webSocketService.onTextResponse = _handleAIResponse; // AI 텍스트 응답 처리
    _webSocketService.onAudioStart = _handleAudioStart; // 오디오 시작 처리
    _webSocketService.onAudioEnd = _handleAudioEnd; // 오디오 종료 처리
    _webSocketService.onError = _handleError; // 에러 처리
    _webSocketService.onConnectionLost = _handleConnectionLost; // 연결 끊김 처리

    _initializeWhisperAndConnect(); // Whisper 및 WebSocket 초기화 및 연결
  }

  // 애니메이션 컨트롤러 초기화
  void _initializeAnimations() {
    _recordController = AnimationController(vsync: this); // 녹음 애니메이션
    _buttonScaleController = AnimationController(
      duration: const Duration(milliseconds: 150), // 버튼 크기 조절 애니메이션 지속 시간
      vsync: this,
    );
  }

  // 통화 시간을 추적하는 티커 초기화
  void _initializeTimer() {
    _ticker = createTicker((elapsed) {
      setState(() {
        _callDuration = elapsed; // 통화 시간 업데이트
      });
    })..start(); // 티커 시작
  }

  // Whisper 서비스와 WebSocket 연결 초기화
  Future<void> _initializeWhisperAndConnect() async {
    try {
      await _whisperService.initialize(); // Whisper 서비스 초기화
      await _webSocketService.connect(); // WebSocket 연결
    } catch (e) {
      setState(() {
        _voiceState = VoiceState.error; // 초기화 실패 시 에러 상태로 전환
      });
    }
  }

  // 서버에서 사용자 관계 정보 가져오기
  Future<void> _fetchRelation() async {
    try {
      final prefs = await SharedPreferences.getInstance(); // 공유 저장소 인스턴스
      final userId = prefs.getString("user_id"); // 사용자 ID 가져오기

      if (userId == null) {
        print("❌ userId 없음"); // 사용자 ID가 없을 경우
        return;
      }

      // 관계 정보를 가져오기 위한 HTTP 요청
      final url = Uri.parse("http://52.78.139.47:8086/chat/relation?userId=$userId");
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body); // 응답 JSON 디코딩
        setState(() {
          _relation = data['relation'] ?? '알 수 없음'; // 관계 정보 업데이트
        });
      } else {
        print("❌ 관계 불러오기 실패: ${response.statusCode}"); // 요청 실패 로그
      }
    } catch (e) {
      print("❌ 관계 요청 예외: $e"); // 예외 발생 로그
    }
  }

  // AI로부터 받은 텍스트 응답 처리
  void _handleAIResponse(String text) {
    setState(() {
      _conversationManager.addAIMessage(text); // AI 메시지를 대화에 추가
    });
    // 🔽 대화창을 최신 메시지로 자동 스크롤
    Future.delayed(Duration(milliseconds: 100), () {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  // AI 오디오 시작 이벤트 처리
  void _handleAudioStart() {
    setState(() {
      _voiceState = VoiceState.listening; // 듣기 상태로 전환
      _recordController.stop(); // 녹음 애니메이션 중지
      _showOnlyChat = true; // 🔹 음성 수신 후 채팅 화면으로 전환
    });
  }

  // AI 오디오 종료 이벤트 처리
  void _handleAudioEnd() {
    setState(() {
      _voiceState = VoiceState.idle; // 대기 상태로 전환
    });
  }

  // 에러 이벤트 처리
  void _handleError(String error) {
    setState(() {
      _voiceState = VoiceState.error; // 에러 상태로 전환
    });
  }

  // WebSocket 연결 끊김 이벤트 처리
  void _handleConnectionLost() {
    setState(() {
      _voiceState = VoiceState.error; // 에러 상태로 전환
    });
  }

  // 말하기 버튼 클릭 처리
  void _handleButtonPress() async {
    // 듣기 또는 처리 중 상태에서는 동작하지 않음
    if (_voiceState == VoiceState.listening || _voiceState == VoiceState.processing) return;

    // 버튼 클릭 애니메이션 실행
    _buttonScaleController.forward().then((_) {
      _buttonScaleController.reverse();
    });
    HapticFeedback.mediumImpact(); // 중간 강도의 햅틱 피드백

    try {
      if (_voiceState == VoiceState.idle) {
        await _startSpeaking(); // 말하기 시작
      } else if (_voiceState == VoiceState.speaking) {
        await _stopSpeaking(); // 말하기 중지
      } else if (_voiceState == VoiceState.error) {
        await _retryConnection(); // 연결 재시도
      }
    } catch (e) {
      setState(() {
        _voiceState = VoiceState.error; // 예외 발생 시 에러 상태로 전환
      });
    }
  }

  // 말하기 시작
  Future<void> _startSpeaking() async {
    setState(() {
      _voiceState = VoiceState.speaking; // 말하기 상태로 전환
      _hasStartedConversation = true; // 대화 시작 플래그 설정
      _currentSpeechText = ''; // 현재 음성 텍스트 초기화
      _recordController.repeat(); // 녹음 애니메이션 반복
      _showOnlyChat = false; // 전체 음성 통화 UI 표시
    });

    // 🔽 말 시작 시 채팅창 아래로 자동 스크롤
    Future.delayed(Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });

    await _whisperService.startRecording(); // 오디오 녹음 시작
  }

  // 말하기 중지
  Future<void> _stopSpeaking() async {
    setState(() {
      _voiceState = VoiceState.processing; // 처리 중 상태로 전환
      _recordController.stop(); // 녹음 애니메이션 중지
    });

    try {
      final audioPath = await _whisperService.stopRecording(); // 녹음 중지 및 파일 경로 반환
      if (audioPath == null) throw Exception('녹음 파일 없음'); // 파일이 없으면 예외 발생

      final transcribedText = await _whisperService.transcribeAudio(audioPath); // 오디오를 텍스트로 변환

      if (transcribedText != null && transcribedText.isNotEmpty) {
        setState(() {
          _currentSpeechText = transcribedText; // 변환된 텍스트 저장
          _conversationManager.addUserMessage(transcribedText); // 사용자 메시지 추가
          _voiceState = VoiceState.listening; // 듣기 상태로 전환
        });

        // 최신 메시지로 스크롤
        Future.delayed(Duration(milliseconds: 100), () {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        });

        await _webSocketService.sendUserMessage(transcribedText); // 사용자 메시지 전송
      } else {
        setState(() {
          _voiceState = VoiceState.idle; // 변환된 텍스트가 없으면 대기 상태로
        });
      }
    } catch (e) {
      setState(() {
        _voiceState = VoiceState.error; // 예외 발생 시 에러 상태로
      });
    }
  }

  // 연결 재시도
  Future<void> _retryConnection() async {
    setState(() {
      _voiceState = VoiceState.idle; // 대기 상태로 전환
    });
    await _initializeWhisperAndConnect(); // Whisper 및 WebSocket 재연결
  }

  // 통화 종료 처리
  Future<void> _handleCallEnd() async {
    HapticFeedback.heavyImpact(); // 강한 햅틱 피드백
    await _webSocketService.sendDisconnect(); // WebSocket 연결 종료
    if (_whisperService.isRecording) {
      await _whisperService.stopRecording(); // 녹음 중지
    }
    Navigator.pop(context); // 화면 종료
  }

  // 리소스 해제
  void _disposeResources() {
    _ticker.dispose(); // 티커 해제
    _recordController.dispose(); // 녹음 애니메이션 컨트롤러 해제
    _buttonScaleController.dispose(); // 버튼 애니메이션 컨트롤러 해제
    _whisperService.dispose(); // Whisper 서비스 해제
    _webSocketService.dispose(); // WebSocket 서비스 해제
    _scrollController.dispose(); // 스크롤 컨트롤러 해제
  }

  // UI 빌드
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0x66000000), // 배경색 설정 (투명 검정)
      body: _showOnlyChat
          ? _buildChatOnlyView() // 채팅 전용 화면
          : _buildFullVoiceCallView(), // 전체 음성 통화 화면
    );
  }

  // 채팅 전용 화면 빌드
  Widget _buildChatOnlyView() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20), // 전체 패딩
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController, // 스크롤 컨트롤러 연결
                child: ConversationContent(
                  hasStartedConversation: _hasStartedConversation, // 대화 시작 여부
                  conversations: _conversationManager.conversations, // 대화 데이터
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 전체 음성 통화 화면 빌드
  Widget _buildFullVoiceCallView() {
    return Stack(
      children: [
        Column(
          children: [
            UserInfoHeader(
              voiceState: _voiceState, // 현재 음성 상태
              callDuration: _callDuration, // 통화 시간
              whisperEnabled: _whisperService.isInitialized, // Whisper 서비스 초기화 여부
              userName: _relation, // 사용자 관계 정보
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(30), // 컨테이너 패딩
                child: Container(
                  width: double.infinity, // 컨테이너 너비 전체
                  padding: const EdgeInsets.all(20), // 내부 패딩
                  decoration: BoxDecoration(
                    color: const Color(0xFFE9F0F9), // 컨테이너 배경색
                    borderRadius: BorderRadius.circular(24), // 둥근 모서리
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1), // 그림자 색상
                        blurRadius: 10, // 그림자 블러
                        offset: const Offset(0, 5), // 그림자 오프셋
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      VoiceStateVisualization(
                        voiceState: _voiceState, // 음성 상태 시각화
                        currentSpeechText: _currentSpeechText, // 현재 음성 텍스트
                        relation: _relation, // 관계 정보
                      ),
                      const SizedBox(height: 32), // 간격
                      Expanded(
                        child: SingleChildScrollView(
                          controller: _scrollController, // 스크롤 컨트롤러 연결
                          child: ConversationContent(
                            hasStartedConversation: _hasStartedConversation, // 대화 시작 여부
                            conversations: _conversationManager.conversations, // 대화 데이터
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 300), // 하단 여백
          ],
        ),
        SpeechBubble(
          voiceState: _voiceState, // 음성 상태에 따른 말풍선 UI
          hasStartedConversation: _hasStartedConversation, // 대화 시작 여부
        ),
        BottomButtons(
          voiceState: _voiceState, // 버튼 상태
          recordController: _recordController, // 녹음 애니메이션 컨트롤러
          buttonScaleController: _buttonScaleController, // 버튼 크기 조절 컨트롤러
          onCallEnd: _handleCallEnd, // 통화 종료 콜백
          onSpeakButtonPress: _handleButtonPress, // 말하기 버튼 콜백
        ),
      ],
    );
  }
}