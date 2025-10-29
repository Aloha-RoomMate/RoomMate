// lib/features/navigationbar/main_navigation.dart
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
  const MainNavigation({
    super.key,
    this.initialIndex = 0,
    this.openMyPageOnStart = false, // ✅ Complete 이후 자동으로 마이페이지 열고 싶을 때 true
  });

  /// 시작 탭 인덱스 (0~4)
  final int initialIndex;

  /// 첫 진입 시 마이페이지를 바로 push로 띄울지 여부
  final bool openMyPageOnStart;

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

  late int _selectedIndex;

  @override
  void initState() {
    super.initState();

    // 초기 탭 인덱스 보정
    _selectedIndex = (widget.initialIndex >= 0 && widget.initialIndex <= 4)
        ? widget.initialIndex
        : 0;

    // 내 정보 구독
    _userSubscription = _userRepository.watchMe().listen((user) {
      if (!mounted) return;
      setState(() => _currentUser = user);
    });

    // 첫 진입 시 마이페이지 자동 오픈 옵션 처리
    if (widget.openMyPageOnStart) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _onMypageTap(_currentUser);
      });
    }
  }

  @override
  void dispose() {
    _userSubscription.cancel();
    super.dispose();
  }

  void _onNavTab(int index) {
    setState(() => _selectedIndex = index);
  }

  Widget _scaledIcon(IconData data, int itemIndex) {
    final isSelected = _selectedIndex == itemIndex;
    return Center(
      // ← 아이콘 영역 전체에서 정확히 가운데 정렬
      child: AnimatedScale(
        scale: isSelected ? 1.15 : 1.0,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        child: FaIcon(data, size: 22), // SizedBox 제거(위로 붙는 현상 방지)
      ),
    );
  }

  void _goMyPage({bool blocked = true}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MypageScreen(isBlocked: blocked),
      ),
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
              _goMyPage(blocked: true);
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
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const MypageScreen(isBlocked: false),
      ),
    );
  }

  PreferredSizeWidget? _buildAppBar() {
    // 추천/글쓰기 탭에서는 앱바 숨김
    if (_selectedIndex == 1 || _selectedIndex == 2) return null;

    final title = _appBarTitles[_selectedIndex];
    final actions = <Widget>[];

    if (_selectedIndex == 0) {
      actions.add(
        IconButton(
          tooltip: '필터',
          onPressed: () => FeedFilterBottomSheet.show(context),
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
        bottom: false,
        child: BottomNavigationBar(
          onTap: (i) {
            HapticFeedback.selectionClick();

            // 가운데 '글 쓰기' 탭 접근 제어
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
          // ⬇️ 아이콘 크기 통일
          selectedIconTheme: const IconThemeData(size: 23),
          unselectedIconTheme: const IconThemeData(size: 21),
          items: navItems,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final body = IndexedStack(
      index: _selectedIndex,
      children: const [
        HomeScreen(),
        UserListScreen(),
        // 글쓰기 탭은 유저 타입에 따라 분기할 수도 있지만,
        // IndexedStack 내에서는 빌드 시점에 타입 접근이 번거로우므로
        // 아래와 같이 두 화면 중 하나를 선택하는 래퍼를 둔다.
        _PostEntryDecider(),
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

/// 글쓰기 탭에서 유저 타입에 따라 화면 분기
class _PostEntryDecider extends StatelessWidget {
  const _PostEntryDecider();

  @override
  Widget build(BuildContext context) {
    // UserRepository는 상위에서 이미 사용 중이므로 여기서도 재사용
    final repo = UserRepository();
    return StreamBuilder<AppUser?>(
      stream: repo.watchMe(), // ✅ 실시간 반영
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final me = snapshot.data!;
        final isOwner = (me.userType?.type ?? '').toLowerCase().contains(
          'owner',
        );

        // ✅ 타입이 바뀌면 다른 키로 교체되어 이전 화면 상태를 폐기
        final key = ValueKey('${me.uid}_${isOwner ? 'owner' : 'searcher'}');
        return KeyedSubtree(
          key: key,
          child: isOwner
              ? const RoomOwnerPostScreen()
              : const SearcherPostScreen(),
        );
      },
    );
  }
}
