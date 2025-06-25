import 'package:flutter/material.dart';
import 'package:neverland_flutter/screen/code_input_screen.dart';

class TermsAgreementScreen extends StatefulWidget {
  const TermsAgreementScreen({super.key});

  @override
  State<TermsAgreementScreen> createState() => _TermsAgreementScreenState();
}

class _TermsAgreementScreenState extends State<TermsAgreementScreen> {
  bool allChecked = false;
  bool termsChecked = false;
  bool privacyChecked = false;
  bool marketingChecked = false;

  void _toggleAll(bool? value) {
    setState(() {
      allChecked = value ?? false;
      termsChecked = allChecked;
      privacyChecked = allChecked;
      marketingChecked = allChecked;
    });
  }

  void _updateAllCheckStatus() {
    setState(() {
      allChecked = termsChecked && privacyChecked && marketingChecked;
    });
  }

  void _showTermsDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: Text(content),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('닫기'),
          ),
        ],
      ),
    );
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
          '약관 동의',
          style: TextStyle(
            fontFamily: 'Pretendard',
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            const Text(
              '서비스의 원활한 이용을 위해\n약관에 동의해주세요',
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 32),

            CheckboxListTile(
              value: allChecked,
              onChanged: _toggleAll,
              title: const Text(
                '네, 모두 동의합니다.',
                style: TextStyle(
                  fontFamily: 'Pretendard',
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
            const Divider(),

            _buildAgreementItem(
              checked: termsChecked,
              onChanged: (val) {
                setState(() {
                  termsChecked = val!;
                  _updateAllCheckStatus();
                });
              },
              title: '서비스 이용약관 동의 (필수)',
              onViewPressed: () {
                _showTermsDialog(
                  '서비스 이용약관',
                  '''
제1조 (목적)
이 약관은 네버랜드(이하 '회사')가 제공하는 서비스 이용과 관련하여 회사와 회원 간의 권리, 의무 및 책임사항 등을 규정함을 목적으로 합니다.

제2조 (정의)
‘회원’이라 함은 본 약관에 동의하고 서비스를 이용하는 자를 의미합니다.

제3조 (약관의 효력 및 변경)
회사는 관련 법령을 위반하지 않는 범위에서 본 약관을 변경할 수 있으며, 변경 시 서비스 내에 공지합니다.
                  ''',
                );
              },
            ),

            _buildAgreementItem(
              checked: privacyChecked,
              onChanged: (val) {
                setState(() {
                  privacyChecked = val!;
                  _updateAllCheckStatus();
                });
              },
              title: '개인정보 처리 방침 보기 (필수)',
              onViewPressed: () {
                _showTermsDialog(
                  '개인정보 처리방침',
                  '''
1. 수집하는 개인정보 항목
- 이름, 이메일, 전화번호, 생년월일 등

2. 수집 및 이용목적
- 회원 식별, 서비스 제공, 고객 지원, 마케팅 정보 전달

3. 보유 및 이용기간
- 회원 탈퇴 후 즉시 파기. 단, 관계법령에 따라 일정기간 보관할 수 있음.
                  ''',
                );
              },
            ),

            _buildAgreementItem(
              checked: marketingChecked,
              onChanged: (val) {
                setState(() {
                  marketingChecked = val!;
                  _updateAllCheckStatus();
                });
              },
              title: '마케팅 정보 메일, SMS 수신 동의 (선택)',
              onViewPressed: () {
                _showTermsDialog(
                  '마케팅 수신 동의',
                  '''
1. 목적
- 이벤트, 할인, 새로운 기능 안내 등 마케팅 정보 제공

2. 수신 방법
- 이메일, 문자(SMS), 푸시 알림 등을 통해 전달

3. 수신 거부
- 사용자는 언제든지 수신 거부 설정을 할 수 있으며, 수신 거부 시 해당 정보는 발송되지 않습니다.
                  ''',
                );
              },
            ),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                onPressed: (termsChecked && privacyChecked)
                    ? () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CodeInputScreen(),
                    ),
                  );
                }
                    : null,
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.resolveWith<Color>(
                        (Set<MaterialState> states) {
                      if (states.contains(MaterialState.disabled)) {
                        return const Color(0xFFD3D3D3);
                      }
                      return const Color(0xFFBB9DF7);
                    },
                  ),
                  shape: MaterialStateProperty.all(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                child: const Text(
                  '동의 완료',
                  style: TextStyle(
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    color: Colors.white,
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

  Widget _buildAgreementItem({
    required bool checked,
    required Function(bool?) onChanged,
    required String title,
    required VoidCallback onViewPressed,
  }) {
    return Row(
      children: [
        Checkbox(value: checked, onChanged: onChanged),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontFamily: 'Pretendard',
              fontSize: 15,
            ),
          ),
        ),
        TextButton(
          onPressed: onViewPressed,
          child: const Text(
            '보기',
            style: TextStyle(
              fontFamily: 'Pretendard',
              fontSize: 14,
              color: Color(0xFF173560),
            ),
          ),
        ),
      ],
    );
  }
}
