import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
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

    final enteredCode = _codeController.text.trim();

    try {
      final uri = Uri.parse('http://192.168.219.68:8086/auth/lookup?auth_code=$enteredCode');
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));

        print('🔑 인증 응답 데이터: $data');

        final authKeyId = data['authKeyId'];
        final userId = data['userId'];
        final deceasedId = data['deceasedId'];

        print('✅ authKeyId: $authKeyId');
        print('✅ userId: $userId');
        print('✅ deceasedId: $deceasedId');

        if (authKeyId != null && userId != null && deceasedId != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('authKeyId', authKeyId);
          await prefs.setString('user_id', userId);
          await prefs.setString('deceased_id', deceasedId);

          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const MainPage()),
          );
          return;
        }

      }

      // 실패: 인증 실패
      setState(() {
        _showError = true;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ 인증 요청 중 오류: $e');
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
                textAlignVertical: TextAlignVertical.center,
                decoration: const InputDecoration(
                  isCollapsed: true,
                  hintText: '발급 받은 코드를 입력해주세요',
                  hintStyle: TextStyle(
                    fontFamily: 'Pretendard',
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
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
            SizedBox(
              width: double.infinity,
              height: 60,
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
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
