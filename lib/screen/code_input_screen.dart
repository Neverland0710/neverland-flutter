import 'package:flutter/material.dart';

class CodeInputScreen extends StatefulWidget {
  const CodeInputScreen({super.key});

  @override
  State<CodeInputScreen> createState() => _CodeInputScreenState();
}

class _CodeInputScreenState extends State<CodeInputScreen> {
  final TextEditingController _codeController = TextEditingController();
  bool _showError = false;

  void _validateCode() {
    if (_codeController.text.trim() == '123456') {
      // TODO: 다음 화면으로 이동
    } else {
      setState(() {
        _showError = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE9F0F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFFE9F0F9),
        elevation: 0,
        leading: const BackButton(color: Colors.black),
        title: const Text(
          '기억 연결 코드 입력',
          style: TextStyle(
            fontFamily: 'Pretendard',
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            const Text(
              '서비스의 원활한 이용을 위해\n발급된 인증코드를 입력해주세요',
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 40),

            // 인증 코드 입력 박스
            Container(
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: _showError ? Colors.red : const Color(0xFFD9D9D9),
                  width: 1.5,
                ),
              ),
              child: TextField(
                controller: _codeController,
                style: const TextStyle(
                  fontFamily: 'Pretendard',
                  fontSize: 14,
                ),
                textAlignVertical: TextAlignVertical.center, // ✅ 입력값 수직 가운데
                decoration: const InputDecoration(
                  isCollapsed: true,
                  hintText: '발급 받은 코드를 입력해주세요',
                  hintStyle: TextStyle(
                    fontFamily: 'Pretendard',
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 14), // ✅ 핵심
                ),
              ),
            ),

            if (_showError)
              const Padding(
                padding: EdgeInsets.only(top: 8.0),
                child: Text(
                  '입력하신 코드가 맞는지 다시 확인해 주세요',
                  style: TextStyle(
                    fontFamily: 'Pretendard',
                    fontSize: 13,
                    color: Colors.red,
                  ),
                ),
              ),

            const Spacer(),

            // 다음 버튼
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _validateCode,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7FA8D7),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  '다음',
                  style: TextStyle(
                    fontFamily: 'Pretendard',
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }
}
