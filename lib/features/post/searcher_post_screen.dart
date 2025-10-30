import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:roommate/class/app_user.dart';
import 'package:roommate/class/searcher_post.dart';
import 'package:roommate/class/searcher_post_repository.dart';
import 'package:roommate/class/user_repository.dart';
import 'package:roommate/constants/gaps.dart';
import 'package:roommate/features/authentication/userinfo/searcher_screen.dart';
import 'package:roommate/features/category/widgets/category_button.dart';
import 'package:roommate/features/navigationbar/main_navigation.dart';
import 'package:roommate/features/post/widgets/form_button.dart';
import 'package:roommate/constants/responsive_sizes.dart';

class SearcherPostScreen extends StatefulWidget {
  const SearcherPostScreen({super.key, this.postToEdit});
  final SearcherPost? postToEdit;

  @override
  State<SearcherPostScreen> createState() => _SearcherPostScreenState();
}

class _SearcherPostScreenState extends State<SearcherPostScreen> {
  // --- Repositories ---
  final UserRepository _userRepository = UserRepository();
  final SearcherPostRepository _postRepository = SearcherPostRepository();

  // --- Controllers ---
  final _titleCtrl = TextEditingController();
  final _depositCtrl = TextEditingController();
  final _minRentCtrl = TextEditingController();
  final _maxRentCtrl = TextEditingController();
  final _movingDateCtrl = TextEditingController();
  final _minContractCtrl = TextEditingController();
  final _maxContractCtrl = TextEditingController();
  final _introductionCtrl = TextEditingController();

  // --- State Variables ---
  AppUser? _currentUser;
  bool _isPosting = false;
  DateTime? _selectedMovingDate;

  bool get _isEdit => widget.postToEdit != null;

  // Chip 및 위치 선택 상태
  final Set<String> _selectedWantAreas = {};
  final Set<String> _selectedRoomTypes = {};
  final Set<String> _selectedPaymentStructures = {};

  // Chip 옵션
  final List<String> _roomTypeOptions = ['원 룸', '투 룸', '빌라', '아파트'];
  final List<String> _paymentOptions = ['보증금 분담', '월세 분담', '관리비 분담', '공과금 분담'];

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();

    // 버튼 활성화 갱신 리스너
    for (final c in [
      _titleCtrl,
      _depositCtrl,
      _minRentCtrl,
      _maxRentCtrl,
      _movingDateCtrl,
      _minContractCtrl,
      _maxContractCtrl,
      _introductionCtrl,
    ]) {
      c.addListener(() => setState(() {}));
    }

