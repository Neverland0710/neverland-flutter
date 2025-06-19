import 'package:flutter/material.dart';
import 'package:neverland_flutter/screen/main_page.dart';

class CodeInputScreen extends StatefulWidget {
  const CodeInputScreen({super.key});

  @override
  State<CodeInputScreen> createState() => _CodeInputScreenState();
}

class _CodeInputScreenState extends State<CodeInputScreen> {
  final TextEditingController _codeController = TextEditingController();
  bool _showError = false;
  bool _isLoading = false;

  void _validateCode() async {
    setState(() {
      _isLoading = true;
      _showError = false;
    });

    await Future.delayed(const Duration(seconds: 2)); // 1초 로딩 효과

    if (_codeController.text.trim() == '123456') {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainPage()),
      );
    } else {
      setState(() {
        _showError = true;
        _isLoading = false;
      });
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFFFFF),
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
                enabled: !_isLoading,
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
              height: 60,
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator()) // ✅ 로딩 중이면 로딩바
                  : ElevatedButton(
                onPressed: _validateCode,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFBB9DF7),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  '다음',
                  style: TextStyle(
                    fontFamily: 'Pretendard',
                    fontSize: 18,
                    color: Colors.white,
                      fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}
