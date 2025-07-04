// voice_ui_widgets.dart
// 음성 통화 화면의 UI 위젯들을 관리하는 파일
// 재사용 가능한 컴포넌트들로 구성되어 있음

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter/widgets.dart' as widgets;
import 'voice_state.dart';
import 'conversation_model.dart';

// ================================
// 상단 사용자 정보 헤더 위젯
// ================================
/// 화면 상단에 표시되는 사용자 정보와 통화 상태를 보여주는 위젯
/// - 사용자 프로필 아바타 (상태에 따라 테두리 색상 변경)
/// - 사용자 이름
/// - 연결 상태 인디케이터
/// - 통화 지속 시간
class UserInfoHeader extends StatelessWidget {
  final VoiceState voiceState;    // 현재 음성 상태
  final Duration callDuration;    // 통화 지속 시간
  final bool whisperEnabled;      // Whisper 서비스 활성화 여부

  const UserInfoHeader({
    super.key,
    required this.voiceState,
    required this.callDuration,
    required this.whisperEnabled,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(top: 24, left: 24, right: 24),
        child: Row(
          children: [
            // 사용자 프로필 아바타 (상태에 따른 테두리 색상 변경)
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  // 상태에 따라 테두리 색상 결정
                  color: voiceState == VoiceState.speaking
                      ? Colors.red.withOpacity(0.8)        // 말하는 중: 빨간색
                      : voiceState == VoiceState.listening
                      ? Colors.green.withOpacity(0.8)      // 듣는 중: 초록색
                      : voiceState == VoiceState.processing
                      ? Colors.orange.withOpacity(0.8)     // 처리 중: 주황색
                      : Colors.transparent,                // 기본: 투명
                  width: 3,
                ),
              ),
              child: const CircleAvatar(
                radius: 24,
                backgroundColor: Color(0xFFBB9DF7),  // 보라색 배경
                child: Icon(
                  Icons.person,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ),
            const SizedBox(width: 12),

            // 사용자 정보 텍스트 영역
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 사용자 이름
                  const Text(
                    '정동연',
                    style: TextStyle(
                      fontFamily: 'pretendard',
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                      color: Colors.white,
                    ),
                  ),

                  // 연결 상태와 통화 시간
                  Row(
                    children: [
                      // 연결 상태 인디케이터 (작은 원형 점)
                      Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.only(right: 6),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          // 연결 상태에 따른 색상
                          color: voiceState == VoiceState.error
                              ? Colors.red      // 에러: 빨간색
                              : whisperEnabled
                              ? Colors.green    // 정상: 초록색
                              : Colors.orange,  // 연결 중: 주황색
                        ),
                      ),

                      // 통화 지속 시간 표시
                      Text(
                        VoiceStateHelper.formatDuration(callDuration),
                        style: const TextStyle(
                          fontFamily: 'pretendard',
                          fontSize: 14,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ================================
// 음성 상태별 시각화 위젯
// ================================
/// 현재 음성 상태에 따라 다른 시각적 표현을 보여주는 위젯
/// - 듣기 상태: Lottie 애니메이션
/// - 말하기 상태: 마이크 아이콘
/// - 처리 상태: 로딩 스피너
/// - 에러 상태: 에러 아이콘
class VoiceStateVisualization extends StatelessWidget {
  final VoiceState voiceState;        // 현재 음성 상태
  final String currentSpeechText;     // 현재 인식된 텍스트

  const VoiceStateVisualization({
    super.key,
    required this.voiceState,
    required this.currentSpeechText,
  });

  @override
  Widget build(BuildContext context) {
    switch (voiceState) {
    // AI가 답변하는 중일 때
      case VoiceState.listening:
        return Column(
          children: [
            // 음성 파형 애니메이션
            SizedBox(
              width: 80,
              height: 80,
              child: Lottie.asset(
                'asset/animation/voice_wave.json',
                fit: BoxFit.contain,
                repeat: true,  // 반복 재생
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'AI가 답변하고 있습니다.',
              style: TextStyle(
                fontFamily: 'pretendard',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.blue,
              ),
            ),
          ],
        );

    // 사용자가 말하는 중일 때
      case VoiceState.speaking:
        return Column(
          children: [
            // 마이크 아이콘과 원형 배경
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.red.withOpacity(0.1),  // 반투명 빨간 배경
                border: Border.all(
                  color: Colors.red.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.mic,
                color: Colors.red,
                size: 40,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '음성을 녹음하고 있습니다.',
              style: TextStyle(
                fontFamily: 'pretendard',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.red,
              ),
            ),
          ],
        );

    // 음성을 텍스트로 변환 처리 중일 때
      case VoiceState.processing:
        return Column(
          children: [
            // 로딩 스피너
            const SizedBox(
              width: 80,
              height: 80,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Whisper AI가 음성을 분석중입니다.',
              style: TextStyle(
                fontFamily: 'pretendard',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.orange,
              ),
            ),

            // 인식된 텍스트가 있으면 미리보기 표시
            if (currentSpeechText.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  currentSpeechText,
                  style: const TextStyle(
                    fontFamily: 'pretendard',
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ],
        );

    // 에러 상태일 때
      case VoiceState.error:
        return Column(
          children: [
            // 에러 아이콘
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.red.withOpacity(0.1),
              ),
              child: const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 40,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '연결에 문제가 발생했습니다.',
              style: TextStyle(
                fontFamily: 'pretendard',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.red,
              ),
            ),
          ],
        );

    // 기본 상태 (아무것도 표시하지 않음)
      default:
        return const SizedBox.shrink();
    }
  }
}

// ================================
// 대화 내용 표시 위젯
// ================================
/// 대화 기록을 표시하는 위젯
/// - 대화가 시작되지 않았으면 환영 메시지 표시
/// - 대화 기록이 있으면 사용자/AI 메시지를 구분해서 표시
class ConversationContent extends StatelessWidget {
  final bool hasStartedConversation;              // 대화 시작 여부
  final List<ConversationMessage> conversations;  // 대화 기록 목록

  const ConversationContent({
    super.key,
    required this.hasStartedConversation,
    required this.conversations,
  });

  @override
  Widget build(BuildContext context) {
    // 대화가 시작되지 않았으면 환영 메시지 표시
    if (!hasStartedConversation) {
      return const Column(
        children: [
          Text(
            '안녕하세요! 😊',
            style: TextStyle(
              fontFamily: 'pretendard',
              fontWeight: FontWeight.w600,
              fontSize: 20,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 12),
          Text(
            '무엇을 도와드릴까요?\n\n(Whisper AI 사용)',
            style: TextStyle(
              fontFamily: 'pretendard',
              fontSize: 16,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

    // 대화 기록이 있으면 메시지들을 표시
    return Column(
      children: conversations.map((conversation) {
        final isUser = conversation.isUser;  // 사용자 메시지인지 확인

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            // 사용자 메시지는 오른쪽, AI 메시지는 왼쪽 정렬
            mainAxisAlignment: isUser
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            children: [
              // AI 메시지일 때 왼쪽에 아바타 표시
              if (!isUser) ...[
                CircleAvatar(
                  radius: 12,
                  backgroundColor: Colors.blue.shade100,
                  child: const Icon(
                    Icons.smart_toy,  // AI 아이콘
                    size: 16,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 8),
              ],

              // 메시지 말풍선
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    // 사용자 메시지는 파란색, AI 메시지는 회색
                    color: isUser
                        ? Colors.blue.shade500
                        : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Text(
                    conversation.message,
                    style: TextStyle(
                      fontFamily: 'pretendard',
                      fontSize: 14,
                      // 사용자 메시지는 흰색 글자, AI 메시지는 검은색 글자
                      color: isUser
                          ? Colors.white
                          : Colors.black87,
                    ),
                  ),
                ),
              ),

              // 사용자 메시지일 때 오른쪽에 아바타 표시
              if (isUser) ...[
                const SizedBox(width: 8),
                CircleAvatar(
                  radius: 12,
                  backgroundColor: Colors.purple.shade100,
                  child: const Icon(
                    Icons.person,  // 사용자 아이콘
                    size: 16,
                    color: Colors.purple,
                  ),
                ),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ================================
// 말풍선 위젯 (상태 메시지 표시)
// ================================
/// 화면 하단에 표시되는 말풍선 형태의 상태 메시지
/// 현재 상태에 따라 다른 안내 메시지를 표시
/// 말하는 중일 때는 숨김 처리
class SpeechBubble extends StatelessWidget {
  final VoiceState voiceState;              // 현재 음성 상태
  final bool hasStartedConversation;        // 대화 시작 여부

  const SpeechBubble({
    super.key,
    required this.voiceState,
    required this.hasStartedConversation,
  });

  @override
  Widget build(BuildContext context) {
    // 말하는 중일 때는 말풍선 숨김
    if (voiceState == VoiceState.speaking) {
      return const SizedBox.shrink();
    }

    return Positioned(
      bottom: 185,  // 하단에서 185px 위치
      left: 0,
      right: 45,    // 오른쪽에 45px 여백 (비대칭 디자인)
      child: Center(
        child: SizedBox(
          width: 360,
          height: 120,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // 말풍선 배경 이미지
              widgets.Image.asset(
                'asset/image/speech_bubble.png',
                fit: BoxFit.contain,
                width: 360,
              ),

              // 말풍선 내부 텍스트
              Positioned(
                top: 25,  // 말풍선 내부에서 위쪽 여백
                child: SizedBox(
                  width: 240,  // 텍스트 영역 너비
                  child: Text(
                    // 상태에 따른 메시지 표시
                    VoiceStateHelper.getBubbleMessage(voiceState, hasStartedConversation),
                    style: const TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ================================
// 하단 버튼들 컨테이너 위젯
// ================================
/// 화면 하단의 통화 종료 버튼과 말하기 버튼을 포함하는 위젯
class BottomButtons extends StatelessWidget {
  final VoiceState voiceState;                      // 현재 음성 상태
  final AnimationController recordController;       // 녹음 애니메이션 컨트롤러
  final AnimationController buttonScaleController;  // 버튼 스케일 애니메이션 컨트롤러
  final VoidCallback onCallEnd;                     // 통화 종료 콜백
  final VoidCallback onSpeakButtonPress;            // 말하기 버튼 콜백

  const BottomButtons({
    super.key,
    required this.voiceState,
    required this.recordController,
    required this.buttonScaleController,
    required this.onCallEnd,
    required this.onSpeakButtonPress,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 32,  // 화면 하단에서 32px 위치
      left: 0,
      right: 0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,  // 버튼들을 균등하게 배치
        children: [
          // 통화 종료 버튼
          CallEndButton(onPressed: onCallEnd),

          // 말하기 버튼 (메인 버튼)
          SpeakButton(
            voiceState: voiceState,
            recordController: recordController,
            buttonScaleController: buttonScaleController,
            onPressed: onSpeakButtonPress,
          ),
        ],
      ),
    );
  }
}

// ================================
// 통화 종료 버튼 위젯
// ================================
/// 빨간색 원형 버튼으로 통화를 종료하는 기능
class CallEndButton extends StatelessWidget {
  final VoidCallback onPressed;  // 버튼 클릭 시 실행할 함수

  const CallEndButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 버튼 터치 영역
        GestureDetector(
          onTap: onPressed,
          child: Container(
            width: 85,
            height: 85,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.red.withOpacity(0.2),    // 반투명 빨간 배경
              border: Border.all(
                color: Colors.red.withOpacity(0.3),  // 빨간 테두리
                width: 5,
              ),
            ),
            child: const Icon(
              Icons.call_end,  // 통화 종료 아이콘
              color: Colors.red,
              size: 36,
            ),
          ),
        ),
        const SizedBox(height: 10),

        // 버튼 설명 텍스트
        const Text(
          '통화 종료',
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'pretendard',
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ================================
// 말하기 버튼 위젯 (메인 버튼)
// ================================
/// 가장 중요한 버튼으로, 음성 녹음을 시작/중지하는 기능
/// 상태에 따라 애니메이션과 색상이 변경됨
class SpeakButton extends StatelessWidget {
  final VoiceState voiceState;                      // 현재 음성 상태
  final AnimationController recordController;       // 녹음 애니메이션 컨트롤러
  final AnimationController buttonScaleController;  // 버튼 스케일 애니메이션 컨트롤러
  final VoidCallback onPressed;                     // 버튼 클릭 시 실행할 함수

  const SpeakButton({
    super.key,
    required this.voiceState,
    required this.recordController,
    required this.buttonScaleController,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 버튼 크기 애니메이션 적용
        ScaleTransition(
          scale: Tween<double>(begin: 1.0, end: 0.95).animate(
            CurvedAnimation(
              parent: buttonScaleController,
              curve: Curves.easeInOut,
            ),
          ),
          child: GestureDetector(
            onTap: onPressed,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    // 상태에 따른 그림자 색상 변경
                    color: voiceState == VoiceState.speaking
                        ? Colors.red.withOpacity(0.3)      // 말하는 중: 빨간 그림자
                        : voiceState == VoiceState.listening
                        ? Colors.grey.withOpacity(0.3)     // 듣는 중: 회색 그림자
                        : voiceState == VoiceState.processing
                        ? Colors.orange.withOpacity(0.3)   // 처리 중: 주황 그림자
                        : Colors.blue.withOpacity(0.3),    // 기본: 파란 그림자
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Lottie.asset(
                'asset/animation/record_pulse.json',  // 녹음 펄스 애니메이션
                controller: recordController,
                fit: BoxFit.contain,
                repeat: false,  // 기본적으로 반복하지 않음
                onLoaded: (composition) {
                  // 애니메이션 로드 완료 시 설정
                  recordController.duration = composition.duration;
                  // 말하는 중일 때만 애니메이션 반복
                  if (voiceState == VoiceState.speaking) {
                    recordController.repeat();
                  }
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),

        // 버튼 설명 텍스트 (위치 조정)
        Transform.translate(
          offset: const Offset(0, -30),  // 텍스트를 위로 30px 이동
          child: Text(
            // 상태에 따른 버튼 텍스트 표시
            VoiceStateHelper.getButtonText(voiceState),
            style: TextStyle(
              // 상태에 따른 텍스트 색상 변경
              color: voiceState == VoiceState.listening || voiceState == VoiceState.processing
                  ? Colors.grey           // 비활성 상태: 회색
                  : voiceState == VoiceState.error
                  ? Colors.red.shade300   // 에러 상태: 연한 빨간색
                  : Colors.white,         // 활성 상태: 흰색
              fontFamily: 'pretendard',
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}