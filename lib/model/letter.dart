class Letter {
  final String title;         // 폰지 제목
  final String content;       // 폰지 내용
  final DateTime createdAt;   // 폰지 생성 시간
  final String? replyContent; // ✅ AI 답장 내용 (nullable)

  Letter({
    required this.title,
    required this.content,
    required this.createdAt,
    this.replyContent,        // ✅ 선택적 값
  });

  /// 하루 뒤 동작 유물 확인
  /// 📌 현재는 테스트용으로 3초 이후 동작 처리
  bool get isArrived {
    return DateTime.now().difference(createdAt).inSeconds >= 3;
  }

  // ✅ 실제 배포 시에는 아래처럼 24시간으로 바꾸면 됩
  // bool get isArrived {
  //   return DateTime.now().difference(createdAt).inHours >= 24;
  // }

  /// yyyy. MM. dd. 형식으로 날짜 표시
  String get formattedDate {
    return '${createdAt.year}. ${createdAt.month.toString().padLeft(2, '0')}. ${createdAt.day.toString().padLeft(2, '0')}';
  }

  /// ✅ 답장이 존재하는지 유물
  bool get hasReply => replyContent != null && replyContent!.isNotEmpty && isArrived;
}
