import 'package:flutter/material.dart';
import 'package:roommate/constants/sizes.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsetsGeometry.all(8),
      child: Center(
        child: Text(
          "채팅. 개발 예정",
          style: TextStyle(
            fontSize: Sizes.size24,
          ),
        ),
      ),
    );
  }
}
