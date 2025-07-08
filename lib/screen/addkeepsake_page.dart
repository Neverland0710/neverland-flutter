import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:dotted_border/dotted_border.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:neverland_flutter/screen/keepsake_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 유품을 추가하는 화면
/// 사진 업로드, 유품 정보 입력, 특별한 이야기 입력 기능을 제공
class AddKeepsakeScreen extends StatefulWidget {
  @override
  _AddKeepsakeScreenState createState() => _AddKeepsakeScreenState();
}

class _AddKeepsakeScreenState extends State<AddKeepsakeScreen> {
  // 텍스트 입력 컨트롤러들 - 각 입력 필드의 값을 관리
  final TextEditingController _titleController = TextEditingController();        // 유품 이름
  final TextEditingController _periodController = TextEditingController();       // 구입/제작시기
  final TextEditingController _descriptionController = TextEditingController();  // 유품 설명
  final TextEditingController _storyController = TextEditingController();        // 특별한 이야기
  final TextEditingController _valueController = TextEditingController();        // 추정 가치

  // 이미지 관련 변수들
  List<File> _selectedImages = [];  // 선택된 이미지 파일들을 저장하는 리스트
  final ImagePicker _picker = ImagePicker();  // 이미지 선택을 위한 picker 인스턴스

  /// 위젯이 소멸될 때 메모리 누수 방지를 위해 컨트롤러들을 해제
  @override
  void dispose() {
    _titleController.dispose();
    _periodController.dispose();
    _descriptionController.dispose();
    _storyController.dispose();
    _valueController.dispose();
    super.dispose();
  }

  /// 갤러리에서 여러 이미지를 선택하는 함수
  Future<void> _pickImage() async {
    // 여러 이미지를 선택할 수 있는 picker 호출
    final List<XFile>? images = await _picker.pickMultiImage();
    if (images != null) {
      setState(() {
        // XFile을 File로 변환하여 _selectedImages 리스트에 저장
        _selectedImages = images.map((image) => File(image.path)).toList();
      });
    }
  }

