import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dotted_border/dotted_border.dart';

class PhotoUploadPage extends StatefulWidget {
  const PhotoUploadPage({super.key});

  @override
  State<PhotoUploadPage> createState() => _PhotoUploadPageState();
}

class _PhotoUploadPageState extends State<PhotoUploadPage> {
  final List<XFile> _selectedImages = [];
  final picker = ImagePicker();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  DateTime? _selectedDate = DateTime.now();
  String _selectedCategory = '사진 앨범';

  Future<void> _pickImages() async {
    final picked = await picker.pickMultiImage(imageQuality: 80);
    if (picked != null) {
      setState(() {
        _selectedImages.addAll(picked);
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  void _selectDate() async {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F6FF),
      body: SafeArea(
        child: Column(
          children: [
            // ✅ 상단 고정 영역
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 60),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF8B7ED8), // 위쪽 색
                    Color(0xFFA994E6), // 아래쪽 색
                  ],
                ),
              ),

              child: Column(
                children: const [
                  Text(
                    '앨범 업로드',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '소중한 추억을 영원히 보관해요',
                    style: TextStyle(fontSize: 14, color: Colors.white70),
                  ),
                ],
              ),
            ),
            // ✅ 스크롤 가능한 영역
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
                child: _buildFormContent(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('사진 선택', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF6B4FBB))),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: _pickImages,
          child: DottedBorder(
            color: const Color(0xFFBB9DF7),
            borderType: BorderType.RRect,
            radius: const Radius.circular(16),
            dashPattern: [8, 4],
            strokeWidth: 2,
            child: Container(
              height: 228,
              width: double.infinity,
              alignment: Alignment.center,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'asset/image/solar_camera-bold.png',
                    width: 67,
                    height: 67,
                    color: const Color(0xFF8B7ED8),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '유품 사진을 선택해주세요',
                    style: TextStyle(fontSize: 15, color: Colors.grey[600], fontWeight: FontWeight.w500),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'JPG, PNG 파일',
                    style: TextStyle(fontSize: 13, color: Colors.grey[400]),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
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
        if (_selectedImages.isNotEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('미리보기', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF6B4FBB))),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: List.generate(_selectedImages.length, (index) {
                  return Stack(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEDE4FF),
                          borderRadius: BorderRadius.circular(12),
                          image: DecorationImage(
                            image: FileImage(File(_selectedImages[index].path)),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => _removeImage(index),
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
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE0D9FA)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('📎 사진 정보', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF6B4FBB))),
              const SizedBox(height: 12),
              const Text('제목', style: TextStyle(color: Color(0xFF6B4FBB), fontWeight: FontWeight.w600)),
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
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text('사진 날짜', style: TextStyle(color: Color(0xFF6B4FBB), fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              GestureDetector(
                onTap: _selectDate,
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFBB9DF7)),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: AbsorbPointer(
                    child: TextFormField(
                      controller: TextEditingController(
                        text: _selectedDate != null ? _selectedDate!.toIso8601String().split('T')[0] : '',
                      ),
                      decoration: const InputDecoration(
                        hintText: '날짜를 선택해주세요',
                        suffixIcon: Icon(Icons.calendar_today, color: Color(0xFFBB9DF7)),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text('설명', style: TextStyle(color: Color(0xFF6B4FBB), fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFBB9DF7)),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: TextField(
                  controller: _descriptionController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    hintText: '이 사진에 담긴 추억이나 이야기를 자유롭게 적어주세요',
                    hintStyle: TextStyle(color: Colors.grey),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text('카테고리', style: TextStyle(color: Color(0xFF6B4FBB), fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _selectedCategory = '사진 앨범';
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _selectedCategory == '사진 앨범' ? const Color(0xFFBB9DF7) : const Color(0xFFEDE4FF),
                      ),
                      child: Text(
                        '사진 앨범',
                        style: TextStyle(
                          color: _selectedCategory == '사진 앨범' ? Colors.white : const Color(0xFFBB9DF7),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _selectedCategory = '유품 기록';
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _selectedCategory == '유품 기록' ? const Color(0xFFBB9DF7) : const Color(0xFFEDE4FF),
                      ),
                      child: Text(
                        '유품 기록',
                        style: TextStyle(
                          color: _selectedCategory == '유품 기록' ? Colors.white : const Color(0xFFBB9DF7),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        Center(
          child: ElevatedButton(
            onPressed: () {
              // 업로드 처리
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFBB9DF7),
              minimumSize: const Size(300, 48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            ),
            child: const Text('업로드하기', style: TextStyle(fontSize: 16, color: Colors.white)),
          ),
        ),
      ],
    );
  }
}
