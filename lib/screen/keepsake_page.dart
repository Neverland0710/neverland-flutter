import 'package:flutter/material.dart';
import 'package:neverland_flutter/screen/addkeepsake_page.dart';
class KeepsakeScreen extends StatefulWidget {
  @override
  _KeepsakeScreenState createState() => _KeepsakeScreenState();
}

class _KeepsakeScreenState extends State<KeepsakeScreen> {
  final TextEditingController _searchController = TextEditingController();
  String selectedFilter = '최신순';

  final List<KeepsakeItem> keepsakes = [
    KeepsakeItem(
      title: '할아버지의 금시계',
      year: '1985년 구입',
      description: '할아버지께서 평생 차고 다니셨던 금시계입니다...',
      story: '"시간은 금보다 소중하다"라고 항상 말씀하셨던 할아버지...',
      date: '2023.08.15',
    ),
    KeepsakeItem(
      title: '어머니의 요리책',
      year: '1995년',
      description: '어머니께서 직접 작성하신 요리 레시피 노트입니다.',
      story: '어릴 적 엄마의 반찬은 늘 이 노트에서 시작되었어요...',
      date: '2022.05.03',
    ),
    KeepsakeItem(
      title: '아버지의 카메라',
      year: '2001년 구입',
      description: '아버지의 취미였던 사진 촬영에 사용된 카메라입니다.',
      story: '이 카메라는 우리 가족의 모든 여행을 기록해 주었죠.',
      date: '2024.02.10',
    ),
  ];

  List<KeepsakeItem> displayedKeepsakes = [];

  @override
  void initState() {
    super.initState();
    displayedKeepsakes = List.from(keepsakes);
    _searchController.addListener(_applyFilters);
    _applyFilters();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _applyFilters() {
    String keyword = _searchController.text.toLowerCase();

    List<KeepsakeItem> filtered = keepsakes.where((item) {
      return item.title.toLowerCase().contains(keyword) ||
          item.description.toLowerCase().contains(keyword);
    }).toList();

    switch (selectedFilter) {
      case '최신순':
        filtered.sort((a, b) => _parseDate(b.date).compareTo(_parseDate(a.date)));
        break;
      case '오래된 순':
        filtered.sort((a, b) => _parseDate(a.date).compareTo(_parseDate(b.date)));
        break;
      case '이름순':
        filtered.sort((a, b) => a.title.compareTo(b.title));
        break;
    }

    setState(() {
      displayedKeepsakes = filtered;
    });
  }

  DateTime _parseDate(String dateStr) {
    return DateTime.tryParse(dateStr.replaceAll('.', '-')) ?? DateTime(2000);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildSearchAndFilter(),
            _buildKeepsakeList(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddKeepsakeScreen()),
          );
        },
        backgroundColor: Color(0xFF8B7ED8),
        child: Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF8B7ED8), Color(0xFFA994E6)],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back_ios, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                Expanded(child: Container()),
              ],
            ),
            SizedBox(height: 20),
            Text('유품 기록', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('소중한 물건들의 이야기를 간직해요', style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 16)),
            SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
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

  Widget _buildFilterButton(String text) {
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedFilter = text;
        });
        _applyFilters();
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selectedFilter == text ? Color(0xFF8B7ED8) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Color(0xFF8B7ED8), width: 1),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: selectedFilter == text ? Colors.white : Color(0xFF8B7ED8),
            fontSize: 14,
            fontWeight: selectedFilter == text ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildKeepsakeList() {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
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

  Widget _buildKeepsakeCard(KeepsakeItem item) {
    return GestureDetector(
      onTap: () => _showKeepsakeModal(context, item),
      child: Container(
        margin: EdgeInsets.only(bottom: 20),
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
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
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Color(0xFFE6E0F8),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.inventory_2_outlined, color: Color(0xFF8B7ED8), size: 30),
                ),
                SizedBox(width: 15),
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
            Text(item.description, style: TextStyle(fontSize: 14, color: Colors.black87, height: 1.4)),
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Color(0xFFF8F6FF),
                borderRadius: BorderRadius.circular(8),
                border: Border(
                  left: BorderSide(color: Color(0xFFA688FA), width: 3), // 💜 왼쪽에만 stroke
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.auto_stories, color: Color(0xFF8B7ED8), size: 16),
                      SizedBox(width: 6),
                      Text('소중한 이야기', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF8B7ED8))),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(item.story, style: TextStyle(fontSize: 13, color: Colors.black87, height: 1.4)),
                ],
              ),
            ),
            SizedBox(height: 12),
            Text(item.date, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
          ],
        ),
      ),
    );
  }

  void _showKeepsakeModal(BuildContext context, KeepsakeItem item) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          insetPadding: EdgeInsets.symmetric(horizontal: 20),
          backgroundColor: Colors.transparent,
          child: Center(
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 20, offset: Offset(0, 10)),
                ],
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: 0,
                    top: 0,
                    child: IconButton(
                      icon: Icon(Icons.close, color: Colors.grey[600]),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: 16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: Color(0xFFE6E0F8),
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            SizedBox(width: 15),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item.title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                                  SizedBox(height: 4),
                                  Text(item.year, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 20),
                        Text('유품 설명', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF8B7ED8))),
                        SizedBox(height: 12),
                        Text(item.description, style: TextStyle(fontSize: 14, height: 1.5)),
                        SizedBox(height: 20),
                        Text('소중한 이야기', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF8B7ED8))),
                        SizedBox(height: 12),
                        Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Color(0xFFF8F6FF),
                            borderRadius: BorderRadius.circular(12),
                            border: Border(
                              left: BorderSide(color: Color(0xFFA688FA), width: 3), // 💜 왼쪽에만 stroke
                            ),
                          ),
                          child: Text(item.story, style: TextStyle(fontSize: 14, height: 1.5)),
                        ),
                        SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(item.date, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class KeepsakeItem {
  final String title;
  final String year;
  final String description;
  final String story;
  final String date;

  KeepsakeItem({
    required this.title,
    required this.year,
    required this.description,
    required this.story,
    required this.date,
  });
}
