import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
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

class _RealTimeChatPageState extends State<RealTimeChatPage> with WidgetsBindingObserver {
  // 메시지 입력 필드를 제어하는 컨트롤러
  final TextEditingController _messageController = TextEditingController();

  // 채팅 목록의 스크롤을 제어하는 컨트롤러
  final ScrollController _scrollController = ScrollController();

  // 메시지 입력 필드의 포커스를 제어하는 노드
  final FocusNode _focusNode = FocusNode();

  // 채팅 메시지들을 저장하는 리스트 (Map 형태로 sender, text/image, time 정보 포함)
  final List<Map<String, dynamic>> _messages = [];
  int _currentPage = 0;
  final int _pageSize = 30;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  bool _isInitialLoading = true; // 초기 로딩 상태 추가

  // 상대방이 타이핑 중인지를 나타내는 상태 변수
  bool _isTyping = false;
  String _relation = '...'; //API로 불러올 관계 텍스트
  double _prevBottomInset = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    initializeDateFormatting('ko');
    _fetchRelation();

    // ✅ 초기 메시지 로딩
    _loadInitialMessages();

    // 키보드 포커스 리스너
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        // 키보드가 올라올 때 확실히 스크롤
        Future.delayed(const Duration(milliseconds: 150), () {
          _forceScrollToBottom();
        });
      }
    });

    // 스크롤 리스너 (상단 도달 시 이전 메시지 로드)
    _scrollController.addListener(() {
      // 스크롤이 위쪽으로 향하고 있을 때만 체크
      if (_scrollController.position.userScrollDirection == ScrollDirection.forward) {
        // 상단에서 충분히 멀리 떨어진 지점에서 미리 로드 시작
        final threshold = _scrollController.position.maxScrollExtent * 0.2; // 전체 높이의 20% 지점

        if (_scrollController.offset <= threshold &&
            !_isLoadingMore &&
            _hasMore &&
            !_isInitialLoading) {
          loadMessagesFromDB(append: true);
        }
      }
    });
  }

  // 초기 메시지 로딩 함수
  Future<void> _loadInitialMessages() async {
    setState(() {
      _isInitialLoading = true;
    });

    await loadMessagesFromDB(append: false);

    setState(() {
      _isInitialLoading = false;
    });

    // 초기 로딩 완료 후 확실히 최하단으로 이동
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _forceScrollToBottom();
    });
  }

  // 강제로 최하단 스크롤 (확실하게 여러 번 시도)
  Future<void> _forceScrollToBottom() async {
    if (!mounted || !_scrollController.hasClients) return;

    // 첫 번째 시도
    _scrollController.jumpTo(_scrollController.position.maxScrollExtent);

    // 50ms 후 두 번째 시도
    await Future.delayed(const Duration(milliseconds: 50));
    if (mounted && _scrollController.hasClients) {
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    }

    // 100ms 후 세 번째 시도
    await Future.delayed(const Duration(milliseconds: 50));
    if (mounted && _scrollController.hasClients) {
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    }

    // 150ms 후 네 번째 시도
    await Future.delayed(const Duration(milliseconds: 50));
    if (mounted && _scrollController.hasClients) {
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    }

    // 마지막으로 200ms 후 다섯 번째 시도
    await Future.delayed(const Duration(milliseconds: 50));
    if (mounted && _scrollController.hasClients) {
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    }
  }

  @override
  void didChangeMetrics() {
    final currentInset = MediaQuery.of(context).viewInsets.bottom;

    if (currentInset != _prevBottomInset) {
      final isKeyboardOpening = currentInset > _prevBottomInset;
      _prevBottomInset = currentInset;

      if (isKeyboardOpening) {
        // 키보드가 열릴 때 - 확실히 최하단으로
        Future.delayed(const Duration(milliseconds: 100), () {
          _forceScrollToBottom();
        });
      }
    }
  }

  Future<void> loadMessagesFromDB({bool append = false}) async {
    if (_isLoadingMore || !_hasMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    final prefs = await SharedPreferences.getInstance();
    final authKeyId = prefs.getString('authKeyId');
    if (authKeyId == null) {
      setState(() {
        _isLoadingMore = false;
      });
      return;
    }

    try {
      final url = Uri.parse('http://52.78.139.47:8086/chat/history?authKeyId=$authKeyId&page=$_currentPage&size=$_pageSize');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> history = jsonDecode(response.body);
        if (history.length < _pageSize) {
          setState(() {
            _hasMore = false;
          });
        }

        // 스크롤 위치 보존을 위한 현재 메시지 개수 저장
        int previousMessageCount = 0;
        if (append) {
          previousMessageCount = _messages.length;
        }

        // 날짜순 정렬
        history.sort((a, b) => DateTime.parse(a['sentAt']).compareTo(DateTime.parse(b['sentAt'])));

        List<Map<String, dynamic>> newMessages = [];
        final Set<String> addedDates = {};

        // 기존 메시지에서 이미 있는 날짜들을 체크
        if (append) {
          for (var msg in _messages) {
            if (msg['type'] == 'date') {
              addedDates.add(msg['date']);
            }
          }
        }

        for (var msg in history) {
          final sentAt = DateTime.parse(msg['sentAt']);
          final dateLabel = DateFormat('y년 M월 d일', 'ko').format(sentAt);

          // 날짜 구분선 추가 (중복 방지)
          if (!addedDates.contains(dateLabel)) {
            newMessages.add({'type': 'date', 'date': dateLabel});
            addedDates.add(dateLabel);
          }

          newMessages.add({
            'type': 'message',
            'sender': msg['sender'] == 'USER' ? '나' : '상대방',
            'text': msg['message'],
            'time': DateFormat('a hh:mm', 'ko').format(sentAt),
            'datetime': sentAt.toIso8601String(),
          });
        }

        setState(() {
          if (append) {
            // 상단에 추가 (과거 메시지)
            _messages.insertAll(0, newMessages);
          } else {
            // 전체 교체 (초기 로딩)
            _messages.clear();
            _messages.addAll(newMessages);
          }
          _currentPage++;
        });

        // 초기 로딩일 때는 추가적인 스크롤 보장
        if (!append) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _forceScrollToBottom();
          });
        }

        // 스크롤 위치 복원 (append 시에만)
        if (append && _scrollController.hasClients) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_scrollController.hasClients && mounted) {
              // 새로 추가된 메시지 개수만큼 스크롤 위치 조정
              final newMessageCount = _messages.length - previousMessageCount;
              final estimatedItemHeight = 80.0; // 메시지 아이템 평균 높이
              final scrollOffset = newMessageCount * estimatedItemHeight;

              final targetOffset = _scrollController.offset + scrollOffset;
              _scrollController.jumpTo(targetOffset.clamp(
                _scrollController.position.minScrollExtent,
                _scrollController.position.maxScrollExtent,
              ));
            }
          });
        }
      } else {
        print("❌ 대화 기록 실패: ${response.statusCode}");
      }
    } catch (e) {
      print("❌ 예외: $e");
    } finally {
      setState(() {
        _isLoadingMore = false;
      });
    }
  }

  /// 메시지 전송 함수
  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final now = DateTime.now();
    final formattedTime = DateFormat('a hh:mm', 'ko').format(now);

    // 1️⃣ 내 메시지 먼저 표시
    setState(() {
      _messages.add({
        "type": "message",
        "sender": "나",
        "text": text,
        "time": formattedTime,
      });
    });

    _messageController.clear();

    // 2️⃣ 메시지 추가 후 확실히 스크롤
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _forceScrollToBottom();
    });

    // 3️⃣ 타이핑 인디케이터 표시
    await Future.delayed(const Duration(milliseconds: 100));
    if (mounted) {
      setState(() {
        _isTyping = true;
      });
      // 타이핑 인디케이터 표시 후 확실히 스크롤
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _forceScrollToBottom();
      });
    }

    // 4️⃣ 서버 응답 요청
    _sendReplyToServer(text);
  }

  Future<void> _sendReplyToServer(String userMessage) async {
    final url = Uri.parse("http://52.78.139.47:8086/chat/ask");

    try {
      final prefs = await SharedPreferences.getInstance();
      final authKeyId = prefs.getString("authKeyId");
      final userId = prefs.getString("user_id");

      if (authKeyId == null || userId == null) {
        print("❌ SharedPreferences에 authKeyId 또는 userId 없음");
        setState(() {
          _isTyping = false;
        });
        return;
      }

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
        final replyJson = jsonDecode(response.body);
        final replyText = replyJson['response'] ?? '';

        final now = DateTime.now();
        final formattedTime = DateFormat('a hh:mm', 'ko').format(now);

        setState(() {
          _isTyping = false;
          _messages.add({
            "type": "message",
            "sender": "상대방",
            "text": replyText,
            "time": formattedTime,
          });
        });

        // 응답 메시지 추가 후 확실히 스크롤 (여러 번 시도)
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _forceScrollToBottom();
        });

      } else {
        print("❌ 서버 응답 실패: ${response.statusCode}");
        setState(() {
          _isTyping = false;
        });
      }
    } catch (e) {
      print("❌ 예외 발생: $e");
      setState(() {
        _isTyping = false;
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
  void _scrollToBottom({bool animate = true}) {
    if (!_scrollController.hasClients) return;

    final maxScrollExtent = _scrollController.position.maxScrollExtent;

    if (animate) {
      _scrollController.animateTo(
        maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
      );
    } else {
      _scrollController.jumpTo(maxScrollExtent);
    }
  }

  /// 미디어 옵션 (카메라/갤러리) 선택 바텀시트를 표시하는 함수
  void _showMediaOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(32, 24, 32, 40),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _mediaOption(Icons.camera_alt, '카메라', _pickFromCamera),
                _mediaOption(Icons.photo, '사진', _pickFromGallery),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _mediaOption(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFFFFFFFF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFFA688FA), size: 32),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  Future<void> _pickFromCamera() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      _addImageMessage(File(pickedFile.path));
    }
  }

  Future<void> _pickFromGallery() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      _addImageMessage(File(pickedFile.path));
    }
  }

  void _addImageMessage(File image) async {
    final now = DateTime.now();
    final formattedTime = DateFormat('a hh:mm', 'ko').format(now);

    setState(() {
      _messages.add({
        "type": "message",
        "sender": "나",
        "image_path": image.path,
        "time": formattedTime,
      });
    });

    // 이미지 메시지 추가 후 확실히 스크롤
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _forceScrollToBottom();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: const Color(0xFFE9E8FC),

      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: AppBar(
          backgroundColor: const Color(0xFFD6C7FF),
          elevation: 0.5,
          automaticallyImplyLeading: false,
          titleSpacing: 0,
          leading: null,
          title: Padding(
            padding: const EdgeInsets.only(left: 5),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left, color: Colors.white, size: 32),
                  onPressed: () => Navigator.pop(context, true),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 4),
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
            // 채팅 메시지 목록 영역
            Expanded(
              child: _isInitialLoading
                  ? const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFFBB9DF7),
                ),
              )
                  : _messages.isEmpty
                  ? const Center(
                child: Text(
                  '대화를 시작해보세요',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 16,
                  ),
                ),
              )
                  : Stack(
                children: [
                  ListView.builder(
                    controller: _scrollController,
                    reverse: false,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                    itemCount: _messages.length + (_isTyping ? 1 : 0),
                    itemBuilder: (context, index) {
                      // 타이핑 인디케이터
                      if (_isTyping && index == _messages.length) {
                        return Padding(
                          padding: const EdgeInsets.only(left: 12, bottom: 8, top: 8),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF2F2F2),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      '입력 중...',
                                      style: TextStyle(fontSize: 12, color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      if (index >= _messages.length) return const SizedBox.shrink();

                      final msg = _messages[index];

                      // 날짜 구분 메시지
                      if (msg['type'] == 'date') {
                        return Container(
                          margin: const EdgeInsets.symmetric(vertical: 10),
                          child: Center(
                            child: Container(
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
                          ),
                        );
                      }

                      // 일반 메시지
                      final isMe = msg['sender'] == '나';
                      final isImage = msg['image_path'] != null;

                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 3),
                        child: Align(
                          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                          child: Column(
                            crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                            children: [
                              Container(
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
                              const SizedBox(height: 2),
                              Text(
                                msg['time'] ?? '',
                                style: const TextStyle(fontSize: 11, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  // 상단 로딩 인디케이터 (Positioned로 오버레이)
                  if (_isLoadingMore && _hasMore)
                    Positioned(
                      top: 10,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 30,
                        child: const Center(
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFFBB9DF7),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // 구분선
            const Divider(height: 1),

            // 하단 메시지 입력 영역
            Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
              color: Colors.white,
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.add, color: Colors.grey),
                    onPressed: _showMediaOptions,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF4F4F4),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: TextField(
                        controller: _messageController,
                        focusNode: _focusNode,
                        maxLines: null,
                        keyboardType: TextInputType.multiline,
                        textInputAction: TextInputAction.send,
                        decoration: const InputDecoration(
                          hintText: '메시지를 입력해주세요',
                          border: InputBorder.none,
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Icons.send_rounded,
                        color: Color(0xFFBB9DF7), size: 26),
                    onPressed: _sendMessage,
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