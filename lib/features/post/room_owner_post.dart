// features/post/room_owner_post.dart
import 'dart:convert';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:roommate/constants/gaps.dart';
import 'package:roommate/constants/sizes.dart';
import 'package:roommate/features/post/widgets/form_button.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RoomOwnerPost extends StatefulWidget {
  const RoomOwnerPost({super.key});

  @override
  State<RoomOwnerPost> createState() => _RoomOwnerPostState();
}

class _RoomOwnerPostState extends State<RoomOwnerPost> {
  // ───────────────── controllers ─────────────────
  final TextEditingController _titleCtrl = TextEditingController();
  final TextEditingController _addrCtrl = TextEditingController();
  final TextEditingController _depositCtrl = TextEditingController();
  final TextEditingController _rentCtrl = TextEditingController();
  final TextEditingController _manageFeeCtrl = TextEditingController();
  final TextEditingController _corFloorCtrl = TextEditingController();
  final TextEditingController _wholeFloorCtrl = TextEditingController();
  final TextEditingController _areaCtrl = TextEditingController();
  final TextEditingController _toiletCtrl = TextEditingController();
  final TextEditingController _movingDateCtrl = TextEditingController();
  final TextEditingController _minContractCtrl = TextEditingController();
  final TextEditingController _maxContractCtrl = TextEditingController();
  final TextEditingController _introductionCtrl = TextEditingController();

  // ───────────────── external services ─────────────────
  final supabase = Supabase.instance.client;
  final ImagePicker _picker = ImagePicker();
  final String _apiKey = "devU01TX0FVVEgyMDI1MDkxMTE3MzcyNzExNjE3NjI=";

  // Supabase Storage (✅ 버킷명 일원화)
  static const String _bucket = 'RoomMate-image';
  final List<XFile> _pickedImages = [];
  bool _uploadingImages = false;

  // UI state
  List<dynamic> _addresses = [];
  bool _isLoading = false;
  bool _isPosting = false;
  String _errorMessage = '';

