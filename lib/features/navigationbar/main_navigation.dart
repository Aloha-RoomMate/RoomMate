import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'package:roommate/class/app_user.dart';
import 'package:roommate/class/user_repository.dart';
import 'package:roommate/constants/responsive_sizes.dart';

// Screens
import 'package:roommate/features/authentication/login/login_screen.dart';
import 'package:roommate/features/chat/chatlist_screen.dart';
import 'package:roommate/features/navigationbar/screens/home_screen.dart';
import 'package:roommate/features/navigationbar/screens/map_screen.dart';
import 'package:roommate/features/navigationbar/screens/mypage_screen.dart';
import 'package:roommate/features/post/room_owner_post_screen.dart';
import 'package:roommate/features/post/searcher_post_screen.dart';
import 'package:roommate/features/recommend/userlist_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  AppUser? _currentUser;
  final UserRepository _userRepository = UserRepository();

  late final StreamSubscription<AppUser?> _userSubscription;

  // 탭 타이틀 (상단 AppBar용) — 유저추천/마이페이지 탭은 상단 AppBar를 숨기므로 실사용은 안 되지만 안전하게 포함
  final List<String> _appBarTitles = [
    '홈', // 0
    '유저추천', // 1 (상단 AppBar 숨김)
    '채팅', // 2
    '맵', // 3
    '마이페이지', // 4 (상단 AppBar 숨김)
  ];

  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _userSubscription = _userRepository.watchMe().listen((user) {
      if (mounted) {
        setState(() {
          _currentUser = user;
        });
      }
    });
  }

  @override
  void dispose() {
    _userSubscription.cancel();
    super.dispose();
  }

  void _onNavTab(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _scaledIcon(IconData data, int itemIndex) {
    final isSelected = _selectedIndex == itemIndex;
    return SizedBox(
      // 아이콘 캔버스 고정 → 레이아웃 흔들림 방지
      width: 24,
      height: 24,
      child: AnimatedScale(
        scale: isSelected ? 1.15 : 1.0,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        child: FaIcon(data),
      ),
    );
  }

  Future<void> _signOut(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (context.mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  // ---------- helpers ----------
  void _goMyPage() {
    setState(() {
      _selectedIndex = 4; // 마이페이지 탭(인덱스 변경: 3 -> 4)
    });
  }

  Future<void> _showNeedInfoDialog({
    required String title,
    required String message,
  }) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('닫기'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _goMyPage();
            },
            child: const Text('마이페이지로 이동'),
          ),
        ],
      ),
    );
  }

  void _toast(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  // ---------- + 버튼 동작 ----------
  void _onPostTap(AppUser? user) {
    // 1) 로그인/로딩 체크
    if (user == null) {
      _toast('사용자 정보를 불러오는 중입니다...');
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
      return;
    }

    // 2) userType 미설정 → 안내
    if (user.userType == null || user.userType?.type == null) {
      _showNeedInfoDialog(
        title: '먼저 사용자 유형을 설정해주세요',
        message: '게시글을 등록하려면 마이페이지에서 사용자 유형을 선택해야 합니다.',
      );
      return;
    }

    // 3) userPass 미통과 → 안내
    final bool isPassed = user.userPass?.pass == true;
    if (!isPassed) {
      _showNeedInfoDialog(
        title: '프로필 정보가 부족합니다',
        message:
            '마이페이지에서 추가로 정보를 입력하세요.\n생활패턴/공동생활/건강정보/자기소개가 충분해야 게시글 작성이 가능합니다.',
      );
      return;
    }

    // 4) 통과 → 유형별 화면 이동
    if (user.userType!.type == 'roomOwner') {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const RoomOwnerPostScreen()),
      );
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const SearcherPostScreen()),
      );
    }
  }

  /// 인덱스별 AppBar 구성
  PreferredSizeWidget? _buildAppBar() {
    // 유저추천(1)과 마이페이지(4)는 하위 위젯이 자체 AppBar를 가짐 → 상위 AppBar 숨김
    if (_selectedIndex == 1 || _selectedIndex == 4) return null;

    final title = _appBarTitles[_selectedIndex];

    // 홈(0)만 + 아이콘 노출
    final actions = <Widget>[];
    if (_selectedIndex == 0) {
      actions.add(
        IconButton(
          onPressed: () => _onPostTap(_currentUser),
          icon: const FaIcon(FontAwesomeIcons.plus),
          tooltip: '게시글 작성',
        ),
      );
    }

    return AppBar(
      scrolledUnderElevation: 0,
      automaticallyImplyLeading: false,
      backgroundColor: Colors.white,
      toolbarHeight: ResponsiveSizes.p(context, 40),
      title: Text(title),
      actionsPadding: EdgeInsets.only(right: ResponsiveSizes.p(context, 20)),
      actions: actions,
    );
  }

  Widget _buildBottomNavigationBar() {
    final cs = Theme.of(context).colorScheme;

    final navItems = <BottomNavigationBarItem>[
      BottomNavigationBarItem(
        icon: _scaledIcon(FontAwesomeIcons.house, 0),
        label: '홈',
      ),
      BottomNavigationBarItem(
        icon: _scaledIcon(FontAwesomeIcons.userGroup, 1),
        label: '유저추천',
      ),
      BottomNavigationBarItem(
        icon: _scaledIcon(FontAwesomeIcons.message, 2),
        label: '채팅',
      ),
      BottomNavigationBarItem(
        icon: _scaledIcon(FontAwesomeIcons.map, 3),
        label: '맵',
      ),
      BottomNavigationBarItem(
        icon: _scaledIcon(FontAwesomeIcons.user, 4),
        label: '마이페이지',
      ),
    ];

    return DecoratedBox(
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(
          top: BorderSide(color: cs.outlineVariant, width: 0.6),
        ), // 헤어라인
      ),
      child: SafeArea(
        top: false,
        child: BottomNavigationBar(
          onTap: (i) {
            HapticFeedback.selectionClick();
            _onNavTab(i);
          },
          currentIndex: _selectedIndex,
          type: BottomNavigationBarType.fixed,
          backgroundColor: cs.surface,
          elevation: 0,
          selectedItemColor: cs.primary,
          unselectedItemColor: cs.onSurfaceVariant,
          showUnselectedLabels: true,
          items: navItems,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // body: 인덱스별로 화면 배치, 앱바 컨트롤
    final body = IndexedStack(
      index: _selectedIndex,
      children: const [
        HomeScreen(), // 0
        UserListScreen(), // 1 ★ 유저추천 (자체 Scaffold+AppBar)
        ChatListScreen(), // 2
        MapScreen(), // 3
        MypageScreen(isBlocked: true), // 4 (자체 AppBar 사용)
      ],
    );

    return Scaffold(
      appBar: _buildAppBar(),
      body: body,
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }
}
