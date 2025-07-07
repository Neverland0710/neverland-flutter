import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/scheduler.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'voice_state.dart';
import 'whisper_service.dart';
import 'websocket_service.dart';
import 'conversation_model.dart';
import 'voice_ui_widgets.dart';

class VoiceCallScreen extends StatefulWidget {
  const VoiceCallScreen({super.key});

  @override
  State<VoiceCallScreen> createState() => _VoiceCallScreenState();
}

class _VoiceCallScreenState extends State<VoiceCallScreen> with TickerProviderStateMixin {
  VoiceState _voiceState = VoiceState.idle;
  bool _hasStartedConversation = false;
  String _currentSpeechText = '';
  String _relation = "...";
  bool _showOnlyChat = false; // 🔹 음성 수신 시 채팅 전용 화면으로 전환

  late final WhisperService _whisperService;
  late final WebSocketService _webSocketService;
  late final ConversationManager _conversationManager;

  late final AnimationController _recordController;
  late final AnimationController _buttonScaleController;

  late final Ticker _ticker;
  Duration _callDuration = Duration.zero;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _initializeAnimations();
    _initializeTimer();
    _fetchRelation();
  }

  @override
  void dispose() {
    _disposeResources();
    super.dispose();
  }

  void _initializeServices() {
    _whisperService = WhisperService();
    _webSocketService = WebSocketService();
    _conversationManager = ConversationManager();

    _webSocketService.onTextResponse = _handleAIResponse;
    _webSocketService.onAudioStart = _handleAudioStart;
    _webSocketService.onAudioEnd = _handleAudioEnd;
    _webSocketService.onError = _handleError;
    _webSocketService.onConnectionLost = _handleConnectionLost;

    _initializeWhisperAndConnect();
  }

  void _initializeAnimations() {
    _recordController = AnimationController(vsync: this);
    _buttonScaleController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
  }

  void _initializeTimer() {
    _ticker = createTicker((elapsed) {
      setState(() {
        _callDuration = elapsed;
      });
    })..start();
  }

  Future<void> _initializeWhisperAndConnect() async {
    try {
      await _whisperService.initialize();
      await _webSocketService.connect();
    } catch (e) {
      setState(() {
        _voiceState = VoiceState.error;
      });
    }
  }

  Future<void> _fetchRelation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString("user_id");

      if (userId == null) {
        print("❌ userId 없음");
        return;
      }

      final url = Uri.parse("http://192.168.219.68:8086/chat/relation?userId=$userId");
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _relation = data['relation'] ?? '알 수 없음';
        });
      } else {
        print("❌ 관계 불러오기 실패: \${response.statusCode}");
      }
    } catch (e) {
      print("❌ 관계 요청 예외: $e");
    }
  }

  void _handleAIResponse(String text) {
    setState(() {
      _conversationManager.addAIMessage(text);
    });
    // 🔽 자동 스크롤
    Future.delayed(Duration(milliseconds: 100), () {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  void _handleAudioStart() {
    setState(() {
      _voiceState = VoiceState.listening;
      _recordController.stop();
      _showOnlyChat = true; // 🔹 음성 수신 후 채팅 화면으로 전환
    });
  }

  void _handleAudioEnd() {
    setState(() {
      _voiceState = VoiceState.idle;
    });
  }

  void _handleError(String error) {
    setState(() {
      _voiceState = VoiceState.error;
    });
  }

  void _handleConnectionLost() {
    setState(() {
      _voiceState = VoiceState.error;
    });
  }

  void _handleButtonPress() async {
    if (_voiceState == VoiceState.listening || _voiceState == VoiceState.processing) return;

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
      setState(() {
        _voiceState = VoiceState.error;
      });
    }
  }

  Future<void> _startSpeaking() async {
    setState(() {
      _voiceState = VoiceState.speaking;
      _hasStartedConversation = true;
      _currentSpeechText = '';
      _recordController.repeat();
      _showOnlyChat = false;
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

    await _whisperService.startRecording();
  }


  Future<void> _stopSpeaking() async {
    setState(() {
      _voiceState = VoiceState.processing;
      _recordController.stop();
    });

    try {
      final audioPath = await _whisperService.stopRecording();
      if (audioPath == null) throw Exception('녹음 파일 없음');

      final transcribedText = await _whisperService.transcribeAudio(audioPath);

      if (transcribedText != null && transcribedText.isNotEmpty) {
        setState(() {
          _currentSpeechText = transcribedText;
          _conversationManager.addUserMessage(transcribedText);
          _voiceState = VoiceState.listening;
        });

        Future.delayed(Duration(milliseconds: 100), () {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        });

        await _webSocketService.sendUserMessage(transcribedText);
      } else {
        setState(() {
          _voiceState = VoiceState.idle;
        });
      }
    } catch (e) {
      setState(() {
        _voiceState = VoiceState.error;
      });
    }
  }

  Future<void> _retryConnection() async {
    setState(() {
      _voiceState = VoiceState.idle;
    });
    await _initializeWhisperAndConnect();
  }

  Future<void> _handleCallEnd() async {
    HapticFeedback.heavyImpact();
    await _webSocketService.sendDisconnect();
    if (_whisperService.isRecording) {
      await _whisperService.stopRecording();
    }
    Navigator.pop(context);
  }

  void _disposeResources() {
    _ticker.dispose();
    _recordController.dispose();
    _buttonScaleController.dispose();
    _whisperService.dispose();
    _webSocketService.dispose();
    _scrollController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0x66000000),
      body: _showOnlyChat
          ? _buildChatOnlyView()
          : _buildFullVoiceCallView(),
    );
  }

  Widget _buildChatOnlyView() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                child: ConversationContent(
                  hasStartedConversation: _hasStartedConversation,
                  conversations: _conversationManager.conversations,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFullVoiceCallView() {
    return Stack(
      children: [
        Column(
          children: [
            UserInfoHeader(
              voiceState: _voiceState,
              callDuration: _callDuration,
              whisperEnabled: _whisperService.isInitialized,
              userName: _relation,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(30),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
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
                      VoiceStateVisualization(
                        voiceState: _voiceState,
                        currentSpeechText: _currentSpeechText,
                        relation: _relation,
                      ),
                      const SizedBox(height: 32),
                      Expanded(
                        child: SingleChildScrollView(
                          controller: _scrollController,
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
        SpeechBubble(
          voiceState: _voiceState,
          hasStartedConversation: _hasStartedConversation,
        ),
        BottomButtons(
          voiceState: _voiceState,
          recordController: _recordController,
          buttonScaleController: _buttonScaleController,
          onCallEnd: _handleCallEnd,
          onSpeakButtonPress: _handleButtonPress,
        ),
      ],
    );
  }
}