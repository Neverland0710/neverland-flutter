import 'package:intl/intl.dart';

class Letter {
  final String id;
  final String title;
  final String content;
  final DateTime createdAt;
  final String? replyContent;
  final String? deliveryStatus; // 추가: 배송 상태

  Letter({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    this.replyContent,
    this.deliveryStatus,
  });

  // 서버 응답 구조에 맞게 JSON 파싱 수정
  factory Letter.fromJson(Map<String, dynamic> json) {
    return Letter(
      id: json['letterId'] ?? json['id'], // 서버에서는 letterId 사용
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      replyContent: json['replyContent'], // 서버에서 직접 제공
      deliveryStatus: json['deliveryStatus'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'replyContent': replyContent,
      'deliveryStatus': deliveryStatus,
    };
  }

  // 답장 도착 여부 확인 - deliveryStatus 기반으로 판단
  bool get isArrived {
    return deliveryStatus == 'DELIVERED' && replyContent != null && replyContent!.isNotEmpty;
  }

  // 날짜 포맷팅
  String get formattedDate {
    return DateFormat('yyyy.MM.dd').format(createdAt);
  }

  // copyWith 메서드 수정
  Letter copyWith({
    String? id,
    String? title,
    String? content,
    DateTime? createdAt,
    String? replyContent,
    String? deliveryStatus,
  }) {
    return Letter(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      replyContent: replyContent ?? this.replyContent,
      deliveryStatus: deliveryStatus ?? this.deliveryStatus,
    );
  }
}