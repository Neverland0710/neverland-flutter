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

class _RealTimeChatPageState extends State<RealTimeChatPage> with WidgetsBindingObserver{
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
  String _relation = '...'; //API로 불러올 관계 텍스트
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    initializeDateFormatting('ko');
    _fetchRelation();

    // ✅ DB에서 메시지 불러오고 스크롤 이동까지 처리
    loadMessagesFromDB().then((_) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    });

    // 키보드가 올라오면 자동으로 스크롤
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        Future.delayed(const Duration(milliseconds: 300), () {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scrollToBottom();
          });
        });
      }
    });
  }
  double _prevBottomInset = 0;

  @override
  void didChangeMetrics() {
    final currentInset = MediaQuery.of(context).viewInsets.bottom;

    if (currentInset != _prevBottomInset) {
      _prevBottomInset = currentInset;

      Future.microtask(() {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted || !_scrollController.hasClients) return;

          if (currentInset > 0) {
            // 키보드 올라옴 → 부드럽게
            _scrollController.animateTo(
              _scrollController.position.minScrollExtent,
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeOut,
            );
          } else {
            // 키보드 내려감 → 즉시
            _scrollController.jumpTo(
              _scrollController.position.minScrollExtent,
            );
          }
        });
      });
    }
  }

  Future<void> loadMessagesFromDB() async {
    final prefs = await SharedPreferences.getInstance();
    final authKeyId = prefs.getString('authKeyId');

    if (authKeyId == null) {
      print("❌ auth_key_id 없음");
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('http://52.78.139.47:8086/chat/history?authKeyId=$authKeyId'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> history = jsonDecode(response.body);

        setState(() {
          _messages.clear();
          DateTime? lastDate; // ✅ 날짜 구분을 위한 기준 변수

          for (var msg in history) {
            final sentAt = DateTime.parse(msg['sentAt']);
            final dateLabel = DateFormat('y년 M월 d일', 'ko').format(sentAt);

            // ✅ 날짜가 바뀔 때마다 날짜 메시지 삽입
            if (lastDate == null ||
                lastDate.year != sentAt.year ||
                lastDate.month != sentAt.month ||
                lastDate.day != sentAt.day) {
              _messages.add({
                'type': 'date',
                'date': dateLabel,
              });
              lastDate = sentAt;
            }

            _messages.add({
              'type': 'message',
              'sender': msg['sender'] == 'USER' ? '나' : '상대방',
              'text': msg['message'],
              'time': DateFormat('a hh:mm', 'ko').format(sentAt),
            });
          }
        });

        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToBottom();
        });
      } else {
        print("❌ 대화 기록 불러오기 실패: ${response.statusCode}");
      }
    } catch (e) {
      print("❌ 대화 기록 요청 예외: $e");
    }
  }

  // Future<void> saveMessagesToPrefs() async {
  //   final prefs = await SharedPreferences.getInstance();
  //   final encoded = jsonEncode(_messages);
  //   await prefs.setString('chat_messages', encoded);
  // }

  /// 메시지 전송 함수
  /// 입력된 텍스트를 메시지 리스트에 추가하고 가짜 응답을 트리거
  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final now = DateTime.now();
    final formattedTime = DateFormat('a hh:mm', 'ko').format(now);

    // 1️⃣ 내 메시지 먼저 표시
    setState(() {
      _messages.add({
        "sender": "나",
        "text": text,
        "time": formattedTime,
      });
    });

    //await saveMessagesToPrefs();
    _messageController.clear();

    // 2️⃣ 메시지를 우선 렌더링할 수 있도록 프레임 기다리기
    await Future.delayed(const Duration(milliseconds: 50));

    // 3️⃣ 이제 타이핑 인디케이터 켜기
    if (mounted) {
      setState(() {
        _isTyping = true;
      });
    }

    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

    // 4️⃣ 서버 응답 요청
    _sendReplyToServer(text);
  }

  Future<void> _sendReplyToServer(String userMessage) async {
    final url = Uri.parse("http://52.78.139.47:8086/chat/ask");

    try {
      final prefs = await SharedPreferences.getInstance();
      final authKeyId = prefs.getString("authKeyId"); // ✅ 여기도 정확히
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
          "authKeyId": authKeyId,
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
          _isTyping = false; // ✅ 응답 도착 후 타이핑 인디케이터 해제
          _messages.add({
            "sender": "상대방",
            "text": replyText,
            "time": formattedTime,
          });
        });

        //await saveMessagesToPrefs();
        Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);

      } else {
        print("❌ 서버 응답 실패: ${response.statusCode}");
      }
    } catch (e) {
      print("❌ 예외 발생: $e");
      setState(() {
        _isTyping = false; // ✅ 예외 시에도 인디케이터 해제
      });
    }
  }


  Future<void> _fetchRelation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString("user_id");

      if (userId == null) {
        print("❌ userId 없음");
        return;
      }

      final url = Uri.parse("http://52.78.139.47:8086/chat/relation?userId=$userId");
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _relation = data['relation'] ?? '알 수 없음';
        });
      } else {
        print("❌ 관계 불러오기 실패: ${response.statusCode}");
      }
    } catch (e) {
      print("❌ 관계 요청 예외: $e");
    }
  }


  /// 채팅 목록을 맨 아래로 스크롤하는 함수
  /// 새 메시지가 추가되었을 때 자동으로 스크롤
  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.minScrollExtent,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
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
            child: Icon(icon, color: const Color(0xFFA688FA), size: 32),
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

    //await saveMessagesToPrefs(); // ✅ 저장

    Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: const Color(0xFFE9E8FC), // 흰색 배경

      // 상단 앱바 (상대방 이름과 뒤로가기 버튼)
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60), // 원하는 높이 지정
        child: AppBar(
          backgroundColor: const Color(0xFFD6C7FF),
          elevation: 0.5,
          automaticallyImplyLeading: false,
          titleSpacing: 0,
          leading: null,
          title: Padding(
            padding: const EdgeInsets.only(left: 5), // 좌측 여백
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center, // ✅ 세로 중앙 정렬
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left, color: Colors.white, size: 32),
                  onPressed: () => Navigator.pop(context, true),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 4), // 아이콘과 텍스트 간격
                Text(
                  _relation,
                  style: const TextStyle(color: Colors.white, fontSize: 20),
                ),
              ],
            ),
          ),
        ),
      ),



      body: SafeArea(
        child: Column(
          children: [
            // 채팅 메시지 목록 영역 (화면의 대부분을 차지)
            Expanded(
              child: ListView.builder(
                reverse: true,
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                // 메시지 개수 + 타이핑 인디케이터 (타이핑 중일 때만)
                itemCount: _messages.length + (_isTyping ? 1 : 0),
                itemBuilder: (context, index) {
                  // 1. 상대방이 타이핑 중일 때 맨 아래에 인디케이터 표시
                  if (_isTyping && index == 0) {
                    return Padding(
                      padding: const EdgeInsets.only(left: 12, bottom: 8),
                      child: Row(
                        children: const [
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

                  // 2. 실제 메시지 인덱스 (뒤에서부터 접근)
                  final reversedIndex = _messages.length - 1 - (index - (_isTyping ? 1 : 0));
                  final msg = _messages[reversedIndex];

                  // 3. 날짜 구분 메시지
                  if (msg['type'] == 'date') {
                    return Center(
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 10),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8E6FF),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          msg['date'],
                          style: const TextStyle(fontSize: 13, color: Colors.black54),
                        ),
                      ),
                    );
                  }

                  // 4. 일반 메시지 (텍스트 or 이미지)
                  final isMe = msg['sender'] == '나';
                  final isImage = msg['image_path'] != null;

                  return Align(
                    alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                    child: Column(
                      crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          padding: isImage ? EdgeInsets.zero : const EdgeInsets.fromLTRB(12, 12, 12, 12),
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.7,
                          ),
                          decoration: BoxDecoration(
                            color: isMe ? const Color(0xFFBB9DF7) : const Color(0xFFF2F2F2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: isImage
                              ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(
                              File(msg['image_path']),
                              width: 160,
                              height: 160,
                              fit: BoxFit.cover,
                            ),
                          )
                              : Text(
                            msg['text'] ?? '',
                            style: TextStyle(
                              fontSize: 14,
                              color: isMe ? Colors.white : Colors.black87,
                            ),
                          ),
                        ),
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
                        scrollPadding: EdgeInsets.zero,
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
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _focusNode.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}