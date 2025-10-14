import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:roommate/class/app_user.dart';
import 'package:roommate/class/searcher_post.dart';
import 'package:roommate/class/searcher_post_repository.dart';
import 'package:roommate/class/user_repository.dart';
import 'package:roommate/constants/gaps.dart';
import 'package:roommate/features/authentication/userinfo/searcher_screen.dart'; // ✅ SearcherScreen import
import 'package:roommate/features/category/widgets/category_button.dart';
import 'package:roommate/features/navigationbar/main_navigation.dart';
import 'package:roommate/features/post/widgets/form_button.dart';
import 'package:roommate/constants/responsive_sizes.dart';

class SearcherPostScreen extends StatefulWidget {
  const SearcherPostScreen({super.key});

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

  // Chip 및 위치 선택 상태
  final Set<String> _selectedWantAreas = {}; // ✅ 희망 위치 저장
  final Set<String> _selectedRoomTypes = {};
  final Set<String> _selectedPaymentStructures = {};

  // Chip 옵션
  final List<String> _roomTypeOptions = ['원 룸', '투 룸', '빌라', '아파트'];
  final List<String> _paymentOptions = ['보증금 분담', '월세 분담', '관리비 분담', '공과금 분담'];

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    // 컨트롤러 리스너 추가하여 버튼 상태 실시간 업데이트
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
    for (var controller in controllers) {
      controller.addListener(() => setState(() {}));
    }
  }

  Future<void> _loadCurrentUser() async {
    _currentUser = await _userRepository.fetchMe();
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
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
    for (var controller in controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  // ✅ 1. 희망 위치 선택 화면으로 이동하고 결과를 받아오는 함수
  Future<void> _onAreaTap() async {
    // SearcherScreen으로 이동하고, List<String> 타입의 결과를 기다립니다.
    final List<String>? result = await Navigator.of(context).push(
      MaterialPageRoute(
        // SearcherScreen이 이제 선택기(picker)로 사용됩니다.
        builder: (context) => const SearcherScreen(),
      ),
    );

    // 결과가 null이 아니고 비어있지 않다면, 상태를 업데이트합니다.
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
    // ✅ 희망 위치 선택 여부도 검사에 포함
    final allChipsSelected =
        _selectedWantAreas.isNotEmpty &&
        _selectedRoomTypes.isNotEmpty &&
        _selectedPaymentStructures.isNotEmpty;
    return allFieldsFilled && allChipsSelected && _currentUser != null;
  }

  void _onSave() async {
    if (!_isNextAvailable() || _isPosting) return;
    setState(() => _isPosting = true);

    try {
      final newPost = SearcherPost(
        authorId: _currentUser!.uid,
        authorGender: _currentUser!.gender,
        title: _titleCtrl.text,
        wantArea: _selectedWantAreas.toList(), // ✅ 선택된 희망 위치 저장
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

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('게시글이 성공적으로 등록되었습니다!')));
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const MainNavigation()),
          (Route<dynamic> route) => false,
        );
      }
    } catch (e) {
      print(">> uid: ${_currentUser!.uid}");
      debugPrint("게시글 생성 오류: $e");
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
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false, // ← 기본 뒤로가기 아이콘 숨김
          elevation: 0,
          scrolledUnderElevation: 0,
          title: Text(
            '게시글 작성',
            style: TextStyle(fontSize: ResponsiveSizes.f(context, 20)),
          ),
        ),
        body: Padding(
          padding: EdgeInsets.all(
            ResponsiveSizes.p(context, 24),
          ),
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
                // ✅ 2. TextField를 CategoryButton 형태로 대체
                Wrap(
                  children: [
                    CategoryButton(
                      text: _selectedWantAreas.isEmpty
                          ? "선택하기"
                          : _selectedWantAreas.join(', '), // 선택된 지역 표시
                      isSelected: _selectedWantAreas.isNotEmpty,
                      myonTap: _onAreaTap, // 탭하면 선택 화면으로 이동
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
                            '게시하기',
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
