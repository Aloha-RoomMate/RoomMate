import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:roommate/class/room_owner_post.dart';
import 'package:roommate/constants/gaps.dart';
import 'package:roommate/constants/sizes.dart';
import 'package:roommate/features/view/room_owner_post_view.dart';

class PostContainer extends StatelessWidget {
  final RoomOwnerPost post;

  const PostContainer({
    super.key,
    required this.post,
  });

  void _onContainerTap(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => RoomOwnerPostView(post: post),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Sizes.size12,
        vertical: Sizes.size4,
      ),
      child: GestureDetector(
        onTap: () => _onContainerTap(context),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.98,
          height: 100,
          padding: const EdgeInsets.all(Sizes.size8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            children: [
              // ✅ 수정: Image.network 대신 정적 Asset 이미지를 표시합니다.
              Container(
                width: 84,
                height: 84,
                clipBehavior: Clip.hardEdge,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(Sizes.size12),
                  image: const DecorationImage(
                    image: AssetImage('assets/house.jpg'), // TODO: 기본 이미지 경로 확인
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Gaps.h16,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Text(
                      post.title ?? '제목 없음', // ✅ Null safety
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: Sizes.size18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: [
                        const FaIcon(
                          FontAwesomeIcons.locationDot,
                          size: Sizes.size12,
                        ),
                        Gaps.h4,
                        // TODO: GeoPoint를 실제 주소 '동'으로 변환하는 로직 필요
                        Text(post.addr != null ? '위치 정보 있음' : '위치 정보 없음'),
                      ],
                    ),
                    Row(
                      children: [
                        const FaIcon(
                          FontAwesomeIcons.calendar,
                          size: Sizes.size12,
                        ),
                        Gaps.h4,
                        // ✅ Null safety
                        Text(
                          post.movingDate != null
                              ? DateFormat(
                                  'yyyy-MM-dd',
                                ).format(post.movingDate!.toDate())
                              : '날짜 미정',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const FaIcon(FontAwesomeIcons.arrowRight, size: Sizes.size16),
            ],
          ),
        ),
      ),
    );
  }
}
