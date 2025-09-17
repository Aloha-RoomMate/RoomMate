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
import 'package:roommate/features/navigationbar/screens/mypage_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  // 현재 사용자 저장할 변수
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

  void _onNavTab(int index) {
    _selectedIndex = index;
    setState(() {});
  }

  void _onPostTap(UserType? userType) {}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: Sizes.size40,
        title: Text(_appBarTitles[_selectedIndex]),
        actionsPadding: EdgeInsets.only(
          right: Sizes.size20,
        ),
        actions: [GestureDetector(child: FaIcon(FontAwesomeIcons.plus))],
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
