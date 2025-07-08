// ═══════════════════════════════════════════════════════════════════════════════════════
// 📚 LIBRARY IMPORTS
// ═══════════════════════════════════════════════════════════════════════════════════════

// 📱 Flutter의 핵심 위젯과 Material Design 컴포넌트들을 사용하기 위한 import
import 'package:flutter/material.dart';

// 📷 사진 업로드 기능을 담당하는 별도 페이지
import 'photo_upload_page.dart';

// 💾 앱 내부에 키-값 형태로 데이터를 저장하는 로컬 저장소 라이브러리
// 사용자 인증 키 등을 저장하는 용도로 사용
import 'package:shared_preferences/shared_preferences.dart';

// 🔄 JSON 형태의 문자열을 Dart 객체로 변환하거나 그 반대를 수행하는 라이브러리
import 'dart:convert';

// 📄 앱의 메인 페이지로 이동하기 위한 import
import 'package:neverland_flutter/screen/main_page.dart';

// 🌐 HTTP 통신(REST API 호출)을 위한 라이브러리
import 'package:http/http.dart' as http;

// ═══════════════════════════════════════════════════════════════════════════════════════
// 📸 PHOTO ALBUM PAGE CLASS
// ═══════════════════════════════════════════════════════════════════════════════════════

/// 📸 사진 앨범 메인 페이지 클래스
///
/// 기능:
/// - 사용자가 업로드한 사진들을 리스트/그리드 형태로 표시
/// - 사진 정렬 (최신순, 오래된순, 이름순)
/// - 사진 상세보기 다이얼로그
/// - 사진 삭제 기능
/// - 사진 업로드 페이지로 이동
///
/// 화면 구성:
/// - 상단: 그라데이션 헤더 (제목, 뒤로가기 버튼)
/// - 중간: 검색바, 뷰 모드 전환 버튼, 정렬 옵션
/// - 하단: 사진 목록 (리스트뷰 또는 그리드뷰)
/// - 플로팅 버튼: 사진 추가
class PhotoAlbumPage extends StatefulWidget {
  const PhotoAlbumPage({super.key});

  @override
  State<PhotoAlbumPage> createState() => _PhotoAlbumPageState();
}

// ═══════════════════════════════════════════════════════════════════════════════════════
// 📊 STATE CLASS
// ═══════════════════════════════════════════════════════════════════════════════════════

class _PhotoAlbumPageState extends State<PhotoAlbumPage> {

  // ───────────────────────────────────────────────────────────────────────────────────
  // 📊 STATE VARIABLES (상태 변수들)
  // ───────────────────────────────────────────────────────────────────────────────────

  /// 🗂️ 서버에서 불러온 사진 데이터를 저장하는 리스트
  /// 각 사진은 Map<String, dynamic> 형태로 저장됨
  ///
  /// 사진 데이터 구조:
  /// - 'id': 사진 고유 ID
  /// - 'title': 사진 제목
  /// - 'description': 사진 설명
  /// - 'date': 사진 날짜
  /// - 'imagePath': 서버에 저장된 이미지 경로 (삭제 시 사용)
  /// - 'imageUrl': 이미지 표시용 URL
  List<Map<String, dynamic>> photos = [];

  /// 🔄 현재 화면 표시 모드를 나타내는 정수
  /// 0: 리스트뷰 모드 (한 줄에 하나씩, 큰 이미지)
  /// 1: 그리드뷰 모드 (한 줄에 두 개씩, 작은 이미지)
  int _viewMode = 0;

  /// 📋 현재 선택된 정렬 기준
  /// 가능한 값: '최신순', '오래된순', '이름순'
  /// 이 값에 따라 photos 리스트가 정렬됨
  String _sortOption = '최신순';

  /// 🔍 검색어 입력을 관리하는 텍스트 컨트롤러
  /// 현재는 UI만 구현되어 있고 실제 검색 기능은 미구현 상태
  final TextEditingController _searchController = TextEditingController();

