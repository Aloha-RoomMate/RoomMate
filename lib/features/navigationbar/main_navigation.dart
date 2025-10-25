import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:roommate/class/app_user.dart';
import 'package:roommate/class/user_repository.dart';
import 'package:roommate/constants/responsive_sizes.dart';
import 'package:roommate/features/authentication/login/login_screen.dart';
import 'package:roommate/features/chat/chat_list_screen.dart';
import 'package:roommate/features/navigationbar/screens/home_screen.dart';
import 'package:roommate/features/navigationbar/screens/map_screen.dart';
import 'package:roommate/features/navigationbar/screens/mypage_screen.dart';
import 'package:roommate/features/navigationbar/widgets/feed_filter.dart';
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

  final List<String> _appBarTitles = [
    '홈',
    '유저추천',
    '글 쓰기',
    '맵',
    '채팅',
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
    if (user == null) {
      _toast('로그인이 만료되었습니다.');
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
      return;
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const MypageScreen(isBlocked: false),
        ),
      );
    }
  }

  PreferredSizeWidget? _buildAppBar() {
    if (_selectedIndex == 1 || _selectedIndex == 2) return null;

    final title = _appBarTitles[_selectedIndex];
    final actions = <Widget>[];

    if (_selectedIndex == 0) {
      actions.add(
        IconButton(
          tooltip: '필터',
          onPressed: () {
            FeedFilterBottomSheet.show(context);
          },
          icon: const FaIcon(FontAwesomeIcons.filter),
        ),
      );
      actions.add(
        IconButton(
          onPressed: () => _onMypageTap(_currentUser),
          icon: const FaIcon(FontAwesomeIcons.solidUser),
          tooltip: '마이페이지',
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
        border: Border(top: BorderSide(color: cs.outlineVariant, width: 0.6)),
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
                return;
              }
              if (_currentUser!.userPass?.pass == false) {
                _showNeedInfoDialog(
                  title: '프로필 정보가 부족합니다',
                  message:
                      '마이페이지에서 추가로 정보를 입력하세요.\n생활패턴/공동생활/건강정보/자기소개가 충분해야 게시글 작성이 가능합니다.',
                );
                return;
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
    final body = IndexedStack(
      index: _selectedIndex,
      children: [
        HomeScreen(),
        UserListScreen(),
        _currentUser?.userType?.type == "roomOwner"
            ? const RoomOwnerPostScreen()
            : const SearcherPostScreen(),
        MapScreen(),
        ChatListScreen(),
      ],
    );

    return Scaffold(
      appBar: _buildAppBar(),
      body: body,
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }
}
