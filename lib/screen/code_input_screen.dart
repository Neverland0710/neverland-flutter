// Flutter와 Material Design 위젯을 사용하기 위한 패키지 임포트
import 'package:flutter/material.dart';
// 다음 화면(MainPage)으로 이동하기 위해 필요한 파일 임포트
import 'package:neverland_flutter/screen/main_page.dart';

// 인증 코드 입력 화면을 위한 StatefulWidget 정의
class CodeInputScreen extends StatefulWidget {
  const CodeInputScreen({super.key});

  @override
  State<CodeInputScreen> createState() => _CodeInputScreenState();
}

// CodeInputScreen의 상태를 관리하는 State 클래스
class _CodeInputScreenState extends State<CodeInputScreen> {
  // 텍스트 입력 필드를 제어하기 위한 컨트롤러
  final TextEditingController _codeController = TextEditingController();
  // 에러 메시지 표시 여부를 나타내는 플래그
  bool _showError = false;
  // 로딩 상태를 나타내는 플래그
  bool _isLoading = false;

  // 입력된 인증 코드를 검증하는 함수
  void _validateCode() async {
    setState(() {
      _isLoading = true; // 로딩 시작
      _showError = false; // 에러 메시지 초기화
    });

    // 서버 요청을 시뮬레이션하기 위한 2초 지연
    await Future.delayed(const Duration(seconds: 2));

    // 입력된 코드가 '123456'인지 확인
    if (_codeController.text.trim() == '123456') {
      if (!mounted) return; // 위젯이 여전히 마운트되어 있는지 확인
      // 올바른 코드일 경우 MainPage로 이동
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainPage()),
      );
    } else {
      // 잘못된 코드일 경우 에러 표시 및 로딩 종료
      setState(() {
        _showError = true;
        _isLoading = false;
      });
    }
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
          '기억 연결 코드 입력', // AppBar 제목
          style: TextStyle(
            fontFamily: 'Pretendard', // 폰트 설정
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        centerTitle: true, // 제목 중앙 정렬
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24), // 좌우 패딩
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, // 좌측 정렬
          children: [
            const SizedBox(height: 16), // 상단 여백
            const Text(
              '서비스의 원활한 이용을 위해\n발급된 인증코드를 입력해주세요', // 안내 문구
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 40), // 문구와 입력 필드 간 여백

            // 인증 코드 입력 박스
            Container(
              height: 48, // 입력 필드 높이
              decoration: BoxDecoration(
                color: Colors.white, // 배경색
                borderRadius: BorderRadius.circular(30), // 모서리 둥글게
                border: Border.all(
                  color: _showError ? Colors.red : const Color(0xFFD9D9D9), // 에러 시 테두리 빨간색
                  width: 1.5, // 테두리 두께
                ),
              ),
              child: TextField(
                controller: _codeController, // 텍스트 입력 컨트롤러 연결
                enabled: !_isLoading, // 로딩 중일 때는 입력 비활성화
                style: const TextStyle(
                  fontFamily: 'Pretendard',
                  fontSize: 14,
                ),
                textAlignVertical: TextAlignVertical.center, // 입력값 수직 중앙 정렬
                decoration: const InputDecoration(
                  isCollapsed: true, // 입력 필드 높이 최적화
                  hintText: '발급 받은 코드를 입력해주세요', // 힌트 텍스트
                  hintStyle: TextStyle(
                    fontFamily: 'Pretendard',
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                  border: InputBorder.none, // 기본 테두리 제거
                  contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 14), // 내부 패딩
                ),
              ),
            ),

            // 에러 메시지 표시
            if (_showError)
              const Padding(
                padding: EdgeInsets.only(top: 8.0), // 에러 메시지 상단 여백
                child: Text(
                  '입력하신 코드가 맞는지 다시 확인해 주세요',
                  style: TextStyle(
                    fontFamily: 'Pretendard',
                    fontSize: 13,
                    color: Colors.red, // 에러 텍스트 색상
                  ),
                ),
              ),

            const Spacer(), // 남은 공간 채우기

            // 다음 버튼
            SizedBox(
              width: double.infinity, // 버튼 너비를 전체로 설정
              height: 60,
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator()) // 로딩 중이면 로딩 인디케이터 표시
                  : ElevatedButton(
                onPressed: _validateCode, // 버튼 클릭 시 코드 검증
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFBB9DF7), // 버튼 배경색
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12), // 버튼 모서리 둥글게
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

            const SizedBox(height: 80), // 하단 여백
          ],
        ),
      ),
    );
  }
}