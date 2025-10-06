import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:roommate/class/app_user.dart';
import 'package:roommate/class/room_owner_post.dart';
import 'package:roommate/class/user_repository.dart';
import 'package:roommate/constants/gaps.dart';
import 'package:roommate/constants/sizes.dart';

class RoomOwnerPostView extends StatefulWidget {
  final RoomOwnerPost post;

  const RoomOwnerPostView({
    super.key,
    required this.post,
  });

  @override
  State<RoomOwnerPostView> createState() => _RoomOwnerPostViewState();
}

class _RoomOwnerPostViewState extends State<RoomOwnerPostView> {
  final UserRepository _userRepository = UserRepository();
  late Future<AppUser?> _authorFuture;

  @override
  void initState() {
    super.initState();
    // authorId가 null이 아닐 때만 사용자 정보를 가져오도록 안전장치 추가
    if (widget.post.authorId != null && widget.post.authorId!.isNotEmpty) {
      _authorFuture = _userRepository.fetchUserById(widget.post.authorId!);
    } else {
      // authorId가 없는 예외적인 경우를 위해 완료된 Future를 할당
      _authorFuture = Future.value(null);
    }
  }

  // 정보 항목을 보여주는 재사용 가능한 헬퍼 위젯
  Widget _buildInfoRow(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Sizes.size8),
      child: Row(
        children: [
          Icon(icon, size: Sizes.size20, color: Colors.grey.shade600),
          Gaps.h16,
          Text(title, style: const TextStyle(fontSize: Sizes.size16)),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: Sizes.size16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final numberFormat = NumberFormat.decimalPattern();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 250.0,
            pinned: true,
            backgroundColor: Theme.of(context).primaryColor,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                widget.post.title ?? '제목 없음', // ✅ Null safety
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              // ✅ 이미지 캐러셀을 정적 이미지로 교체
              background: Image.asset(
                'assets/house.jpg', // TODO: 기본 이미지 경로 확인 및 설정
                fit: BoxFit.cover,
                color: Colors.black.withOpacity(0.3),
                colorBlendMode: BlendMode.darken,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(Sizes.size20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- 작성자 정보 ---
                  FutureBuilder<AppUser?>(
                    future: _authorFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (!snapshot.hasData || snapshot.data == null) {
                        return const ListTile(
                          leading: CircleAvatar(child: Icon(Icons.person_off)),
                          title: Text('작성자 정보 없음'),
                        );
                      }
                      final author = snapshot.data!;
                      return ListTile(
                        leading: CircleAvatar(
                          radius: 24,
                          backgroundImage: author.photoURL != null
                              ? NetworkImage(author.photoURL!)
                              : null,
                          child: author.photoURL == null
                              ? const Icon(Icons.person)
                              : null,
                        ),
                        title: Text(
                          author.displayName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: const Text('프로필 보기'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          // TODO: 작성자 프로필 화면으로 이동하는 로직
                        },
                      );
                    },
                  ),
                  const Divider(height: Sizes.size40),

                  // --- 게시글 상세 정보 (Null 안전 처리) ---
                  const Text(
                    "방 정보",
                    style: TextStyle(
                      fontSize: Sizes.size20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Gaps.v16,
                  _buildInfoRow(
                    Icons.location_on_outlined,
                    "위치",
                    "위치 정보 부근",
                  ), // TODO: GeoPoint -> 주소 변환
                  _buildInfoRow(
                    Icons.attach_money_outlined,
                    "보증금",
                    "${numberFormat.format(widget.post.deposit ?? 0)}만원",
                  ),
                  _buildInfoRow(
                    Icons.local_atm_outlined,
                    "월세",
                    "${numberFormat.format(widget.post.rent ?? 0)}만원",
                  ),
                  _buildInfoRow(
                    Icons.receipt_long_outlined,
                    "관리비",
                    "${numberFormat.format(widget.post.manageFee ?? 0)}만원",
                  ),
                  _buildInfoRow(
                    Icons.stairs_outlined,
                    "층수",
                    "${widget.post.corFloor ?? '-'}층 / ${widget.post.wholeFloor ?? '-'}층",
                  ),
                  _buildInfoRow(
                    Icons.square_foot_outlined,
                    "전용 면적",
                    "${widget.post.area ?? '-'}평",
                  ),
                  _buildInfoRow(
                    Icons.bathtub_outlined,
                    "화장실 개수",
                    "${widget.post.toilet ?? '-'}개",
                  ),

                  const Divider(height: Sizes.size40),
                  const Text(
                    "계약 정보",
                    style: TextStyle(
                      fontSize: Sizes.size20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Gaps.v16,
                  _buildInfoRow(
                    Icons.event_available_outlined,
                    "입주 가능일",
                    // ✅ movingDate가 null일 경우를 대비하여 기본값 제공
                    widget.post.movingDate != null
                        ? DateFormat(
                            'yyyy년 MM월 dd일',
                          ).format(widget.post.movingDate!.toDate())
                        : "정보 없음",
                  ),
                  _buildInfoRow(
                    Icons.article_outlined,
                    "계약 기간",
                    "${widget.post.minContract ?? '-'}개월 ~ ${widget.post.maxContract ?? '-'}개월",
                  ),

                  const Divider(height: Sizes.size40),
                  const Text(
                    "소개글",
                    style: TextStyle(
                      fontSize: Sizes.size20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Gaps.v16,
                  Text(
                    widget.post.introduction ?? '작성된 소개글이 없습니다.',
                    style: const TextStyle(fontSize: Sizes.size16, height: 1.5),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: Sizes.size8,
            horizontal: Sizes.size20,
          ),
          child: ElevatedButton(
            onPressed: () {
              // TODO: 채팅하기 로직 구현
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: Sizes.size8),
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text(
              '채팅으로 연락하기',
              style: TextStyle(
                fontSize: Sizes.size16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
