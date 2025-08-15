import 'package:flutter/material.dart';

class MypageScreen extends StatelessWidget {
  const MypageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("마이페이지"),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Container(
            color: Theme.of(context).primaryColor.withAlpha(50),
            height: 1,
          ),
        ),
      ),
    );
  }
}
