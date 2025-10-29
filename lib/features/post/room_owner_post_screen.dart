// lib/features/post/room_owner_post_screen.dart
import 'dart:convert';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:roommate/constants/responsive_sizes.dart';
import 'package:roommate/features/navigationbar/main_navigation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:roommate/class/app_user.dart';
import 'package:roommate/class/room_owner_post.dart';
import 'package:roommate/class/user_repository.dart';
import 'package:roommate/constants/gaps.dart';
import 'package:roommate/net/jsonp_web.dart';
import 'package:roommate/features/post/widgets/form_button.dart';

const _jusoKey = String.fromEnvironment(
  'JUSO_API_KEY',
  defaultValue: '',
);

class RoomOwnerPostScreen extends StatefulWidget {
  const RoomOwnerPostScreen({super.key, this.postToEdit});
  final RoomOwnerPost? postToEdit;

  @override
  State<RoomOwnerPostScreen> createState() => _RoomOwnerPostScreenState();
}

class _RoomOwnerPostScreenState extends State<RoomOwnerPostScreen> {
  // ── controllers ────────────────────────────────────────────────────────────
  final _titleCtrl = TextEditingController();
  final _roadAddrCtrl = TextEditingController(); // 도로명 주소
  final _jibunAddrCtrl = TextEditingController(); // 지번 주소 (UI 표시용)
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

  List<dynamic> _addresses = [];
  bool _isLoading = false;
  String _errorMessage = '';

  // image pick & upload (Supabase)
  final _picker = ImagePicker();
  final List<XFile> _pickedImages = []; // 새로 추가할 이미지(저장 시 업로드)
  bool _uploadingImages = false;

  // === 기존 업로드 이미지(편집 모드) ===
  List<String> _existingImagePaths = []; // storage 경로
  List<String> _existingImageUrls = []; // 표시용 signed URL
  bool _loadingExistingImages = false;

  static const String _bucket = 'RoomMate-image';
  final _supabase = Supabase.instance.client;

  // 성별 정규화(동일 파일 내 헬퍼)
  static const Set<String> _maleTokens = {'male', '남성', '남자', 'm', 'M'};
  static const Set<String> _femaleTokens = {'female', '여성', '여자', 'f', 'F'};

  String? _normalizeGender(String? g) {
    if (g == null) return null;
    final t = g.trim();
    if (_maleTokens.contains(t)) return 'male';
    if (_femaleTokens.contains(t)) return 'female';
    return t; // 알 수 없는 표기는 원문 유지
  }

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

