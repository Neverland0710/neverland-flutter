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
import 'package:neverland_flutter/screen/voice/voice_call_screen.dart';

/// 메인 페이지 StatefulWidget
/// fromLetter 매개변수로 편지 페이지에서 왔는지 확인 가능
class MainPage extends StatefulWidget {
  final bool fromLetter;
  const MainPage({super.key, this.fromLetter = false});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
// 편지 작성 여부 변수 추가
  late bool isLetterWritten;

  @override
  void initState() {
    super.initState();
    _checkLetterStatus();  // 편지 작성 여부 확인
    _loadStatistics();      // 통계 로드
    _loadPhotos();          // 사진 썸네일 로드
  }

  List<Map<String, dynamic>> _photos = []; // 사진 목록

// 통계 카운트들
  int _photoCount = 0; // 저장된 사진 개수
  int _replyLetterCount = 0; // 답장온 편지 개수
  int _keepsakeCount = 0; // 유품 기록 개수

// 편지 작성 여부를 확인하는 함수
  Future<void> _checkLetterStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final letterStatus = prefs.getBool('isLetterWritten') ?? false;  // 기본값은 false

    setState(() {
      isLetterWritten = letterStatus;
    });
  }

  Future<void> _loadStatistics() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id');

    if (userId == null || userId.isEmpty) {
      print('❌ userId가 없습니다.');
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('http://52.78.139.47:8086/statistics/get?userId=$userId'),
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

  /// 서버에서 사진 썸네일 목록을 불러오는 함수
  void _loadPhotos() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final authKeyId = prefs.getString('authKeyId');

      if (authKeyId == null || authKeyId.isEmpty) {
        print('❌ authKeyId 없습니다.');
        return;
      }

      final response = await http.get(
        Uri.parse('http://52.78.139.47:8086/photo/list?authKeyId=$authKeyId'),
      );

      print('📡 사진 응답 상태코드: ${response.statusCode}');
      //print('📦 응답 바디: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body);
        //print('🧾 받은 JSON 개수: ${jsonList.length}');

        setState(() {
          _photos = jsonList
              .map((e) {
            final rawUrl = e['imagePath'];
            if (rawUrl == null || rawUrl.toString().contains('FILE_SAVE_FAILED')) {
              return null;
            }

            final completeUrl = rawUrl.toString().startsWith('http')
                ? rawUrl
                : 'http://52.78.139.47:8086$rawUrl';

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
                      imageWidget: SvgPicture.asset(
                        'asset/image/chat_icon.svg',
                        width: 36,
                        height: 36,
                      ),
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
                      imageWidget: SvgPicture.asset(
                        'asset/image/call_icon.svg',
                        width: 40,
                        height: 40,
                      ),
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


                    // 편지 쓰기 카드 ✅ 수정된 부분
                    _buildCardMenu(
                      context,
                      imageWidget: SvgPicture.asset(
                        'asset/image/letter_icon.svg',
                        width: 36,
                        height: 36,
                      ),
                      title: '편지 쓰기',
                      subtitle: '마음을 담은 편지를 전해보세요',
                      description: '고인에게 전하고 싶은 마음을 편지로 작성하고, 따뜻한 답장을 받아보세요.',
                      onTap: () async {
                        final prefs = await SharedPreferences.getInstance();
                        final authKeyId = prefs.getString('authKeyId') ?? '';
                        final userId = prefs.getString('user_id') ?? ''; // ✅ 추가

                        if (authKeyId.isEmpty) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => LetterWritePage(userId: userId)), // ✅ 수정
                          );
                          return;
                        }

                        try {
                          final response = await http.get(
                            Uri.parse('http://52.78.139.47:8086/letter/list?authKeyId=$authKeyId'),
                          );

                          if (response.statusCode == 200) {
                            final List<dynamic> letters = jsonDecode(response.body);

                            if (letters.isNotEmpty) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const LetterListPage()),
                              );
                            } else {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => LetterWritePage(userId: userId)), // ✅ 수정
                              );
                            }
                          } else {
                            print('❌ 서버 오류: ${response.statusCode}');
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => LetterWritePage(userId: userId)), // ✅ 수정
                            );
                          }
                        } catch (e) {
                          print('❌ 네트워크 오류: $e');
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => LetterWritePage(userId: userId)), // ✅ 수정
                          );
                        }
                      },
                    ),



                    const SizedBox(height: 32),

                    // 디지털 추억 보관소 섹션 제목
                    const Text(
                      '디지털 추억 보관소',
                      style: TextStyle(
                        fontFamily: 'Pretendard',
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Color(0xFF6B4FBB),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // 사진 앨범 카드
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: InkWell(
                        onTap: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const PhotoAlbumPage()),
                          );
                          if (result == true) {
                            _loadPhotos();
                            _loadStatistics();
                          }
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.only(top: 25, left: 34, right: 34, bottom: 25),
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
                                  SvgPicture.asset(
                                    'asset/image/image.svg', // ✅ SVG 경로
                                    width: 36,
                                    height: 36,
                                    color: Color(0xFFBB9DF7), // ✅ SVG에도 색 적용됨
                                  ),
                                  const SizedBox(width: 20),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: const [
                                        Text(
                                          '사진 앨범',
                                          style: TextStyle(
                                            fontFamily: 'Pretendard',
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        SizedBox(height: 2),
                                        Text(
                                          '소중한 추억들',
                                          style: TextStyle(
                                            fontFamily: 'Pretendard',
                                            fontSize: 14,
                                            color: Colors.black45,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(
                                    Icons.arrow_forward_ios,
                                    size: 16,
                                    color: Colors.black38,
                                  ),
                                ],
                              ),

                              const SizedBox(height: 12),

                              // 썸네일 미리보기
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: _photos.isEmpty
                                      ? List.generate(3, (index) {
                                    return Padding(
                                      padding: const EdgeInsets.only(right: 8),
                                      child: Container(
                                        width: 80,
                                        height: 80,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF1EBFF),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: const Icon(Icons.add, color: Color(0xFFBB9DF7), size: 24),
                                      ),
                                    );
                                  })
                                      : [
                                    ...List.generate(_photos.length, (index) {
                                      final photo = _photos[index];
                                      return Padding(
                                        padding: const EdgeInsets.only(right: 8),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(12),
                                          child: Image.network(
                                            photo['imageUrl'],
                                            width: 80,
                                            height: 80,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) => Container(
                                              color: Colors.grey[300],
                                              width: 80,
                                              height: 80,
                                              child: const Icon(Icons.broken_image, color: Colors.grey),
                                            ),
                                          ),
                                        ),
                                      );
                                    }),
                                    Padding(
                                      padding: const EdgeInsets.only(right: 8),
                                      child: Container(
                                        width: 80,
                                        height: 80,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF1EBFF),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: const Icon(Icons.add, color: Color(0xFFBB9DF7)),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),


                    // 유품 기록 카드
                    _buildCardMenu(
                      context,
                      imageWidget: SvgPicture.asset(
                        'asset/image/box.svg',
                        width: 36,
                        height: 36,
                      ),
                      title: '유품 기록',
                      subtitle: '의미있는 물건들',
                      description: '시계, 반지, 책 등 특별한 유품들의 이야기를 기록합니다.',
                      onTap: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => KeepsakeScreen(),
                          ),
                        );

                        if (result == true) {
                          _loadKeepsakes();
                          setState(() {});
                        }
                      },
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
        required Widget imageWidget,
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
          padding: const EdgeInsets.only(top: 25, left: 34, right: 34, bottom: 25),
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
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ✅ SVG나 이미지 위젯을 직접 넣기
                  SizedBox(
                    width: 42,
                    height: 42,
                    child: imageWidget,
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontFamily: 'Pretendard',
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            fontFamily: 'Pretendard',
                            fontSize: 14,
                            color: Colors.black45,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.black38,
                  ),
                ],
              ),
              const SizedBox(height: 12),
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