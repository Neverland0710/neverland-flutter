import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:dotted_border/dotted_border.dart';

class AddKeepsakeScreen extends StatefulWidget {
  @override
  _AddKeepsakeScreenState createState() => _AddKeepsakeScreenState();
}

class _AddKeepsakeScreenState extends State<AddKeepsakeScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _periodController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _storyController = TextEditingController();
  final TextEditingController _valueController = TextEditingController();

  List<File> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _titleController.dispose();
    _periodController.dispose();
    _descriptionController.dispose();
    _storyController.dispose();
    _valueController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final List<XFile>? images = await _picker.pickMultiImage();
    if (images != null) {
      setState(() {
        _selectedImages = images.map((image) => File(image.path)).toList();
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  void _submitKeepsake() {
    if (_titleController.text.isEmpty || _descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('필수 항목을 입력해주세요'),
          backgroundColor: Colors.red[400],
        ),
      );
      return;
    }

    // TODO: 실제 데이터 저장 로직 구현
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('유품이 성공적으로 등록되었습니다'),
        backgroundColor: Color(0xFF8B7ED8),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPhotoUploadSection(),
                    SizedBox(height: 30),
                    _buildImagePreviewSection(),
                    SizedBox(height: 30),
                    _buildInfoSection(),
                    SizedBox(height: 40),
                    _buildStorySection(),
                    SizedBox(height: 40),
                    _buildSubmitButton(),
                    SizedBox(height: 30), // 하단 여유 공간
                  ],
                ),
              ),
            ),
          ],
        ),
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
            Text('기록 업로드', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('소중한 추억을 영원히 보관해요', style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 16)),
            SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoUploadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('사진 선택'),
        SizedBox(height: 16),
        GestureDetector(
          onTap: _pickImage,
          child: DottedBorder(
            color: Color(0xFF8B7ED8),
            strokeWidth: 2,
            dashPattern: [8, 4], // 점선 패턴 (선 길이, 간격)
            borderType: BorderType.RRect,
            radius: Radius.circular(12),
            child: Container(
              width: double.infinity,
              height: 228,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.white,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'asset/image/solar_camera-bold.png',
                    width: 67,
                    height: 67,
                    color: Color(0xFF8B7ED8),
                  ),
                  SizedBox(height: 10),
                  Text('유품 사진을 선택해주세요', style: TextStyle(fontSize: 15, color: Colors.grey[600])),
                  SizedBox(height: 4),
                  Text('JPG, PNG 파일', style: TextStyle(fontSize: 13, color: Colors.grey[400])),
                  SizedBox(height: 12),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                    decoration: BoxDecoration(color: Color(0xFF8B7ED8), borderRadius: BorderRadius.circular(8)),
                    child: Text('파일 선택', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImagePreviewSection() {
    if (_selectedImages.isEmpty) return SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('미리보기'),
        SizedBox(height: 15),
        Container(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _selectedImages.length,
            itemBuilder: (context, index) {
              return Container(
                width: 120,
                height: 120,
                margin: EdgeInsets.only(right: 10),
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: Color(0xFFE6E0F8)),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(_selectedImages[index], width: 120, height: 120, fit: BoxFit.cover),
                    ),
                    Positioned(
                      top: 5,
                      right: 5,
                      child: GestureDetector(
                        onTap: () => _removeImage(index),
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                          child: Icon(Icons.close, color: Colors.white, size: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildInfoSection() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Color(0xFFE6E0F8)), // 연보라색 테두리
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('유품 정보'),
          SizedBox(height: 20),
          _buildOutlinedInputField('유품 이름', '사진 제목을 입력해주세요', _titleController),
          SizedBox(height: 20),
          _buildOutlinedInputField('구입/제작시기', '예 : 1984년 구입, 1960년대', _periodController),
          SizedBox(height: 20),
          _buildOutlinedInputField('유품 설명', '유품의 외관, 특징, 재질 등을 자세히 설명해주세요', _descriptionController, maxLines: 4),
          SizedBox(height: 20),
          _buildOutlinedInputField('추정 가치 (선택사항)', '숫자만 입력', _valueController, suffix: '원'),
        ],
      ),
    );
  }

  Widget _buildOutlinedInputField(String label, String hint, TextEditingController controller,
      {int maxLines = 1, String? suffix}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF7E6BE0), // 연보라색
          ),
        ),
        SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: suffix != null ? TextInputType.number : TextInputType.text,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
            filled: true,
            fillColor: Colors.white,
            suffixText: suffix,
            suffixStyle: TextStyle(color: Color(0xFF7E6BE0), fontWeight: FontWeight.w600),
            contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Color(0xFFD8CCF1)),
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Color(0xFFB5A8F0), width: 1.5),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          style: TextStyle(fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildStorySection() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Color(0xFFFAFBFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Color(0xFFE6E0F8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('특별한 이야기 (선택사항)'),
          SizedBox(height: 20),

          // 이야기 예시 전체 박스
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Color(0xFFFFFFFF),
              borderRadius: BorderRadius.circular(12),
              border: Border(
                left: BorderSide(color: Color(0xFFA688FA), width: 3), // 💜 왼쪽에만 stroke
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '이야기 예시',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF7E6BE0),
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  '"할머니께서 항상 이 반지를 끼고 계셨어요. 할아버지가 프로포즈할 때 주신 거래요..."\n'
                      '"아버지의 서재에서 가장 소중히 여기셨던 책입니다. 밑줄과 메모가 가득해요..."\n'
                      '"명절 때마다 이 한복을 입고 차례를 지내셨던 어머니의 모습이 떠올라요..."',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[800],
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 20),

          // 자유 입력 텍스트 영역
          _buildOutlinedTextArea(
            hint: '이 유품과 관련된 특별한 추억, 고인의 말씀, 사용하셨던 모습 등을 자유롭게 적어주세요',
            controller: _storyController,
          ),
        ],
      ),
    );
  }

  Widget _buildOutlinedTextArea({required String hint, required TextEditingController controller}) {
    return TextField(
      controller: controller,
      maxLines: 6,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
        filled: true,
        fillColor: Colors.white,
        contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Color(0xFFD8CCF1)),
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Color(0xFFB5A8F0), width: 1.5),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      style: TextStyle(fontSize: 14),
    );
  }


  Widget _buildInputField(String label, String hint, TextEditingController controller, {int maxLines = 1, String? suffix}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87)),
        SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: TextField(
            controller: controller,
            maxLines: maxLines,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(12),
              suffixText: suffix,
              suffixStyle: TextStyle(color: Colors.grey[600]),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _submitKeepsake,
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFF8B7ED8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
        child: Text('업로드하기', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(width: 4, height: 20, decoration: BoxDecoration(color: Color(0xFF8B7ED8), borderRadius: BorderRadius.circular(2))),
        SizedBox(width: 8),
        Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF6B4FBB))),
      ],
    );
  }
}