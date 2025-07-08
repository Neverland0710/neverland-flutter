// 필요한 패키지 가져오기
import 'dart:async'; // 비동기 작업(타이머 등)을 위해
import 'dart:convert'; // JSON 인코딩/디코딩 및 base64 처리
import 'dart:io'; // 파일 시스템 작업을 위해
import 'dart:typed_data'; // Uint8List와 같은 타입 데이터 처리
import 'package:flutter_dotenv/flutter_dotenv.dart'; // 환경 변수 관리
import 'package:flutter_sound/flutter_sound.dart'; // 오디오 재생 기능
import 'package:path_provider/path_provider.dart'; // 임시 디렉토리 접근
import 'package:shared_preferences/shared_preferences.dart'; // 영구 저장소
import 'package:web_socket_channel/io.dart'; // WebSocket 통신을 위한 IO 기반 채널
import 'package:web_socket_channel/web_socket_channel.dart'; // WebSocket 채널 관리

// WebSocket 통신을 관리하는 클래스
class WebSocketService {
  // WebSocket 연결 채널
  WebSocketChannel? _channel;
  // 수신된 오디오 데이터를 저장하는 버퍼
  final List<Uint8List> _audioBuffer = [];
  // 오디오 버퍼를 처리하기 위한 타이머
  Timer? _bufferTimer;
  // WebSocket 연결 유지 확인을 위한 핑 타이머
  Timer? _pingTimer;

  // MP3 오디오 재생을 위한 플레이어
  final FlutterSoundPlayer _player = FlutterSoundPlayer();

  // 외부에서 사용할 콜백 함수들
  Function(String)? onTextResponse; // 텍스트 응답 처리
  Function()? onAudioStart; // 오디오 시작 이벤트
  Function()? onAudioEnd; // 오디오 종료 이벤트
  Function(String)? onError; // 에러 발생 이벤트
  Function()? onConnectionLost; // 연결 끊김 이벤트
  Function()? onReconnected; // ✅ 연결 재성공 이벤트

  // 환경 변수에서 백엔드 WebSocket URL 가져오기 (기본값: 로컬호스트)
  String get _backendUrl => dotenv.env['BACKEND_URL'] ?? 'ws://localhost:8080/ws/audio';
  // WebSocket 연결 상태 확인
  bool get isConnected => _channel != null;

  // 생성자: 플레이어 초기화
  WebSocketService() {
    _initPlayer(); // 플레이어 초기화 호출
  }

  // 오디오 플레이어 초기화
  Future<void> _initPlayer() async {
    await _player.openPlayer(); // 플레이어 열기
  }

  // 오디오 플레이어 해제
  Future<void> _disposePlayer() async {
    await _player.stopPlayer(); // 플레이어 중지
    await _player.closePlayer(); // 플레이어 닫기
  }

  // WebSocket 서버에 연결
  Future<void> connect() async {
    try {
      // 공유 저장소에서 인증 키 가져오기
      final prefs = await SharedPreferences.getInstance();
      final authKeyId = prefs.getString('authKeyId') ?? '';
      final wsUrl = _backendUrl; // WebSocket URL

      // WebSocket 연결 설정
      _channel = IOWebSocketChannel.connect(Uri.parse(wsUrl));
      // 인증 메시지 전송
      _channel!.sink.add(jsonEncode({
        'type': 'auth',
        'authKeyId': authKeyId,
        'timestamp': DateTime.now().toIso8601String(),
      }));

      // WebSocket 스트림 리스너 설정
      _channel!.stream.listen(
            (data) {
          if (data is String) {
            _handleMessage(data); // 문자열 메시지 처리
          } else if (data is Uint8List) {
            _enqueueAudio(data); // 바이너리 오디오 데이터 처리
          }
        },
        onError: (error) {
          onError?.call('WebSocket 연결 오류'); // 에러 콜백 호출
          _scheduleReconnect(); // 재연결 예약
        },
        onDone: () {
          onConnectionLost?.call(); // 연결 끊김 콜백 호출
          _scheduleReconnect(); // 재연결 예약
        },
      );

      // 연결 후 약간의 지연 후 connect 메시지 전송
      await Future.delayed(const Duration(milliseconds: 500));
      await sendMessage({
        'type': 'connect',
        'timestamp': DateTime.now().toIso8601String(),
      });

      _startPingTimer(); // 핑 타이머 시작

      // ✅ 연결 성공 시 콜백 호출
      onReconnected?.call();
    } catch (e) {
      onError?.call('서버 연결 실패'); // 연결 실패 시 에러 콜백
      _scheduleReconnect(); // 재연결 예약
    }
  }

  // JSON 메시지를 WebSocket으로 전송
  Future<void> sendMessage(Map<String, dynamic> message) async {
    _channel?.sink.add(json.encode(message)); // JSON으로 인코딩 후 전송
  }