  // ───────────────────────────────────────────────────────────────────────────────────
  // 📋 SORTING METHODS (정렬 관련 메서드)
  // ───────────────────────────────────────────────────────────────────────────────────

  /// 📋 선택된 정렬 옵션에 따라 사진 리스트를 정렬하는 함수
  ///
  /// 정렬 기준:
  /// - '최신순': 날짜 기준 내림차순 (최신 사진이 위로)
  /// - '오래된순': 날짜 기준 오름차순 (오래된 사진이 위로)
  /// - '이름순': 제목 기준 가나다순 (ㄱ, ㄴ, ㄷ... 순서)
  void _sortPhotos() {
    if (_sortOption == '최신순') {
      // compareTo 메서드를 사용하여 날짜 문자열을 비교
      // b.compareTo(a)는 내림차순 (큰 값이 앞으로)
      photos.sort((a, b) => b['date']!.compareTo(a['date']!));
    } else if (_sortOption == '오래된순') {
      // a.compareTo(b)는 오름차순 (작은 값이 앞으로)
      photos.sort((a, b) => a['date']!.compareTo(b['date']!));
    } else if (_sortOption == '이름순') {
      // 제목을 알파벳/가나다순으로 정렬
      photos.sort((a, b) => a['title']!.compareTo(b['title']!));
    }
  }

  // ───────────────────────────────────────────────────────────────────────────────────
  // 🗑️ DELETE METHODS (삭제 관련 메서드)
  // ───────────────────────────────────────────────────────────────────────────────────

