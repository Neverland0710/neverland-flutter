// conversation_model.dart
// 대화 관련 데이터 모델과 관리 클래스

class ConversationMessage {
  final String type;        // 'user' 또는 'ai'
  final String message;     // 메시지 내용
  final DateTime timestamp; // 메시지 시간

  ConversationMessage({
    required this.type,
    required this.message,
    required this.timestamp,
  });

  bool get isUser => type == 'user';
  bool get isAI => type == 'ai';

  // JSON 변환
  Map<String, dynamic> toJson() => {
    'type': type,
    'message': message,
    'timestamp': timestamp.toIso8601String(),
  };

  factory ConversationMessage.fromJson(Map<String, dynamic> json) => ConversationMessage(
    type: json['type'],
    message: json['message'],
    timestamp: DateTime.parse(json['timestamp']),
  );
}

class ConversationManager {
  final List<ConversationMessage> _conversations = [];

  List<ConversationMessage> get conversations => List.unmodifiable(_conversations);
  bool get hasMessages => _conversations.isNotEmpty;
  int get messageCount => _conversations.length;

  // 사용자 메시지 추가
  void addUserMessage(String message) {
    _conversations.add(ConversationMessage(
      type: 'user',
      message: message,
      timestamp: DateTime.now(),
    ));
  }

  // AI 메시지 추가
  void addAIMessage(String message) {
    _conversations.add(ConversationMessage(
      type: 'ai',
      message: message,
      timestamp: DateTime.now(),
    ));
  }

  // 대화 기록 초기화
  void clear() {
    _conversations.clear();
  }

  // 최근 메시지 가져오기
  ConversationMessage? getLastMessage() {
    return _conversations.isNotEmpty ? _conversations.last : null;
  }

  // 사용자의 최근 메시지 가져오기
  ConversationMessage? getLastUserMessage() {
    for (int i = _conversations.length - 1; i >= 0; i--) {
      if (_conversations[i].isUser) {
        return _conversations[i];
      }
    }
    return null;
  }

  // AI의 최근 메시지 가져오기
  ConversationMessage? getLastAIMessage() {
    for (int i = _conversations.length - 1; i >= 0; i--) {
      if (_conversations[i].isAI) {
        return _conversations[i];
      }
    }
    return null;
  }
}