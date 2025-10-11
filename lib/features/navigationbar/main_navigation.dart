import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:roommate/class/app_user.dart';
import 'package:roommate/class/user_repository.dart';
import 'package:roommate/constants/sizes.dart';
import 'package:roommate/features/authentication/login/login_screen.dart';
import 'package:roommate/features/chat/chatlist_screen.dart';
import 'package:roommate/features/navigationbar/screens/home_screen.dart';
import 'package:roommate/features/navigationbar/screens/map_screen.dart';
import 'package:roommate/features/navigationbar/screens/mypage_screen.dart';
import 'package:roommate/features/post/room_owner_post_screen.dart';
import 'package:roommate/features/post/searcher_post_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  AppUser? _currentUser;
  final UserRepository _userRepository = UserRepository();

  late final StreamSubscription<AppUser?> _userSubscription;

  final List<String> _appBarTitles = [
    '홈',
    '채팅',
    '지도',
    '마이페이지',
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
      _selectedIndex = 3; // 마이페이지 탭
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
            '마이페이지에서 추가로 정보를 입력하세요.\n'
            '생활패턴/공동생활/건강정보/자기소개가 충분해야 게시글 작성이 가능합니다.',
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
    // 마이페이지는 하위 위젯(MypageScreen)이 자체 AppBar를 가짐 → 상위 AppBar 숨김
    if (_selectedIndex == 3) return null;

    final title = _appBarTitles[_selectedIndex];

    // 홈만 + 아이콘 노출
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
      automaticallyImplyLeading: false,
      backgroundColor: Colors.white,
      toolbarHeight: Sizes.size40,
      title: Text(title),
      actionsPadding: const EdgeInsets.only(right: Sizes.size20),
      actions: actions,
    );
  }

  @override
  Widget build(BuildContext context) {
    // body: 인덱스별로 화면 배치, 앱바 컨트롤
    final body = IndexedStack(
      index: _selectedIndex,
      children: const [
        HomeScreen(), // 0
        ChatListScreen(), // 1
        MapScreen(), // 2
        MypageScreen(isBlocked: true), // 3 (자체 AppBar 사용)
      ],
    );

    return Scaffold(
      appBar: _buildAppBar(),
      body: body,
      bottomNavigationBar: BottomNavigationBar(
        onTap: _onNavTab,
        currentIndex: _selectedIndex,
        unselectedItemColor: Colors.grey,
        selectedItemColor: Theme.of(context).primaryColor,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: FaIcon(FontAwesomeIcons.house),
            label: '홈',
          ),
          BottomNavigationBarItem(
            icon: FaIcon(FontAwesomeIcons.message),
            label: '채팅',
          ),
          BottomNavigationBarItem(
            icon: FaIcon(FontAwesomeIcons.map),
            label: '지도',
          ),
          BottomNavigationBarItem(
            icon: FaIcon(FontAwesomeIcons.user),
            label: '마이페이지',
          ),
        ],
      ),
    );
  }
}
