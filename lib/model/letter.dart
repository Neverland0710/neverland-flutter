// 날짜 형식을 처리하기 위해 intl 패키지를 가져옵니다.
import 'package:intl/intl.dart';

/// 편지 데이터를 나타내는 클래스입니다.
/// 편지의 기본 정보, 답장 내용, 배송 상태 및 관련 ID를 관리합니다.
class Letter {
  // 편지의 고유 식별자입니다.
  final String id;
  // 편지의 제목입니다.
  final String title;
  // 편지의 본문 내용입니다.
  final String content;
  // 편지가 생성된 날짜와 시간입니다.
  final DateTime createdAt;
  // 답장 내용 (선택 사항)입니다.
  final String? replyContent;
  // 편지의 배송 상태 (예: 'DELIVERED')입니다.
  final String? deliveryStatus;

  // 인증 키 ID (선택 사항)입니다.
  final String? authKeyId;
  // 사용자 ID (선택 사항)입니다.
  final String? userId;
  // 사망자 ID (선택 사항)입니다.
  final String? deceasedId;

  /// Letter 객체를 생성하는 생성자입니다.
  /// 필수 매개변수: id, title, content, createdAt
  /// 선택 매개변수: replyContent, deliveryStatus, authKeyId, userId, deceasedId
  Letter({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    this.replyContent,
    this.deliveryStatus,
    this.authKeyId,
    this.userId,
    this.deceasedId,
  });

  /// 서버에서 받은 JSON 데이터를 바탕으로 Letter 객체를 생성하는 팩토리 생성자입니다.
  /// 서버 응답 구조에 맞게 데이터를 파싱합니다.
  factory Letter.fromJson(Map<String, dynamic> json) {
    // authKey 객체가 없으면 빈 맵을 사용합니다.
    final authKey = json['authKey'] ?? {};
    return Letter(
      id: json['letterId'] ?? json['id'], // 서버에서 letterId 또는 id를 사용
      title: json['title'] ?? '', // 제목이 없으면 빈 문자열
      content: json['content'] ?? '', // 내용이 없으면 빈 문자열
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt']) // createdAt을 DateTime으로 파싱
          : DateTime.now(), // 값이 없으면 현재 시간
      replyContent: json['replyContent'], // 서버에서 제공된 답장 내용
      deliveryStatus: json['deliveryStatus'], // 서버에서 제공된 배송 상태
      authKeyId: authKey['authKeyId'], // authKey에서 인증 키 ID
      userId: authKey['userId'], // authKey에서 사용자 ID
      deceasedId: authKey['deceasedId'], // authKey에서 사망자 ID
    );
  }

  /// Letter 객체를 JSON 형식으로 변환하여 반환합니다.
  /// 서버로 전송하거나 저장할 때 사용됩니다.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'createdAt': createdAt.toIso8601String(), // DateTime을 ISO 8601 문자열로 변환
      'replyContent': replyContent,
      'deliveryStatus': deliveryStatus,
    };
  }

  /// 답장이 도착했는지 확인하는 getter입니다.
  /// 배송 상태가 'DELIVERED'이고 답장 내용이 비어 있지 않은 경우 true를 반환합니다.
  bool get isArrived {
    return deliveryStatus == 'DELIVERED' && replyContent != null && replyContent!.isNotEmpty;
  }

  /// 생성 날짜를 'yyyy.MM.dd' 형식으로 포맷팅하여 반환합니다.
  String get formattedDate {
    return DateFormat('yyyy.MM.dd').format(createdAt);
  }

  /// 기존 Letter 객체를 복사하면서 일부 속성을 업데이트하여 새 객체를 반환합니다.
  /// 지정되지 않은 속성은 기존 값을 유지합니다.
  Letter copyWith({
    String? id,
    String? title,
    String? content,
    DateTime? createdAt,
    String? replyContent,
    String? deliveryStatus,
  }) {
    return Letter(
      id: id ?? this.id, // 새로운 id가 없으면 기존 id 사용
      title: title ?? this.title, // 새로운 title이 없으면 기존 title 사용
      content: content ?? this.content, // 새로운 content가 없으면 기존 content 사용
      createdAt: createdAt ?? this.createdAt, // 새로운 createdAt이 없으면 기존 createdAt 사용
      replyContent: replyContent ?? this.replyContent, // 새로운 replyContent가 없으면 기존 replyContent 사용
      deliveryStatus: deliveryStatus ?? this.deliveryStatus, // 새로운 deliveryStatus가 없으면 기존 deliveryStatus 사용
      authKeyId: this.authKeyId, // authKeyId는 복사하지 않음
      userId: this.userId, // userId는 복사하지 않음
      deceasedId: this.deceasedId, // deceasedId는 복사하지 않음
    );
  }
}