    // ✅ 편집 모드 프리필
    final p = widget.postToEdit;
    if (p != null) {
      _titleCtrl.text = p.title ?? '';
      _depositCtrl.text = (p.deposit ?? 0).toString();
      _minRentCtrl.text = (p.minRent ?? 0).toString();
      _maxRentCtrl.text = (p.maxRent ?? 0).toString();
      _minContractCtrl.text = (p.minContract ?? 0).toString();
      _maxContractCtrl.text = (p.maxContract ?? 0).toString();
      _introductionCtrl.text = p.introduction ?? '';

      _selectedWantAreas
        ..clear()
        ..addAll(p.wantArea ?? const []);
      _selectedRoomTypes
        ..clear()
        ..addAll(p.wantRoom ?? const []);
      _selectedPaymentStructures
        ..clear()
        ..addAll(p.wantPay ?? const []);

      _selectedMovingDate = p.movingDate?.toDate();
      _movingDateCtrl.text = p.movingDate == null
          ? ''
          : DateFormat('yyyy-MM-dd').format(p.movingDate!.toDate());
    }
  }

  Future<void> _loadCurrentUser() async {
    _currentUser = await _userRepository.fetchMe();
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    for (final c in [
      _titleCtrl,
      _depositCtrl,
      _minRentCtrl,
      _maxRentCtrl,
      _movingDateCtrl,
      _minContractCtrl,
      _maxContractCtrl,
      _introductionCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  // 희망 위치 선택
  Future<void> _onAreaTap() async {
    final List<String>? result = await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SearcherScreen()),
    );
    if (result != null && result.isNotEmpty) {
      setState(() {
        _selectedWantAreas
          ..clear()
          ..addAll(result);
      });
    }
  }

  void _onChipTap(Set<String> selectionSet, String value) {
    setState(() {
      if (selectionSet.contains(value)) {
        selectionSet.remove(value);
      } else {
        selectionSet.add(value);
      }
    });
  }

  void _onTimePickerChanged(DateTime date) {
    setState(() {
      _selectedMovingDate = date;
      _movingDateCtrl.text =
          "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
    });
  }

  Future<void> _onTimeFieldTap() async {
    await showModalBottomSheet(
      context: context,
      builder: (context) {
        return SizedBox(
          height: 300,
          child: CupertinoDatePicker(
            mode: CupertinoDatePickerMode.date,
            onDateTimeChanged: _onTimePickerChanged,
            minimumDate: DateTime.now(),
            initialDateTime: _selectedMovingDate ?? DateTime.now(),
          ),
        );
      },
    );
  }

  bool _isNextAvailable() {
    final controllers = [
      _titleCtrl,
      _depositCtrl,
      _minRentCtrl,
      _maxRentCtrl,
      _movingDateCtrl,
      _minContractCtrl,
      _maxContractCtrl,
      _introductionCtrl,
    ];
    final allFieldsFilled = controllers.every((c) => c.text.isNotEmpty);
    final allChipsSelected =
        _selectedWantAreas.isNotEmpty &&
        _selectedRoomTypes.isNotEmpty &&
        _selectedPaymentStructures.isNotEmpty;

    // ✅ 편집 모드에서는 _currentUser가 없어도 통과 (작성자 고정)
    if (_isEdit) return allFieldsFilled && allChipsSelected;
    return allFieldsFilled && allChipsSelected && _currentUser != null;
  }

  Future<void> _onSave() async {
    if (!_isNextAvailable() || _isPosting) return;
    setState(() => _isPosting = true);

    try {
      if (_isEdit) {
        // ✅ 수정 로직: patch 업데이트
        final patch = <String, dynamic>{
          'title': _titleCtrl.text,
          'wantArea': _selectedWantAreas.toList(),
          'wantRoom': _selectedRoomTypes.toList(),
          'wantPay': _selectedPaymentStructures.toList(),
          'deposit': int.tryParse(_depositCtrl.text) ?? 0,
          'minRent': int.tryParse(_minRentCtrl.text) ?? 0,
          'maxRent': int.tryParse(_maxRentCtrl.text) ?? 0,
          'movingDate': _selectedMovingDate == null
              ? null
              : Timestamp.fromDate(_selectedMovingDate!),
          'minContract': int.tryParse(_minContractCtrl.text) ?? 0,
          'maxContract': int.tryParse(_maxContractCtrl.text) ?? 0,
          'introduction': _introductionCtrl.text,
        }..removeWhere((_, v) => v == null);

        await _postRepository.updatePost(widget.postToEdit!.postId!, patch);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('수정되었습니다.')),
        );
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const MainNavigation()),
          (route) => false,
        );
        return;
      }

      // ✅ 신규 생성 로직
      final newPost = SearcherPost(
        authorId: _currentUser!.uid,
        authorGender: _currentUser!.gender,
        title: _titleCtrl.text,
        wantArea: _selectedWantAreas.toList(),
        wantRoom: _selectedRoomTypes.toList(),
        deposit: int.tryParse(_depositCtrl.text) ?? 0,
        minRent: int.tryParse(_minRentCtrl.text) ?? 0,
        maxRent: int.tryParse(_maxRentCtrl.text) ?? 0,
        wantPay: _selectedPaymentStructures.toList(),
        movingDate: _selectedMovingDate != null
            ? Timestamp.fromDate(_selectedMovingDate!)
            : Timestamp.now(),
        minContract: int.tryParse(_minContractCtrl.text) ?? 0,
        maxContract: int.tryParse(_maxContractCtrl.text) ?? 0,
        introduction: _introductionCtrl.text,
        createdAt: DateTime.now(),
      );

      await _postRepository.createPost(newPost);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('게시글이 성공적으로 등록되었습니다!')),
      );
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainNavigation()),
        (Route<dynamic> route) => false,
      );
    } catch (e) {
      debugPrint("게시글 저장 오류: $e");
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('오류가 발생했습니다: $e')));
      }
    } finally {
      if (mounted) setState(() => _isPosting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final titleText = _isEdit ? '게시글 수정' : '게시글 작성';
    final buttonText = _isEdit ? '수정 완료' : '게시하기';

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          // ✅ 요구사항 2: 편집 모드에서 뒤로가기 버튼 표시
          automaticallyImplyLeading: _isEdit,
          elevation: 0,
          scrolledUnderElevation: 0,
          title: Text(
            titleText,
            style: TextStyle(fontSize: ResponsiveSizes.f(context, 20)),
          ),
        ),
        body: Padding(
          padding: EdgeInsets.all(ResponsiveSizes.p(context, 24)),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '제목을 입력해주세요!',
                  style: TextStyle(
                    fontSize: ResponsiveSizes.f(context, 16),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Gaps.v6(context),
                TextField(
                  controller: _titleCtrl,
                  decoration: const InputDecoration(
                    hintText: '제목 입력',
                    hintStyle: TextStyle(color: Colors.black38),
                    border: OutlineInputBorder(),
                  ),
                ),
                Gaps.v24(context),

                Text(
                  '희망 위치',
                  style: TextStyle(
                    fontSize: ResponsiveSizes.f(context, 16),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Gaps.v6(context),
                Wrap(
                  children: [
                    CategoryButton(
                      text: _selectedWantAreas.isEmpty
                          ? "선택하기"
                          : _selectedWantAreas.join(', '),
                      isSelected: _selectedWantAreas.isNotEmpty,
                      myonTap: _onAreaTap,
                    ),
                  ],
                ),
                Gaps.v24(context),

                Text(
                  '희망 방 종류/구조',
                  style: TextStyle(
                    fontSize: ResponsiveSizes.f(context, 16),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Gaps.v10(context),
                Wrap(
                  spacing: ResponsiveSizes.p(context, 8),
                  runSpacing: ResponsiveSizes.p(context, 8),
                  children: [
                    for (final option in _roomTypeOptions)
                      CategoryButton(
                        text: option,
                        isSelected: _selectedRoomTypes.contains(option),
                        myonTap: () => _onChipTap(_selectedRoomTypes, option),
                      ),
                  ],
                ),
                Gaps.v24(context),

                Text(
                  '수용 가능 보증금/월세(관리비 포함)',
                  style: TextStyle(
                    fontSize: ResponsiveSizes.f(context, 16),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Gaps.v6(context),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _depositCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          hintText: "보증금(만 원)",
                          hintStyle: TextStyle(color: Colors.black38),
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    Gaps.h8(context),
                    Expanded(
                      child: TextField(
                        controller: _minRentCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          hintText: "최소 월세(만 원)",
                          hintStyle: TextStyle(color: Colors.black38),
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    Gaps.h8(context),
                    Expanded(
                      child: TextField(
                        controller: _maxRentCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          hintText: "최대 월세(만 원)",
                          hintStyle: TextStyle(color: Colors.black38),
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                Gaps.v24(context),

                Text(
                  '희망 지불 구조',
                  style: TextStyle(
                    fontSize: ResponsiveSizes.f(context, 16),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Gaps.v10(context),
                Wrap(
                  spacing: ResponsiveSizes.p(context, 8),
                  runSpacing: ResponsiveSizes.p(context, 8),
                  children: [
                    for (final option in _paymentOptions)
                      CategoryButton(
                        text: option,
                        isSelected: _selectedPaymentStructures.contains(option),
                        myonTap: () =>
                            _onChipTap(_selectedPaymentStructures, option),
                      ),
                  ],
                ),
                Gaps.v24(context),

                Text(
                  '입주 희망일',
                  style: TextStyle(
                    fontSize: ResponsiveSizes.f(context, 16),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Gaps.v6(context),
                TextField(
                  onTap: _onTimeFieldTap,
                  controller: _movingDateCtrl,
                  readOnly: true,
                  decoration: const InputDecoration(
                    hintText: '입주 희망일 선택',
                    hintStyle: TextStyle(color: Colors.black38),
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(CupertinoIcons.calendar),
                  ),
                ),
                Gaps.v24(context),

                Text(
                  '희망 계약 기간',
                  style: TextStyle(
                    fontSize: ResponsiveSizes.f(context, 16),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Gaps.v6(context),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _minContractCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          hintText: "최소(개월)",
                          hintStyle: TextStyle(color: Colors.black38),
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    Gaps.h12(context),
                    Expanded(
                      child: TextField(
                        controller: _maxContractCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          hintText: "최대(개월)",
                          hintStyle: TextStyle(color: Colors.black38),
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                Gaps.v24(context),

                Text(
                  '자유 소개',
                  style: TextStyle(
                    fontSize: ResponsiveSizes.f(context, 16),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Gaps.v6(context),
                TextField(
                  controller: _introductionCtrl,
                  minLines: null,
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                  decoration: const InputDecoration(
                    hintText: '자유롭게 글을 작성해주세요!',
                    hintStyle: TextStyle(color: Colors.black38),
                    border: OutlineInputBorder(),
                  ),
                ),
                Gaps.v24(context),

                GestureDetector(
                  onTap: _isPosting ? null : _onSave,
                  child: FormButton(
                    enabled: _isNextAvailable(),
                    widget: _isPosting
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            buttonText,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: ResponsiveSizes.f(context, 16),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
