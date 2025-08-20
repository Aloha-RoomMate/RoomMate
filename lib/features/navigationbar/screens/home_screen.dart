import 'package:flutter/material.dart';
import 'package:roommate/constants/sizes.dart';
import 'package:roommate/features/navigationbar/widgets/post_container.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('홈'),
          bottom: TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.black87,
            indicatorSize: TabBarIndicatorSize.tab,
            indicator: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Theme.of(context).primaryColor,
            ),
            tabs: const [
              Tab(text: "Room-Owner"),
              Tab(text: "Searcher"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            PostContainer(),
            PostContainer(),
          ],
        ),
      ),
    );
  }
}