  // ───────────────── lifecycle ─────────────────
  @override
  void initState() {
    super.initState();
    for (final c in [
      _titleCtrl,
      _addrCtrl,
      _depositCtrl,
      _rentCtrl,
      _manageFeeCtrl,
      _corFloorCtrl,
      _wholeFloorCtrl,
      _areaCtrl,
      _toiletCtrl,
      _movingDateCtrl,
      _minContractCtrl,
      _maxContractCtrl,
      _introductionCtrl,
    ]) {
      c.addListener(() {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _addrCtrl.dispose();
    _depositCtrl.dispose();
    _rentCtrl.dispose();
    _manageFeeCtrl.dispose();
    _corFloorCtrl.dispose();
    _wholeFloorCtrl.dispose();
    _areaCtrl.dispose();
    _toiletCtrl.dispose();
    _movingDateCtrl.dispose();
    _minContractCtrl.dispose();
    _maxContractCtrl.dispose();
    _introductionCtrl.dispose();
    super.dispose();
  }

  // ───────────────── image pick / upload ─────────────────
  Future<void> _pickImages() async {
    final files = await _picker.pickMultiImage(imageQuality: 85);
    if (files.isNotEmpty) {
      setState(() => _pickedImages.addAll(files));
    }
  }

  void _removeImageAt(int index) {
    setState(() => _pickedImages.removeAt(index));
  }

  void _log(Object o) => debugPrint('[RoomOwnerPosts] $o');

  /// Supabase(Private 버킷)에 업로드 후, Storage 경로 리스트 반환
  Future<List<String>> _uploadAllImagesToSupabase({
    required String uid,
    required String postId,
  }) async {
    setState(() => _uploadingImages = true);
    final paths = <String>[];
    try {
      for (int i = 0; i < _pickedImages.length; i++) {
        final xf = _pickedImages[i];
        _log('upload start: ${xf.path}');
        final ext = xf.path.split('.').last.toLowerCase();
        final filename = '${DateTime.now().millisecondsSinceEpoch}-$i.$ext';
        final storagePath = 'roomOwnerPosts/$uid/$postId/$filename';

        // bytes 업로드 (경로/권한 이슈 최소화)
        final bytes = await xf.readAsBytes();
        await supabase.storage
            .from(_bucket)
            .uploadBinary(
              storagePath,
              bytes,
              fileOptions: FileOptions(
                cacheControl: '3600',
                upsert: false,
                contentType: _guessMimeType(ext),
              ),
            );

        _log('upload done: $storagePath');
        paths.add(storagePath);
      }
      return paths;
    } catch (e, st) {
      _log('upload error: $e\n$st');
      rethrow;
    } finally {
      if (mounted) setState(() => _uploadingImages = false);
    }
  }

  String _guessMimeType(String ext) {
    switch (ext) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'heic':
        return 'image/heic';
      case 'jpg':
      case 'jpeg':
      default:
        return 'image/jpeg';
    }
  }

  // ───────────────── address search ─────────────────
  Future<void> _searchAddress(String keyword) async {
    if (keyword.isEmpty) {
      setState(() {
        _errorMessage = '검색어를 입력해주세요.';
        _addresses = [];
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    final url = Uri.https('www.juso.go.kr', '/addrlink/addrLinkApi.do', {
      'confmKey': _apiKey,
      'currentPage': '1',
      'countPerPage': '20',
      'keyword': keyword,
      'resultType': 'json',
    });

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final decodedData = jsonDecode(response.body);
        if (decodedData['results'] != null &&
            decodedData['results']['juso'] != null) {
          setState(() {
            _addresses = decodedData['results']['juso'];
            if (_addresses.isEmpty) _errorMessage = '검색 결과가 없습니다.';
          });
        } else {
          final commonData = decodedData['results']['common'];
          setState(() {
            _errorMessage = commonData['errorMessage'] ?? '알 수 없는 오류가 발생했습니다.';
            _addresses = [];
          });
        }
      } else {
        setState(() {
          _errorMessage = 'API 서버 오류: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = '데이터 요청 중 오류가 발생했습니다: $e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ───────────────── small utils ─────────────────
  void _onScaffoldTap(BuildContext context) => FocusScope.of(context).unfocus();

  void _onTimePickerChanged(DateTime date) {
    _movingDateCtrl.text =
        "${date.year.toString()}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  void _onTimeFieldTap() async {
    await showModalBottomSheet(
      context: context,
      builder: (context) => CupertinoDatePicker(
        mode: CupertinoDatePickerMode.date,
        onDateTimeChanged: _onTimePickerChanged,
        minimumDate: DateTime.now(),
        initialDateTime: DateTime.now(),
      ),
    );
  }

  bool _isNextAvailable() {
    return _titleCtrl.text.isNotEmpty &&
        _addrCtrl.text.isNotEmpty &&
        _depositCtrl.text.isNotEmpty &&
        _rentCtrl.text.isNotEmpty &&
        _manageFeeCtrl.text.isNotEmpty &&
        _corFloorCtrl.text.isNotEmpty &&
        _wholeFloorCtrl.text.isNotEmpty &&
        _areaCtrl.text.isNotEmpty &&
        _toiletCtrl.text.isNotEmpty &&
        _movingDateCtrl.text.isNotEmpty &&
        _minContractCtrl.text.isNotEmpty &&
        _maxContractCtrl.text.isNotEmpty &&
        _introductionCtrl.text.isNotEmpty;
  }

  Map<String, dynamic> _buildPayload() {
    return {
      'postType': 'roomOwner', // ✅ 리스트 필터와 맞추기
      'title': _titleCtrl.text,
      'addressLabel': _addrCtrl.text, // ✅ 카드에서 쓰는 키
      'address': _addrCtrl.text, // (선택) 기존 키 유지해도 무방
      'deposit': int.tryParse(_depositCtrl.text) ?? 0,
      'rent': int.tryParse(_rentCtrl.text) ?? 0,
      'manageFee': int.tryParse(_manageFeeCtrl.text) ?? 0,
      'corFloor': int.tryParse(_corFloorCtrl.text) ?? 0,
      'wholeFloor': int.tryParse(_wholeFloorCtrl.text) ?? 0,
      'area': int.tryParse(_areaCtrl.text) ?? 0,
      'toilet': int.tryParse(_toiletCtrl.text) ?? 0,
      'minContract': int.tryParse(_minContractCtrl.text) ?? 0,
      'maxContract': int.tryParse(_maxContractCtrl.text) ?? 0,
      'introduction': _introductionCtrl.text,
      'movingDate': _movingDateCtrl.text.isEmpty
          ? null
          : Timestamp.fromDate(DateTime.parse(_movingDateCtrl.text)),
      'updatedAt': DateTime.now().toIso8601String(),
    };
  }

  // ───────────────── submit ─────────────────
  Future<void> _onNextTap() async {
    if (!_isNextAvailable() || _isPosting) return;

    try {
      setState(() => _isPosting = true);

      // 0) 앱/프로젝트 정보
      _log('Firebase projectId=${Firebase.app().options.projectId}');

      // 1) 로그인 상태
      final auth = FirebaseAuth.instance;
      final user = auth.currentUser ?? (await auth.signInAnonymously()).user!;
      final uid = user.uid;
      _log('auth uid=$uid isAnon=${user.isAnonymous}');

      // 2) payload 구성
      final built = _buildPayload();
      final basePayload = {
        ...built,
        'authorId': uid,
        'imageUrls': <String>[],
        'createdAt': FieldValue.serverTimestamp(),
      };

      // 2-1) 핵심 필드 타입/값 로그
      _log('payload keys=${basePayload.keys.toList()}');
      _log('authorId=${basePayload['authorId']}');
      _log('createdAtType=${basePayload['createdAt']?.runtimeType}');
      _log(
        'movingDate=${basePayload['movingDate']} (type=${basePayload['movingDate']?.runtimeType})',
      );
      _log('addr(field in payload?)=${basePayload.containsKey('addr')}');
      _log('address(string)=${basePayload['address']}');
      _log(
        'updatedAt=${basePayload['updatedAt']} (type=${basePayload['updatedAt']?.runtimeType})',
      );

      // 3) 쓰기
      final col = FirebaseFirestore.instance.collection('roomOwnerPosts');
      _log('WRITE TO: ${col.path}');
      DocumentReference docRef;
      try {
        docRef = await col.add(basePayload);
        _log('create ok: docId=${docRef.id}');
      } on FirebaseException catch (e) {
        _log('CREATE FAIL code=${e.code} message=${e.message}');
        rethrow;
      }

      final postId = docRef.id;

      // 4) 이미지 업로드
      List<String> imagePaths = [];
      if (_pickedImages.isNotEmpty) {
        imagePaths = await _withTimeoutRetry<List<String>>(
          () => _uploadAllImagesToSupabase(uid: uid, postId: postId),
          timeoutSec: 25,
          retries: 2,
        );
        _log('uploaded ${imagePaths.length} images');
      }

      // 5) Firestore 업데이트(이미지 경로)
      if (imagePaths.isNotEmpty) {
        try {
          await docRef.update({
            'imageUrls': imagePaths,
            // 규칙상 필수는 아니지만, 관례상 updatedAt도 서버시간으로
            'updatedAt': FieldValue.serverTimestamp(),
          });
          _log('update ok (imageUrls)');
        } on FirebaseException catch (e) {
          _log('UPDATE FAIL code=${e.code} message=${e.message}');
          rethrow;
        }
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('글 포스팅 성공~')),
      );
      Navigator.of(context).pop();
    } catch (e, st) {
      _log('onNextTap error: $e\n$st');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('오류 발생~ $e')),
      );
    } finally {
      if (mounted) setState(() => _isPosting = false);
    }
  }

  // 간단 타임아웃 + 재시도
  Future<T> _withTimeoutRetry<T>(
    Future<T> Function() job, {
    int timeoutSec = 15,
    int retries = 1,
  }) async {
    int attempt = 0;
    while (true) {
      attempt++;
      try {
        return await job().timeout(Duration(seconds: timeoutSec));
      } catch (e) {
        if (attempt > retries) rethrow;
        await Future.delayed(const Duration(seconds: 1));
      }
    }
  }

  // ───────────────── UI ─────────────────
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _onScaffoldTap(context),
      child: Scaffold(
        appBar: AppBar(
          elevation: 10,
          title: Text('게시글 작성', style: TextStyle(fontSize: Sizes.size24)),
        ),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 제목
                Text(
                  '제목을 입력해주세요!',
                  style: TextStyle(
                    fontSize: Sizes.size16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Gaps.v6,
                TextField(
                  controller: _titleCtrl,
                  decoration: const InputDecoration(
                    hintText: '제목 입력',
                    border: OutlineInputBorder(),
                  ),
                ),
                Gaps.v24,

                // 주소 안내
                Text(
                  '주소를 입력해주세요!',
                  style: TextStyle(
                    fontSize: Sizes.size16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '다른 유저에게는 XX동 \'부근\'으로 보여져요. \n지도에는 실제 주소 반경 200m 내의 랜덤한 위치로 나타나요',
                  style: TextStyle(fontSize: Sizes.size14, color: Colors.grey),
                ),
                Gaps.v6,

                // 사진 업로드 섹션
                Text(
                  '사진 업로드',
                  style: TextStyle(
                    fontSize: Sizes.size16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Gaps.v6,
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: _uploadingImages ? null : _pickImages,
                      icon: const Icon(Icons.photo_library_outlined),
                      label: const Text('사진 선택'),
                    ),
                    Gaps.h12,
                    if (_uploadingImages)
                      const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    if (!_uploadingImages) Text('${_pickedImages.length}장 선택됨'),
                  ],
                ),
                Gaps.v12,
                if (_pickedImages.isNotEmpty)
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                        ),
                    itemCount: _pickedImages.length,
                    itemBuilder: (_, i) => Stack(
                      fit: StackFit.expand,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            File(_pickedImages[i].path),
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          right: 4,
                          top: 4,
                          child: InkWell(
                            onTap: () => _removeImageAt(i),
                            child: const CircleAvatar(
                              radius: 12,
                              backgroundColor: Colors.black54,
                              child: Icon(
                                Icons.close,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                Gaps.v12,

                // 주소 입력/검색
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _addrCtrl,
                        decoration: const InputDecoration(
                          hintText: '주소 입력.',
                          border: OutlineInputBorder(),
                        ),
                        onSubmitted: (value) => _searchAddress(value),
                      ),
                    ),
                    Gaps.h12,
                  ],
                ),
                Gaps.v24,
                SizedBox(
                  height: _addresses.isNotEmpty ? 300 : 0,
                  child: _buildResults(),
                ),
                Gaps.v12,

                // 금액/정보
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _depositCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          hintText: "보증금(만 원)",
                          hintStyle: TextStyle(fontSize: Sizes.size12),
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    Gaps.h8,
                    Expanded(
                      child: TextField(
                        controller: _rentCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          hintText: "월세(만 원)",
                          hintStyle: TextStyle(fontSize: Sizes.size12),
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    Gaps.h8,
                    Expanded(
                      child: TextField(
                        controller: _manageFeeCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          hintText: "관리비(만 원)",
                          hintStyle: TextStyle(fontSize: Sizes.size12),
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                Gaps.v24,

                // 층수
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _corFloorCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          hintText: '해당층',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    Gaps.h12,
                    Expanded(
                      child: TextField(
                        controller: _wholeFloorCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          hintText: '건물층',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                Gaps.v24,

                // 전용면적/화장실
                Text(
                  '전용 면적 / 화장실 개수',
                  style: TextStyle(
                    fontSize: Sizes.size16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Gaps.v6,
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _areaCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          hintText: '(평)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    Gaps.h12,
                    Expanded(
                      child: TextField(
                        controller: _toiletCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          hintText: '화장실 개수',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                Gaps.v24,

                // 입주일
                Text(
                  '입주가능일',
                  style: TextStyle(
                    fontSize: Sizes.size16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Gaps.v6,
                TextField(
                  onTap: _onTimeFieldTap,
                  controller: _movingDateCtrl,
                  readOnly: true,
                  decoration: const InputDecoration(
                    suffixIcon: Padding(
                      padding: EdgeInsets.all(10),
                      child: FaIcon(FontAwesomeIcons.calendar),
                    ),
                    hintText: '입주 가능일',
                    border: OutlineInputBorder(),
                  ),
                ),
                Gaps.v24,

                // 계약기간
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _minContractCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          hintText: '최소 거주 기간(개월)',
                          hintStyle: TextStyle(fontSize: Sizes.size14),
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    Gaps.h12,
                    Expanded(
                      child: TextField(
                        controller: _maxContractCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          hintText: '최대 거주 기간(개월)',
                          hintStyle: TextStyle(fontSize: Sizes.size14),
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                Gaps.v24,

                // 소개
                TextField(
                  controller: _introductionCtrl,
                  minLines: 3,
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                  decoration: const InputDecoration(
                    hintText:
                        '자유롭게 글을 작성해주세요!\n취미, 희망 진로, 동거 규칙에 대해 작성해주시면 좋아요!',
                    hintStyle: TextStyle(fontSize: Sizes.size14),
                    border: OutlineInputBorder(),
                  ),
                ),
                Gaps.v24,

                // 제출
                GestureDetector(
                  onTap: _onNextTap,
                  child: FormButton(
                    enabled: _isNextAvailable(),
                    widget: _isPosting
                        ? const CircularProgressIndicator()
                        : const Text('다음', textAlign: TextAlign.center),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResults() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    } else if (_errorMessage.isNotEmpty) {
      return Center(child: Text(_errorMessage));
    } else {
      return ListView.builder(
        itemCount: _addresses.length,
        itemBuilder: (context, index) {
          final address = _addresses[index];
          return GestureDetector(
            onTap: () {
              setState(() {
                _addrCtrl.text = address['roadAddr'] ?? '';
                _addresses = [];
              });
            },
            child: Card(
              margin: const EdgeInsets.symmetric(vertical: 6),
              child: ListTile(
                leading: CircleAvatar(child: Text('${index + 1}')),
                title: Text(address['roadAddr'] ?? '도로명 주소 없음'),
                subtitle: Text('[지번] ${address['jibunAddr'] ?? '지번 주소 없음'}'),
              ),
            ),
          );
        },
      );
    }
  }
}
