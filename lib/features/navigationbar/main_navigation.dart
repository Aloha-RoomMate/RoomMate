import 'dart:async';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:roommate/class/app_user.dart';
import 'package:roommate/class/user_repository.dart';
import 'package:roommate/constants/sizes.dart';
import 'package:roommate/features/navigationbar/screens/chat_screen.dart';
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
  // 현재 사용자 저장할 변수s
  AppUser? _currentUser;
  final UserRepository _userRepository = UserRepository();
  // 실시간 사용자 정보 저장을 위한 변수
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
    // 화면 시작 시 현재 유저 실시간 감시 시작.
    super.initState();
    _userSubscription = _userRepository.watchMe().listen((user) {
      // 변화 생기면 _currentUser 업데이트
      setState(() {
        _currentUser = user;
      });
    });
  }

  @override
  void dispose() {
    // 화면이 종료될 때, 메모리 누수를 막기 위해 감시를 중단
    _userSubscription.cancel();
    super.dispose();
  }

  void _onNavTab(int index) {
    _selectedIndex = index;
    setState(() {});
  }

  void _onPostTap(AppUser? user) {
    // 사용자가 아직 로딩 중이거나 로그아웃 상태이면 아무것도 하지 않음
    if (user == null || user.userType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('사용자 정보를 불러오는 중입니다...')),
      );
      return;
    }

    if (user.userType!.type == 'roomOwner') {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => const RoomOwnerPostScreen()),
      );
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => const SearcherPost()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: Sizes.size40,
        title: Text(_appBarTitles[_selectedIndex]),
        actionsPadding: EdgeInsets.only(
          right: Sizes.size20,
        ),
        actions: [
          GestureDetector(
            onTap: () => _onPostTap(_currentUser),
            child: FaIcon(FontAwesomeIcons.plus),
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          HomeScreen(),
          ChatScreen(),
          _selectedIndex == 2 ? MapScreen() : SizedBox.shrink(),
          MypageScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        onTap: _onNavTab,
        currentIndex: _selectedIndex,
        unselectedItemColor: Colors.grey,
        selectedItemColor: Theme.of(context).primaryColor,
        items: <BottomNavigationBarItem>[
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
