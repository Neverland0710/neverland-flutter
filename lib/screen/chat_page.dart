import 'package:flutter/material.dart';
import 'package:intl/intl.dart';                 // 날짜/시간 포맷팅을 위한 패키지
import 'package:intl/date_symbol_data_local.dart'; // 한국어 날짜 포맷을 위한 로케일 데이터
import 'package:image_picker/image_picker.dart';   // 카메라/갤러리에서 이미지 선택을 위한 패키지
import 'dart:io';                                  // File 클래스 사용을 위한 dart:io
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// 실시간 채팅 화면을 담당하는 StatefulWidget
/// 텍스트 메시지와 이미지 전송, 가짜 응답 등의 기능을 제공
class RealTimeChatPage extends StatefulWidget {
  const RealTimeChatPage({super.key});

  @override
  State<RealTimeChatPage> createState() => _RealTimeChatPageState();
}

class _RealTimeChatPageState extends State<RealTimeChatPage> {
  // 메시지 입력 필드를 제어하는 컨트롤러
  final TextEditingController _messageController = TextEditingController();

  // 채팅 목록의 스크롤을 제어하는 컨트롤러
  final ScrollController _scrollController = ScrollController();

  // 메시지 입력 필드의 포커스를 제어하는 노드
  final FocusNode _focusNode = FocusNode();

  // 채팅 메시지들을 저장하는 리스트 (Map 형태로 sender, text/image, time 정보 포함)
  final List<Map<String, dynamic>> _messages = [];

  // 상대방이 타이핑 중인지를 나타내는 상태 변수
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();

    // ✅ 저장된 채팅 불러오기
    loadMessagesFromPrefs(); // 🔥 이 줄 추가

    // 한국어 날짜 포맷 초기화 (오전/오후 표시를 위해)
    initializeDateFormatting('ko');

    // 위젯이 완전히 빌드된 후 채팅 목록을 맨 아래로 스크롤
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

