// 📁 파일 시스템 관련 기능 import
import 'dart:io';
// 📱 Flutter 핵심 위젯 및 Material Design 컴포넌트 import
import 'package:flutter/material.dart';
// 📷 이미지 선택 기능 (갤러리, 카메라) import
import 'package:image_picker/image_picker.dart';
// 🔲 점선 테두리 UI 컴포넌트 import
import 'package:dotted_border/dotted_border.dart';
// 🌐 HTTP 통신용 import
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// 📤 사진 업로드 페이지
/// 사용자가 사진을 선택하고 제목, 설명, 날짜 등을 입력해서 서버에 업로드하는 페이지
class PhotoUploadPage extends StatefulWidget {
  const PhotoUploadPage({super.key});

  @override
  State<PhotoUploadPage> createState() => _PhotoUploadPageState();
}

class _PhotoUploadPageState extends State<PhotoUploadPage> {
  // 📊 상태 변수들
  /// 사용자가 선택한 이미지 파일들 리스트
  final List<XFile> _selectedImages = [];

  /// 이미지 선택을 위한 ImagePicker 인스턴스
  final picker = ImagePicker();

  /// 사진 제목 입력 컨트롤러
  final TextEditingController _titleController = TextEditingController();

  /// 사진 설명 입력 컨트롤러
  final TextEditingController _descriptionController = TextEditingController();

  /// 선택된 사진 날짜 (기본값: 현재 날짜)
  DateTime? _selectedDate = DateTime.now();

  /// 사진 카테고리 (현재 고정값)
  String _selectedCategory = '사진 앨범';

  /// 📷 갤러리에서 여러 이미지를 선택하는 함수
  Future<void> _pickImages() async {
    // 갤러리에서 여러 이미지 선택 (품질 80%로 압축)
    final picked = await picker.pickMultiImage(imageQuality: 80);

    if (picked != null) {
      setState(() {
        _selectedImages.addAll(picked); // 선택된 이미지들을 리스트에 추가
      });
    }
  }

