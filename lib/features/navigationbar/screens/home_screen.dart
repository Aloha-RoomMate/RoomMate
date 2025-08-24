import 'package:flutter/material.dart';
import 'package:roommate/constants/sizes.dart';
import 'package:roommate/features/navigationbar/widgets/post_container.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        // TabBar와 TabBarView를 하나의 위젯으로 묶어주는 Column
        children: [
          // 상단에 TabBar 배치
          TabBar(
            labelColor: Theme.of(context).primaryColor,
            unselectedLabelColor: Colors.black87,
            indicatorSize: TabBarIndicatorSize.tab,
            indicator: UnderlineTabIndicator(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: Theme.of(context).primaryColor,
                width: 2.0,
              ),
            ),
            tabs: [
              Tab(text: "Room-Owner"),
              Tab(text: "Searcher"),
            ],
          ),
          // 나머지 공간에 TabBarView를 채우기 위해 Expanded 사용
          Expanded(
            child: TabBarView(
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: Sizes.size8,
                  ),
                  child: Column(
                    children: [PostContainer(), PostContainer()],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: Sizes.size8,
                  ),
                  child: Column(
                    children: [PostContainer(), PostContainer()],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