  // 사용자 텍스트 메시지 전송
  Future<void> sendUserMessage(String text) async {
    await sendMessage({
      'type': 'user_message',
      'text': text,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  // 연결 종료 메시지 전송
  Future<void> sendDisconnect() async {
    await sendMessage({
      'type': 'disconnect',
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  // 수신된 메시지 처리
  void _handleMessage(dynamic data) async {
    try {
      if (data is String) {
        // JSON 파싱 시도
        try {
          final message = json.decode(data);

          // 메시지 타입에 따라 처리
          switch (message['type']) {
            case 'audio_chunk':
              final audioBytes = base64Decode(message['audio_data']); // base64 디코딩
              _enqueueAudio(audioBytes); // 오디오 데이터 버퍼에 추가
              break;
            case 'audio_start':
              onAudioStart?.call(); // 오디오 시작 콜백 호출
              break;
            case 'audio_end':
              onAudioEnd?.call(); // 오디오 종료 콜백 호출
              break;
            case 'text_response':
              final text = message['text']?.toString() ?? '';
              onTextResponse?.call(text); // 텍스트 응답 콜백 호출
              break;
            case 'error':
              onError?.call(message['message'] ?? '서버 오류'); // 에러 콜백 호출
              break;
            case 'pong':
              break; // 핑 응답 무시
            default:
              onError?.call('알 수 없는 메시지 타입: ${message['type']}'); // 알 수 없는 타입 처리
          }
        } catch (e) {
          // ✅ JSON이 아닌 일반 텍스트 처리
          print('📨 일반 텍스트 메시지 수신: $data');
          onTextResponse?.call(data); // 텍스트를 바로 콜백으로 전달
        }
      } else if (data is Uint8List) {
        _enqueueAudio(data); // 바이너리 오디오 데이터 처리
      } else {
        onError?.call('알 수 없는 데이터 형식: ${data.runtimeType}'); // 알 수 없는 데이터 형식 처리
      }
    } catch (e) {
      onError?.call('메시지 처리 오류: $e'); // 메시지 처리 실패 시 에러 콜백
      print('📛 메시지 처리 실패. 원본 데이터: $data'); // 디버깅 로그
    }
  }

  // 오디오 데이터를 버퍼에 추가
  void _enqueueAudio(Uint8List chunk) {
    _audioBuffer.add(chunk); // 오디오 청크를 버퍼에 추가
    _bufferTimer?.cancel(); // 기존 타이머 취소
    // 500ms 후 버퍼된 오디오 재생
    _bufferTimer = Timer(const Duration(milliseconds: 500), () {
      _playBufferedMp3(); // 버퍼된 오디오 재생
    });
  }

  // 버퍼된 MP3 오디오 재생
  Future<void> _playBufferedMp3() async {
    if (_audioBuffer.isEmpty) return; // 버퍼가 비어 있으면 종료
    final combined = _audioBuffer.expand((e) => e).toList(); // 버퍼 데이터 결합
    _audioBuffer.clear(); // 버퍼 비우기

    try {
      final dir = await getTemporaryDirectory(); // 임시 디렉토리 가져오기
      final path = '${dir.path}/buffered_audio.mp3'; // 임시 파일 경로
      final file = File(path);
      await file.writeAsBytes(combined, flush: true); // 파일에 오디오 데이터 쓰기

      // MP3 파일 재생
      await _player.startPlayer(
        fromURI: path,
        codec: Codec.mp3, // MP3 코덱 지정
        whenFinished: () => onAudioEnd?.call(), // 재생 완료 시 콜백
      );
    } catch (e) {
      onError?.call('오디오 재생 실패: $e'); // 재생 실패 시 에러 콜백
    }
  }

  // 서버와 연결 유지 확인을 위한 핑 타이머 시작
  void _startPingTimer() {
    _pingTimer?.cancel(); // 기존 타이머 취소
    _pingTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      sendMessage({
        'type': 'ping',
        'timestamp': DateTime.now().toIso8601String(),
      }); // 30초마다 핑 메시지 전송
    });
  }

  // 연결이 끊겼을 때 재연결 예약
  void _scheduleReconnect() {
    Future.delayed(const Duration(seconds: 5), () {
      connect(); // 5초 후 재연결 시도
    });
  }

  // 리소스 해제
  Future<void> dispose() async {
    _pingTimer?.cancel(); // 핑 타이머 취소
    _bufferTimer?.cancel(); // 버퍼 타이머 취소
    _audioBuffer.clear(); // 오디오 버퍼 비우기
    await _disposePlayer(); // 플레이어 해제
    await _channel?.sink.close(); // WebSocket 채널 닫기
    _channel = null; // 채널 초기화
  }
}