  /// ❗ 사진 삭제 확인 다이얼로그를 표시하는 함수
  ///
  /// 사용자가 실수로 사진을 삭제하는 것을 방지하기 위해
  /// 삭제 전에 확인 다이얼로그를 표시함
  ///
  /// @param photo 삭제할 사진 데이터
  void _confirmDeletePhoto(Map<String, dynamic> photo) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          // 📋 다이얼로그 제목
          title: const Text('사진 삭제'),
          // 📝 확인 메시지
          content: const Text('정말 이 사진을 삭제하시겠습니까?'),
          // 🔘 액션 버튼들
          actions: [
            // ❌ 취소 버튼 - 다이얼로그만 닫고 아무 작업 안 함
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('취소'),
            ),
            // ✅ 삭제 확인 버튼 - 실제 삭제 함수 호출
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // 다이얼로그 먼저 닫기
                _deletePhoto(photo); // 실제 삭제 함수 호출
              },
              child: const Text('삭제', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  /// 🗑️ 서버에서 사진을 삭제하는 비동기 함수
  ///
  /// 삭제 과정:
  /// 1. 로컬 저장소에서 사용자 인증 키 가져오기
  /// 2. 서버에 DELETE 요청 보내기
  /// 3. 성공하면 화면에서 해당 사진 제거
  /// 4. 실패하면 오류 로그 출력
  ///
  /// @param photo 삭제할 사진 데이터
  void _deletePhoto(Map<String, dynamic> photo) async {
    try {
      // 🔗 서버에 저장된 이미지 경로 가져오기
      final imagePath = photo['imagePath']; // 서버에서 받은 상대 경로

      // 🔍 이미지 경로가 유효한지 확인
      if (imagePath == null || imagePath.isEmpty) {
        print('❌ imagePath가 없습니다.');
        return;
      }

      // 🔑 로컬 저장소에서 사용자 인증 키 가져오기
      final prefs = await SharedPreferences.getInstance();
      final authKeyId = prefs.getString('authKeyId');

      // 🔍 인증 키가 유효한지 확인
      if (authKeyId == null || authKeyId.isEmpty) {
        print('❌ authKeyId 없습니다.');
        return;
      }

      // 🌐 DELETE 요청을 위한 URI 생성
      // 쿼리 파라미터로 인증 키와 이미지 URL 전달
      final uri = Uri.parse('http://52.78.139.47:8086/photo/delete')
          .replace(queryParameters: {
        'authKeyId': authKeyId,
        'imageUrl': imagePath,
      });

      // 🚀 서버에 DELETE 요청 보내기
      final response = await http.delete(uri);

      // ✅ 요청 성공 시 (HTTP 200)
      if (response.statusCode == 200) {
        setState(() {
          // 화면에서 해당 사진 제거
          photos.remove(photo);
        });
        print('✅ 삭제 완료');
      } else {
        // ❌ 요청 실패 시 오류 정보 출력
        print('❌ 삭제 실패: ${response.statusCode}');
        print(response.body);
      }
    } catch (e) {
      // 🚨 네트워크 오류 또는 예외 발생 시
      print('❌ 삭제 중 오류 발생: $e');
    }
  }

  // ───────────────────────────────────────────────────────────────────────────────────
  // 🔍 DETAIL VIEW METHODS (상세보기 관련 메서드)
  // ───────────────────────────────────────────────────────────────────────────────────

  /// 🔍 사진 상세보기 다이얼로그를 표시하는 함수
  ///
  /// 기능:
  /// - 큰 크기의 사진 이미지 표시
  /// - 사진 제목, 날짜, 설명 표시
  /// - 스크롤 가능한 내용 영역
  /// - 닫기 버튼 제공
  ///
  /// @param context 현재 BuildContext
  /// @param photo 상세보기할 사진 데이터
  void _showPhotoDetail(BuildContext context, Map<String, dynamic> photo) {
    showDialog(
      context: context,
      barrierDismissible: true, // 다이얼로그 외부 터치 시 닫기 허용
      builder: (BuildContext dialogContext) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Column(
            mainAxisSize: MainAxisSize.min, // 내용에 맞게 높이 조절
            children: [
              // ❌ 닫기 버튼 (오른쪽 상단에 위치)
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  icon: Icon(Icons.close, color: Colors.grey[600]),
                  onPressed: () => Navigator.of(dialogContext).pop(),
                ),
              ),
              // 📜 스크롤 가능한 내용 영역
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 🖼️ 사진 이미지 (큰 크기)
                      Container(
                        height: 200,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          image: DecorationImage(
                            image: NetworkImage(photo['imageUrl'] ?? ''),
                            fit: BoxFit.cover, // 이미지를 컨테이너에 맞게 크롭
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // 📝 사진 제목 (굵은 글씨)
                      Text(
                        photo['title'] ?? '',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      // 📅 사진 날짜 (회색 글씨)
                      Text(
                        photo['date'] ?? '',
                        style: const TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      const SizedBox(height: 12),
                      // 📄 사진 설명 (읽기 쉬운 줄 간격)
                      Text(
                        photo['description'] ?? '',
                        style: const TextStyle(fontSize: 15, height: 1.5),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ───────────────────────────────────────────────────────────────────────────────────
  // 🚀 LIFECYCLE METHODS (생명주기 관련 메서드)
  // ───────────────────────────────────────────────────────────────────────────────────

  /// 🚀 위젯이 처음 생성될 때 호출되는 초기화 함수
  ///
  /// 이 함수에서는 페이지 로드 시 필요한 초기 데이터를 불러옴
  /// State 클래스의 모든 변수들이 초기화된 후에 호출됨
  @override
  void initState() {
    super.initState();
    _loadPhotos(); // 서버에서 사진 목록 불러오기
  }

  /// 🧹 위젯이 해제될 때 호출되는 정리 함수
  ///
  /// 메모리 누수를 방지하기 위해 사용하지 않는 리소스들을 해제함
  /// 특히 TextEditingController 같은 리소스는 반드시 해제해야 함
  @override
  void dispose() {
    _searchController.dispose(); // 텍스트 컨트롤러 메모리 해제
    super.dispose();
  }


  // 📥 DATA LOADING METHODS (데이터 로딩 관련 메서드)

  void _loadPhotos() async {
    try {
      // 🔑 로컬 저장소에서 사용자 인증 키 가져오기
      final prefs = await SharedPreferences.getInstance();
      final authKeyId = prefs.getString('authKeyId');

      // 🔍 인증 키가 유효한지 확인
      if (authKeyId == null || authKeyId.isEmpty) {
        print('❌ authKeyId 없습니다.');
        return;
      }

      // 🌐 서버에 GET 요청으로 사진 목록 요청
      final response = await http.get(
        Uri.parse('http://52.78.139.47:8086/photo/list?authKeyId=$authKeyId'),
      );

      // ✅ 요청 성공 시 (HTTP 200)
      if (response.statusCode == 200) {
        // 🔄 JSON 문자열을 Dart 리스트로 변환
        final List<dynamic> jsonList = jsonDecode(response.body);

        setState(() {
          // 📋 서버 응답 데이터를 앱에서 사용할 형태로 변환
          photos = jsonList
              .map((e) {
            // 🖼️ 서버에서 받은 이미지 경로
            final rawUrl = e['imagePath'];

            // 🔍 유효하지 않은 이미지 경로 필터링
            // null이거나 파일 저장 실패 메시지가 포함된 경우 제외
            if (rawUrl == null || rawUrl.toString().contains('FILE_SAVE_FAILED')) {
              return null;
            }

            // 📦 사진 데이터 객체 생성
            return {
              'id': e['photoId'],           // 사진 고유 ID
              'title': e['title'],          // 사진 제목
              'description': e['description'], // 사진 설명
              'date': e['photoDate'],       // 사진 날짜
              'imagePath': rawUrl,          // 서버 경로 (삭제 시 사용)
              'imageUrl': rawUrl,           // 표시용 URL
            };
          })
              .where((e) => e != null)     // null 항목 제거
              .cast<Map<String, dynamic>>() // 타입 캐스팅
              .toList();
        });
      } else {
        // ❌ 요청 실패 시 오류 정보 출력
        print('❌ 목록 조회 실패: ${response.statusCode}');
      }
    } catch (e) {
      // 🚨 네트워크 오류 또는 예외 발생 시
      print('❌ 네트워크 오류: $e');
    }
  }

  // 🚀 NAVIGATION METHODS (네비게이션 관련 메서드)

  void _navigateToUploadPage() async {
    // 🚀 업로드 페이지로 이동하고 결과 값 대기
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PhotoUploadPage()),
    );

    // ✅ 업로드가 성공적으로 완료된 경우
    if (result == true) {
      _loadPhotos(); // 서버에서 최신 사진 목록 다시 불러오기
    }
  }


  // 🎨 UI BUILD METHODS (UI 구성 관련 메서드)

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 🎨 전체 화면 배경색 (연한 보라색)
      backgroundColor: const Color(0xFFF8F6FF),

      // 📋 세로 방향으로 위젯들을 배치하는 메인 컨테이너
      body: Column(
        children: [

          Container(
            width: double.infinity, // 화면 전체 너비
            // 📱 상단 여백: 상태바 + 추가 여백, 좌우 여백, 하단 여백
            padding: const EdgeInsets.only(top: 56, left: 24, right: 24, bottom: 60),
            // 🌈 보라색 그라데이션 배경
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,    // 왼쪽 위에서 시작
                end: Alignment.bottomRight,  // 오른쪽 아래로 끝
                colors: [Color(0xFF8B7ED8), Color(0xFFA994E6)], // 보라색 그라데이션
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // ⬅️ 뒤로가기 버튼 (왼쪽 정렬)
                Align(
                  alignment: Alignment.centerLeft,
                  child: GestureDetector(
                    onTap: () {
                      // 🏠 메인 페이지로 이동 (현재 페이지를 교체)
                      // pushReplacement를 사용하여 뒤로가기 스택에서 현재 페이지 제거
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => MainPage()),
                      );
                    },
                    child: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 12),
                // 📸 페이지 제목 (흰색 굵은 글씨)
                const Text(
                  '사진 앨범',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                // 📝 페이지 부제목 (반투명 흰색)
                const Text(
                  '소중한 추억들을 모아보세요.',
                  style: TextStyle(color: Colors.white70, fontSize: 15),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),


          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                // 🔍 검색 입력 필드 (확장 가능한 영역)
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      // 💡 힌트 텍스트 (사용자 안내)
                      hintText: '사진 제목이나 설명을 검색해보세요',
                      hintStyle: TextStyle(
                        color: Colors.grey[400], // 회색 힌트 텍스트
                      ),
                      // 🔍 검색 아이콘 (입력 필드 앞쪽)
                      prefixIcon: Icon(Icons.search, color: Color(0xFF8B7ED8)),
                      // 🎨 입력 필드 스타일링
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                      // 🔲 둥근 테두리 (테두리 선 없음)
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    // 🔄 검색어 변경 시 화면 새로고침 (현재 기능 미구현)
                    onChanged: (value) {
                      setState(() {}); // 검색 기능 구현 예정
                    },
                  ),
                ),
                const SizedBox(width: 8),
                // 📋 뷰 모드 전환 버튼 (리스트 ↔ 그리드)
                GestureDetector(
                  onTap: () {
                    setState(() {
                      // 0과 1 사이를 토글 (0: 리스트, 1: 그리드)
                      _viewMode = (_viewMode + 1) % 2;
                    });
                  },
                  child: Container(
                    height: 48,
                    width: 48,
                    // 🎨 버튼 스타일링 (흰색 배경, 보라색 테두리)
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFBB9DF7)),
                    ),
                    // 🔄 현재 뷰 모드에 따라 아이콘 변경
                    child: Icon(
                      _viewMode == 0 ? Icons.view_agenda : Icons.grid_view,
                      color: const Color(0xFFBB9DF7),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),


          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: ['최신순', '오래된순', '이름순'].map((option) {
                // 🎯 현재 선택된 옵션인지 확인
                final isSelected = _sortOption == option;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _sortOption = option;  // 선택된 옵션 업데이트
                        _sortPhotos();         // 선택된 옵션으로 정렬 실행
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        // 🎨 선택된 옵션은 보라색 배경, 아닌 것은 흰색 배경
                        color: isSelected ? const Color(0xFFBB9DF7) : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFBB9DF7)),
                      ),
                      child: Text(
                        option,
                        style: TextStyle(
                          // 🎨 선택된 옵션은 흰글자, 아닌 것은 보라글자
                          color: isSelected ? Colors.white : const Color(0xFFBB9DF7),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),

          // ═══════════════════════════════════════════════════════════════════════════════
          // 📊 사진 개수 표시 영역
          // ═══════════════════════════════════════════════════════════════════════════════
          Text('총 ${photos.length}장의 사진',
              style: const TextStyle(fontSize: 14, color: Colors.grey)),
          const SizedBox(height: 8),

          // ═══════════════════════════════════════════════════════════════════════════════
          // 📸 사진 목록 표시 영역 (화면의 나머지 공간을 모두 사용)
          // ═══════════════════════════════════════════════════════════════════════════════
          Expanded(
            child: photos.isEmpty
                ? // 📭 사진이 없을 때 표시되는 안내 메시지
            const Center(
              child: Text(
                '아직 등록된 사진이 없어요.\n추억을 추가해보세요!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            )
                : _viewMode == 0
                ? // 📋 리스트 뷰 모드 (한 줄에 하나씩, 세로 스크롤)
            ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: photos.length,
              itemBuilder: (context, index) => _buildListPhotoCard(photos[index]),
            )
                : // 📊 그리드 뷰 모드 (한 줄에 두 개씩, 세로 스크롤)
            GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,        // 한 줄에 2개씩 배치
                mainAxisSpacing: 16,      // 세로 간격
                crossAxisSpacing: 16,     // 가로 간격
                childAspectRatio: 0.65,   // 세로가 더 긴 비율 (0.65 = 가로:세로 = 65:100)
              ),
              itemCount: photos.length,
              itemBuilder: (context, index) => _buildGridPhotoCard(photos[index]),
            ),
          ),
        ],
      ),

      // ═══════════════════════════════════════════════════════════════════════════════
      // ➕ 사진 추가 플로팅 액션 버튼 (화면 우하단 고정)
      // ═══════════════════════════════════════════════════════════════════════════════
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFBB9DF7), // 보라색 배경
        onPressed: _navigateToUploadPage,          // 사진 업로드 페이지로 이동
        child: const Icon(Icons.add, color: Colors.white), // 흰색 + 아이콘
      ),
    );
  }




  /// 📊 그리드 뷰용 사진 카드 위젯 생성 함수

  Widget _buildGridPhotoCard(Map<String, dynamic> photo) {
    return GestureDetector(
      // 🖱️ 카드 터치 시 상세보기 다이얼로그 표시
      onTap: () => _showPhotoDetail(context, photo),
      child: Container(
        // 🎨 카드 스타일링 (흰색 배경, 둥근 모서리, 그림자)
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 📷 사진 이미지 영역 (카드 상단)
            Container(
              height: 170,
              width: double.infinity,
              decoration: BoxDecoration(
                // 🔲 위쪽 모서리만 둥글게 처리
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                image: DecorationImage(
                  image: NetworkImage(photo['imageUrl'] ?? ''),
                  fit: BoxFit.cover, // 이미지를 컨테이너에 맞게 크롭
                ),
              ),
            ),
            // 📝 사진 정보 텍스트 영역 (카드 하단)
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 📋 사진 제목 (굵은 글씨, 작은 크기)
                  Text(photo['title'] ?? '',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 4),
                  // 📅 사진 날짜 (회색 글씨, 더 작은 크기)
                  Text(photo['date'] ?? '',
                      style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  const SizedBox(height: 4),
                  // 📄 사진 설명 (최대 3줄, 넘치면 '...'으로 생략)
                  Text(
                    photo['description'] ?? '',
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 📋 리스트 뷰용 사진 카드 위젯 생성 함수

  Widget _buildListPhotoCard(Map<String, dynamic> photo) {
    return GestureDetector(
      // 🖱️ 카드 터치 시 상세보기 다이얼로그 표시
      onTap: () => _showPhotoDetail(context, photo),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16), // 카드 간 세로 간격
        // 🎨 카드 스타일링 (흰색 배경, 둥근 모서리, 그림자)
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 4))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 📷 사진 이미지 영역 (리스트뷰는 더 큰 사이즈)
            Container(
              height: 220,
              width: double.infinity,
              decoration: BoxDecoration(
                // 🔲 위쪽 모서리만 둥글게 처리
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                image: DecorationImage(
                  image: NetworkImage(photo['imageUrl'] ?? ''),
                  fit: BoxFit.cover, // 이미지를 컨테이너에 맞게 크롭
                ),
              ),
            ),
            // 📝 사진 정보 및 삭제 버튼 영역
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 📋 제목과 삭제 버튼을 한 줄에 배치
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // 📝 사진 제목 (확장 가능한 영역, 길면 생략)
                      Expanded(
                        child: Text(
                          photo['title'] ?? '',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // 🗑️ 삭제 버튼 (빨간색 아이콘과 텍스트)
                      TextButton.icon(
                        onPressed: () => _confirmDeletePhoto(photo), // 삭제 확인 다이얼로그 표시
                        icon: const Icon(Icons.delete, color: Colors.redAccent),
                        label: const Text('삭제', style: TextStyle(color: Colors.redAccent)),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          // 🎨 연한 빨간색 배경
                          backgroundColor: Colors.redAccent.withOpacity(0.1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // 📅 사진 날짜 (회색 글씨)
                  Text(photo['date'] ?? '',
                      style: const TextStyle(fontSize: 13, color: Colors.grey)),
                  const SizedBox(height: 8),
                  // 📄 사진 설명 (최대 3줄, 넘치면 '...'으로 생략)
                  Text(
                    photo['description'] ?? '',
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