  /// 선택된 이미지를 삭제하는 함수
  /// @param index 삭제할 이미지의 인덱스
  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  /// 유품 정보를 서버에 업로드하는 메인 함수
  /// 유품 업로드를 처리하는 메인 함수
  /// 1. 필수 입력 검증 → 2. 이미지 업로드 → 3. 유품 정보 업로드 → 4. 업로드 완료 시 이전 화면으로 복귀
  void _submitKeepsake() async {
    // ✅ 1. 필수 항목(제목, 설명) 입력 여부 확인
    if (_titleController.text.isEmpty || _descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('필수 항목을 입력해주세요'),  // 에러 메시지
          backgroundColor: Colors.red[400],
        ),
      );
      return; // 필수 항목 미입력 시 종료
    }

    // ✅ [추가] 추정 가치 유효성 검사
    final valueText = _valueController.text.trim();
    if (valueText.isNotEmpty && !RegExp(r'^\d+$').hasMatch(valueText)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('추정 가치는 숫자만 입력해주세요'),
          backgroundColor: Colors.red[400],
        ),
      );
      return;
    }


    // ✅ 2. 업로드된 이미지 URL들을 저장할 리스트 생성
    List<String> uploadedImageUrls = [];

    // ✅ 3. 선택된 이미지들을 반복하며 서버에 업로드
    for (var image in _selectedImages) {
      final url = await _uploadImageToServer(image); // 서버 업로드 시도
      if (url != null) {
        uploadedImageUrls.add(url); // 성공 시 URL 저장
      } else {
        // 실패 시 에러 표시하고 함수 종료
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('이미지 업로드 실패'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    // ✅ 5. 모든 업로드가 성공하면 이전 화면으로 돌아가기
    if (mounted) {
      Navigator.pop(context, true); // 업로드 완료 후 결과 true 전달하며 pop
      print('✅ 유품 업로드 완료');
    }
  }


  /// 메인 화면 구성
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,  // 키보드가 올라올 때 화면 크기 조정
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),  // 상단 헤더 영역
            Expanded(
              child: SingleChildScrollView(  // 스크롤 가능한 본문 영역
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPhotoUploadSection(),    // 사진 업로드 섹션
                    SizedBox(height: 30),
                    _buildImagePreviewSection(),   // 이미지 미리보기 섹션
                    SizedBox(height: 30),
                    _buildInfoSection(),           // 유품 정보 입력 섹션
                    SizedBox(height: 40),
                    _buildStorySection(),          // 특별한 이야기 입력 섹션
                    SizedBox(height: 40),
                    _buildSubmitButton(),          // 업로드 버튼
                    SizedBox(height: 30),          // 하단 여유 공간
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 상단 헤더 영역 구성
  /// 그라데이션 배경과 제목, 뒤로가기 버튼 포함
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF8B7ED8), Color(0xFFA994E6)],  // 보라색 그라데이션
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // 뒤로가기 버튼 행
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: 8.0, top: 8.0),
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(
                    Icons.arrow_back, // 👈 둘 다 같은 아이콘
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ),
            SizedBox(height: 25),
            // 제목 텍스트
            Transform.translate(
              offset: Offset(0, -10), // 👈 Y축 -10 = 위로 10픽셀
              child: Text(
                '유품 업로드',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            SizedBox(height: 8),
            // 부제목 텍스트
            Transform.translate(
              offset: Offset(0, -10), // 👈 Y축으로 10픽셀 위로 올림
              child: Text(
                '소중한 추억을 영원히 보관해요',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 16,
                ),
              ),
            ),

            SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  /// 사진 업로드 섹션 구성
  /// 점선 테두리의 업로드 영역과 안내 텍스트 포함
  Widget _buildPhotoUploadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('사진 선택'),  // 섹션 제목
        SizedBox(height: 16),
        GestureDetector(
          onTap: _pickImage,  // 탭하면 이미지 선택 함수 호출
          child: DottedBorder(
            color: Color(0xFF8B7ED8),    // 점선 색상
            strokeWidth: 2,              // 점선 두께
            dashPattern: [8, 4],         // 점선 패턴 (8px 선, 4px 공백)
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
                  // 카메라 아이콘
                  Image.asset(
                    'asset/image/solar_camera-bold.png',
                    width: 67,
                    height: 67,
                    color: Color(0xFF8B7ED8),
                  ),
                  SizedBox(height: 10),
                  // 안내 텍스트들
                  Text('유품 사진을 선택해주세요',
                      style: TextStyle(fontSize: 15, color: Colors.grey[600])),
                  SizedBox(height: 4),
                  Text('JPG, PNG 파일',
                      style: TextStyle(fontSize: 13, color: Colors.grey[400])),
                  SizedBox(height: 12),
                  // 파일 선택 버튼
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                    decoration: BoxDecoration(
                        color: Color(0xFF8B7ED8),
                        borderRadius: BorderRadius.circular(8)
                    ),
                    child: Text('파일 선택',
                        style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// 서버에 이미지를 업로드하는 함수
  /// @param imageFile 업로드할 이미지 파일
  /// @return 업로드 성공 시 문자열, 실패 시 null
  /// 이미지 파일을 서버에 업로드하고, 유품 정보도 함께 전송하는 함수
  /// @param imageFile 업로드할 로컬 이미지 파일
  /// @return 성공 시 '성공' 문자열 반환, 실패 시 null 반환
  Future<String?> _uploadImageToServer(File imageFile) async {
    // ✅ SharedPreferences에서 authKeyId 가져오기
    final prefs = await SharedPreferences.getInstance();
    final authKeyId = prefs.getString('authKeyId');

    if (authKeyId == null || authKeyId.isEmpty) {
      print('❌ auth_key_id 가 없습니다.');
      return null;
    }

    final uri = Uri.parse('http://52.78.139.47:8086/keepsake/upload');
    final request = http.MultipartRequest('POST', uri);

    // ✅ 텍스트 데이터 설정
    request.fields['authKeyId'] = authKeyId;
    request.fields['item_name'] = _titleController.text;
    request.fields['description'] = _descriptionController.text;
    request.fields['acquisition_period'] = _periodController.text;
    request.fields['special_story'] = _storyController.text;
    request.fields['estimated_value'] =
    _valueController.text.isNotEmpty ? _valueController.text : '0';

    // ✅ 이미지 파일 첨부
    request.files.add(await http.MultipartFile.fromPath('file', imageFile.path));

    // ✅ 전송
    final response = await request.send();

    if (response.statusCode == 200) {
      print('✅ 업로드 성공');
      return '성공';
    } else {
      print('❌ 업로드 실패: ${response.statusCode}');
      return null;
    }
  }

  /// 선택된 이미지들의 미리보기 섹션
  /// 이미지가 없으면 빈 위젯 반환
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
            scrollDirection: Axis.horizontal,  // 가로 스크롤
            itemCount: _selectedImages.length,
            itemBuilder: (context, index) {
              return Container(
                width: 120,
                height: 120,
                margin: EdgeInsets.only(right: 10),
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Color(0xFFE6E0F8)  // 연보라색 배경
                ),
                child: Stack(
                  children: [
                    // 이미지 표시
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                          _selectedImages[index],
                          width: 120,
                          height: 120,
                          fit: BoxFit.cover
                      ),
                    ),
                    // 삭제 버튼 (오른쪽 상단)
                    Positioned(
                      top: 5,
                      right: 5,
                      child: GestureDetector(
                        onTap: () => _removeImage(index),  // 이미지 삭제
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle
                          ),
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

  /// 유품 정보 입력 섹션
  /// 유품 이름, 구입/제작시기, 설명, 추정 가치 입력 필드들 포함
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
          // 각 입력 필드들
          _buildOutlinedInputField('유품 이름', '사진 제목을 입력해주세요', _titleController),
          SizedBox(height: 20),
          _buildOutlinedInputField('구입/제작시기', '예 : 1984년 구입, 1960년대', _periodController),
          SizedBox(height: 20),
          _buildOutlinedInputField('유품 설명', '유품의 외관, 특징, 재질 등을 자세히 설명해주세요', _descriptionController, maxLines: 4),
          SizedBox(height: 20),
          _buildOutlinedInputField('추정 가치 (선택사항)', 'ex) 10000', _valueController, suffix: '원'),
        ],
      ),
    );
  }

  /// 테두리가 있는 입력 필드 생성
  /// @param label 필드 라벨
  /// @param hint 힌트 텍스트
  /// @param controller 텍스트 컨트롤러
  /// @param maxLines 최대 줄 수 (기본값: 1)
  /// @param suffix 접미사 텍스트 (예: "원")
  Widget _buildOutlinedInputField(String label, String hint, TextEditingController controller,
      {int maxLines = 1, String? suffix}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 필드 라벨
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF7E6BE0), // 연보라색
          ),
        ),
        SizedBox(height: 8),
        // 텍스트 입력 필드
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: suffix != null ? TextInputType.number : TextInputType.text,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
            filled: true,
            fillColor: Colors.white,
            suffixText: suffix,  // 접미사 텍스트 (예: "원")
            suffixStyle: TextStyle(color: Color(0xFF7E6BE0), fontWeight: FontWeight.w600),
            contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            // 테두리 스타일
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

  /// 특별한 이야기 입력 섹션
  /// 예시 텍스트와 자유 입력 영역 포함
  Widget _buildStorySection() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Color(0xFFFAFBFF),  // 매우 연한 배경색
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Color(0xFFE6E0F8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('특별한 이야기 (선택사항)'),
          SizedBox(height: 20),

          // 이야기 예시 박스
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Color(0xFFFFFFFF),
              borderRadius: BorderRadius.circular(12),
              border: Border(
                left: BorderSide(color: Color(0xFFA688FA), width: 3), // 왼쪽에만 보라색 테두리
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 예시 제목
                Text(
                  '이야기 예시',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF7E6BE0),
                  ),
                ),
                SizedBox(height: 8),
                // 예시 내용
                Text(
                  '"할머니께서 항상 이 반지를 끼고 계셨어요. 할아버지가 프로포즈할 때 주신 거래요..."\n'
                      '"아버지의 서재에서 가장 소중히 여기셨던 책입니다. 밑줄과 메모가 가득해요..."\n'
                      '"명절 때마다 이 한복을 입고 차례를 지내셨던 어머니의 모습이 떠올라요..."',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[800],
                    height: 1.5,  // 줄 간격
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

  /// 여러 줄 텍스트 입력 영역 생성
  /// @param hint 힌트 텍스트
  /// @param controller 텍스트 컨트롤러
  Widget _buildOutlinedTextArea({required String hint, required TextEditingController controller}) {
    return TextField(
      controller: controller,
      maxLines: 6,  // 6줄 입력 가능
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
        filled: true,
        fillColor: Colors.white,
        contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        // 테두리 스타일
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

  /// 기본 입력 필드 생성 (현재 사용되지 않음)
  /// @param label 필드 라벨
  /// @param hint 힌트 텍스트
  /// @param controller 텍스트 컨트롤러
  /// @param maxLines 최대 줄 수
  /// @param suffix 접미사 텍스트
  Widget _buildInputField(String label, String hint, TextEditingController controller,
      {int maxLines = 1, String? suffix}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87)),
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

  /// 업로드 버튼 생성
  Widget _buildSubmitButton() {
    return Container(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _submitKeepsake,  // 업로드 함수 호출
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFF8B7ED8),  // 보라색 배경
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,  // 그림자 제거
        ),
        child: Text('업로드하기',
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }

  /// 섹션 제목 생성 (왼쪽에 보라색 바와 함께)
  /// @param title 섹션 제목 텍스트
  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        // 왼쪽 보라색 바
        Container(
            width: 4,
            height: 20,
            decoration: BoxDecoration(
                color: Color(0xFF8B7ED8),
                borderRadius: BorderRadius.circular(2)
            )
        ),
        SizedBox(width: 8),
        // 제목 텍스트
        Text(title,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF6B4FBB))),
      ],
    );
  }
}