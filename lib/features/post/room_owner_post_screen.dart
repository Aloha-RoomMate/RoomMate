// features/post/room_owner_post_screen.dart
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
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:roommate/class/app_user.dart';
import 'package:roommate/class/room_owner_post.dart';
import 'package:roommate/class/user_repository.dart';
import 'package:roommate/constants/gaps.dart';
import 'package:roommate/constants/sizes.dart';
import 'package:roommate/features/post/widgets/form_button.dart';

class RoomOwnerPostScreen extends StatefulWidget {
  const RoomOwnerPostScreen({super.key, this.postToEdit});
  final RoomOwnerPost? postToEdit;

  @override
  State<RoomOwnerPostScreen> createState() => _RoomOwnerPostScreenState();
}

class _RoomOwnerPostScreenState extends State<RoomOwnerPostScreen> {
  // ── controllers ────────────────────────────────────────────────────────────
  final _titleCtrl = TextEditingController();
  final _addrCtrl = TextEditingController();
  final _depositCtrl = TextEditingController();
  final _rentCtrl = TextEditingController();
  final _manageFeeCtrl = TextEditingController();
  final _corFloorCtrl = TextEditingController();
  final _wholeFloorCtrl = TextEditingController();
  final _areaCtrl = TextEditingController();
  final _toiletCtrl = TextEditingController();
  final _movingDateCtrl = TextEditingController();
  final _minContractCtrl = TextEditingController();
  final _maxContractCtrl = TextEditingController();
  final _introductionCtrl = TextEditingController();

  bool get _isEdit => widget.postToEdit != null;

  // 현재 사용자
  final UserRepository _userRepository = UserRepository();
  AppUser? _me;

  // ── Juso 검색 ───────────────────────────────────────────────────────────────
  static const String _jusoKey = "devU01TX0FVVEgyMDI1MDkxMTE3MzcyNzExNjE3NjI=";
  List<dynamic> _addresses = [];
  bool _isLoading = false;
  String _errorMessage = '';

  // ── image pick & upload (Supabase) ─────────────────────────────────────────
  final _picker = ImagePicker();
  final List<XFile> _pickedImages = [];
  bool _uploadingImages = false;

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

