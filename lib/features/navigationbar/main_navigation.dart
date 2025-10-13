import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:roommate/class/app_user.dart';
import 'package:roommate/class/user_repository.dart';
import 'package:roommate/constants/responsive_sizes.dart';
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
    '추천 유저', // 1 (상단 AppBar 숨김)
    '글 쓰기', // 2 (상단 AppBar 숨김)
    '지도', // 3
    '채팅', // 4
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

  // ---------- helpers ----------
  void _goMyPage() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => MypageScreen(isBlocked: true)),
    );
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

  void _onMypageTap(AppUser? user) {
    // 로그인 안되어 있으면
    if (user == null) {
      _toast('로그인이 만료되었습니다.');
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
      return;
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const MypageScreen(
            isBlocked: false,
          ),
        ),
      );
    }
  }

  /// 인덱스별 AppBar 구성
  PreferredSizeWidget? _buildAppBar() {
    // 유저추천(1)과 글쓰기(2)는 하위 위젯이 자체 AppBar를 가짐 → 상위 AppBar 숨김
    if (_selectedIndex == 1 || _selectedIndex == 2) return null;

    final title = _appBarTitles[_selectedIndex];

    // 홈(0)만 + 아이콘 노출
    final actions = <Widget>[];
    if (_selectedIndex == 0) {
      actions.add(
        IconButton(
          onPressed: () => _onMypageTap(_currentUser),
          icon: const FaIcon(FontAwesomeIcons.solidUser),
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
        icon: _scaledIcon(FontAwesomeIcons.star, 1),
        label: '추천 유저',
      ),
      BottomNavigationBarItem(
        icon: _scaledIcon(FontAwesomeIcons.solidSquarePlus, 2),
        label: '글 쓰기',
      ),
      BottomNavigationBarItem(
        icon: _scaledIcon(FontAwesomeIcons.map, 3),
        label: '지도',
      ),
      BottomNavigationBarItem(
        icon: _scaledIcon(FontAwesomeIcons.message, 4),
        label: '채팅',
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
            if (i == 2) {
              if (_currentUser == null) {
                _toast('로그인이 만료되었습니다.');
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
                return; // 여기서 return하여 _onNavTab(i)가 호출되지 않도록 함
              }
              if (_currentUser!.userPass?.pass == false) {
                _showNeedInfoDialog(
                  title: '프로필 정보가 부족합니다',
                  message:
                      '마이페이지에서 추가로 정보를 입력하세요.\n생활패턴/공동생활/건강정보/자기소개가 충분해야 게시글 작성이 가능합니다.',
                );
                return; // 여기서 return하여 _onNavTab(i)가 호출되지 않도록 함
              }
            }
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
      children: [
        HomeScreen(), // 0
        UserListScreen(), // 1 ★ 유저추천 (자체 Scaffold+AppBar)
        _currentUser?.userType?.type == "roomOwner"
            ? RoomOwnerPostScreen()
            : SearcherPostScreen(),
        MapScreen(), // 3
        ChatListScreen(), // 4 (자체 AppBar 사용)
      ],
    );

    return Scaffold(
      appBar: _buildAppBar(),
      body: body,
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }
}
