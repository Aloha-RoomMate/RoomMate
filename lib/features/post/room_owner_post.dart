import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:roommate/constants/gaps.dart';
import 'package:roommate/constants/sizes.dart';
import 'package:roommate/features/post/widgets/form_button.dart';

class RoomOwnerPost extends StatefulWidget {
  const RoomOwnerPost({super.key});

  @override
  State<RoomOwnerPost> createState() => _RoomOwnerPostState();
}

class _RoomOwnerPostState extends State<RoomOwnerPost> {
  // ── controllers ────────────────────────────────────────────────────────────
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

  // ── image pick (UI 유지) ───────────────────────────────────────────────────
  final ImagePicker _picker = ImagePicker();
  final List<XFile> _pickedImages = [];
  bool _uploadingImages = false;

  Future<void> _showPickSourceSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton.icon(
                  onPressed: () async {
                    Navigator.of(ctx).pop();
                    await _getCameraImage();
                  },
                  icon: const Icon(Icons.photo_camera_outlined),
                  label: const Text('사진 찍기'),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: () async {
                    Navigator.of(ctx).pop();
                    await _getPhotoLibraryImages();
                  },
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('라이브러리에서 불러오기'),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('취소'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _getCameraImage() async {
    try {
      final x = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        preferredCameraDevice: CameraDevice.rear,
      );
      if (x != null) setState(() => _pickedImages.add(x));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('카메라에서 이미지를 가져오지 못했어요.')),
      );
    }
  }

  Future<void> _getPhotoLibraryImages() async {
    try {
      final files = await _picker.pickMultiImage(imageQuality: 85);
      if (files.isNotEmpty) setState(() => _pickedImages.addAll(files));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('앨범에서 이미지를 가져오지 못했어요.')),
      );
    }
  }

  void _removeImageAt(int index) =>
      setState(() => _pickedImages.removeAt(index));

  // ── Supabase 업로드 ─────────────────────────────────────────────────────────
  static const String _bucket = 'RoomMate-image';
  final _supabase = Supabase.instance.client;

  String _guessMimeType(String ext) {
    switch (ext.toLowerCase()) {
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

  Future<List<String>> _uploadAllImagesToSupabase({
    required String uid,
    required String postId,
  }) async {
    if (_pickedImages.isEmpty) return <String>[];
    setState(() => _uploadingImages = true);

    final uploadedPaths = <String>[];
    try {
      for (int i = 0; i < _pickedImages.length; i++) {
        final xf = _pickedImages[i];
        final ext = xf.path.split('.').last;
        final fileName = '${DateTime.now().millisecondsSinceEpoch}-$i.$ext';
        final storagePath = 'roomOwnerPosts/$uid/$postId/$fileName';

        final bytes = await xf.readAsBytes();
        await _supabase.storage
            .from(_bucket)
            .uploadBinary(
              storagePath,
              bytes,
              fileOptions: FileOptions(
                contentType: _guessMimeType(ext),
                upsert: false,
                cacheControl: '3600',
              ),
            );
        uploadedPaths.add(storagePath); // ⚠️ "경로" 저장 (서명URL 아님)
      }
    } finally {
      if (mounted) setState(() => _uploadingImages = false);
    }
    return uploadedPaths;
  }

  // ── Juso 검색 ───────────────────────────────────────────────────────────────
  final String _jusoApiKey = "devU01TX0FVVEgyMDI1MDkxMTE3MzcyNzExNjE3NjI=";
  List<dynamic> _addresses = [];
  bool _isLoading = false;
  bool _isPosting = false;
  String _errorMessage = '';
  DateTime? _selectedMovingDate;

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
      'confmKey': _jusoApiKey,
      'currentPage': '1',
      'countPerPage': '20',
      'keyword': keyword,
      'resultType': 'json',
    });

    try {
      final res = await http.get(url);
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        final juso = decoded['results']?['juso'] as List?;
        setState(() {
          _addresses = juso ?? [];
          if (_addresses.isEmpty) _errorMessage = '검색 결과가 없습니다.';
        });
      } else {
        setState(() => _errorMessage = 'API 서버 오류: ${res.statusCode}');
      }
    } catch (e) {
      setState(() => _errorMessage = '데이터 요청 중 오류가 발생했습니다: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ── VWorld 지오코딩 + 200m 랜덤 ────────────────────────────────────────────
  Future<Map<String, double>?> _addrToCoordinate(String address) async {
    const KEY = '859C0BAE-5962-3698-97E5-FE4089A6517A'; // 너가 쓰던 키
    final url = Uri.https('api.vworld.kr', '/req/address', {
      'service': 'address',
      'request': 'getcoord',
      'version': '2.0',
      'crs': 'epsg:4326',
      'address': address,
      'refine': 'true',
      'simple': 'false',
      'format': 'json',
      'type': 'road',
      'key': KEY,
    });

    try {
      final response = await http.get(url);
      if (response.statusCode != 200) return null;

      final decoded = jsonDecode(response.body);
      if (decoded['response']?['status'] == 'OK') {
        final p = decoded['response']['result']['point'];
        final lon = double.tryParse('${p['x']}');
        final lat = double.tryParse('${p['y']}');
        if (lat == null || lon == null) return null;
        return {'latitude': lat, 'longitude': lon};
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Map<String, double> _randomizeCoord(
    Map<String, double> center,
    double meter,
  ) {
    final r = Random();
    const R = 6371000.0; // earth radius(m)
    final lat = center['latitude']!;
    final lon = center['longitude']!;

    final dist = sqrt(r.nextDouble()) * meter; // 균일 분포
    final ang = r.nextDouble() * 2 * pi;

    final dLat = (dist * cos(ang)) / R;
    final dLon = (dist * sin(ang)) / (R * cos(lat * pi / 180));

    return {
      'latitude': lat + dLat * 180 / pi,
      'longitude': lon + dLon * 180 / pi,
    };
  }

  // ── misc ───────────────────────────────────────────────────────────────────
  void _onScaffoldTap(BuildContext context) => FocusScope.of(context).unfocus();

  void _onTimePickerChanged(DateTime date) {
    _selectedMovingDate = date;
    _movingDateCtrl.text =
        "${date.year.toString()}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  void _onTimeFieldTap() async {
    await showModalBottomSheet(
      context: context,
      builder: (context) {
        return CupertinoDatePicker(
          mode: CupertinoDatePickerMode.date,
          onDateTimeChanged: (date) => _onTimePickerChanged(date),
          minimumDate: DateTime.now(),
          initialDateTime: DateTime.now(),
        );
      },
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

  // ── submit ─────────────────────────────────────────────────────────────────
  Future<void> _onNextTap() async {
    if (!_isNextAvailable() || _isPosting) return;

    try {
      setState(() => _isPosting = true);

      // 1) 로그인(uid)
      final auth = FirebaseAuth.instance;
      final me = auth.currentUser ?? (await auth.signInAnonymously()).user!;
      final uid = me.uid;

      // 2) 주소 → 좌표
      final center = await _addrToCoordinate(_addrCtrl.text);
      if (center == null) {
        throw Exception('주소를 좌표로 변환하지 못했습니다.');
      }
      final jitter = _randomizeCoord(center, 200.0);

      // 3) Firestore 기본 문서 생성 (imageUrls = 빈 배열)
      final col = FirebaseFirestore.instance.collection('roomOwnerPosts');
      final docRef = await col.add({
        'authorId': uid,
        'postType': 'roomOwner',
        'title': _titleCtrl.text,
        'addressLabel': _addrCtrl.text,
        'address': _addrCtrl.text,
        'addr': GeoPoint(jitter['latitude']!, jitter['longitude']!),
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
        'movingDate': _selectedMovingDate == null
            ? null
            : Timestamp.fromDate(_selectedMovingDate!),
        'imageUrls': <String>[],
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': DateTime.now().toIso8601String(),
      });
      final postId = docRef.id;

      // 4) Supabase에 이미지 업로드 → 경로 리스트 취득
      final uploadedPaths = await _uploadAllImagesToSupabase(
        uid: uid,
        postId: postId,
      );

      // 5) Firestore 문서 imageUrls 업데이트
      if (uploadedPaths.isNotEmpty) {
        await docRef.update({
          'imageUrls': uploadedPaths,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('글 포스팅 성공~')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('오류: $e')),
      );
    } finally {
      if (mounted) setState(() => _isPosting = false);
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

  // ── UI ─────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          elevation: 10,
          title: const Text('게시글 작성', style: TextStyle(fontSize: Sizes.size24)),
        ),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 제목
                const Text(
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

                // 안내
                const Text(
                  '주소를 입력해주세요!',
                  style: TextStyle(
                    fontSize: Sizes.size16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  '다른 유저에게는 XX동 \'부근\'으로 보여져요.\n지도에는 실제 주소 반경 200m 내의 랜덤한 위치로 표시돼요.',
                  style: TextStyle(fontSize: Sizes.size14, color: Colors.grey),
                ),
                Gaps.v6,

                // 사진 업로드(선택 UI 그대로)
                const Text(
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
                      onPressed: _uploadingImages ? null : _showPickSourceSheet,
                      icon: const Icon(Icons.add_a_photo_outlined),
                      label: const Text('사진 추가'),
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
                          hintText: '주소 입력',
                          border: OutlineInputBorder(),
                        ),
                        onSubmitted: (value) => _searchAddress(value),
                      ),
                    ),
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
                const Text(
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
                const Text(
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