        // Firestore엔 "경로"를 저장(서명 URL 아님)
        uploadedPaths.add(storagePath);
      }
    } finally {
      if (mounted) setState(() => _uploadingImages = false);
    }
    return uploadedPaths;
  }

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

  // ── VWorld 지오코딩 + 200m 랜덤 ────────────────────────────────────────────
  Future<Map<String, double>?> _addrToCoordinate(String address) async {
    const KEY = '859C0BAE-5962-3698-97E5-FE4089A6517A';
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
      final res = await http.get(url);
      if (res.statusCode != 200) return null;
      final decoded = jsonDecode(res.body);
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
    const R = 6371000.0; // m
    final lat = center['latitude']!;
    final lon = center['longitude']!;

    final dist = sqrt(r.nextDouble()) * meter;
    final ang = r.nextDouble() * 2 * pi;

    final dLat = (dist * cos(ang)) / R;
    final dLon = (dist * sin(ang)) / (R * cos(lat * pi / 180));

    return {
      'latitude': lat + dLat * 180 / pi,
      'longitude': lon + dLon * 180 / pi,
    };
  }

  // ── lifecycle ──────────────────────────────────────────────────────────────
  DateTime? _selectedMovingDate;
  bool _isPosting = false;

  @override
  void initState() {
    super.initState();
    _loadMe();

    // ✅ 입력값 변경 시 버튼 상태/색 갱신
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

    // 수정 모드라면 초기값 세팅
    final p = widget.postToEdit;
    if (p != null) {
      _titleCtrl.text = p.title ?? '';
      _addrCtrl.text = p.addressLabel ?? '';
      _depositCtrl.text = (p.deposit ?? 0).toString();
      _rentCtrl.text = (p.rent ?? 0).toString();
      _manageFeeCtrl.text = (p.manageFee ?? 0).toString();
      _corFloorCtrl.text = (p.corFloor ?? 0).toString();
      _wholeFloorCtrl.text = (p.wholeFloor ?? 0).toString();
      _areaCtrl.text = (p.area ?? 0).toString();
      _toiletCtrl.text = (p.toilet ?? 0).toString();
      _movingDateCtrl.text = p.movingDate != null
          ? DateFormat('yyyy-MM-dd').format(p.movingDate!.toDate())
          : '';
      _minContractCtrl.text = (p.minContract ?? 0).toString();
      _maxContractCtrl.text = (p.maxContract ?? 0).toString();
      _introductionCtrl.text = p.introduction ?? '';
      _selectedMovingDate = p.movingDate?.toDate();
    }
  }

  Future<void> _loadMe() async {
    final me = await _userRepository.fetchMe();
    if (!mounted) return;
    setState(() => _me = me);
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

  // ── time picker ────────────────────────────────────────────────────────────
  void _onTimePickerChanged(DateTime date) {
    _selectedMovingDate = date;
    _movingDateCtrl.text =
        "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
    if (mounted) setState(() {}); // 버튼 색 갱신
  }

  Future<void> _onTimeFieldTap() async {
    await showModalBottomSheet(
      context: context,
      builder: (context) {
        return CupertinoDatePicker(
          mode: CupertinoDatePickerMode.date,
          onDateTimeChanged: _onTimePickerChanged,
          minimumDate: DateTime.now(),
          initialDateTime: DateTime.now(),
        );
      },
    );
  }

  // ── validators ─────────────────────────────────────────────────────────────
  bool _isNextAvailable() {
    final base =
        _titleCtrl.text.isNotEmpty &&
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

    // 작성 모드에서는 사용자 정보 필요
    if (_isEdit) return base;
    return base && _me != null;
  }

  // ── juso search ────────────────────────────────────────────────────────────
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
      'confmKey': _jusoKey,
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
      setState(() => _errorMessage = '데이터 요청 중 오류: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ── save (작성 & 수정) ─────────────────────────────────────────────────────
  Future<void> _onSave() async {
    if (!_isNextAvailable() || _isPosting) return;
    setState(() => _isPosting = true);

    try {
      // uid 확보(미로그인 대비)
      final auth = FirebaseAuth.instance;
      final user = auth.currentUser ?? (await auth.signInAnonymously()).user!;
      final uid = user.uid;

      // 공통 필드
      final common = <String, dynamic>{
        'title': _titleCtrl.text,
        'addressLabel': _addrCtrl.text,
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
      };

      final col = FirebaseFirestore.instance.collection('roomOwnerPosts');

      if (_isEdit) {
        // ── 수정 모드 ────────────────────────────────────────────────────────
        final docId = widget.postToEdit!.postId!;
        final docRef = col.doc(docId);

        // 주소가 바뀐 경우: 지오코딩 → 200m 랜덤 → addr 갱신
        final oldLabel = widget.postToEdit!.addressLabel ?? '';
        final newLabel = _addrCtrl.text.trim();
        if (newLabel.isNotEmpty && newLabel != oldLabel) {
          final center = await _addrToCoordinate(newLabel);
          if (center != null) {
            final jitter = _randomizeCoord(center, 200.0);
            common['addr'] = GeoPoint(
              jitter['latitude']!,
              jitter['longitude']!,
            );
          }
        }

        // 텍스트/숫자 등 기본 필드 업데이트
        await docRef.update({
          ...common,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // 새로 선택한 이미지가 있다면 업로드 후 imageUrls append
        if (_pickedImages.isNotEmpty) {
          final newPaths = await _uploadAllImagesToSupabase(
            uid: uid,
            postId: docId,
          );

          if (newPaths.isNotEmpty) {
            final snap = await docRef.get();
            final exist =
                (snap.data()?['imageUrls'] as List?)
                    ?.map((e) => e.toString())
                    .toList() ??
                <String>[];
            final merged = [...exist, ...newPaths];
            await docRef.update({
              'imageUrls': merged,
              'updatedAt': FieldValue.serverTimestamp(),
            });
          }
        }

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('수정되었습니다.')),
        );
        Navigator.pop(context);
        return;
      }

      // ── 작성 모드 ──────────────────────────────────────────────────────────
      // 주소 → 좌표
      final center = await _addrToCoordinate(_addrCtrl.text);
      if (center == null) {
        throw Exception('주소를 좌표로 변환하지 못했습니다.');
      }
      final jitter = _randomizeCoord(center, 200.0);

      // 문서 선 생성 (imageUrls 비움)
      final docRef = await col.add({
        'authorId': _me?.uid ?? uid,
        'postType': _me?.userType?.type ?? 'roomOwner',
        'title': _titleCtrl.text,
        'address': _addrCtrl.text,
        'addressLabel': _addrCtrl.text,
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

      // 이미지 업로드 → imageUrls 업데이트
      final uploadedPaths = await _uploadAllImagesToSupabase(
        uid: uid,
        postId: postId,
      );

      if (uploadedPaths.isNotEmpty) {
        await docRef.update({
          'imageUrls': uploadedPaths,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('게시글 저장 완료~')),
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

  // ── UI ─────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final buttonText = _isEdit ? '수정 완료' : '다음';
    final canSubmit = _isNextAvailable() && !_isPosting;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          elevation: 10,
          title: Text(
            _isEdit ? '게시글 수정' : '게시글 작성',
            style: const TextStyle(fontSize: Sizes.size24),
          ),
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

                // 주소 안내
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

                // 사진 업로드
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
                          hintText: '주소 입력.',
                          border: OutlineInputBorder(),
                        ),
                        onSubmitted: _searchAddress,
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

                // 전용 면적 / 화장실 개수
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

                // 저장 버튼 (FormButton 유지)
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: canSubmit ? _onSave : null, // ✅ 비활성 시 터치 불가
                  child: FormButton(
                    enabled: canSubmit,
                    widget: _isPosting
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(buttonText, textAlign: TextAlign.center),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── 검색 결과 리스트 ───────────────────────────────────────────────────────
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