    // 포커스 상태 변화를 감지하여 UI 업데이트 (키보드 올라올 때 등)
    _focusNode.addListener(() {
      setState(() {});
    });
  }

  Future<void> loadMessagesFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = prefs.getString('chat_messages');
    if (encoded != null) {
      final List<dynamic> decoded = jsonDecode(encoded);
      setState(() {
        _messages.clear(); // 기존 메시지 초기화
        for (var msg in decoded) {
          if (msg is Map<String, dynamic>) {
            // ✅ image_path가 있으면 image로 File 객체 복원
            if (msg.containsKey('image_path')) {
              msg['image'] = File(msg['image_path']);
            }
            _messages.add(msg);
          }
        }
      });
    }
  }

  Future<void> saveMessagesToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(_messages);
    await prefs.setString('chat_messages', encoded);
  }


  /// 메시지 전송 함수
  /// 입력된 텍스트를 메시지 리스트에 추가하고 가짜 응답을 트리거
  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final now = DateTime.now();
    final formattedTime = DateFormat('a hh:mm', 'ko').format(now);

    setState(() {
      _messages.add({
        "sender": "나",
        "text": text,
        "time": formattedTime,
      });
    });

    await saveMessagesToPrefs(); // ✅ 여기에 추가

    _messageController.clear();
    Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);

    _sendReplyToServer(text); // ✅ 실제 서버 전송
  }

  Future<void> _sendReplyToServer(String userMessage) async {
    final url = Uri.parse("http://192.168.219.68:8086/chat/ask");

    try {
      final prefs = await SharedPreferences.getInstance();
      final authKeyId = prefs.getString("auth_key_id"); // ✅ 여기도 정확히
      final userId = prefs.getString("user_id");

      if (authKeyId == null || userId == null) {
        print("❌ SharedPreferences에 authKeyId 또는 userId 없음");
        return;
      }

      print('✅ SharedPreferences 불러오기 완료: $authKeyId / $userId');

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "auth_key_id": authKeyId,
          "user_id": userId,
          "user_input": userMessage,
        }),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        print("📥 서버 응답 바디: ${response.body}");
        final replyJson = jsonDecode(response.body);
        final replyText = replyJson['response'] ?? '';

        final now = DateTime.now();
        final formattedTime = DateFormat('a hh:mm', 'ko').format(now);

        setState(() {
          _messages.add({
            "sender": "상대방",
            "text": replyText,
            "time": formattedTime,
          });
        });

        await saveMessagesToPrefs(); // ✅ 이 줄 추가

        Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
      } else {
        print("❌ 서버 응답 실패: ${response.statusCode}");
      }
    } catch (e) {
      print("❌ 예외 발생: $e");
    }
  }

  /// 상대방의 가짜 응답 메시지를 생성하는 함수
  /// 실제 채팅 앱처럼 타이핑 인디케이터를 보여준 후 응답
  void _sendFakeReply() {
    // 미리 정의된 응답 메시지들
    final responses = [
      "응, 알겠어!",
      "좋아~",
      "지금 확인해볼게.",
      "ㅎㅎ 고마워~",
      "알았어!",
    ];

    // 응답 리스트를 섞어서 랜덤한 응답 선택
    final reply = (responses..shuffle()).first;

    // 타이핑 인디케이터 표시 시작
    setState(() {
      _isTyping = true;
    });

    // 3초 후 실제 응답 메시지 표시
    Future.delayed(const Duration(seconds: 3), () {
      final now = DateTime.now();
      final formattedTime = DateFormat('a hh:mm', 'ko').format(now);

      setState(() {
        _isTyping = false; // 타이핑 인디케이터 숨김
        _messages.add({
          "sender": "상대방",
          "text": reply,
          "time": formattedTime,
        });
      });

      // 새 메시지 추가 후 스크롤을 맨 아래로 이동
      Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
    });
  }

  /// 채팅 목록을 맨 아래로 스크롤하는 함수
  /// 새 메시지가 추가되었을 때 자동으로 스크롤
  void _scrollToBottom() {
    if (_scrollController.hasClients) { // 스크롤 컨트롤러가 연결되어 있는지 확인
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 80, // 최대 스크롤 위치 + 여유 공간
        duration: const Duration(milliseconds: 300),     // 애니메이션 지속 시간
        curve: Curves.easeOut,                           // 애니메이션 곡선
      );
    }
  }

  /// 미디어 옵션 (카메라/갤러리) 선택 바텀시트를 표시하는 함수
  void _showMediaOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      // 상단 모서리를 둥글게 처리
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(32, 24, 32, 40),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly, // 균등 배치
              children: [
                // 카메라 옵션
                _mediaOption(Icons.camera_alt, '카메라', _pickFromCamera),
                // 갤러리 옵션
                _mediaOption(Icons.photo, '사진', _pickFromGallery),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 미디어 옵션 버튼을 생성하는 위젯
  /// 아이콘, 라벨, 탭 이벤트를 받아서 버튼 형태로 구성
  Widget _mediaOption(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context); // 바텀시트 닫기
        onTap();               // 전달받은 콜백 함수 실행
      },
      child: Column(
        mainAxisSize: MainAxisSize.min, // 최소 크기로 설정
        children: [
          // 아이콘을 담는 둥근 컨테이너
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFFFFFFFF), // 연한 파란색 배경
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFFBB9DF7), size: 32),
          ),
          const SizedBox(height: 8),
          // 옵션 라벨 텍스트
          Text(label, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  /// 카메라에서 사진을 선택하는 함수
  Future<void> _pickFromCamera() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      _addImageMessage(File(pickedFile.path)); // 선택된 이미지로 메시지 추가
    }
  }

  /// 갤러리에서 사진을 선택하는 함수
  Future<void> _pickFromGallery() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      _addImageMessage(File(pickedFile.path)); // 선택된 이미지로 메시지 추가
    }
  }

  /// 이미지 메시지를 채팅에 추가하는 함수
  /// File 객체를 받아서 메시지 리스트에 이미지 메시지로 추가
  void _addImageMessage(File image) async {
    final now = DateTime.now();
    final formattedTime = DateFormat('a hh:mm', 'ko').format(now);

    setState(() {
      _messages.add({
        "sender": "나",
        "image_path": image.path, // 🔥 File 대신 경로만 저장
        "time": formattedTime,
      });
    });

    await saveMessagesToPrefs(); // ✅ 저장

    Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF), // 흰색 배경

      // 상단 앱바 (상대방 이름과 뒤로가기 버튼)
      appBar: AppBar(
        backgroundColor: const Color(0xFFD6C7FF), // 앱바 배경색
        leading: const BackButton(color: Colors.black), // 뒤로가기 버튼
        elevation: 0.5, // 약간의 그림자
      ),

      body: SafeArea(
        child: Column(
          children: [
            // 채팅 메시지 목록 영역 (화면의 대부분을 차지)
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                // 메시지 개수 + 타이핑 인디케이터 (타이핑 중일 때만)
                itemCount: _messages.length + (_isTyping ? 1 : 0),
                itemBuilder: (context, index) {
                  // 타이핑 인디케이터 표시 (가장 마지막 아이템이고 타이핑 중일 때)
                  if (_isTyping && index == _messages.length) {
                    return Padding(
                      padding: const EdgeInsets.only(left: 12, bottom: 8),
                      child: Row(
                        children: const [
                          // 작은 원형 아바타와 점점점 아이콘
                          CircleAvatar(
                            radius: 12,
                            backgroundColor: Color(0xFFE5EEF7),
                            child: Icon(Icons.more_horiz, size: 16, color: Colors.grey),
                          ),
                          SizedBox(width: 8),
                          Text(
                            '상대방이 입력 중...',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    );
                  }

                  // 실제 채팅 메시지 표시
                  final msg = _messages[index];
                  final isMe = msg['sender'] == '나'; // 내가 보낸 메시지인지 확인

                  return Align(
                    // 내 메시지는 오른쪽, 상대방 메시지는 왼쪽 정렬
                    alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                    child: Column(
                      // 시간 표시를 위한 정렬 (내 메시지는 오른쪽, 상대방은 왼쪽)
                      crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                      children: [
                        // 메시지 말풍선
                        Container(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          // 이미지 메시지는 패딩 없음, 텍스트 메시지는 패딩 추가
                          padding: msg['image'] != null
                              ? EdgeInsets.zero
                              : const EdgeInsets.fromLTRB(12, 12, 12, 12),
                          constraints: BoxConstraints(
                            // 메시지 최대 너비는 화면의 70%
                            maxWidth: MediaQuery.of(context).size.width * 0.7,
                          ),
                          decoration: BoxDecoration(
                            // 내 메시지는 보라색, 상대방 메시지는 회색
                            color: isMe ? const Color(0xFFBB9DF7) : const Color(0xFFF2F2F2),
                            borderRadius: BorderRadius.circular(16), // 둥근 모서리
                          ),
                          child: msg['image'] != null
                              ? // 이미지 메시지 표시
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(
                              msg['image'],
                              width: 160,
                              height: 160,
                              fit: BoxFit.cover, // 이미지를 컨테이너에 맞게 크롭
                            ),
                          )
                              : // 텍스트 메시지 표시
                          Text(
                            msg['text'] ?? '',
                            style: TextStyle(
                              fontFamily: 'Pretendard',
                              fontSize: 14,
                              // 내 메시지는 흰색, 상대방 메시지는 검은색
                              color: isMe ? Colors.white : Colors.black87,
                            ),
                          ),
                        ),
                        // 메시지 전송 시간 표시
                        Text(
                          msg['time'] ?? '',
                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // 구분선
            const Divider(height: 1),

            // 하단 메시지 입력 영역
            Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
              color: Colors.white, // 입력 영역 배경색
              child: Row(
                children: [
                  // 미디어 추가 버튼 (+ 아이콘)
                  IconButton(
                    icon: const Icon(Icons.add, color: Colors.grey),
                    onPressed: _showMediaOptions, // 미디어 옵션 바텀시트 표시
                  ),
                  const SizedBox(width: 4),

                  // 메시지 입력 필드 (확장 가능)
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF4F4F4), // 입력 필드 배경색
                        borderRadius: BorderRadius.circular(20), // 둥근 모서리
                      ),
                      child: TextField(
                        controller: _messageController,
                        focusNode: _focusNode,
                        decoration: const InputDecoration(
                          hintText: '메시지를 입력해주세요',
                          border: InputBorder.none, // 테두리 제거
                        ),
                        onSubmitted: (_) => _sendMessage(), // 엔터키로 메시지 전송
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),

                  // 메시지 전송 버튼
                  IconButton(
                    icon: const Icon(Icons.send_rounded,
                        color: Color(0xFFBB9DF7), size: 26),
                    onPressed: _sendMessage, // 메시지 전송 함수 호출
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