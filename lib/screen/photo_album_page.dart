// 📱 Flutter 핵심 위젯 및 Material Design 컴포넌트 import
import 'package:flutter/material.dart';
// 📷 사진 업로드 페이지 import
import 'photo_upload_page.dart';
// 💾 로컬 저장소 관리용 (현재 미사용)
import 'package:shared_preferences/shared_preferences.dart';
// 🔄 JSON 데이터 변환용
import 'dart:convert';
// 📄 메인 페이지 import
import 'package:neverland_flutter/screen/main_page.dart';
// 🌐 HTTP 통신용
import 'package:http/http.dart' as http;

/// 📸 사진 앨범 메인 페이지
/// 사용자가 업로드한 사진들을 리스트/그리드 형태로 보여주고 관리하는 페이지
class PhotoAlbumPage extends StatefulWidget {
  const PhotoAlbumPage({super.key});

  @override
  State<PhotoAlbumPage> createState() => _PhotoAlbumPageState();
}

class _PhotoAlbumPageState extends State<PhotoAlbumPage> {
  // 📊 상태 변수들
  /// 서버에서 불러온 사진 데이터 리스트
  List<Map<String, dynamic>> photos = [];

  /// 화면 표시 모드 (0: 리스트뷰, 1: 그리드뷰)
  int _viewMode = 0;

  /// 사진 정렬 기준 ('최신순', '오래된순', '이름순')
  String _sortOption = '최신순';

  /// 검색어 입력 컨트롤러 (현재 기능 미구현)
  final TextEditingController _searchController = TextEditingController();

  /// 📋 선택된 정렬 옵션에 따라 사진 리스트를 정렬하는 함수
  void _sortPhotos() {
    if (_sortOption == '최신순') {
      // 날짜 기준 내림차순 (최신이 위로)
      photos.sort((a, b) => b['date']!.compareTo(a['date']!));
    } else if (_sortOption == '오래된순') {
      // 날짜 기준 오름차순 (오래된 것이 위로)
      photos.sort((a, b) => a['date']!.compareTo(b['date']!));
    } else if (_sortOption == '이름순') {
      // 제목 기준 가나다순
      photos.sort((a, b) => a['title']!.compareTo(b['title']!));
    }
  }

