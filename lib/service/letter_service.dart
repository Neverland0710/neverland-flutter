import 'package:http/http.dart' as http;
import 'dart:convert';
import '../model/letter.dart';

/// 편지 관련 서비스 헬퍼 클래스
/// 공통으로 사용되는 API 호출 로직을 모아둔 유틸리티 클래스
class LetterService {
  // 서버 베이스 URL (실제 환경에 맞게 수정)
  static const String baseUrl = 'http://52.78.139.47:8086';

  /// 수신자 이름을 서버에서 불러오는 함수
  ///
  /// [userId]: 사용자 ID
  ///
  /// Returns: 수신자 이름 또는 null (실패 시)
  static Future<String?> fetchRecipientName(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/chat/relation?userId=$userId'),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return data['name'];
      } else {
        print('❌ 이름 불러오기 실패: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('❌ 네트워크 오류: $e');
      return null;
    }
  }

  /// 편지 목록을 서버에서 불러오는 함수
  ///
  /// [authKeyId]: 인증 키 ID
  ///
  /// Returns: Letter 객체 리스트 또는 null (실패 시)
  static Future<List<Letter>?> fetchLetterList(String authKeyId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/letter/list?authKeyId=$authKeyId'),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final List<dynamic> jsonList = jsonDecode(response.body);
        return jsonList.map((e) => Letter.fromJson(e)).toList();
      } else {
        print('❌ 편지 목록 불러오기 실패: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('❌ 네트워크 오류: $e');
      return null;
    }
  }

  /// 편지를 서버에 전송하는 함수
  ///
  /// [userId]: 사용자 ID
  /// [authKeyId]: 인증 키 ID
  /// [title]: 편지 제목
  /// [content]: 편지 내용
  /// [createdAt]: 작성일시
  ///
  /// Returns: 서버 응답 JSON 또는 null (실패 시)
  static Future<Map<String, dynamic>?> sendLetter({
    required String userId,
    required String authKeyId,
    required String title,
    required String content,
    required DateTime createdAt,
  }) async {
    final requestBody = {
      'user_id': userId,
      'auth_key_id': authKeyId,
      'title': title,
      'content': content,
      'created_at': createdAt.toIso8601String(),
    };

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/letter/send'),
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Accept': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (response.body.isNotEmpty && response.body.trim().startsWith('{')) {
          return jsonDecode(response.body) as Map<String, dynamic>;
        }
        return {}; // 빈 응답이지만 성공한 경우
      } else {
        print('❌ 편지 전송 실패: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('❌ 편지 전송 오류: $e');
      return null;
    }
  }

  /// 답장 생성을 요청하는 함수
  ///
  /// [letterId]: 편지 ID
  /// [authKeyId]: 인증 키 ID
  /// [userId]: 사용자 ID
  ///
  /// Returns: 성공 여부 (true/false)
  static Future<bool> generateReply({
    required String letterId,
    required String authKeyId,
    required String userId,
  }) async {
    final requestBody = {
      'letterId': letterId,
      'authKeyId': authKeyId,
      'userId': userId,
    };

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/letter/reply'),
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Accept': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        print('✅ 답장 생성 요청 성공');
        return true;
      } else {
        print('❌ 답장 생성 요청 실패: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ 답장 생성 오류: $e');
      return false;
    }
  }
}