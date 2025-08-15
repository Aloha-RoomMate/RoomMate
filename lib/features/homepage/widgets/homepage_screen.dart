import 'package:flutter/material.dart';
import 'package:roommate/constants/sizes.dart';
import 'package:roommate/features/navigationbar/chat_screen.dart';
import 'package:roommate/features/navigationbar/home_screen.dart';
import 'package:roommate/features/navigationbar/map_screen.dart';
import 'package:roommate/features/navigationbar/mypage_screen.dart';

class HomepageScreen extends StatefulWidget {
  const HomepageScreen({super.key});

  @override
  State<HomepageScreen> createState() => _HomepageScreenState();
}

class _HomepageScreenState extends State<HomepageScreen> {
  int _index = 0;

  // 각 탭 화면
  late final List<Widget> _pages = const [
    HomeScreen(key: PageStorageKey('home')),
    ChatScreen(key: PageStorageKey('chat')),
    MapScreen(key: PageStorageKey('map')),
    MypageScreen(key: PageStorageKey('mypage')),
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Padding(
              padding: const EdgeInsets.all(Sizes.size4),

              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, anim) {
                  final isForward = child.key == ValueKey(_index);
                  final beginOffset = isForward
                      ? const Offset(0, 0.04)
                      : const Offset(0, -0.04);
                  return FadeTransition(
                    opacity: anim,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: beginOffset,
                        end: Offset.zero,
                      ).animate(anim),
                      child: child,
                    ),
                  );
                },

                child: IndexedStack(
                  key: ValueKey(_index),
                  index: _index,
                  children: _pages,
                ),
              ),
            ),
          ),
        ),
      ),

      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          height: 72,
          elevation: 12,
          indicatorColor: cs.primary.withAlpha(25),
          indicatorShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            final isSelected = states.contains(WidgetState.selected);
            return TextStyle(
              fontSize: isSelected ? 0 : 0,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            );
          }),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            final isSelected = states.contains(WidgetState.selected);
            return IconThemeData(
              size: isSelected ? 30 : 28,
              color: isSelected
                  ? cs.primary
                  : cs.onSurfaceVariant.withAlpha(40),
            );
          }),
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
        ),
        child: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: '',
            ),
            NavigationDestination(
              icon: Icon(Icons.chat_bubble_outline_rounded),
              selectedIcon: Icon(Icons.chat_bubble_rounded),
              label: '',
            ),
            NavigationDestination(
              icon: Icon(Icons.map_outlined),
              selectedIcon: Icon(Icons.map_rounded),
              label: '',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline_rounded),
              selectedIcon: Icon(Icons.person_rounded),
              label: '',
            ),
          ],
        ),
      ),
    );
  }
}