  Future<Map<String, double>?> _addrToCoordinate(String address) async {
    return await addrToCoordinate(address);
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

  DateTime? _selectedMovingDate;
  bool _isPosting = false;

  @override
  void initState() {
    super.initState();
    _loadMe();

    for (final c in [
      _titleCtrl,
      _roadAddrCtrl,
      _jibunAddrCtrl,
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

    final p = widget.postToEdit;
    if (p != null) {
      _titleCtrl.text = p.title ?? '';
      _roadAddrCtrl.text = p.roadAddress ?? '';
      _jibunAddrCtrl.text = p.jibunAddress ?? '';
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

      _loadExistingImages(); // ✅ 편집 모드: 기존 이미지 불러오기
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
    _roadAddrCtrl.dispose();
    _jibunAddrCtrl.dispose();
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

  void _onTimePickerChanged(DateTime date) {
    _selectedMovingDate = date;
    _movingDateCtrl.text =
        "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
    if (mounted) setState(() {});
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

  bool _isNextAvailable() {
    final base =
        _titleCtrl.text.isNotEmpty &&
        _roadAddrCtrl.text.isNotEmpty &&
        _jibunAddrCtrl.text.isNotEmpty &&
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

    if (_isEdit) return base;
    return base && _me != null;
  }

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

  Future<void> _onSave() async {
    if (!_isNextAvailable() || _isPosting) return;
    setState(() => _isPosting = true);

    try {
      final auth = FirebaseAuth.instance;
      final user = auth.currentUser ?? (await auth.signInAnonymously()).user!;
      final uid = user.uid;

      final roadAddress = _roadAddrCtrl.text.trim();
      final jibunAddress = _jibunAddrCtrl.text.trim();

      final common = <String, dynamic>{
        'title': _titleCtrl.text,
        'roadAddress': roadAddress,
        'jibunAddress': jibunAddress,
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
        final docId = widget.postToEdit!.postId!;
        final docRef = col.doc(docId);

        if (roadAddress.isNotEmpty) {
          final center = await _addrToCoordinate(roadAddress);
          if (center != null) {
            final jitter = _randomizeCoord(center, 200.0);
            common['coordinate'] = GeoPoint(
              jitter['latitude']!,
              jitter['longitude']!,
            );
          }
        }

        await docRef.update({
          ...common,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        if (_pickedImages.isNotEmpty) {
          final newPaths = await _uploadAllImagesToSupabase(
            uid: uid,
            postId: docId,
          );

          if (newPaths.isNotEmpty) {
            await docRef.update({
              'imageUrls': FieldValue.arrayUnion(newPaths),
              'updatedAt': FieldValue.serverTimestamp(),
            });
          }
        }

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('수정되었습니다.')),
        );
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const MainNavigation()),
          (Route<dynamic> route) => false,
        );
        return;
      }

      // 1. 게시물 ID를 클라이언트에서 미리 생성
      final postId = col.doc().id;

      // 2. 이미지를 먼저 업로드
      final uploadedPaths = await _uploadAllImagesToSupabase(
        uid: uid,
        postId: postId,
      );

      // 3. 주소 변환 및 기타 정보 준비
      final center = await _addrToCoordinate(roadAddress);
      if (center == null) {
        throw Exception('주소를 좌표로 변환하지 못했습니다.');
      }
      final jitter = _randomizeCoord(center, 200.0);
      final normalizedGender = _normalizeGender(_me?.gender);

      // 4. 문서 생성
      await col.doc(postId).set({
        ...common,
        'authorId': _me?.uid ?? uid,
        'authorGender': normalizedGender ?? _me?.gender,
        'postType': 'roomOwner',
        'status': 'open', // ✅ 신규 글은 기본 open
        'coordinate': GeoPoint(jitter['latitude']!, jitter['longitude']!),
        'imageUrls': uploadedPaths, // 업로드된 이미지 경로 사용
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('게시글 저장 완료~')),
      );
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const MainNavigation()),
        (Route<dynamic> route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('오류: $e')),
      );
    } finally {
      if (mounted) setState(() => _isPosting = false);
    }
  }

  // ==== 편집 모드: 기존 이미지 불러오기 & 삭제 ====

  Future<void> _loadExistingImages() async {
    final post = widget.postToEdit;
    if (post == null) return;

    final paths = (post.imageUrls ?? [])
        .whereType<String>()
        .where((s) => s.trim().isNotEmpty)
        .toList();

    if (paths.isEmpty) {
      setState(() {
        _existingImagePaths = [];
        _existingImageUrls = [];
      });
      return;
    }

    setState(() => _loadingExistingImages = true);
    try {
      final urls = await Future.wait(
        paths.map(
          (p) => _supabase.storage.from(_bucket).createSignedUrl(p, 3600),
        ),
      );
      if (!mounted) return;
      setState(() {
        _existingImagePaths = paths;
        _existingImageUrls = urls;
      });
    } catch (_) {
      // 보기 실패는 무시
    } finally {
      if (mounted) setState(() => _loadingExistingImages = false);
    }
  }

  Future<void> _removeExistingImageAt(int index) async {
    final post = widget.postToEdit;
    if (post == null) return;

    final docId = post.postId!;
    final col = FirebaseFirestore.instance.collection('roomOwnerPosts');
    final docRef = col.doc(docId);

    final path = _existingImagePaths[index];

    final yes = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('이미지 삭제'),
        content: const Text('이 이미지를 삭제할까요? (되돌릴 수 없습니다)'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
    if (yes != true) return;

    try {
      // 1) Storage에서 삭제
      await _supabase.storage.from(_bucket).remove([path]);

      // 2) Firestore 배열에서 제거
      await docRef.update({
        'imageUrls': FieldValue.arrayRemove([path]),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // 3) 로컬 상태에서 제거
      setState(() {
        _existingImagePaths.removeAt(index);
        _existingImageUrls.removeAt(index);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이미지를 삭제했습니다.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('삭제에 실패했어요: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final buttonText = _isEdit ? '수정 완료' : '다음';
    final canSubmit = _isNextAvailable() && !_isPosting;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          // ✅ 뒤로가기 화살표
          automaticallyImplyLeading: true,
          leading: const BackButton(),
          elevation: 0,
          scrolledUnderElevation: 0,
          title: Text(_isEdit ? '게시글 수정' : '게시글 작성'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(12),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '제목을 입력해주세요!',
                  style: TextStyle(
                    fontSize: ResponsiveSizes.f(context, 24),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Gaps.v10(context),
                TextField(
                  controller: _titleCtrl,
                  decoration: InputDecoration(
                    hintText: '제목 입력',
                    hintStyle: TextStyle(
                      fontSize: ResponsiveSizes.f(context, 14),
                      color: Colors.black38,
                      fontWeight: FontWeight.w300,
                    ),
                    border: const OutlineInputBorder(),
                  ),
                ),
                Gaps.v48(context),

                Text(
                  '주소를 입력해주세요!',
                  style: TextStyle(
                    fontSize: ResponsiveSizes.f(context, 24),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Gaps.v2(context),
                Text(
                  '다른 유저에게는 상세주소 대신 … 부근으로 노출돼요.\n지도에는 실제 주소 반경 200m 내의 랜덤 위치로 표시돼요.',
                  style: TextStyle(
                    fontSize: ResponsiveSizes.f(context, 14),
                    color: Colors.black87,
                    fontWeight: FontWeight.w300,
                  ),
                ),
                Gaps.v12(context),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _roadAddrCtrl,
                        decoration: InputDecoration(
                          hintText: '도로명 주소 입력 후 엔터',
                          border: const OutlineInputBorder(),
                          hintStyle: TextStyle(
                            fontSize: ResponsiveSizes.f(context, 14),
                            color: Colors.black38,
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                        onSubmitted: (kw) async {
                          await _searchAddress(kw);
                        },
                      ),
                    ),
                  ],
                ),
                Builder(
                  builder: (context) {
                    final jibun = _jibunAddrCtrl.text.trim();
                    if (jibun.isEmpty) return const SizedBox.shrink();

                    final tempPost = RoomOwnerPost(
                      authorId: '',
                      jibunAddress: jibun,
                    );
                    final displayAddress = tempPost.getAddressLabel;

                    if (displayAddress.isEmpty ||
                        displayAddress == '주소 정보 없음' ||
                        displayAddress == jibun) {
                      return const SizedBox.shrink();
                    }

                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.visibility_outlined,
                            size: 16,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            "공개 표시는 ‘$displayAddress’ 로 보여집니다",
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                Gaps.v2(context),

                // === 기존 업로드된 이미지 (편집 모드) ===
                if (_isEdit) ...[
                  Gaps.v12(context),
                  Text(
                    '기존 업로드된 사진',
                    style: TextStyle(
                      fontSize: ResponsiveSizes.f(context, 24),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Gaps.v12(context),
                  if (_loadingExistingImages)
                    const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else if (_existingImageUrls.isEmpty)
                    const Text('기존 이미지가 없습니다.')
                  else
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            mainAxisSpacing: 8,
                            crossAxisSpacing: 8,
                          ),
                      itemCount: _existingImageUrls.length,
                      itemBuilder: (_, i) => Stack(
                        fit: StackFit.expand,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              _existingImageUrls[i],
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const ColoredBox(
                                color: Color(0xFFE0E0E0),
                                child: Center(
                                  child: Icon(Icons.broken_image_outlined),
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            right: 4,
                            top: 4,
                            child: InkWell(
                              onTap: () => _removeExistingImageAt(i),
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
                  Gaps.v24(context),
                ],

                // === 새로 추가할 로컬 선택 이미지 미리보기 ===
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
                          // 웹 호환을 위해 Image.network 사용(Blob URL)
                          child: Image.network(
                            _pickedImages[i].path,
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
                Gaps.v24(context),

                SizedBox(
                  height: _addresses.isNotEmpty ? 300 : 0,
                  child: _buildResults(),
                ),
                Gaps.v12(context),
                Text(
                  '사진 업로드',
                  style: TextStyle(
                    fontSize: ResponsiveSizes.f(context, 24),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Gaps.v6(context),
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: _uploadingImages ? null : _showPickSourceSheet,
                      icon: const Icon(Icons.add_a_photo_outlined),
                      label: const Text('사진 추가'),
                    ),
                    Gaps.h12(context),
                    if (_uploadingImages)
                      const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    if (!_uploadingImages) Text('${_pickedImages.length}장 선택됨'),
                  ],
                ),
                Gaps.v40(context),

                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _depositCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: "보증금(만 원)",
                          hintStyle: TextStyle(
                            fontSize: ResponsiveSizes.f(context, 14),
                            color: Colors.black38,
                            fontWeight: FontWeight.w300,
                          ),
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ),
                    Gaps.h8(context),
                    Expanded(
                      child: TextField(
                        controller: _rentCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: "월세(만 원)",
                          hintStyle: TextStyle(
                            fontSize: ResponsiveSizes.f(context, 14),
                            color: Colors.black38,
                            fontWeight: FontWeight.w300,
                          ),
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ),
                    Gaps.h8(context),
                    Expanded(
                      child: TextField(
                        controller: _manageFeeCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: "관리비(만 원)",
                          hintStyle: TextStyle(
                            fontSize: ResponsiveSizes.f(context, 14),
                            color: Colors.black38,
                            fontWeight: FontWeight.w300,
                          ),
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                Gaps.v24(context),

                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _corFloorCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: '해당층',
                          hintStyle: TextStyle(
                            fontSize: ResponsiveSizes.f(context, 14),
                            color: Colors.black38,
                            fontWeight: FontWeight.w300,
                          ),
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ),
                    Gaps.h12(context),
                    Expanded(
                      child: TextField(
                        controller: _wholeFloorCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: '건물층',
                          hintStyle: TextStyle(
                            fontSize: ResponsiveSizes.f(context, 14),
                            color: Colors.black38,
                            fontWeight: FontWeight.w300,
                          ),
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                Gaps.v24(context),
                Text(
                  '전용 면적 / 화장실 개수',
                  style: TextStyle(
                    fontSize: ResponsiveSizes.f(context, 24),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Gaps.v6(context),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _areaCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: '(평)',
                          hintStyle: TextStyle(
                            fontSize: ResponsiveSizes.f(context, 14),
                            color: Colors.black38,
                            fontWeight: FontWeight.w300,
                          ),
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ),
                    Gaps.h12(context),
                    Expanded(
                      child: TextField(
                        controller: _toiletCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: '화장실 개수',
                          hintStyle: TextStyle(
                            fontSize: ResponsiveSizes.f(context, 14),
                            color: Colors.black38,
                            fontWeight: FontWeight.w300,
                          ),
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                Gaps.v24(context),

                Text(
                  '입주가능일',
                  style: TextStyle(
                    fontSize: ResponsiveSizes.f(context, 24),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Gaps.v6(context),
                TextField(
                  onTap: _onTimeFieldTap,
                  controller: _movingDateCtrl,
                  readOnly: true,
                  decoration: InputDecoration(
                    suffixIcon: const Padding(
                      padding: EdgeInsets.all(10),
                      child: FaIcon(FontAwesomeIcons.calendar),
                    ),
                    hintText: '입주 가능일',
                    hintStyle: TextStyle(
                      fontSize: ResponsiveSizes.f(context, 14),
                      color: Colors.black38,
                      fontWeight: FontWeight.w300,
                    ),
                    border: const OutlineInputBorder(),
                  ),
                ),
                Gaps.v24(context),

                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _minContractCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: '최소 거주 기간(개월)',
                          hintStyle: TextStyle(
                            fontSize: ResponsiveSizes.f(context, 14),
                            color: Colors.black38,
                            fontWeight: FontWeight.w300,
                          ),
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ),
                    Gaps.h12(context),
                    Expanded(
                      child: TextField(
                        controller: _maxContractCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: '최대 거주 기간(개월)',
                          hintStyle: TextStyle(
                            fontSize: ResponsiveSizes.f(context, 14),
                            color: Colors.black38,
                            fontWeight: FontWeight.w300,
                          ),
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                Gaps.v24(context),
                Text(
                  '더 상세하게 알려주세요 !',
                  style: TextStyle(
                    fontSize: ResponsiveSizes.f(context, 24),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Gaps.v24(context),
                TextField(
                  controller: _introductionCtrl,
                  minLines: null,
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                  decoration: InputDecoration(
                    hintText:
                        '자유롭게 글을 작성해주세요!\n취미, 희망 진로, 동거 규칙에 대해 작성해주시면 좋아요!',
                    hintStyle: TextStyle(
                      fontSize: ResponsiveSizes.f(context, 14),
                      color: Colors.black38,
                      fontWeight: FontWeight.w300,
                    ),
                    border: const OutlineInputBorder(),
                  ),
                ),
                Gaps.v24(context),

                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: canSubmit ? _onSave : null,
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

  Widget _buildResults() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    } else if (_errorMessage.isNotEmpty) {
      return Center(child: Text(_errorMessage));
    } else {
      return ListView.builder(
        itemCount: _addresses.length,
        itemBuilder: (context, index) {
          final address = _addresses[index] as Map<String, dynamic>;
          return GestureDetector(
            onTap: () {
              setState(() {
                _roadAddrCtrl.text = address['roadAddr'] ?? '';
                _jibunAddrCtrl.text = address['jibunAddr'] ?? '';
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