  /// ❗ 사진 삭제 확인 다이얼로그를 표시하는 함수
  /// [photo] 삭제할 사진 데이터
  void _confirmDeletePhoto(Map<String, dynamic> photo) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('사진 삭제'),
          content: const Text('정말 이 사진을 삭제하시겠습니까?'),
          actions: [
            // 취소 버튼
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('취소'),
            ),
            // 삭제 확인 버튼
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // 다이얼로그 닫기
                _deletePhoto(photo); // 실제 삭제 함수 호출
              },
              child: const Text('삭제', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  /// 🗑️ 서버에서 사진을 삭제하는 함수
  /// [photo] 삭제할 사진 데이터
  void _deletePhoto(Map<String, dynamic> photo) async {
    try {
      final imagePath = photo['imagePath']; // 서버에서 받은 상대 경로

      if (imagePath == null || imagePath.isEmpty) {
        print('❌ imagePath가 없습니다.');
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      final authKeyId = prefs.getString('auth_key_id');

      if (authKeyId == null || authKeyId.isEmpty) {
        print('❌ auth_key_id가 없습니다.');
        return;
      }

      final uri = Uri.parse('http://192.168.219.68:8086/photo/delete')
          .replace(queryParameters: {
        'auth_key_id': authKeyId,
        'imageUrl': imagePath,
      });

      final response = await http.delete(uri);

      if (response.statusCode == 200) {
        setState(() {
          photos.remove(photo);
        });
        print('✅ 삭제 완료');
      } else {
        print('❌ 삭제 실패: ${response.statusCode}');
        print(response.body);
      }
    } catch (e) {
      print('❌ 삭제 중 오류 발생: $e');
    }
  }


  /// 🔍 사진 상세보기 다이얼로그를 표시하는 함수
  /// [context] BuildContext
  /// [photo] 상세보기할 사진 데이터
  void _showPhotoDetail(BuildContext context, Map<String, dynamic> photo) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 닫기 버튼 (오른쪽 상단)
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  icon: Icon(Icons.close, color: Colors.grey[600]),
                  onPressed: () => Navigator.of(dialogContext).pop(),
                ),
              ),
              // 내용 스크롤 영역
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 사진 이미지
                      Container(
                        height: 200,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          image: DecorationImage(
                            image: NetworkImage(photo['imageUrl'] ?? ''),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // 제목
                      Text(
                        photo['title'] ?? '',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      // 날짜
                      Text(
                        photo['date'] ?? '',
                        style: const TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      const SizedBox(height: 12),
                      // 설명
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


  /// 🚀 위젯 초기화 시 호출되는 함수
  @override
  void initState() {
    super.initState();
    _loadPhotos(); // 페이지 로드 시 사진 목록 불러오기
  }

  /// 📥 서버에서 사진 목록을 불러오는 함수
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

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body);
        setState(() {
          photos = jsonList
              .map((e) {
            final rawUrl = e['imagePath'];
            if (rawUrl == null || rawUrl.toString().contains('FILE_SAVE_FAILED')) {
              return null;
            }

            return {
              'id': e['photoId'],
              'title': e['title'],
              'description': e['description'],
              'date': e['photoDate'],
              'imagePath': e['imagePath'], // 삭제용
              'imageUrl': e['imagePath'].toString().startsWith('http')
                  ? e['imagePath']
                  : 'http://192.168.219.68:8086${e['imagePath']}', // ✅ 여기가 중요
            };

          })
              .where((e) => e != null)
              .cast<Map<String, dynamic>>()
              .toList();
        });
      } else {
        print('❌ 목록 조회 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ 네트워크 오류: $e');
    }
  }


  /// 🧹 위젯 해제 시 리소스 정리
  @override
  void dispose() {
    _searchController.dispose(); // 텍스트 컨트롤러 메모리 해제
    super.dispose();
  }

  /// 📤 사진 업로드 페이지로 이동하는 함수
  void _navigateToUploadPage() async {
    // 업로드 페이지로 이동하고 결과 받기
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PhotoUploadPage()),
    );

    // 업로드가 성공적으로 완료된 경우 사진 목록 새로고침
    if (result == true) {
      _loadPhotos(); // ✅ 서버에서 최신 사진 목록 다시 불러오기
    }
  }

  /// 🎨 메인 UI 빌드 함수
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F6FF), // 연보라 배경색
      body: Column(
        children: [
          // 🎯 상단 헤더 영역 (그라데이션 배경)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 56, left: 24, right: 24, bottom: 60),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF8B7ED8), Color(0xFFA994E6)], // 보라색 그라데이션
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // ⬅️ 뒤로가기 버튼
                Align(
                  alignment: Alignment.centerLeft,
                  child: GestureDetector(
                    onTap: () {
                      // 메인 페이지로 이동 (현재 페이지 교체)
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => MainPage()),
                      );
                    },
                    child: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 12),
                // 📸 페이지 제목
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
                // 📝 페이지 부제목
                const Text(
                  '소중한 추억들을 모아보세요.',
                  style: TextStyle(color: Colors.white70, fontSize: 15),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 🔍 검색바 및 뷰 모드 전환 버튼 영역
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                // 🔍 검색 입력 필드
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: '사진 제목이나 설명을 검색해보세요',
                      prefixIcon: Icon(Icons.search, color: Color(0xFF8B7ED8)),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {}); // 검색 기능 준비 (현재 미구현)
                    },
                  ),
                ),
                const SizedBox(width: 8),
                // 📋 뷰 모드 전환 버튼 (리스트 ↔ 그리드)
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _viewMode = (_viewMode + 1) % 2; // 0↔1 토글
                    });
                  },
                  child: Container(
                    height: 48,
                    width: 48,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFBB9DF7)),
                    ),
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

          // 🔄 정렬 옵션 버튼들
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: ['최신순', '오래된순', '이름순'].map((option) {
                final isSelected = _sortOption == option;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _sortOption = option;
                        _sortPhotos(); // 선택된 옵션으로 정렬 실행
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        // 선택된 옵션은 보라색, 아닌 것은 흰색 배경
                        color: isSelected ? const Color(0xFFBB9DF7) : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFBB9DF7)),
                      ),
                      child: Text(
                        option,
                        style: TextStyle(
                          // 선택된 옵션은 흰글자, 아닌 것은 보라글자
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

          // 📊 사진 개수 표시
          Text('총 ${photos.length}장의 사진',
              style: const TextStyle(fontSize: 14, color: Colors.grey)),
          const SizedBox(height: 8),

          // 📸 사진 목록 표시 영역
          Expanded(
            child: photos.isEmpty
                ? // 📭 사진이 없을 때 안내 메시지
            const Center(
              child: Text(
                '아직 등록된 사진이 없어요.\n추억을 추가해보세요!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            )
                : _viewMode == 0
                ? // 📋 리스트 뷰 모드
            ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: photos.length,
              itemBuilder: (context, index) => _buildListPhotoCard(photos[index]),
            )
                : // 📊 그리드 뷰 모드
            GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, // 한 줄에 2개씩
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 0.65, // 세로가 더 긴 비율
              ),
              itemCount: photos.length,
              itemBuilder: (context, index) => _buildGridPhotoCard(photos[index]),
            ),
          ),
        ],
      ),
      // ➕ 사진 추가 플로팅 버튼
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFBB9DF7),
        onPressed: _navigateToUploadPage,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  /// 📊 그리드 뷰용 사진 카드 위젯 생성 함수
  /// [photo] 표시할 사진 데이터
  Widget _buildGridPhotoCard(Map<String, dynamic> photo) {
    return GestureDetector(
      onTap: () => _showPhotoDetail(context, photo), // 탭 시 상세보기
      child: Container(
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
            // 📷 사진 이미지 영역
            Container(
              height: 170,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                image: DecorationImage(
                  image: NetworkImage(photo['imageUrl'] ?? ''),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            // 📝 사진 정보 텍스트 영역
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 사진 제목
                  Text(photo['title'] ?? '',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 4),
                  // 사진 날짜
                  Text(photo['date'] ?? '',
                      style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  const SizedBox(height: 4),
                  // 사진 설명 (최대 3줄, 넘치면 생략)
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
  /// [photo] 표시할 사진 데이터
  Widget _buildListPhotoCard(Map<String, dynamic> photo) {
    return GestureDetector(
      onTap: () => _showPhotoDetail(context, photo), // 탭 시 상세보기
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
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
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                image: DecorationImage(
                  image: NetworkImage(photo['imageUrl'] ?? ''),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            // 📝 사진 정보 및 삭제 버튼 영역
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 제목과 삭제 버튼을 한 줄에 배치
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // 사진 제목 (길면 생략)
                      Expanded(
                        child: Text(
                          photo['title'] ?? '',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // 🗑️ 삭제 버튼
                      TextButton.icon(
                        onPressed: () => _confirmDeletePhoto(photo),
                        icon: const Icon(Icons.delete, color: Colors.redAccent),
                        label: const Text('삭제', style: TextStyle(color: Colors.redAccent)),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          backgroundColor: Colors.redAccent.withOpacity(0.1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // 사진 날짜
                  Text(photo['date'] ?? '',
                      style: const TextStyle(fontSize: 13, color: Colors.grey)),
                  const SizedBox(height: 8),
                  // 사진 설명 (최대 3줄, 넘치면 생략)
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