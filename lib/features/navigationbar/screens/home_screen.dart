import 'package:flutter/material.dart';
import 'package:roommate/features/view/post_list_view.dart';
import 'package:roommate/features/navigationbar/widgets/feed_filter.dart'; // FeedTarget import

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    this.targetNotifier,
  });

  /// 현재 탭의 FeedTarget을 부모(MainNavigation)에 알려주기 위한 notifier
  final ValueNotifier<FeedTarget>? targetNotifier;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  void _emitTarget() {
    final t = (_tabController.index == 1)
        ? FeedTarget.searcher
        : FeedTarget.roomOwner;
    widget.targetNotifier?.value = t;
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) _emitTarget();
    });
    // 초기값도 한 번 발행
    WidgetsBinding.instance.addPostFrameCallback((_) => _emitTarget());
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
