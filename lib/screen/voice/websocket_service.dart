// websocket_service.dart
// Spring Boot 백엔드와의 WebSocket 통신을 담당하는 서비스 클래스
// AI 음성 응답 및 텍스트 응답 처리 기능 포함

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class WebSocketService {
  WebSocketChannel? _channel;                 // WebSocket 채널 객체
  final AudioPlayer _audioPlayer = AudioPlayer(); // 오디오 재생용
  Timer? _pingTimer;                          // 주기적인 ping 타이머

  // 콜백 함수들 - 외부에서 지정 가능
  Function(String)? onTextResponse;           // 텍스트 응답 처리
  Function()? onAudioStart;                   // 오디오 시작 신호 처리
  Function()? onAudioEnd;                     // 오디오 끝 신호 처리
  Function(String)? onError;                  // 에러 메시지 처리
  Function()? onConnectionLost;               // 연결 종료 시 호출

  // WebSocket URL (환경 변수에서 가져옴)
  String get _backendUrl => dotenv.env['BACKEND_URL'] ?? 'ws://localhost:8080/voice-call';

  // 현재 연결 상태 확인용 getter
  bool get isConnected => _channel != null;

  // WebSocket 백엔드 서버에 연결
  Future<void> connect() async {
    try {
      // SharedPreferences에서 authKeyId 불러옴
      final prefs = await SharedPreferences.getInstance();
      final authKeyId = prefs.getString('authKeyId') ?? '';

      // 쿼리 파라미터 포함된 URI 구성
      final wsUri = Uri.parse(_backendUrl);
      final updatedUri = Uri(
        scheme: wsUri.scheme,
        host: wsUri.host,
        port: wsUri.port,
        path: wsUri.path,
        queryParameters: {
          'authKeyId': authKeyId,
        },
      );

      // WebSocket 연결
      _channel = IOWebSocketChannel.connect(updatedUri.toString());

      // 연결 후 수신 스트림 처리
      _channel!.stream.listen(
            (data) {
          print('WebSocket 메시지 수신: $data');
          _handleMessage(data);
        },
        onError: (error) {
          print('Backend WebSocket Error: $error');
          onError?.call('WebSocket 연결 오류');
          _scheduleReconnect();  // 오류 시 재연결 예약
        },
        onDone: () {
          print('Backend WebSocket connection closed');
          onConnectionLost?.call(); // 연결 종료 콜백 호출
          _scheduleReconnect();     // 종료 후 재연결 예약
        },
      );

      // 연결 완료 후 초기 메시지 전송 (connect)
      await Future.delayed(Duration(milliseconds: 500));
      await sendMessage({
        'type': 'connect',
        'timestamp': DateTime.now().toIso8601String(),
      });

      print('WebSocket 연결 성공');
      _startPingTimer(); // ping 타이머 시작

    } catch (e) {
      print('Backend connection failed: $e');
      onError?.call('서버 연결 실패');
      _scheduleReconnect(); // 연결 실패 시 재시도 예약
    }
  }

  // 서버로 메시지 전송
  Future<void> sendMessage(Map<String, dynamic> message) async {
    if (_channel != null) {
      _channel!.sink.add(json.encode(message));
    }
  }

  // 사용자 텍스트 메시지를 서버에 전송
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

  // 서버에서 수신한 메시지 처리
  void _handleMessage(dynamic data) async {
    try {
      final message = json.decode(data);

      switch (message['type']) {
        case 'audio_chunk':
        // 오디오 청크 수신 → 재생
          final audioBytes = base64Decode(message['audio_data']);
          await _playAudioChunk(audioBytes);
          break;

        case 'audio_start':
        // AI 응답 시작 알림
          onAudioStart?.call();
          break;

        case 'audio_end':
        // AI 응답 종료 알림
          onAudioEnd?.call();
          break;

        case 'text_response':
        // AI가 생성한 텍스트 응답 수신
          final text = message['text']?.toString() ?? '';
          onTextResponse?.call(text);
          break;

        case 'error':
        // 서버 오류 메시지 수신
          print('Backend error: ${message['message']}');
          onError?.call(message['message'] ?? '서버 오류');
          break;

        case 'pong':
        // ping 응답 수신 (생존 확인용)
          print('Pong received - connection alive');
          break;
      }
    } catch (e) {
      print('Message handling error: $e');
      onError?.call('메시지 처리 오류');
    }
  }

  // 오디오 청크 재생 처리
  Future<void> _playAudioChunk(Uint8List audioBytes) async {
    try {
      await _audioPlayer.play(BytesSource(audioBytes));
    } catch (e) {
      print('Audio playback error: $e');
    }
  }

  // 주기적으로 ping 메시지 전송
  void _startPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(Duration(seconds: 30), (timer) {
      _sendPing();
    });
  }

  // ping 메시지 전송
  void _sendPing() {
    sendMessage({
      'type': 'ping',
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  // 서버 연결 실패 또는 끊김 시 재연결 예약
  void _scheduleReconnect() {
    Future.delayed(Duration(seconds: 5), () {
      print('WebSocket 재연결 시도');
      connect();
    });
  }

  // 리소스 해제
  Future<void> dispose() async {
    _pingTimer?.cancel();          // 타이머 중지
    await _audioPlayer.dispose();  // 오디오 플레이어 종료
    if (_channel != null) {
      await _channel!.sink.close(); // WebSocket 종료
      _channel = null;
    }
  }
}
