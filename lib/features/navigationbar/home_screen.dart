import 'package:flutter/material.dart';
import 'package:roommate/constants/sizes.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2, // 탭 수
      child: Scaffold(
        backgroundColor: Colors.white,

        appBar: AppBar(
          title: const Text("홈"),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(48 + 1),
            child: Column(
              children: [
                // TabBar
                TabBar(
                  // 스타일은 필요 시 조정
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.black87,
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicator: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Theme.of(context).primaryColor,
                  ),
                  tabs: const [
                    Tab(text: "룸오너"),
                    Tab(text: "서쳐"),
                  ],
                ),
                // 하단 구분선
                Container(
                  color: Theme.of(context).primaryColor.withAlpha(50),
                  height: 1,
                ),
              ],
            ),
          ),
        ),
        body: const TabBarView(
          // 각 탭의 화면
          children: [
            Center(child: Text("룸오너 화면")),
            Center(child: Text("서쳐 화면")),
          ],
        ),
      ),
    );
  }
}
