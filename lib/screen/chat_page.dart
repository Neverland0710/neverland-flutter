import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class RealTimeChatPage extends StatefulWidget {
  const RealTimeChatPage({super.key});

  @override
  State<RealTimeChatPage> createState() => _RealTimeChatPageState();
}

class _RealTimeChatPageState extends State<RealTimeChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> _messages = [];

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('ko');
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  // 메시지 전송 함수
  void _sendMessage() {
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

    _messageController.clear();
    Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
  }

  // 리스트뷰 최하단으로 스크롤
  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 80,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  // 미디어 선택 옵션 모달 표시
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

  // 모달 내 옵션 버튼 UI
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
              color: const Color(0xFFE5EEF7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFFBB9DF7), size: 32),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  // 카메라 이미지 선택
  Future<void> _pickFromCamera() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      _addImageMessage(File(pickedFile.path));
    }
  }

  // 갤러리 이미지 선택
  Future<void> _pickFromGallery() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      _addImageMessage(File(pickedFile.path));
    }
  }

  // 이미지 메시지 추가
  void _addImageMessage(File image) {
    final now = DateTime.now();
    final formattedTime = DateFormat('a hh:mm', 'ko').format(now);

    setState(() {
      _messages.add({
        "sender": "나",
        "image": image,
        "time": formattedTime,
      });
    });

    Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('동연', style: TextStyle(color: Colors.black)),
        leading: const BackButton(color: Colors.black),
        elevation: 0.5,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 채팅 리스트
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  final isMe = msg['sender'] == '나';

                  return Align(
                    alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                    child: Column(
                      crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.all(4),
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.7,
                          ),
                          decoration: BoxDecoration(
                            color: isMe ? const Color(0xFFBB9DF7) : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: msg['image'] != null
                              ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(
                              msg['image'],
                              width: 200,
                              height: 200,
                              fit: BoxFit.cover,
                            ),
                          )
                              : Text(
                            msg['text'] ?? '',
                            style: const TextStyle(
                              fontFamily: 'Pretendard',
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        Text(
                          msg['time'] ?? '',
                          style: const TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // 메시지 입력창
            const Divider(height: 1),
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
                    icon: const Icon(Icons.send, color: Color(0xFFBB9DF7)),
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
}
