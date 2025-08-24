import 'package:flutter/material.dart';
import 'package:roommate/constants/sizes.dart';
import 'dart:ui';

class MypageScreen extends StatelessWidget {
  const MypageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(Sizes.size12),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // 이전 DrawerHeader와 InkWell 로직을 일반적인 위젯으로 변경
          // DrawerHeader는 Drawer 위젯 내에서 사용될 때 의미가 있습니다.
          SafeArea(
            child: Align(
              alignment: Alignment.topLeft,
              child: InkWell(
                onTap: () => Navigator.of(context).pop(),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.2),
                        spreadRadius: 1,
                        blurRadius: 3,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 18,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ),
            ),
          ),
          const ListTile(title: Text("sksksk")),
          // 여기에 다른 마이페이지 항목을 추가합니다.
        ],
      ),
    );
  }
}
