import 'package:flutter/material.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  // 채팅 입력창 제어용 텍스트 컨트롤러
  final TextEditingController _controller = TextEditingController();

  // 스크롤 제어용 컨트롤러
  final ScrollController _scrollController = ScrollController();

  // 채팅 메시지 데이터 리스트
  final List<Map<String, dynamic>> _messages = [
    {'from': '엄마', 'text': '점심은 뭐 먹었어??', 'time': '오전 9:27'},
    {'from': 'me', 'text': '오늘은 김치찌개 먹었어요', 'time': '오전 9:27'},
    {
      'from': '엄마',
      'text':
      '점심은 뭐 먹었어??1단계 - 당신은 초등학교 1학년 아이에게 설명하는 친절한 선생님입니다. 아래 문장을 아주 쉬운 말로 전체형으로 천천히 설명해주세요. 당신은 초등학교 2~3학년 아이에게 설명하는 친절한 선생님입니다. 갑니다!',
      'time': '오전 9:27'
    },
    {'from': 'me', 'text': '오늘은 김치찌개 먹었어요오오오옹>ㅇ<', 'time': '오전 9:27'},
    {'date': '5월 28일'},
    {'from': '엄마', 'text': '건더야 잘자??', 'time': '오전 9:27'},
  ];

  // 메시지 전송 시 호출되는 함수
  void _sendMessage() {
    if (_controller.text.trim().isEmpty) return;

    setState(() {
      _messages.add({
        'from': 'me',
        'text': _controller.text.trim(),
        'time': '오전 9:28',
      });
      _controller.clear(); // 입력창 비우기
    });

    _scrollToBottom(); // 메시지 추가 후 자동 스크롤
  }

  // 자동 스크롤 함수
  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    // 앱 컬러 정의
    const backgroundColor = Color(0xFFFFFBE8); // 전체 배경
    const userBubbleColor = Color(0xFFFFBE13); // 사용자 말풍선 색
    const dateTagColor = Color(0xFFF4C6D0);    // 날짜 태그 배경색

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text(
          '엄마',
          style: TextStyle(fontFamily: 'pretendard', fontWeight: FontWeight.bold),
        ),
        backgroundColor: backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () {}, // 햄버거 메뉴 (추후 기능 연결)
        ),
      ),
      body: Column(
        children: [
          // 채팅 리스트 영역
          Expanded(
            child: ListView.builder(
              controller: _scrollController, // ✅ 스크롤 컨트롤러 연결
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];

                // 날짜 태그 처리
                if (msg.containsKey('date')) {
                  return Center(
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: dateTagColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        msg['date'],
                        style: const TextStyle(fontFamily: 'pretendard', fontSize: 12),
                      ),
                    ),
                  );
                }

                final isMe = msg['from'] == 'me'; // 사용자 여부 확인

                // 말풍선 메시지 구성
                // 말풍선 메시지 구성
                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                    children: [
                      // 엄마일 경우 프로필 이미지 왼쪽
                      if (!isMe)
                        const CircleAvatar(
                          radius: 20,
                          backgroundImage: AssetImage('asset/img/mother_profile.png'),
                        ),

                      if (!isMe) const SizedBox(width: 10), // 엄마 말풍선과 프로필 사이 간격

                      // 말풍선 위치 및 여백 조절
                      Flexible(
                        child: Padding(
                          padding: EdgeInsets.only(
                            right: isMe ? 0 : 60, // 엄마일 경우 오른쪽 간격
                            left: isMe ? 60 : 0,  // 자녀일 경우 왼쪽 간격
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isMe ? userBubbleColor : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              msg['text'],
                              style: const TextStyle(fontFamily: 'pretendard', fontSize: 14),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );

              },
            ),
          ),

          const Divider(height: 1), // 입력창 상단 구분선

          // 메시지 입력창 영역
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 15, 16, 30), // 입력창 외부 여백 조정
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  // 이미지 등록 아이콘
                  IconButton(
                    onPressed: () {
                      // TODO: 이미지 업로드 기능 추가
                    },
                    icon: Image.asset(
                      'asset/icon/imges_icon.png',
                      width: 26,
                      height: 26,
                    ),
                  ),

                  // 텍스트 입력 필드
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: const InputDecoration(
                        hintText: '메시지를 입력해주세요',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 8),
                      ),
                    ),
                  ),

                  // 전송 아이콘
                  IconButton(
                    onPressed: _sendMessage,
                    icon: Image.asset(
                      'asset/icon/send_icon.png',
                      width: 26,
                      height: 26,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
