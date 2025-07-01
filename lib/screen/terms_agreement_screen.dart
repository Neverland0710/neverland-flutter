// Flutter와 Material Design 위젯을 사용하기 위한 패키지 임포트
import 'package:flutter/material.dart';
// CodeInputScreen으로 이동하기 위해 필요한 파일 임포트
import 'package:neverland_flutter/screen/code_input_screen.dart';

// 약관 동의 화면을 위한 StatefulWidget 정의
class TermsAgreementScreen extends StatefulWidget {
  const TermsAgreementScreen({super.key});

  @override
  State<TermsAgreementScreen> createState() => _TermsAgreementScreenState();
}

// TermsAgreementScreen의 상태를 관리하는 State 클래스
class _TermsAgreementScreenState extends State<TermsAgreementScreen> {
  // 모든 약관 동의 여부를 나타내는 플래그
  bool allChecked = false;
  // 서비스 이용약관 동의 여부
  bool termsChecked = false;
  // 개인정보 처리방침 동의 여부
  bool privacyChecked = false;
  // 마케팅 정보 수신 동의 여부
  bool marketingChecked = false;

  // "모두 동의" 체크박스를 토글하는 함수
  void _toggleAll(bool? value) {
    setState(() {
      // 모든 체크박스의 상태를 value로 설정 (null 체크 포함)
      allChecked = value ?? false;
      termsChecked = allChecked;
      privacyChecked = allChecked;
      marketingChecked = allChecked;
    });
  }

  // 개별 체크박스 상태 변경 시 "모두 동의" 상태를 업데이트하는 함수
  void _updateAllCheckStatus() {
    setState(() {
      // 모든 개별 체크박스가 true일 때만 allChecked를 true로 설정
      allChecked = termsChecked && privacyChecked && marketingChecked;
    });
  }

  // 약관 내용을 다이얼로그로 보여주는 함수
  void _showTermsDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title), // 다이얼로그 제목
        content: SingleChildScrollView(
          child: Text(content), // 약관 내용을 스크롤 가능하게 표시
        ),
        actions: [
          // 다이얼로그 닫기 버튼
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
      backgroundColor: const Color(0xFFFFFFFF), // 배경색을 흰색으로 설정
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFFFFF), // AppBar 배경색
        elevation: 0, // AppBar 그림자 제거
        leading: const BackButton(color: Colors.black), // 뒤로 가기 버튼
        title: const Text(
          '약관 동의', // AppBar 제목
          style: TextStyle(
            fontFamily: 'Pretendard', // 폰트 설정
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        centerTitle: true, // 제목 중앙 정렬
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0), // 좌우 패딩
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, // 좌측 정렬
          children: [
            const SizedBox(height: 16), // 상단 여백
            const Text(
              '서비스의 원활한 이용을 위해\n약관에 동의해주세요', // 안내 문구
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 32), // 문구와 체크박스 간 여백

            // "모두 동의" 체크박스
            CheckboxListTile(
              value: allChecked,
              onChanged: _toggleAll, // 체크 시 모든 체크박스 상태 변경
              title: const Text(
                '네, 모두 동의합니다.',
                style: TextStyle(
                  fontFamily: 'Pretendard',
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              controlAffinity: ListTileControlAffinity.leading, // 체크박스 왼쪽 배치
              contentPadding: EdgeInsets.zero, // 패딩 제거
            ),
            const Divider(), // 구분선

            // 서비스 이용약관 체크박스
            _buildAgreementItem(
              checked: termsChecked,
              onChanged: (val) {
                setState(() {
                  termsChecked = val!; // 체크 상태 업데이트
                  _updateAllCheckStatus(); // "모두 동의" 상태 갱신
                });
              },
              title: '서비스 이용약관 동의 (필수)',
              onViewPressed: () {
                // 약관 내용 다이얼로그 표시
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

            // 개인정보 처리방침 체크박스
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

            // 마케팅 정보 수신 동의 체크박스
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

            const Spacer(), // 남은 공간 채우기

            // 동의 완료 버튼
            SizedBox(
              width: double.infinity, // 버튼 너비를 전체로 설정
              height: 60,
              child: ElevatedButton(
                onPressed: (termsChecked && privacyChecked)
                    ? () {
                  // 필수 약관 동의 시 다음 화면으로 이동
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CodeInputScreen(),
                    ),
                  );
                }
                    : null, // 필수 약관 미동의 시 버튼 비활성화
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.resolveWith<Color>(
                        (Set<MaterialState> states) {
                      // 버튼 비활성화 시 회색, 활성화 시 보라색
                      if (states.contains(MaterialState.disabled)) {
                        return const Color(0xFFD3D3D3);
                      }
                      return const Color(0xFFBB9DF7);
                    },
                  ),
                  shape: MaterialStateProperty.all(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12), // 버튼 모서리 둥글게
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

            const SizedBox(height: 80), // 하단 여백
          ],
        ),
      ),
    );
  }

  // 약관 항목 UI를 생성하는 헬퍼 함수
  Widget _buildAgreementItem({
    required bool checked, // 체크박스 상태
    required Function(bool?) onChanged, // 체크 시 호출되는 콜백
    required String title, // 항목 제목
    required VoidCallback onViewPressed, // "보기" 버튼 클릭 시 호출
  }) {
    return Row(
      children: [
        Checkbox(value: checked, onChanged: onChanged), // 체크박스
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontFamily: 'Pretendard',
              fontSize: 15,
            ),
          ),
        ),
        // 약관 내용 보기 버튼
        TextButton(
          onPressed: onViewPressed,
          child: const Text(
            '보기',
            style: TextStyle(
              fontFamily: 'Pretendard',
              fontSize: 14,
              color: Color(0xFF173560), // 버튼 텍스트 색상
            ),
          ),
        ),
      ],
    );
  }
}