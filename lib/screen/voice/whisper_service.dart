// whisper_service.dart
// Whisper STT 관련 기능을 담당하는 서비스 클래스
// - 녹음 시작/종료
// - Whisper(OpenAI) API를 통한 음성 → 텍스트 변환
// - 리소스 관리 및 권한 처리 포함

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class WhisperService {
  late FlutterSoundRecorder _recorder;      // 녹음기 객체
  String? _currentRecordingPath;            // 현재 녹음 파일 경로
  bool _isInitialized = false;              // 초기화 여부

  // 외부에서 접근할 수 있는 상태
  bool get isInitialized => _isInitialized;
  bool get isRecording => _recorder.isRecording;

  // ✅ 초기화 (권한 요청 + 환경변수 확인)
  Future<void> initialize() async {
    try {
      _recorder = FlutterSoundRecorder();
      await _recorder.openRecorder();

      // 마이크 권한 요청
      final micStatus = await Permission.microphone.request();
      if (micStatus != PermissionStatus.granted) {
        throw Exception('마이크 권한이 필요합니다');
      }

      // OpenAI API 키 확인
      final apiKey = dotenv.env['OPENAI_API_KEY'];
      if (apiKey == null || apiKey.isEmpty) {
        throw Exception('OpenAI API 키가 설정되지 않았습니다');
      }

      _isInitialized = true;
      print('Whisper STT 초기화 완료');
    } catch (e) {
      print('Whisper STT 초기화 실패: $e');
      rethrow; // 외부에 에러 전달
    }
  }

  // ✅ 녹음 시작
  Future<void> startRecording() async {
    if (!_isInitialized) {
      throw Exception('Whisper 서비스가 초기화되지 않았습니다');
    }

    try {
      // 임시 디렉토리 경로 가져오기
      final tempDir = await getTemporaryDirectory();
      _currentRecordingPath = '${tempDir.path}/whisper_audio_${DateTime.now().millisecondsSinceEpoch}.m4a';

      // 녹음 시작 (m4a 파일 생성)
      await _recorder.startRecorder(
        toFile: _currentRecordingPath!,
        codec: Codec.aacMP4,
        bitRate: 128000,
        sampleRate: 16000,
      );

      print('녹음 시작: $_currentRecordingPath');
    } catch (e) {
      print('녹음 시작 오류: $e');
      rethrow;
    }
  }

  // ✅ 녹음 종료 및 파일 경로 반환
  Future<String?> stopRecording() async {
    try {
      await _recorder.stopRecorder();
      print('녹음 중지: $_currentRecordingPath');

      // 파일 유효성 검사
      if (_currentRecordingPath == null || !File(_currentRecordingPath!).existsSync()) {
        throw Exception('녹음 파일을 찾을 수 없습니다');
      }

      return _currentRecordingPath;
    } catch (e) {
      print('녹음 중지 오류: $e');
      rethrow;
    }
  }

  // ✅ Whisper API로 텍스트 변환 (파일 경로 전달)
  Future<String?> transcribeAudio(String audioPath) async {
    try {
      print('Whisper STT 처리 시작...');

      final audioFile = File(audioPath);
      final audioBytes = await audioFile.readAsBytes();

      final transcribedText = await _callWhisperAPI(audioBytes);

      // 처리 후 임시 녹음 파일 삭제
      await audioFile.delete();

      print('STT 결과: $transcribedText');
      return transcribedText;
    } catch (e) {
      print('Whisper STT 오류: $e');
      rethrow;
    }
  }

  // ✅ Whisper API 호출 (OpenAI)
  Future<String?> _callWhisperAPI(Uint8List audioBytes) async {
    final apiKey = dotenv.env['OPENAI_API_KEY'] ?? '';
    if (apiKey.isEmpty) {
      print('OpenAI API 키가 설정되지 않았습니다.');
      return null;
    }

    final uri = Uri.parse('https://api.openai.com/v1/audio/transcriptions');
    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $apiKey'
      ..fields['model'] = 'whisper-1'
      ..fields['language'] = 'ko'
      ..files.add(http.MultipartFile.fromBytes(
        'file',
        audioBytes,
        filename: 'audio.m4a',
      ));

    try {
      final response = await request.send();
      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        final data = json.decode(responseData);
        return data['text']?.toString();
      } else {
        print('Whisper API 오류: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Whisper API 호출 오류: $e');
      return null;
    }
  }

  // ✅ 리소스 해제
  Future<void> dispose() async {
    if (_recorder.isRecording) {
      await _recorder.stopRecorder();
    }
    await _recorder.closeRecorder();
  }
}
