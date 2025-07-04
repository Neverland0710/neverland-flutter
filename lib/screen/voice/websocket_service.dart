import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class WebSocketService {
  WebSocketChannel? _channel;
  final List<Uint8List> _audioBuffer = [];
  Timer? _bufferTimer;
  Timer? _pingTimer;

  // MP3 플레이어
  final FlutterSoundPlayer _player = FlutterSoundPlayer();

  // 콜백
  Function(String)? onTextResponse;
  Function()? onAudioStart;
  Function()? onAudioEnd;
  Function(String)? onError;
  Function()? onConnectionLost;
  Function()? onReconnected; // ✅ 추가된 콜백

  String get _backendUrl => dotenv.env['BACKEND_URL'] ?? 'ws://localhost:8080/ws/audio';
  bool get isConnected => _channel != null;

  WebSocketService() {
    _initPlayer(); // 플레이어 초기화
  }

  Future<void> _initPlayer() async {
    await _player.openPlayer();
  }

  Future<void> _disposePlayer() async {
    await _player.stopPlayer();
    await _player.closePlayer();
  }

  Future<void> connect() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final authKeyId = prefs.getString('auth_key_id') ?? '';
      final wsUrl = _backendUrl;

      _channel = IOWebSocketChannel.connect(Uri.parse(wsUrl));
      _channel!.sink.add(jsonEncode({
        'type': 'auth',
        'authKeyId': authKeyId,
        'timestamp': DateTime.now().toIso8601String(),
      }));

      _channel!.stream.listen(
            (data) {
          if (data is String) {
            _handleMessage(data);
          } else if (data is Uint8List) {
            _enqueueAudio(data);
          }
        },
        onError: (error) {
          onError?.call('WebSocket 연결 오류');
          _scheduleReconnect();
        },
        onDone: () {
          onConnectionLost?.call();
          _scheduleReconnect();
        },
      );

      // 약간의 딜레이 후 connect 메시지 전송
      await Future.delayed(const Duration(milliseconds: 500));
      await sendMessage({
        'type': 'connect',
        'timestamp': DateTime.now().toIso8601String(),
      });

      _startPingTimer();

      // ✅ 연결 성공 알림
      onReconnected?.call();
    } catch (e) {
      onError?.call('서버 연결 실패');
      _scheduleReconnect();
    }
  }

  Future<void> sendMessage(Map<String, dynamic> message) async {
    _channel?.sink.add(json.encode(message));
  }

  Future<void> sendUserMessage(String text) async {
    await sendMessage({
      'type': 'user_message',
      'text': text,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  Future<void> sendDisconnect() async {
    await sendMessage({
      'type': 'disconnect',
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  void _handleMessage(dynamic data) async {
    try {
      if (data is String) {
        // JSON으로 파싱 가능한지 확인
        try {
          final message = json.decode(data);

          switch (message['type']) {
            case 'audio_chunk':
              final audioBytes = base64Decode(message['audio_data']);
              _enqueueAudio(audioBytes);
              break;
            case 'audio_start':
              onAudioStart?.call();
              break;
            case 'audio_end':
              onAudioEnd?.call();
              break;
            case 'text_response':
              final text = message['text']?.toString() ?? '';
              onTextResponse?.call(text);
              break;
            case 'error':
              onError?.call(message['message'] ?? '서버 오류');
              break;
            case 'pong':
              break;
            default:
              onError?.call('알 수 없는 메시지 타입: ${message['type']}');
          }
        } catch (e) {
          // ✅ JSON이 아니라면 일반 텍스트로 처리
          print('📨 일반 텍스트 메시지 수신: $data');
          onTextResponse?.call(data); // 바로 사용자에게 보여줌
        }
      } else if (data is Uint8List) {
        _enqueueAudio(data);
      } else {
        onError?.call('알 수 없는 데이터 형식: ${data.runtimeType}');
      }
    } catch (e) {
      onError?.call('메시지 처리 오류: $e');
      print('📛 메시지 처리 실패. 원본 데이터: $data');
    }
  }



  void _enqueueAudio(Uint8List chunk) {
    _audioBuffer.add(chunk);
    _bufferTimer?.cancel();
    _bufferTimer = Timer(const Duration(milliseconds: 500), () {
      _playBufferedMp3();
    });
  }

  Future<void> _playBufferedMp3() async {
    if (_audioBuffer.isEmpty) return;
    final combined = _audioBuffer.expand((e) => e).toList();
    _audioBuffer.clear();

    try {
      final dir = await getTemporaryDirectory();
      final path = '${dir.path}/buffered_audio.mp3';
      final file = File(path);
      await file.writeAsBytes(combined, flush: true);

      await _player.startPlayer(
        fromURI: path,
        codec: Codec.mp3,
        whenFinished: () => onAudioEnd?.call(),
      );
    } catch (e) {
      onError?.call('오디오 재생 실패: $e');
    }
  }

  void _startPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      sendMessage({
        'type': 'ping',
        'timestamp': DateTime.now().toIso8601String(),
      });
    });
  }

  void _scheduleReconnect() {
    Future.delayed(const Duration(seconds: 5), () {
      connect();
    });
  }

  Future<void> dispose() async {
    _pingTimer?.cancel();
    _bufferTimer?.cancel();
    _audioBuffer.clear();
    await _disposePlayer();
    await _channel?.sink.close();
    _channel = null;
  }
}