  /// 🗑️ 선택된 이미지를 제거하는 함수
  /// [index] 제거할 이미지의 인덱스
  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index); // 해당 인덱스의 이미지 제거
    });
  }

  /// 📅 날짜 선택 다이얼로그를 표시하는 함수
  void _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(), // 초기 날짜
      firstDate: DateTime(2000), // 선택 가능한 최소 날짜
      lastDate: DateTime(2100),  // 선택 가능한 최대 날짜
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked; // 선택된 날짜 저장
      });
    }
  }

  /// 📅 날짜 선택 함수 (중복 - 실제로는 사용되지 않음)
  /// ⚠️ 주의: 이 함수는 위의 _selectDate와 동일한 기능의 중복 함수입니다
  void _selectdDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  /// 📤 서버에 사진을 업로드하는 함수
  void _uploadToServer() async {
    if (_selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("사진을 선택해주세요.")));
      return;
    }

    // 🔑 SharedPreferences에서 auth_key_id 가져오기
    final prefs = await SharedPreferences.getInstance();
    final authKeyId = prefs.getString('authKeyId');

    if (authKeyId == null || authKeyId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("인증 정보가 없습니다.")));
      return;
    }

    final uri = Uri.parse('http://192.168.219.68:8086/photo/upload');
    final request = http.MultipartRequest('POST', uri);

    // 📎 이미지 파일 추가 (멀티 업로드)
    for (var i = 0; i < _selectedImages.length; i++) {
      final imageFile =
      await http.MultipartFile.fromPath('file', _selectedImages[i].path);
      request.files.add(imageFile);
    }

    // 📋 요청 필드 추가
    request.fields['authKeyId'] = authKeyId;
    request.fields['title'] = _titleController.text;
    request.fields['description'] = _descriptionController.text;
    request.fields['photo_date'] =
    _selectedDate!.toIso8601String().split('T')[0];

    try {
      final response = await request.send();

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("✅ 업로드 성공")));
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("❌ 업로드 실패: ${response.statusCode}")));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ 서버 오류: $e")));
    }
  }


  /// 🎨 메인 UI 빌드 함수
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F6FF), // 연보라 배경색
      body: SafeArea(
        child: Column(
          children: [
            // 🎯 상단 고정 헤더 영역 (그라데이션 배경)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 40),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF8B7ED8), // 위쪽 보라색
                    Color(0xFFA994E6), // 아래쪽 연보라색
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, // 왼쪽 정렬
                children: [
                  // 🔙 뒤로가기 버튼
                  Padding(
                    padding: const EdgeInsets.only(left: 16),
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 📤 제목과 부제목
                  const Center(
                    child: Column(
                      children: [
                        Text(
                          '앨범 업로드',
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        SizedBox(height: 12),
                        Text(
                          '소중한 추억을 영원히 보관해요',
                          style: TextStyle(fontSize: 14, color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // 📜 스크롤 가능한 컨텐츠 영역
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
                child: _buildFormContent(), // 폼 컨텐츠 위젯 호출
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 📝 업로드 폼 컨텐츠를 구성하는 위젯 함수
  Widget _buildFormContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 📷 사진 선택 섹션
        const Text('사진 선택',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF6B4FBB))),
        const SizedBox(height: 12),

        // 🔲 점선 테두리 사진 선택 영역
        GestureDetector(
          onTap: _pickImages, // 탭 시 이미지 선택 함수 호출
          child: DottedBorder(
            color: const Color(0xFFBB9DF7), // 점선 색상
            borderType: BorderType.RRect,
            radius: const Radius.circular(16),
            dashPattern: [8, 4], // 점선 패턴 (8px 선, 4px 공백)
            strokeWidth: 2,
            child: Container(
              height: 228,
              width: double.infinity,
              alignment: Alignment.center,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 📷 카메라 아이콘 이미지
                  Image.asset(
                    'asset/image/solar_camera-bold.png',
                    width: 67,
                    height: 67,
                    color: const Color(0xFF8B7ED8),
                  ),
                  const SizedBox(height: 10),
                  // 📝 안내 텍스트
                  Text(
                    '사진을 선택해주세요',
                    style: TextStyle(fontSize: 15, color: Colors.grey[600], fontWeight: FontWeight.w500),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  // 📄 지원 파일 형식 안내
                  Text(
                    'JPG, PNG 파일',
                    style: TextStyle(fontSize: 13, color: Colors.grey[400]),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  // 🔘 파일 선택 버튼
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF8B7ED8),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      '파일 선택',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),

        // 👀 선택된 이미지들의 미리보기 섹션 (이미지가 있을 때만 표시)
        if (_selectedImages.isNotEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('미리보기',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF6B4FBB))),
              const SizedBox(height: 12),

              // 🖼️ 선택된 이미지들을 격자 형태로 표시
              Wrap(
                spacing: 12, // 좌우 간격
                runSpacing: 12, // 상하 간격
                children: List.generate(_selectedImages.length, (index) {
                  return Stack(
                    children: [
                      // 📷 이미지 미리보기 컨테이너
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEDE4FF), // 배경색
                          borderRadius: BorderRadius.circular(12),
                          image: DecorationImage(
                            image: FileImage(File(_selectedImages[index].path)), // 선택된 이미지 파일
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      // ❌ 이미지 삭제 버튼 (우상단에 위치)
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => _removeImage(index), // 탭 시 해당 이미지 제거
                          child: const CircleAvatar(
                            backgroundColor: Colors.white,
                            radius: 12,
                            child: Icon(Icons.close, size: 16, color: Colors.black),
                          ),
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ],
          ),
        const SizedBox(height: 24),

        // 📝 사진 정보 입력 폼 컨테이너
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE0D9FA)), // 연보라 테두리
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 📎 섹션 제목
              const Text('📎 사진 정보',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF6B4FBB))),
              const SizedBox(height: 12),

              // 📝 제목 입력 필드
              const Text('제목',
                  style: TextStyle(color: Color(0xFF6B4FBB), fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFBB9DF7)),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    hintText: '사진 제목을 입력해주세요',
                    hintStyle: TextStyle(color: Colors.grey),
                    border: InputBorder.none, // 기본 테두리 제거
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 📅 사진 날짜 선택 필드
              const Text('사진 날짜',
                  style: TextStyle(color: Color(0xFF6B4FBB), fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              GestureDetector(
                onTap: _selectDate, // 탭 시 날짜 선택 다이얼로그 표시
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFBB9DF7)),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: AbsorbPointer( // 직접 입력 방지 (다이얼로그를 통해서만 선택)
                    child: TextFormField(
                      controller: TextEditingController(
                        // 선택된 날짜를 YYYY-MM-DD 형식으로 표시
                        text: _selectedDate != null ? _selectedDate!.toIso8601String().split('T')[0] : '',
                      ),
                      decoration: const InputDecoration(
                        hintText: '날짜를 선택해주세요',
                        suffixIcon: Icon(Icons.calendar_today, color: Color(0xFFBB9DF7)), // 달력 아이콘
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 📄 설명 입력 필드 (멀티라인)
              const Text('설명',
                  style: TextStyle(color: Color(0xFF6B4FBB), fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFBB9DF7)),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: TextField(
                  controller: _descriptionController,
                  maxLines: 4, // 4줄까지 입력 가능
                  decoration: const InputDecoration(
                    hintText: '이 사진에 담긴 추억이나 이야기를 자유롭게 적어주세요',
                    hintStyle: TextStyle(color: Colors.grey),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
        const SizedBox(height: 32),

        // 📤 업로드 버튼
        Center(
          child: ElevatedButton(
            onPressed: _uploadToServer, // 탭 시 서버 업로드 함수 호출
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFBB9DF7), // 보라색 배경
              minimumSize: const Size(300, 48), // 최소 크기 설정
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)), // 둥근 모서리
            ),
            child: const Text('업로드하기',
                style: TextStyle(fontSize: 16, color: Colors.white)),
          ),
        ),
      ],
    );
  }
}