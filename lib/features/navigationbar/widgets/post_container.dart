import 'package:flutter/material.dart';
import 'package:roommate/constants/sizes.dart';

class PostContainer extends StatelessWidget {
  const PostContainer({super.key});

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      widthFactor: 0.85,
      heightFactor: 0.2,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: Sizes.size12,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
              children: [
                Text('제목'),
                Text('위치'),
              ],
            ),
          ],
        ),
        decoration: BoxDecoration(
          color: Colors.red,
        ),
      ),
    );
  }
}
