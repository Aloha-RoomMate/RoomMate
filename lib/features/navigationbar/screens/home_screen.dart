import 'package:flutter/material.dart';
import 'package:roommate/features/navigationbar/widgets/post_list_view.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
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
            tabs: const [
              Tab(text: "Room-Owner"),
              Tab(text: "Searcher"),
            ],
          ),
          const Expanded(
            child: TabBarView(
              children: [
                // 각 탭에 PostListView를 배치하고, postType을 전달.
                PostListView(postType: 'roomOwner'),
                // TODO: SearcherPost 모델이 준비되면 아래를 활성화
                // PostListView(postType: 'Searcher'),
                PostListView(postType: 'Searcher'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
