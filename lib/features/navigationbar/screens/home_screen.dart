import 'package:flutter/material.dart';
import 'package:roommate/features/view/post_list_view.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabBar(
          controller: _tabController,
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
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: const [
              PostListView(postType: 'roomOwner'),
              PostListView(postType: 'Searcher'),
            ],
          ),
        ),
      ],
    );
  }
}
