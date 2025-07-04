// import 'dart:async';
//
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:http/http.dart' as http;
// import 'package:lottie/lottie.dart';
// import 'package:flutter/scheduler.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:web_socket_channel/io.dart';
// import 'package:web_socket_channel/web_socket_channel.dart';
// import 'package:audioplayers/audioplayers.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:flutter_dotenv/flutter_dotenv.dart';
// import 'package:flutter_sound/flutter_sound.dart';
// import 'package:path_provider/path_provider.dart';
// import 'dart:convert';
// import 'dart:typed_data';
// import 'dart:io';
//
// // Image 충돌 해결을 위한 alias
// import 'package:flutter/widgets.dart' as widgets;
//
// // 음성 통화 상태를 나타내는 열거형
// enum VoiceState {
//   idle,        // 대기 상태 (말하기 대기중)
//   speaking,    // 사용자가 말하는 중
//   listening,   // AI가 응답하는 중 (답변 듣는중)
//   processing,  // Whisper STT 처리 중
//   error,       // 에러 상태
// }
//
// // 음성 통화 화면 위젯
// class VoiceCallScreen extends StatefulWidget {
//   const VoiceCallScreen({super.key});
//
//   @override
//   State<VoiceCallScreen> createState() => _VoiceCallScreenState();
// }
//
// class _VoiceCallScreenState extends State<VoiceCallScreen> with TickerProviderStateMixin {
//   // 현재 음성 상태
//   VoiceState _voiceState = VoiceState.idle;
//
//   // 첫 번째 말하기 버튼 클릭 여부
//   bool _hasStartedConversation = false;
//
//   // Lottie 애니메이션 컨트롤러들
//   late final AnimationController _recordController;
//   late final AnimationController _buttonScaleController;
//
//   // 통화 시간 계산을 위한 Ticker
//   late final Ticker _ticker;
//
//   // 통화 지속 시간
//   Duration _callDuration = Duration.zero;
//
//   // 현재 AI 응답 텍스트
//   String _aiResponse = '';
//
//   // 대화 기록
//   List<Map<String, dynamic>> _conversations = [];
//
//   // Whisper STT 관련 변수들
//   late FlutterSoundRecorder _recorder;
//   final AudioPlayer _audioPlayer = AudioPlayer();
//   WebSocketChannel? _backendChannel;
//   bool _whisperEnabled = false;
//   String _currentSpeechText = '';
//   String? _currentRecordingPath;
//
//   // Spring Boot WebSocket URL - 환경변수에서 읽기
//   String get _backendUrl => dotenv.env['BACKEND_URL'] ?? 'ws://localhost:8080/voice-call';
//
//   // Whisper API 호출 메서드
//   Future<String?> transcribeAudioWithWhisper(Uint8List audioBytes) async {
//     final apiKey = dotenv.env['OPENAI_API_KEY'] ?? '';
//     if (apiKey.isEmpty) {
//       print('OpenAI API 키가 설정되지 않았습니다.');
//       return null;
//     }
//
//     final uri = Uri.parse('https://api.openai.com/v1/audio/transcriptions');
//     final request = http.MultipartRequest('POST', uri)
//       ..headers['Authorization'] = 'Bearer $apiKey'
//       ..fields['model'] = 'whisper-1'
//       ..fields['language'] = 'ko'
//       ..files.add(http.MultipartFile.fromBytes(
//         'file',
//         audioBytes,
//         filename: 'audio.m4a',
//       ));
//
//     try {
//       final response = await request.send();
//       if (response.statusCode == 200) {
//         final responseData = await response.stream.bytesToString();
//         final data = json.decode(responseData);
//         return data['text']?.toString();
//       } else {
//         print('Whisper API 오류: ${response.statusCode}');
//         return null;
//       }
//     } catch (e) {
//       print('Whisper STT 오류: $e');
//       return null;
//     }
//   }
//
//   @override
//   void initState() {
//     super.initState();
//     // 애니메이션 컨트롤러들 초기화
//     _recorder = FlutterSoundRecorder();
//     _recordController = AnimationController(vsync: this);
//     _buttonScaleController = AnimationController(
//       duration: const Duration(milliseconds: 150),
//       vsync: this,
//     );
//
//     // 통화 시간을 실시간으로 업데이트하는 Ticker 생성 및 시작
//     _ticker = createTicker((elapsed) {
//       setState(() {
//         _callDuration = elapsed;
//       });
//     })..start();
//
//     // Whisper STT 초기화
//     _initializeWhisperSTT();
//   }
//
//   @override
//   void dispose() {
//     // 메모리 누수 방지를 위한 리소스 해제
//     _ticker.dispose();
//     _recordController.dispose();
//     _buttonScaleController.dispose();
//     _audioPlayer.dispose();
//     _recorder.closeRecorder();
//     _backendChannel?.sink.close();
//     super.dispose();
//   }
//
//   // Whisper STT 초기화
//   Future<void> _initializeWhisperSTT() async {
//     try {
//       await _recorder.openRecorder();
//       // 마이크 권한 요청
//       final micStatus = await Permission.microphone.request();
//       if (micStatus != PermissionStatus.granted) {
//         throw Exception('마이크 권한이 필요합니다');
//       }
//
//       // OpenAI API 키 확인
//       final apiKey = dotenv.env['OPENAI_API_KEY'];
//       if (apiKey == null || apiKey.isEmpty) {
//         throw Exception('OpenAI API 키가 설정되지 않았습니다');
//       }
//
//       _whisperEnabled = true;
//
//       // 백엔드 연결
//       await _connectToBackend();
//
//       print('Whisper STT 초기화 완료');
//     } catch (e) {
//       print('Whisper STT 초기화 실패: $e');
//       setState(() {
//         _voiceState = VoiceState.error;
//       });
//     }
//   }
//
// // WebSocket 연결 시도
//   Future<void> _connectToBackend() async {
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       final authKeyId = prefs.getString('authKeyId') ?? '';
//
//       final wsUri = Uri.parse(_backendUrl);
//       final updatedUri = Uri(
//         scheme: wsUri.scheme,
//         host: wsUri.host,
//         port: wsUri.port,
//         path: wsUri.path,
//         queryParameters: {
//           'authKeyId': authKeyId,
//         },
//       );
//
//       _backendChannel = IOWebSocketChannel.connect(
//         updatedUri.toString(),
//       );
//
//       _backendChannel!.stream.listen(
//             (data) {
//           print('WebSocket 메시지 수신: $data'); // 디버그 로그 추가
//           _handleBackendMessage(data);
//         },
//         onError: (error) {
//           print('Backend WebSocket Error: $error');
//           setState(() {
//             _voiceState = VoiceState.error;
//           });
//           // 재연결 시도 추가 (간격을 길게)
//           Future.delayed(Duration(seconds: 5), () {
//             print('WebSocket 재연결 시도');
//             _connectToBackend();
//           });
//         },
//         onDone: () {
//           print('Backend WebSocket connection closed');
//           setState(() {
//             _voiceState = VoiceState.error;
//           });
//           // 재연결 시도 추가 (간격을 길게)
//           Future.delayed(Duration(seconds: 5), () {
//             print('WebSocket 재연결 시도');
//             _connectToBackend();
//           });
//         },
//       );
//
//       // 연결 성공 메시지 전송 (딜레이 추가)
//       await Future.delayed(Duration(milliseconds: 500));
//       _backendChannel!.sink.add(json.encode({
//         'type': 'connect',
//         'timestamp': DateTime.now().toIso8601String(),
//       }));
//
//       print('WebSocket 연결 성공 및 초기 메시지 전송');
//
//       // WebSocket 연결 후 ping 메시지 주기적으로 보내기 시작
//       _startPingTimer();  // ping 타이머 시작
//
//     } catch (e) {
//       print('Backend connection failed: $e');
//       setState(() {
//         _voiceState = VoiceState.error;
//       });
//       // 재연결 시도: 5초 후
//       Future.delayed(Duration(seconds: 5), () {
//         print('WebSocket 재연결 시도');
//         _connectToBackend();
//       });
//     }
//   }
//
// // 서버로 주기적으로 ping 메시지를 보내는 방법
//   Future<void> _sendPing() async {
//     if (_backendChannel != null) {
//       _backendChannel!.sink.add(json.encode({
//         'type': 'ping',
//         'timestamp': DateTime.now().toIso8601String(),
//       }));
//     }
//   }
//
// // 일정 시간 간격으로 ping 보내기
//   void _startPingTimer() {
//     Timer.periodic(Duration(seconds: 30), (timer) {
//       _sendPing();
//     });
//   }
//
//   // Spring Boot에서 오는 메시지 처리
//   void _handleBackendMessage(dynamic data) async {
//     try {
//       final message = json.decode(data);
//
//       switch (message['type']) {
//         case 'audio_chunk':
//         // 실시간 오디오 청크 재생
//           final audioBytes = base64Decode(message['audio_data']);
//           await _playAudioChunk(audioBytes);
//           break;
//
//         case 'audio_start':
//         // AI 응답 시작
//           setState(() {
//             _voiceState = VoiceState.listening;
//             _recordController.stop();
//           });
//           break;
//
//         case 'audio_end':
//         // AI 응답 완료, 다시 말하기 가능 상태로
//           setState(() {
//             _voiceState = VoiceState.idle;
//           });
//           break;
//
//         case 'text_response':
//         // AI 텍스트 응답 (UI 업데이트용)
//           setState(() {
//             _aiResponse = message['text'];
//             _conversations.add({
//               'type': 'ai',
//               'message': _aiResponse,
//               'timestamp': DateTime.now(),
//             });
//           });
//           break;
//
//         case 'error':
//           print('Backend error: ${message['message']}');
//           setState(() {
//             _voiceState = VoiceState.error;
//           });
//           break;
//       }
//     } catch (e) {
//       print('Message handling error: $e');
//     }
//   }
//
//   // 실시간 오디오 청크 재생
//   Future<void> _playAudioChunk(Uint8List audioBytes) async {
//     try {
//       await _audioPlayer.play(BytesSource(audioBytes));
//     } catch (e) {
//       print('Audio playback error: $e');
//     }
//   }
//
//   // 음성 녹음 시작
//   Future<void> _startRecording() async {
//     if (!_whisperEnabled) return;
//
//     try {
//       // 임시 디렉토리 경로 가져오기
//       final tempDir = await getTemporaryDirectory();
//       _currentRecordingPath = '${tempDir.path}/whisper_audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
//
//       // 녹음 시작 (hasPermission 체크 제거)
//       try {
//         await _recorder.startRecorder(
//           toFile: _currentRecordingPath!,
//           codec: Codec.aacMP4,
//           bitRate: 128000,
//           sampleRate: 16000,
//         );
//
//         setState(() {
//           _currentSpeechText = '';
//         });
//
//         print('녹음 시작: $_currentRecordingPath');
//       } catch (e) {
//         print('녹음 시작 실패: $e');
//         throw Exception('녹음 권한이 없거나 녹음을 시작할 수 없습니다');
//       }
//     } catch (e) {
//       print('녹음 시작 오류: $e');
//       setState(() {
//         _voiceState = VoiceState.error;
//       });
//     }
//   }
//
//   // 음성 녹음 중지 및 Whisper STT 처리
//   Future<void> _stopRecording() async {
//     try {
//       // 녹음 중지
//       await _recorder.stopRecorder();
//
//
//       setState(() {
//         _voiceState = VoiceState.processing;
//       });
//
//       print('녹음 중지: $_currentRecordingPath');
//
//       // 파일 존재 확인
//       if (_currentRecordingPath == null || !File(_currentRecordingPath!).existsSync()) {
//         throw Exception('녹음 파일을 찾을 수 없습니다');
//       }
//
//       // Whisper STT 처리
//       await _transcribeWithWhisper(_currentRecordingPath!);
//
//     } catch (e) {
//       print('녹음 중지 오류: $e');
//       setState(() {
//         _voiceState = VoiceState.error;
//       });
//     }
//   }
//
//   // Whisper API로 음성을 텍스트로 변환
//   Future<void> _transcribeWithWhisper(String audioPath) async {
//     try {
//       print('Whisper STT 처리 시작...');
//
//       // 오디오 파일 읽기
//       final audioFile = File(audioPath);
//       final audioBytes = await audioFile.readAsBytes();
//
//       // Whisper API 호출
//       final transcribedText = await transcribeAudioWithWhisper(audioBytes) ?? '';
//
//       setState(() {
//         _currentSpeechText = transcribedText;
//       });
//
//       if (transcribedText.isNotEmpty) {
//         // 인식된 텍스트를 Spring Boot로 전송
//         _sendTextToBackend(transcribedText);
//
//         // 대화 기록에 추가
//         setState(() {
//           _conversations.add({
//             'type': 'user',
//             'message': transcribedText,
//             'timestamp': DateTime.now(),
//           });
//           _voiceState = VoiceState.listening; // AI 응답 대기 상태로 변경
//         });
//
//         print('STT 결과: $transcribedText');
//       } else {
//         setState(() {
//           _voiceState = VoiceState.idle;
//         });
//         print('인식된 텍스트가 없습니다.');
//       }
//
//       // 임시 파일 삭제
//       await audioFile.delete();
//
//     } catch (e) {
//       print('Whisper STT 오류: $e');
//       setState(() {
//         _voiceState = VoiceState.error;
//       });
//     }
//   }
//
//   // 텍스트를 Spring Boot로 전송
//   void _sendTextToBackend(String text) {
//     if (_backendChannel != null) {
//       _backendChannel!.sink.add(json.encode({
//         'type': 'user_message',
//         'text': text,
//         'timestamp': DateTime.now().toIso8601String(),
//       }));
//     }
//   }
//
//   // 통화 시간을 MM:SS 형식으로 포맷팅
//   String _formatDuration(Duration duration) {
//     final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
//     final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
//     return '$minutes:$seconds';
//   }
//
//   // 현재 상태에 따른 버튼 텍스트 반환
//   String _getButtonText() {
//     switch (_voiceState) {
//       case VoiceState.idle:
//         return '말하기';
//       case VoiceState.listening:
//         return '답변 듣는중...';
//       case VoiceState.speaking:
//         return '그만말하기';
//       case VoiceState.processing:
//         return '처리중...';
//       case VoiceState.error:
//         return '다시 시도';
//     }
//   }
//
//   // 말풍선 메시지 반환
//   String _getBubbleMessage() {
//     if (!_hasStartedConversation) {
//       return '말하기 버튼을 누르고 말씀해주세요';
//     }
//
//     switch (_voiceState) {
//       case VoiceState.listening:
//         return 'AI가 답변하고 있습니다\n잠시만 기다려주세요';
//       case VoiceState.speaking:
//         return '말씀이 끝나시면\n그만말하기를 눌러주세요';
//       case VoiceState.processing:
//         return '음성을 분석하고 있습니다\n잠시만 기다려주세요';
//       case VoiceState.error:
//         return '연결에 문제가 발생했습니다\n다시 시도해주세요';
//       default:
//         return '말하기 버튼을 누르고 말씀해주세요';
//     }
//   }
//
//   // 버튼 클릭 처리
//   void _handleButtonPress() async {
//     if (_voiceState == VoiceState.listening || _voiceState == VoiceState.processing) {
//       return; // 듣기 또는 처리 상태에서는 버튼 비활성화
//     }
//
//     // 버튼 애니메이션
//     _buttonScaleController.forward().then((_) {
//       _buttonScaleController.reverse();
//     });
//
//     HapticFeedback.mediumImpact();
//
//     try {
//       setState(() {
//         if (_voiceState == VoiceState.idle) {
//           // 말하기 시작
//           _voiceState = VoiceState.speaking;
//           _hasStartedConversation = true;
//           _recordController.repeat();
//           _startRecording(); // 녹음 시작
//
//         } else if (_voiceState == VoiceState.speaking) {
//           // 말하기 중단
//           _recordController.stop();
//           _stopRecording(); // 녹음 중지 및 STT 처리
//
//         } else if (_voiceState == VoiceState.error) {
//           // 에러 상태에서 재시도
//           _voiceState = VoiceState.idle;
//           _initializeWhisperSTT();
//         }
//       });
//     } catch (e) {
//       print('Button press error: $e');
//       setState(() {
//         _voiceState = VoiceState.error;
//       });
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       // 반투명 검은색 배경
//       backgroundColor: const Color(0x66000000),
//       body: Stack(
//         children: [
//           // 메인 레이아웃
//           Column(
//             children: [
//               // 상단 사용자 정보 영역
//               SafeArea(
//                 child: Padding(
//                   padding: const EdgeInsets.only(top: 24, left: 24, right: 24),
//                   child: Row(
//                     children: [
//                       // 사용자 프로필 아바타 (상태에 따른 테두리 색상)
//                       Container(
//                         decoration: BoxDecoration(
//                           shape: BoxShape.circle,
//                           border: Border.all(
//                             color: _voiceState == VoiceState.speaking
//                                 ? Colors.red.withOpacity(0.8)
//                                 : _voiceState == VoiceState.listening
//                                 ? Colors.green.withOpacity(0.8)
//                                 : _voiceState == VoiceState.processing
//                                 ? Colors.orange.withOpacity(0.8)
//                                 : Colors.transparent,
//                             width: 3,
//                           ),
//                         ),
//                         child: const CircleAvatar(
//                           radius: 24,
//                           backgroundColor: Color(0xFFBB9DF7),
//                           child: Icon(
//                             Icons.person,
//                             color: Colors.white,
//                             size: 28,
//                           ),
//                         ),
//                       ),
//                       const SizedBox(width: 12),
//                       // 사용자 이름과 통화 시간
//                       Expanded(
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             const Text(
//                               '정동연',
//                               style: TextStyle(
//                                 fontFamily: 'pretendard',
//                                 fontWeight: FontWeight.w700,
//                                 fontSize: 18,
//                                 color: Colors.white,
//                               ),
//                             ),
//                             Row(
//                               children: [
//                                 // 연결 상태 인디케이터
//                                 Container(
//                                   width: 8,
//                                   height: 8,
//                                   margin: const EdgeInsets.only(right: 6),
//                                   decoration: BoxDecoration(
//                                     shape: BoxShape.circle,
//                                     color: _voiceState == VoiceState.error
//                                         ? Colors.red
//                                         : _whisperEnabled
//                                         ? Colors.green
//                                         : Colors.orange,
//                                   ),
//                                 ),
//                                 Text(
//                                   _formatDuration(_callDuration),
//                                   style: const TextStyle(
//                                     fontFamily: 'pretendard',
//                                     fontSize: 14,
//                                     color: Colors.white,
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ],
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//
//               // 중앙 대화 내용 영역
//               Expanded(
//                 child: Padding(
//                   padding: const EdgeInsets.all(30),
//                   child: Container(
//                     width: double.infinity,
//                     padding: const EdgeInsets.all(50),
//                     decoration: BoxDecoration(
//                       color: const Color(0xFFE9F0F9),
//                       borderRadius: BorderRadius.circular(24),
//                       boxShadow: [
//                         BoxShadow(
//                           color: Colors.black.withOpacity(0.1),
//                           blurRadius: 10,
//                           offset: const Offset(0, 5),
//                         ),
//                       ],
//                     ),
//                     child: Column(
//                       children: [
//                         // 상태별 애니메이션 및 텍스트
//                         if (_voiceState == VoiceState.listening) ...[
//                           SizedBox(
//                             width: 80,
//                             height: 80,
//                             child: Lottie.asset(
//                               'asset/animation/voice_wave.json',
//                               fit: BoxFit.contain,
//                               repeat: true,
//                             ),
//                           ),
//                           const SizedBox(height: 16),
//                           const Text(
//                             'AI가 답변하고 있습니다.',
//                             style: TextStyle(
//                               fontFamily: 'pretendard',
//                               fontSize: 16,
//                               fontWeight: FontWeight.w600,
//                               color: Colors.blue,
//                             ),
//                           ),
//                         ] else if (_voiceState == VoiceState.speaking) ...[
//                           // 말하기 상태 시각화
//                           Container(
//                             width: 80,
//                             height: 80,
//                             decoration: BoxDecoration(
//                               shape: BoxShape.circle,
//                               color: Colors.red.withOpacity(0.1),
//                               border: Border.all(
//                                 color: Colors.red.withOpacity(0.3),
//                                 width: 2,
//                               ),
//                             ),
//                             child: const Icon(
//                               Icons.mic,
//                               color: Colors.red,
//                               size: 40,
//                             ),
//                           ),
//                           const SizedBox(height: 16),
//                           const Text(
//                             '음성을 녹음하고 있습니다.',
//                             style: TextStyle(
//                               fontFamily: 'pretendard',
//                               fontSize: 16,
//                               fontWeight: FontWeight.w600,
//                               color: Colors.red,
//                             ),
//                           ),
//                         ] else if (_voiceState == VoiceState.processing) ...[
//                           // 처리 상태 시각화
//                           SizedBox(
//                             width: 80,
//                             height: 80,
//                             child: CircularProgressIndicator(
//                               strokeWidth: 3,
//                               valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
//                             ),
//                           ),
//                           const SizedBox(height: 16),
//                           const Text(
//                             'Whisper AI가 음성을 분석중입니다.',
//                             style: TextStyle(
//                               fontFamily: 'pretendard',
//                               fontSize: 16,
//                               fontWeight: FontWeight.w600,
//                               color: Colors.orange,
//                             ),
//                           ),
//                           // 분석 결과 미리보기
//                           if (_currentSpeechText.isNotEmpty) ...[
//                             const SizedBox(height: 12),
//                             Container(
//                               padding: const EdgeInsets.all(12),
//                               decoration: BoxDecoration(
//                                 color: Colors.grey.shade100,
//                                 borderRadius: BorderRadius.circular(8),
//                               ),
//                               child: Text(
//                                 _currentSpeechText,
//                                 style: const TextStyle(
//                                   fontFamily: 'pretendard',
//                                   fontSize: 14,
//                                   color: Colors.black87,
//                                 ),
//                                 textAlign: TextAlign.center,
//                               ),
//                             ),
//                           ],
//                         ] else if (_voiceState == VoiceState.error) ...[
//                           Container(
//                             width: 80,
//                             height: 80,
//                             decoration: BoxDecoration(
//                               shape: BoxShape.circle,
//                               color: Colors.red.withOpacity(0.1),
//                             ),
//                             child: const Icon(
//                               Icons.error_outline,
//                               color: Colors.red,
//                               size: 40,
//                             ),
//                           ),
//                           const SizedBox(height: 16),
//                           const Text(
//                             '연결에 문제가 발생했습니다.',
//                             style: TextStyle(
//                               fontFamily: 'pretendard',
//                               fontSize: 16,
//                               fontWeight: FontWeight.w600,
//                               color: Colors.red,
//                             ),
//                           ),
//                         ],
//
//                         const SizedBox(height: 32),
//
//                         // 대화 내용 스크롤 영역
//                         Expanded(
//                           child: SingleChildScrollView(
//                             child: Column(
//                               children: [
//                                 // 기본 대화 내용
//                                 if (!_hasStartedConversation) ...[
//                                   const Text(
//                                     '안녕하세요! 😊',
//                                     style: TextStyle(
//                                       fontFamily: 'pretendard',
//                                       fontWeight: FontWeight.w600,
//                                       fontSize: 20,
//                                       color: Colors.black87,
//                                     ),
//                                     textAlign: TextAlign.center,
//                                   ),
//                                   const SizedBox(height: 12),
//                                   const Text(
//                                     '무엇을 도와드릴까요?\n\n(Whisper AI 사용)',
//                                     style: TextStyle(
//                                       fontFamily: 'pretendard',
//                                       fontSize: 16,
//                                       color: Colors.grey,
//                                     ),
//                                     textAlign: TextAlign.center,
//                                   ),
//                                 ] else ...[
//                                   // 실제 대화 내용 표시
//                                   ...List.generate(_conversations.length, (index) {
//                                     final conversation = _conversations[index];
//                                     final isUser = conversation['type'] == 'user';
//
//                                     return Container(
//                                       margin: const EdgeInsets.symmetric(vertical: 8),
//                                       child: Row(
//                                         mainAxisAlignment: isUser
//                                             ? MainAxisAlignment.end
//                                             : MainAxisAlignment.start,
//                                         children: [
//                                           if (!isUser) ...[
//                                             CircleAvatar(
//                                               radius: 12,
//                                               backgroundColor: Colors.blue.shade100,
//                                               child: const Icon(
//                                                 Icons.smart_toy,
//                                                 size: 16,
//                                                 color: Colors.blue,
//                                               ),
//                                             ),
//                                             const SizedBox(width: 8),
//                                           ],
//                                           Flexible(
//                                             child: Container(
//                                               padding: const EdgeInsets.symmetric(
//                                                 horizontal: 16,
//                                                 vertical: 12,
//                                               ),
//                                               decoration: BoxDecoration(
//                                                 color: isUser
//                                                     ? Colors.blue.shade500
//                                                     : Colors.grey.shade200,
//                                                 borderRadius: BorderRadius.circular(18),
//                                               ),
//                                               child: Text(
//                                                 conversation['message'],
//                                                 style: TextStyle(
//                                                   fontFamily: 'pretendard',
//                                                   fontSize: 14,
//                                                   color: isUser
//                                                       ? Colors.white
//                                                       : Colors.black87,
//                                                 ),
//                                               ),
//                                             ),
//                                           ),
//                                           if (isUser) ...[
//                                             const SizedBox(width: 8),
//                                             CircleAvatar(
//                                               radius: 12,
//                                               backgroundColor: Colors.purple.shade100,
//                                               child: const Icon(
//                                                 Icons.person,
//                                                 size: 16,
//                                                 color: Colors.purple,
//                                               ),
//                                             ),
//                                           ],
//                                         ],
//                                       ),
//                                     );
//                                   }),
//                                 ],
//                               ],
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 300),
//             ],
//           ),
//
//           // 말풍선 (상태에 따른 메시지)
//           if (_voiceState != VoiceState.speaking)
//             Positioned(
//               bottom: 185,
//               left: 0,
//               right: 45,
//               child: Center(
//                 child: SizedBox(
//                   width: 360,
//                   height: 120,
//                   child: Stack(
//                     alignment: Alignment.center,
//                     children: [
//                       widgets.Image.asset(
//                         'asset/image/speech_bubble.png',
//                         fit: BoxFit.contain,
//                         width: 360,
//                       ),
//                       Positioned(
//                         top: 25,
//                         child: SizedBox(
//                           width: 240,
//                           child: Text(
//                             _getBubbleMessage(),
//                             style: const TextStyle(
//                               fontFamily: 'Pretendard',
//                               fontSize: 14,
//                               fontWeight: FontWeight.w700,
//                               color: Colors.white,
//                             ),
//                             textAlign: TextAlign.center,
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//
//           // 하단 버튼 영역
//           Positioned(
//             bottom: 32,
//             left: 0,
//             right: 0,
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//               children: [
//                 // 통화 종료 버튼
//                 Column(
//                   children: [
//                     GestureDetector(
//                       onTap: () async {
//                         HapticFeedback.heavyImpact();
//
//                         // WebSocket 연결 정리
//                         if (_backendChannel != null) {
//                           _backendChannel!.sink.add(json.encode({
//                             'type': 'disconnect',
//                             'timestamp': DateTime.now().toIso8601String(),
//                           }));
//                           await _backendChannel!.sink.close();
//                         }
//
//                         // 녹음기 정리
//                         if (_recorder.isRecording) {
//                           await _recorder.stopRecorder();
//                         }
//                         await _recorder.closeRecorder();
//
//                         Navigator.pop(context);
//                       },
//                       child: Container(
//                         width: 85,
//                         height: 85,
//                         decoration: BoxDecoration(
//                           shape: BoxShape.circle,
//                           color: Colors.red.withOpacity(0.2),
//                           border: Border.all(
//                             color: Colors.red.withOpacity(0.3),
//                             width: 5,
//                           ),
//                         ),
//                         child: const Icon(
//                           Icons.call_end,
//                           color: Colors.red,
//                           size: 36,
//                         ),
//                       ),
//                     ),
//                     const SizedBox(height: 10),
//                     Transform.translate(
//                       offset: const Offset(0, 0),
//                       child: const Text(
//                         '통화 종료',
//                         style: TextStyle(
//                           color: Colors.white,
//                           fontFamily: 'pretendard',
//                           fontSize: 14,
//                           fontWeight: FontWeight.w600,
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//
//                 // 말하기 버튼
//                 Column(
//                   children: [
//                     ScaleTransition(
//                       scale: Tween<double>(begin: 1.0, end: 0.95).animate(
//                         CurvedAnimation(
//                           parent: _buttonScaleController,
//                           curve: Curves.easeInOut,
//                         ),
//                       ),
//                       child: GestureDetector(
//                         onTap: _handleButtonPress,
//                         child: Container(
//                           width: 150,
//                           height: 150,
//                           decoration: BoxDecoration(
//                             shape: BoxShape.circle,
//                             boxShadow: [
//                               BoxShadow(
//                                 color: _voiceState == VoiceState.speaking
//                                     ? Colors.red.withOpacity(0.3)
//                                     : _voiceState == VoiceState.listening
//                                     ? Colors.grey.withOpacity(0.3)
//                                     : _voiceState == VoiceState.processing
//                                     ? Colors.orange.withOpacity(0.3)
//                                     : Colors.blue.withOpacity(0.3),
//                                 blurRadius: 20,
//                                 spreadRadius: 5,
//                               ),
//                             ],
//                           ),
//                           child: Lottie.asset(
//                             'asset/animation/record_pulse.json',
//                             controller: _recordController,
//                             fit: BoxFit.contain,
//                             repeat: false,
//                             onLoaded: (composition) {
//                               _recordController.duration = composition.duration;
//                               if (_voiceState == VoiceState.speaking) {
//                                 _recordController.repeat();
//                               }
//                             },
//                           ),
//                         ),
//                       ),
//                     ),
//                     const SizedBox(height: 10),
//                     Transform.translate(
//                       offset: const Offset(0, -30),
//                       child: Text(
//                         _getButtonText(),
//                         style: TextStyle(
//                           color: _voiceState == VoiceState.listening || _voiceState == VoiceState.processing
//                               ? Colors.grey
//                               : _voiceState == VoiceState.error
//                               ? Colors.red.shade300
//                               : Colors.white,
//                           fontFamily: 'pretendard',
//                           fontSize: 14,
//                           fontWeight: FontWeight.w600,
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }