class Letter {
  final String id;
  final String title;
  final String content;
  final DateTime createdAt;
  final String? replyContent;

  Letter({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    this.replyContent,
  });

  factory Letter.fromJson(Map<String, dynamic> json) {
    print('JSON 파싱: $json');
    return Letter(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toString()),
      replyContent: json['replyContent'] as String?,
    );
  }

  // 클라이언트에서 3초 후 도착으로 테스트 (실제 배포 시 24시간으로 변경)
  bool get isArrived {
    return DateTime.now().difference(createdAt).inSeconds >= 3;
  }

  // 실제 배포 시 사용
  // bool get isArrived {
  //   return DateTime.now().difference(createdAt).inHours >= 24;
  // }

  String get formattedDate {
    return '${createdAt.year}. ${createdAt.month.toString().padLeft(2, '0')}. ${createdAt.day.toString().padLeft(2, '0')}';
  }

  bool get hasReply => replyContent != null && replyContent!.isNotEmpty && isArrived;
}