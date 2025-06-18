import 'package:flutter/material.dart';
import 'package:neverland_flutter/screen/family_certification_screen.dart';

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

            // ✅ 모두 동의
            CheckboxListTile(
              value: allChecked,
              onChanged: _toggleAll,
              title: const Text(
                '네, 모두 동의합니다.',
                style: TextStyle(
                  fontFamily: 'Pretendard',
                  fontSize: 16,
                ),
              ),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
            const Divider(),

            // 항목 1
            _buildAgreementItem(
              checked: termsChecked,
              onChanged: (val) {
                setState(() {
                  termsChecked = val!;
                  _updateAllCheckStatus();
                });
              },
              title: '서비스 이용약관 동의 (필수)',
            ),

            // 항목 2
            _buildAgreementItem(
              checked: privacyChecked,
              onChanged: (val) {
                setState(() {
                  privacyChecked = val!;
                  _updateAllCheckStatus();
                });
              },
              title: '개인정보 처리 방침 보기 (필수)',
            ),

            // 항목 3
            _buildAgreementItem(
              checked: marketingChecked,
              onChanged: (val) {
                setState(() {
                  marketingChecked = val!;
                  _updateAllCheckStatus();
                });
              },
              title: '마케팅 정보 메일, SMS 수신 동의 (선택)',
            ),

            const Spacer(),

            // ✅ 동의 완료 버튼
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: (termsChecked && privacyChecked)
                    ? () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const FamilyCertificationScreen(),
                    ),
                  );
                }
                    : null,
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.resolveWith<Color>(
                        (Set<MaterialState> states) {
                      if (states.contains(MaterialState.disabled)) {
                        return const Color(0xFFD3D3D3); // 비활성
                      }
                      return const Color(0xFFBB9DF7);   // 활성
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
                    fontSize: 16,
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
          onPressed: () {
            // TODO: 약관 보기 연결
          },
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
