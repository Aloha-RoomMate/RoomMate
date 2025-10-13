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

  // 실시간 감시를 위한 구독 객체 선언
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

  void _onPostTap(AppUser? user) {
    // 사용자가 아직 로딩 중이거나 로그아웃 상태이면 아무것도 하지 않음
    if (user == null || user.userType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('사용자 정보를 불러오는 중입니다...')),
      );
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => LoginScreen(),
        ),
      );
      return;
    }

    if (user.userType!.type == 'roomOwner') {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => const RoomOwnerPostScreen()),
      );
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => const SearcherPostScreen()),
      );
    }
  }

  void _onNavTab(int index) {
    _selectedIndex = index;
    setState(() {});
  }

  Future<void> _signOut(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (context.mounted) {
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => LoginScreen()));
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
          ChatListScreen(), //이거 오류나서 chatroom을 바로 만들지 않고 채팅 리스트를 만들어서 push 하며, chatroomId 를 넘겨줘야한다.
          _selectedIndex == 2 ? MapScreen() : SizedBox.shrink(),
          _selectedIndex == 3
              ? MypageScreen(
                  isBlocked: true,
                )
              : SizedBox.shrink(),
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
