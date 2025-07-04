// voice_state.dart
// 음성 통화 상태를 나타내는 열거형과 상태별 UI 텍스트 관련 유틸리티 클래스

/// 음성 통화 상태 열거형
enum VoiceState {
  idle,        // 대기 상태 (말하기 대기중)
  speaking,    // 사용자가 말하는 중
  listening,   // AI가 응답하는 중 (답변 듣는중)
  processing,  // Whisper STT 처리 중
  error,       // 에러 상태
}

/// 음성 상태에 따른 UI 표시 문자열 등을 제공하는 헬퍼 클래스
class VoiceStateHelper {
  /// 🔘 현재 상태에 따라 버튼에 표시할 텍스트 반환
  static String getButtonText(VoiceState state) {
    switch (state) {
      case VoiceState.idle:
        return '말하기';         // 기본 대기 상태
      case VoiceState.listening:
        return '답변 듣는중...'; // AI가 말하는 중
      case VoiceState.speaking:
        return '그만말하기';     // 유저가 말하는 중
      case VoiceState.processing:
        return '처리중...';      // STT 변환 중
      case VoiceState.error:
        return '다시 시도';      // 에러 발생
    }
  }

  /// 💬 말풍선에 들어갈 상태별 안내 메시지 반환
  static String getBubbleMessage(VoiceState state, bool hasStartedConversation) {
    if (!hasStartedConversation) {
      return '말하기 버튼을 누르고 말씀해주세요'; // 대화 시작 전 기본 메시지
    }

    switch (state) {
      case VoiceState.listening:
        return 'AI가 답변하고 있습니다\n잠시만 기다려주세요';
      case VoiceState.speaking:
        return '말씀이 끝나시면\n그만말하기를 눌러주세요';
      case VoiceState.processing:
        return '음성을 분석하고 있습니다\n잠시만 기다려주세요';
      case VoiceState.error:
        return '연결에 문제가 발생했습니다\n다시 시도해주세요';
      default:
        return '말하기 버튼을 누르고 말씀해주세요';
    }
  }

  /// ⏱️ 통화 시간을 "MM:SS" 형식으로 변환
  static String formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
