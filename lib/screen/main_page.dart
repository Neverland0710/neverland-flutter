import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:neverland_flutter/model/letter.dart';
import 'package:neverland_flutter/screen/letter_list_page.dart';
import 'package:neverland_flutter/screen/letter_write_page.dart';
import 'package:neverland_flutter/screen/chat_page.dart';
import 'package:neverland_flutter/screen/login.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:neverland_flutter/screen/keepsake_page.dart';
import 'dart:convert';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:neverland_flutter/screen/photo_album_page.dart';
import 'package:http/http.dart' as http;
import 'package:neverland_flutter/screen/voice_call_screen.dart';

/// 메인 페이지 StatefulWidget
/// fromLetter 매개변수로 편지 페이지에서 왔는지 확인 가능
class MainPage extends StatefulWidget {
  final bool fromLetter;
  const MainPage({super.key, this.fromLetter = false});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  // 데이터 리스트들

  List<Map<String, dynamic>> _photos = []; // 사진 목록


  // 통계 카운트들
  int _photoCount = 0; // 저장된 사진 개수
  int _replyLetterCount = 0; // 답장온 편지 개수
  int _keepsakeCount = 0; // 유품 기록 개수




  Future<void> _loadStatistics() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id');

    if (userId == null || userId.isEmpty) {
      print('❌ userId가 없습니다.');
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('http://192.168.219.68:8086/statistics/get?userId=$userId'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        setState(() {
          _photoCount = data['photoCount'] ?? 0;
          _replyLetterCount = data['sentLetterCount'] ?? 0;
          _keepsakeCount = data['keepsakeCount'] ?? 0;
        });
      } else {
        print('❌ 통계 불러오기 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ 통계 요청 중 오류 발생: $e');
    }
  }



  /// 위젯 초기화 시 실행되는 함수
  @override
  void initState() {
    super.initState();
    _loadStatistics();   // ✅ 통계 수치만 한 번에 불러오기

    _loadPhotos();       // 🖼️ 사진 썸네일도 필요 시
  }



  /// 서버에서 사진 썸네일 목록을 불러오는 함수
  void _loadPhotos() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final authKeyId = prefs.getString('auth_key_id');

      if (authKeyId == null || authKeyId.isEmpty) {
        print('❌ auth_key_id가 없습니다.');
        return;
      }

      final response = await http.get(
        Uri.parse('http://192.168.219.68:8086/photo/list?auth_key_id=$authKeyId'),
      );

