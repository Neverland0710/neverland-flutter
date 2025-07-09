import 'package:flutter/material.dart';
import 'package:neverland_flutter/screen/addkeepsake_page.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:neverland_flutter/screen/main_page.dart';
import 'package:http_parser/http_parser.dart';

/// 유품 목록을 표시하고 관리하는 메인 화면
class KeepsakeScreen extends StatefulWidget {
  @override
  _KeepsakeScreenState createState() => _KeepsakeScreenState();
}

class _KeepsakeScreenState extends State<KeepsakeScreen> {
  // 검색 텍스트를 관리하는 컨트롤러
  final TextEditingController _searchController = TextEditingController();

  // 현재 선택된 정렬 필터 (기본값: 최신순)
  String selectedFilter = '최신순';

  // 서버에서 가져온 전체 유품 목록을 저장하는 리스트
  List<KeepsakeItem> keepsakes = [];

  // 검색 및 필터링 결과를 표시할 유품 목록
  List<KeepsakeItem> displayedKeepsakes = [];

  // ❗ 사진 삭제 확인 다이얼로그를 표시하는 함수
  // [photo] 삭제할 사진 데이터
  void _confirmDeleteKeepsake(String? imageUrl) {
    if (imageUrl == null) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('유품 삭제'),
          content: const Text('정말 이 유품을 삭제하시겠습니까?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteKeepsake(imageUrl); // ✅ 전체 S3 URL 전달
                print('🔥 삭제 요청 URL: $imageUrl');
              },
              child: const Text('삭제', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }



  @override
  void initState() {
    super.initState();
    // 화면 초기화 시 서버에서 유품 목록을 가져옴
    fetchKeepsakes();
    // 검색 텍스트 변경 시 필터링을 적용하는 리스너 추가
    _searchController.addListener(_applyFilters);
  }

  /// 서버에서 특정 유품을 삭제하는 함수
  /// [imageUrl] - 삭제할 유품의 이미지 파일명
  Future<void> _deleteKeepsake(String imageUrl) async {
    final prefs = await SharedPreferences.getInstance();
    final authKeyId = prefs.getString('authKeyId');

    if (authKeyId == null || authKeyId.isEmpty) {
      print('❌ 인증 키가 없습니다.');
      return;
    }

    final uri = Uri.parse('http://52.78.139.47:8086/keepsake/delete').replace(queryParameters: {
      'authKeyId': authKeyId,      // ✅ 이거 추가해야 백엔드에서 안 터짐
      'imageUrl': imageUrl,
    });

    print('🔥 최종 삭제 요청 URI: $uri');

    try {
      final response = await http.delete(uri);

      if (response.statusCode == 200) {
        print('✅ 유품 삭제 성공');
        fetchKeepsakes(); // 목록 새로고침
      } else {
        print('❌ 유품 삭제 실패: ${response.statusCode}');
        print('서버 응답: ${response.body}');
      }
    } catch (e) {
      print('❌ 삭제 요청 중 예외 발생: $e');
    }
  }


  @override
  void dispose() {
    // 메모리 누수 방지를 위해 컨트롤러 해제
    _searchController.dispose();
    super.dispose();
  }

  /// 검색어와 정렬 옵션에 따라 유품 목록을 필터링하고 정렬하는 함수
  void _applyFilters() {
    // 검색어를 소문자로 변환하여 대소문자 구분 없이 검색
    String keyword = _searchController.text.toLowerCase();

    print('🔍 현재 검색어: "$keyword"');

    // 제목 또는 설명에 검색어가 포함된 유품만 필터링
    List<KeepsakeItem> filtered = keepsakes.where((item) {
      return item.title.toLowerCase().contains(keyword) ||
          item.description.toLowerCase().contains(keyword);
    }).toList();

    // 선택된 정렬 옵션에 따라 목록 정렬
    switch (selectedFilter) {
      case '최신순':
      // 날짜 기준 내림차순 정렬 (최신이 위로)
        filtered.sort((a, b) => _parseDate(b.date).compareTo(_parseDate(a.date)));
        break;
      case '오래된 순':
      // 날짜 기준 오름차순 정렬 (오래된 것이 위로)
        filtered.sort((a, b) => _parseDate(a.date).compareTo(_parseDate(b.date)));
        break;
      case '이름순':
      // 제목 기준 알파벳 순 정렬
        filtered.sort((a, b) => a.title.compareTo(b.title));
        break;
    }

    // 필터링된 결과로 화면 업데이트
    setState(() {
      displayedKeepsakes = filtered;
    });
    print('🔍 필터링 후 유품 개수: ${displayedKeepsakes.length}');
  }

  /// 날짜 문자열을 DateTime 객체로 변환하는 함수
  /// [dateStr] - "2023.08.15" 형태의 날짜 문자열
  /// 반환값: DateTime 객체 (파싱 실패 시 기본값 2000년 1월 1일)
  DateTime _parseDate(String dateStr) {
    return DateTime.tryParse(dateStr.replaceAll('.', '-')) ?? DateTime(2000);
  }

  /// 서버에서 유품 목록을 가져오는 함수
  Future<void> fetchKeepsakes() async {
    final prefs = await SharedPreferences.getInstance();
    final authKeyId = prefs.getString('authKeyId');

    if (authKeyId == null) {
      print('❌ 저장된 인증 키가 없습니다.');
      return;
    }

    final uri = Uri.parse('http://52.78.139.47:8086/keepsake/list?authKeyId=$authKeyId');
    final response = await http.get(uri);

    print('📡 요청 상태: ${response.statusCode}');

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
      print('📦 받은 유품 개수: ${data.length}');

      keepsakes = data.map((item) {
        final imagePath = item['imagePath'];
        final fullUrl = imagePath?.toString();


        return KeepsakeItem(
          id: '${item['keepsakeId']}',
          title: item['itemName'] ?? '',
          year: '${item['acquisitionPeriod'] ?? ''}',
          description: '${item['description'] ?? ''}',
          story: '${item['specialStory'] ?? ''}',
          date: '${item['createdAt'] ?? ''}',
          imageUrl: fullUrl,
        );
      }).toList();

      setState(() {
        displayedKeepsakes = List.from(keepsakes);
      });

      _applyFilters();
    } else {
      print('❌ 유품 목록 불러오기 실패: ${response.statusCode}');
      print('📭 응답 바디: ${response.body}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),           // 상단 헤더 영역
            _buildSearchAndFilter(),  // 검색 및 필터 영역
            _buildKeepsakeList(),     // 유품 목록 영역
          ],
        ),
      ),
      // 유품 추가 버튼 (플로팅 액션 버튼)
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // 유품 추가 화면으로 이동
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddKeepsakeScreen()),
          ).then((result) {
            // ✅ 검색창에 남아있는 텍스트 초기화하여 유품 필터링 방지
            _searchController.clear();
            // 유품 추가 후 돌아오면 목록 새로고침
            if (result == true) {
              fetchKeepsakes();
            }
          });
        },
        backgroundColor: Color(0xFF8B7ED8),
        child: Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }

  /// 상단 헤더 영역을 구성하는 위젯
  /// 그라데이션 배경, 뒤로가기 버튼, 제목 및 설명 포함
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 20, left: 12, right: 24, bottom: 0), // ← left 줄임
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF8B7ED8), Color(0xFFA994E6)], // 보라색 그라데이션
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // 상단 네비게이션 바 (뒤로가기 버튼)
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: 0, bottom: 0), // ← 왼쪽 여백 따로 줄임
                child: GestureDetector(
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => MainPage()),
                    );
                  },
                  child: const Icon(Icons.arrow_back, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // 메인 타이틀
            Transform.translate(
              offset: const Offset(0, -10),
              child: const Text(
                '유품 기록',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 8),

            // 서브 타이틀
            Transform.translate(
              offset: const Offset(0, -10),
              child: Text(
                '소중한 물건들의 이야기를 간직해요',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 16,
                ),
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
  /// 검색 입력창과 정렬 필터 버튼들을 구성하는 위젯
  Widget _buildSearchAndFilter() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          // 검색 입력창
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Color(0xFF8B7ED8), width: 2),
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '사진 제목이나 설명을 검색해보세요',
                hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                prefixIcon: Icon(Icons.search, color: Color(0xFF8B7ED8)),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
              ),
            ),
          ),
          SizedBox(height: 15),
          // 정렬 필터 버튼들
          Row(
            children: [
              _buildFilterButton('최신순'),
              SizedBox(width: 10),
              _buildFilterButton('오래된 순'),
              SizedBox(width: 10),
              _buildFilterButton('이름순'),
            ],
          ),
        ],
      ),
    );
  }

  /// 개별 필터 버튼을 생성하는 위젯
  /// [text] - 버튼에 표시할 텍스트
  Widget _buildFilterButton(String text) {
    return GestureDetector(
      onTap: () {
        // 필터 선택 상태 변경 및 필터링 적용
        setState(() {
          selectedFilter = text;
        });
        _applyFilters();
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          // 선택된 필터는 배경색 채움, 나머지는 투명
          color: selectedFilter == text ? Color(0xFF8B7ED8) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Color(0xFF8B7ED8), width: 1),
        ),
        child: Text(
          text,
          style: TextStyle(
            // 선택된 필터는 흰색 텍스트, 나머지는 보라색 텍스트
            color: selectedFilter == text ? Colors.white : Color(0xFF8B7ED8),
            fontSize: 14,
            fontWeight: selectedFilter == text ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  /// 유품 목록을 표시하는 위젯
  Widget _buildKeepsakeList() {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 섹션 타이틀
            Row(
              children: [
                // 보라색 세로 막대
                Container(
                  width: 4,
                  height: 20,
                  decoration: BoxDecoration(
                    color: Color(0xFF8B7ED8),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                SizedBox(width: 8),
                Text('소중한 유품들', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF6B4FBB))),
              ],
            ),
            SizedBox(height: 20),
            // 유품 카드 목록 (스크롤 가능)
            Expanded(
              child: ListView.builder(
                itemCount: displayedKeepsakes.length,
                itemBuilder: (context, index) {
                  return _buildKeepsakeCard(displayedKeepsakes[index]);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 개별 유품 카드를 생성하는 위젯
  /// [item] - 표시할 유품 데이터
  Widget _buildKeepsakeCard(KeepsakeItem item) {
    return GestureDetector(
      // 카드 탭 시 상세 모달 표시
      onTap: () => _showKeepsakeModal(context, item),
      child: Container(
        margin: EdgeInsets.only(bottom: 20),
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          // 그림자 효과
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, 2),
            ),
          ],
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 상단 영역: 이미지 + 제목/연도
            Row(
              children: [
                // 유품 이미지 또는 기본 아이콘
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Color(0xFFE6E0F8),
                  ),
                  child: item.imageUrl != null
                      ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        item.imageUrl!,  // ✅ 주소 중복 없이 바로 사용
                        fit: BoxFit.contain,
                      )
                  )
                      : Icon(Icons.inventory_2_outlined, color: Color(0xFF8B7ED8), size: 30),
                ),
                SizedBox(width: 15),
                // 제목과 연도 정보
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                      SizedBox(height: 4),
                      Text(item.year, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 15),
            // 유품 설명
            Text(item.description, style: TextStyle(fontSize: 14, color: Colors.black87, height: 1.4)),
            SizedBox(height: 12),
            // 소중한 이야기 박스
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Color(0xFFF8F6FF),
                borderRadius: BorderRadius.circular(8),
                border: Border(
                  left: BorderSide(color: Color(0xFFA688FA), width: 3), // 왼쪽 보라색 테두리
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 이야기 섹션 헤더
                  Row(
                    children: [
                      Icon(Icons.auto_stories, color: Color(0xFF8B7ED8), size: 16),
                      SizedBox(width: 6),
                      Text('소중한 이야기', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF8B7ED8))),
                    ],
                  ),
                  SizedBox(height: 8),
                  // 이야기 내용
                  Text(item.story, style: TextStyle(fontSize: 13, color: Colors.black87, height: 1.4)),
                ],
              ),
            ),
            SizedBox(height: 12),
            // 삭제 버튼
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () {
                  final rawUrl = item.imageUrl ?? '';
                  final filename = Uri.encodeComponent(rawUrl.split('/').last);
                  _confirmDeleteKeepsake(rawUrl); // ✅ 다이얼로그 먼저 띄움
                  print('🔥 삭제 요청 파일명: $filename');

                },
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
            ),

            // 등록 날짜
            Text(item.date, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
          ],
        ),
      ),
    );
  }

  /// 유품 상세 정보를 표시하는 모달 다이얼로그
  /// [context] - 빌드 컨텍스트
  /// [item] - 표시할 유품 데이터
  void _showKeepsakeModal(BuildContext context, KeepsakeItem item) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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

              // 내용 스크롤 가능 영역
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 이미지 + 제목/연도
                      Row(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE6E0F8),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: item.imageUrl != null
                                ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(item.imageUrl!, fit: BoxFit.cover),
                            )
                                : const Icon(Icons.inventory_2_outlined, color: Color(0xFF8B7ED8), size: 30),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.title,
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                                const SizedBox(height: 4),
                                Text(item.year, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // 설명
                      const Text('유품 설명',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF8B7ED8))),
                      const SizedBox(height: 12),
                      Text(item.description, style: const TextStyle(fontSize: 14, height: 1.5)),

                      const SizedBox(height: 20),

                      // 소중한 이야기
                      const Text('소중한 이야기',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF8B7ED8))),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8F6FF),
                          borderRadius: BorderRadius.circular(12),
                          border: const Border(left: BorderSide(color: Color(0xFFA688FA), width: 3)),
                        ),
                        child: Text(item.story, style: const TextStyle(fontSize: 14, height: 1.5)),
                      ),

                      const SizedBox(height: 12),

                      // 등록 날짜
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(item.date, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                      ),
                      const SizedBox(height: 8),
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

}

/// 유품 데이터를 저장하는 모델 클래스
class KeepsakeItem {
  final String id;          // 유품 고유 ID
  final String title;       // 유품 제목
  final String year;        // 취득 연도
  final String description; // 유품 설명
  final String story;       // 소중한 이야기
  final String date;        // 등록 날짜
  final String? imageUrl;   // 이미지 URL (선택적)

  KeepsakeItem({
    required this.id,
    required this.title,
    required this.year,
    required this.description,
    required this.story,
    required this.date,
    this.imageUrl,
  });
}