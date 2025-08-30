import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:roommate/constants/sizes.dart';
import 'package:roommate/features/navigationbar/screens/chat_screen.dart';
import 'package:roommate/features/navigationbar/screens/home_screen.dart';
import 'package:roommate/features/navigationbar/screens/map_screen.dart';
import 'package:roommate/features/navigationbar/screens/mypage_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  final List<String> _appBarTitles = [
    '홈',
    '채팅',
    '지도',
    '마이페이지',
  ];

  int _selectedIndex = 0;

  void _onNavTab(int index) {
    _selectedIndex = index;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: Sizes.size40,
        title: Text(_appBarTitles[_selectedIndex]),
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
