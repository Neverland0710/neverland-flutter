class Letter {
  final String title;      // 편지 제목
  final String content;    // 편지 내용
  final DateTime createdAt; // 편지 생성 시각

  Letter({
    required this.title,
    required this.content,
    required this.createdAt,
  });

  /// 하루 뒤 도착 여부 확인
  /// 📌 현재는 테스트용으로 3초 이후 도착 처리
  bool get isArrived {
    return DateTime.now().difference(createdAt).inSeconds >= 3;
  }

  // ✅ 실제 배포 시에는 아래처럼 24시간으로 바꾸면 됨
  // bool get isArrived {
  //   return DateTime.now().difference(createdAt).inHours >= 24;
  // }

  /// yyyy. MM. dd. 형식으로 날짜 표시
  String get formattedDate {
    return '${createdAt.year}. ${createdAt.month.toString().padLeft(2, '0')}. ${createdAt.day.toString().padLeft(2, '0')}';
  }
}
