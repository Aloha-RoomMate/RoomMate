import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:roommate/class/room_owner_post.dart';
import 'package:roommate/constants/gaps.dart';
import 'package:roommate/constants/sizes.dart';
import 'package:roommate/features/navigationbar/main_navigation.dart';
import 'package:roommate/features/view/room_owner_post_view.dart';

class PostContainer extends StatelessWidget {
  final RoomOwnerPost post;
  const PostContainer({super.key, required this.post});

  void _onContainerTap(BuildContext context) {
    Navigator.of(
      context,
    ).push(
      MaterialPageRoute(
        builder: (context) => MainNavigation(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: Sizes.size12,
        vertical: Sizes.size4,
      ),
      child: GestureDetector(
        onTap: () => _onContainerTap(context),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.98,
          height: 100,
          padding: EdgeInsets.symmetric(
            horizontal: Sizes.size8,
            vertical: Sizes.size8,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(Sizes.size12),
                      image: DecorationImage(
                        image: AssetImage('assets/house.jpg'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ],
              ),
              Gaps.h24,
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '제목입니다.',
                    style: TextStyle(
                      fontSize: Sizes.size20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      FaIcon(
                        FontAwesomeIcons.locationDot,
                        size: Sizes.size12,
                      ),
                      Gaps.h4,
                      Text('서울시 강북구 송중동'),
                    ],
                  ),
                  Row(
                    children: [
                      FaIcon(
                        FontAwesomeIcons.calendar,
                        size: Sizes.size12,
                      ),
                      Gaps.h4,
                      Text('2025-09-10'),
                    ],
                  ),
                ],
              ),
              Gaps.h52,
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FaIcon(
                    FontAwesomeIcons.arrowRight,
                    size: Sizes.size16,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
