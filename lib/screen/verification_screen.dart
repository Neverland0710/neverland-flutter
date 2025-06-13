import 'package:flutter/material.dart';

class VerificationScreen extends StatefulWidget {
  const VerificationScreen({super.key});

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  final TextEditingController _codeController = TextEditingController();
  bool _isInvalid = false;

  void _validateCode() {
    FocusScope.of(context).unfocus(); // 키보드 닫기
    if (_codeController.text != "1234") {
      setState(() {
        _isInvalid = true;
      });
    } else {
      setState(() {
        _isInvalid = false;
      });
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    const backgroundColor = Color(0xFFFFFBE8);
    const buttonColor = Color(0xFFFFBE13);
    const errorColor = Color(0xFFF50000);
    const titleColor = Color(0xFFFFB32C);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 80),
              const Text(
                '인증코드를 입력해주세요',
                style: TextStyle(
                  fontFamily: 'pretendard',
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                  color: titleColor,
                ),
              ),
              const SizedBox(height: 40),
              Container(
                width: 272,
                height: 50,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 6,
                        spreadRadius: 0.5,
                        offset: Offset(0, 2),
                      )
                    ]
                ),
                child: TextField(
                  controller: _codeController,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: '발급 받은 코드를 입력해주세요',
                  ),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'pretendard',
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              if (_isInvalid)
                const Text(
                  '유효하지 않은 코드입니다',
                  style: TextStyle(
                    fontFamily: 'pretendard',
                    fontSize: 14,
                    color: errorColor,
                  ),
                ),
              const Spacer(),
              Center(
                child: SizedBox(
                  width: 295, // ✅ 피그마 기준으로 적당한 너비
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _validateCode,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: buttonColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 4,
                    ),
                    child: const Text(
                      '다음',
                      style: TextStyle(
                        fontFamily: 'pretendard',
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