      print('📡 사진 응답 상태코드: ${response.statusCode}');
      print('📦 응답 바디: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body);
        print('🧾 받은 JSON 개수: ${jsonList.length}');

        setState(() {
          _photos = jsonList
              .map((e) {
            final rawUrl = e['imagePath'];
            if (rawUrl == null || rawUrl.toString().contains('FILE_SAVE_FAILED')) {
              return null;
            }

            final completeUrl = rawUrl.toString().startsWith('http')
                ? rawUrl
                : 'http://192.168.219.68:8086$rawUrl';

            return {
              'id': e['id'],
              'title': e['title'],
              'description': e['description'],
              'date': e['date'],
              'imageUrl': completeUrl,
            };
          })
              .where((e) => e != null)
              .cast<Map<String, dynamic>>()
              .toList();
        });
      } else {
        print('❌ 메인에서 사진 로드 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ 메인에서 사진 로드 에러: $e');
    }
  }



  /// 로그아웃 확인 다이얼로그 표시
  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFFF8F4FF),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            '정말 나가시겠어요?',
            style: TextStyle(
              fontFamily: 'Pretendard',
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          content: const Text(
            '이탈 시 연결이 끊기며\n위약금은 100배로 청구됩니다.',
            style: TextStyle(fontFamily: 'Pretendard', fontSize: 14),
          ),
          actions: [
            // 취소 버튼
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                '조금만 더 있을래요',
                style: TextStyle(
                  fontFamily: 'Pretendard',
                  color: Colors.deepPurple,
                ),
              ),
            ),
            // 확인 버튼
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFBB9DF7),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop(); // 다이얼로그 닫기
                _logout(); // 로그아웃 실행
              },
              child: const Text(
                '네, 로그아웃할게요',
                style: TextStyle(fontFamily: 'Pretendard', color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  /// 로그아웃 처리 함수
  void _logout() async {
    // 안전한 저장소에서 JWT 토큰 삭제
    const storage = FlutterSecureStorage();
    await storage.delete(key: 'jwt');

    // 위젯이 마운트된 상태인지 확인
    if (!mounted) return;

    // 로그인 화면으로 이동하면서 이전 스택 모두 제거
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
    );
  }
  void _loadKeepsakes() async {
    await _loadStatistics();  // 비동기로 통계만 다시 불러오기
    if (mounted) setState(() {});  // UI 갱신
  }

  /// 메인 UI 빌드 함수
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // 상단 헤더 이미지 (SVG)
            AspectRatio(
              aspectRatio: 375 / 200, // 화면 비율 설정
              child: SvgPicture.asset(
                'asset/image/main_header.svg',
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),

            // 통계 박스들 (사진, 편지, 유품 개수)
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _StatBox(count: '$_photoCount', label: '저장된 사진'),
                  _StatBox(count: '$_replyLetterCount', label: '답장온 편지'),
                  _StatBox(count: '$_keepsakeCount', label: '유품 기록'),
                ],
              ),
            ),

            // 메인 콘텐츠 영역 (스크롤 가능)
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),

                    // 실시간 대화 카드
                    _buildCardMenu(
                      context,
                      imagePath: 'asset/image/chat_icon.png',
                      title: '실시간 대화',
                      subtitle: '언제든 대화해보세요',
                      description:
                      'AI 기술을 통해 고인의 말투와 성격을 반영한 자연스러운 대화를 나눌 수 있습니다.',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const RealTimeChatPage(),
                          ),
                        );
                      },
                    ),

                    // 실시간 통화 카드
                    _buildCardMenu(
                      context,
                      imagePath: 'asset/image/call_icon.png', // 👉 아이콘 경로
                      title: '실시간 통화',
                      subtitle: '목소리로 마음을 전해보세요',
                      description: '그리운 순간마다, 감정이 담긴 대화로 마음을 나눠보세요.',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const VoiceCallScreen(),
                          ),
                        );
                      },
                    ),

                    // 편지 쓰기 카드
                    _buildCardMenu(
                      context,
                      imagePath: 'asset/image/letter_icon.png',
                      title: '편지 쓰기',
                      subtitle: '마음을 담은 편지를 전해보세요',
                      description: '고인에게 전하고 싶은 마음을 편지로 작성하고, 따뜻한 답장을 받아보세요.',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LetterWritePage(),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 32),

                    // 디지털 추억 보관소 섹션 제목
                    const Text(
                      '디지털 추억 보관소',
                      style: TextStyle(
                        fontFamily: 'Pretendard',
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFF6C4ED4),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // 사진 앨범 카드
                    GestureDetector(
                      onTap: () async {
                        // 사진 앨범 페이지로 이동
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PhotoAlbumPage(),
                          ),
                        );
                        // 페이지에서 돌아왔을 때 유품 개수 새로고침
                        if (result == true) {
                          _loadPhotos();       // 썸네일 다시 로드
                          _loadStatistics();   // 통계 다시 로드
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Color(0xFFE0D7FF)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 사진 앨범 제목 영역
                            Row(
                              children: [
                                Image.asset(
                                  'asset/image/image.png',
                                  width: 36,
                                  height: 36,
                                  color: Color(0xFFBB9DF7),
                                ),
                                const SizedBox(width: 8),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: const [
                                    Text(
                                      '사진 앨범',
                                      style: TextStyle(
                                        fontFamily: 'Pretendard',
                                        fontWeight: FontWeight.w700,
                                        fontSize: 16,
                                      ),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      '소중한 추억들',
                                      style: TextStyle(
                                        fontFamily: 'Pretendard',
                                        fontSize: 13,
                                        color: Colors.black54,
                                      ),
                                    ),
                                  ],
                                ),
                                const Spacer(), // ← 이걸로 오른쪽으로 밀고
                                const Icon(
                                  Icons.arrow_forward_ios,
                                  size: 16,
                                  color: Colors.black38,
                                ), // ← 이게 > 아이콘
                              ],
                            ),
                            const SizedBox(height: 4),
                            const SizedBox(height: 12),

                            // 사진 미리보기 영역
                            // 📜 사진 미리보기 박스 섹션 (가로 스크롤 가능한 형태)
                            SingleChildScrollView(
                              scrollDirection:
                              Axis.horizontal, // ➡️ 수평 스크롤 가능하게 설정
                              child: Row(
                                children: _photos.isEmpty
                                // 📦 사진이 없을 경우 - 기본 박스 3개 생성
                                    ? List.generate(3, (index) {
                                  return Padding(
                                    padding: const EdgeInsets.only(
                                      right: 8,
                                    ), // 👉 박스 사이 간격
                                    child: GestureDetector(
                                      // 첫 번째 박스만 탭 가능 (앨범 이동)
                                      onTap: index == 0
                                          ? () async {
                                        final result =
                                        await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                            const PhotoAlbumPage(),
                                          ),
                                        );
                                        // ✅ 앨범에서 사진 추가 후 새로고침
                                        if (result == true) {
                                          _loadPhotos(); // 서버에서 다시 불러오기
                                          setState(() {}); // UI 갱신
                                        }
                                      }
                                          : null,
                                      child: Container(
                                        width: 100,
                                        height: 100, // 📏 박스 크기
                                        decoration: BoxDecoration(
                                          color: const Color(
                                            0xFFF1EBFF,
                                          ), // 🎨 연보라 배경
                                          borderRadius:
                                          BorderRadius.circular(
                                            12,
                                          ), // 🔘 모서리 둥글게
                                        ),
                                        child: const Icon(
                                          Icons.add,
                                          color: Color(0xFFBB9DF7),
                                          size: 28,
                                        ), // ➕ 아이콘
                                      ),
                                    ),
                                  );
                                })
                                    :
                                // 🖼️ 사진이 있는 경우 - 사진 썸네일 + 추가 버튼
                                [
                                  ...List.generate(_photos.length, (
                                      index,
                                      ) {
                                    final photo =
                                    _photos[index]; // 📸 각 사진 데이터
                                    return Padding(
                                      padding: const EdgeInsets.only(
                                        right: 8,
                                      ), // 👉 사진 사이 간격
                                      child: GestureDetector(
                                        onTap: () async {
                                          // 📂 사진 클릭 시 앨범으로 이동
                                          final result =
                                          await Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                              const PhotoAlbumPage(),
                                            ),
                                          );
                                          if (result == true) {
                                            _loadPhotos(); // 서버에서 다시 불러오기
                                            setState(() {}); // UI 갱신
                                          }
                                        },
                                        child: ClipRRect(
                                          borderRadius:
                                          BorderRadius.circular(
                                            12,
                                          ), // 🔘 모서리 둥글게
                                          child: Image.network(
                                            photo['imageUrl'], // 🌐 이미지 URL
                                            width: 100,
                                            height: 100,
                                            fit:
                                            BoxFit.cover, // 이미지 꽉 채우기
                                            errorBuilder:
                                                (
                                                context,
                                                error,
                                                stackTrace,
                                                ) => Container(
                                              color: Colors
                                                  .grey[300], // ❌ 로드 실패 시 회색 박스
                                              width: 100,
                                              height: 100,
                                              child: const Icon(
                                                Icons.broken_image,
                                                color: Colors.grey,
                                              ), // 🧱 대체 아이콘
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  }),

                                  // ➕ 마지막에 추가 버튼 (항상 보이게)
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      right: 8,
                                    ), // 간격 유지
                                    child: GestureDetector(
                                      onTap: () async {
                                        // 📂 + 버튼 탭 → 사진 앨범 페이지 이동
                                        final result =
                                        await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                            const PhotoAlbumPage(),
                                          ),
                                        );
                                        if (result == true) {
                                          _loadPhotos(); // 갱신
                                          setState(() {}); // UI 갱신
                                        }
                                      },
                                      child: Container(
                                        width: 100,
                                        height: 100,
                                        decoration: BoxDecoration(
                                          color: const Color(
                                            0xFFF1EBFF,
                                          ), // 연보라 박스
                                          borderRadius:
                                          BorderRadius.circular(
                                            12,
                                          ), // 둥글게
                                        ),
                                        child: const Icon(
                                          Icons.add,
                                          color: Color(0xFFBB9DF7),
                                        ), // + 아이콘
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 유품 기록 카드
                    GestureDetector(
                      // 🔘 클릭 시 KeepsakeScreen으로 이동
                      onTap: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => KeepsakeScreen(),
                          ),
                        );

                        if (result == true) {
                          _loadKeepsakes(); // 유품 목록 새로고침
                          setState(() {});  // UI 갱신
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Color(0xFFE0D7FF)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),

                        // 📦 Stack 사용 → 아이콘을 오른쪽 상단에 강제로 고정시키기 위함
                        child: Stack(
                          children: [
                            // ✅ 텍스트 + 이미지 구성 Row (화살표 제외)
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // 📍 유품 아이콘 이미지
                                Image.asset(
                                  'asset/image/box.png',
                                  width: 32,
                                  height: 32,
                                ),
                                const SizedBox(width: 12),

                                // 📍 텍스트 묶음
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: const [
                                      // 🟣 타이틀
                                      Text(
                                        '유품 기록',
                                        style: TextStyle(
                                          fontFamily: 'Pretendard',
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(height: 4),

                                      // 🔹 부제목
                                      Text(
                                        '의미있는 물건들',
                                        style: TextStyle(
                                          fontFamily: 'Pretendard',
                                          fontSize: 13,
                                          color: Colors.black54,
                                        ),
                                      ),
                                      SizedBox(height: 2),

                                      // 🔹 설명 텍스트
                                      Text(
                                        '시계, 반지, 책 등 특별한 유품들의 이야기를 기록합니다.',
                                        style: TextStyle(
                                          fontFamily: 'Pretendard',
                                          fontSize: 13,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            // 📌 화살표 아이콘을 오른쪽 상단에 강제 위치 고정
                            const Positioned(
                              right: 0,
                              top: 0,
                              child: Icon(
                                Icons.arrow_forward_ios,
                                size: 16,
                                color: Colors.black38,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // 로그아웃 버튼
                    Center(
                      child: TextButton(
                        onPressed: _confirmLogout,
                        child: const Text(
                          '로그아웃',
                          style: TextStyle(
                            fontFamily: 'Pretendard',
                            fontSize: 14,
                            color: Colors.grey,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 메뉴 카드를 빌드하는 함수
  /// @param context - BuildContext
  /// @param imagePath - 아이콘 이미지 경로
  /// @param title - 카드 제목
  /// @param subtitle - 카드 부제목
  /// @param description - 카드 설명
  /// @param onTap - 카드 클릭 시 실행할 함수
  Widget _buildCardMenu(
      BuildContext context, {
        required String imagePath,
        required String title,
        required String subtitle,
        required String description,
        required VoidCallback onTap,
      }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.black12),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 상단 영역: 아이콘 + 제목 + 부제목 + 화살표
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 메뉴 아이콘
                  Image.asset(
                    imagePath,
                    width: 36,
                    height: 36,
                    color: const Color(0xFFBB9DF7),
                  ),
                  const SizedBox(width: 12),
                  // 제목과 부제목
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontFamily: 'Pretendard',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            fontFamily: 'Pretendard',
                            fontSize: 13,
                            color: Colors.black45,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // 화살표 아이콘
                  const Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.black38,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // 상세 설명
              Text(
                description,
                style: const TextStyle(
                  fontFamily: 'Pretendard',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 통계 박스 위젯 (사진, 편지, 유품 개수 표시)
class _StatBox extends StatelessWidget {
  final String count; // 표시할 숫자
  final String label; // 표시할 라벨

  const _StatBox({required this.count, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xFFEAEAEA)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // 숫자 표시
          Text(
            count,
            style: const TextStyle(
              fontFamily: 'Pretendard',
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: Color(0xFF6C4ED4),
            ),
          ),
          const SizedBox(height: 4),
          // 라벨 표시
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Pretendard',
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
