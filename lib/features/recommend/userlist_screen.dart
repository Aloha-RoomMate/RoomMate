import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:roommate/class/app_user.dart';
import 'package:roommate/class/chat_repository.dart';
import 'package:roommate/features/chat/chat_screen.dart';
import 'package:roommate/constants/sizes.dart';

// 상세지표/사유 계산
import 'package:roommate/features/recommend/compatibility.dart';

// 상대 프로필 & 게시글 보기
import 'package:roommate/features/view/user_profile_view.dart';

/// ===============================
/// 가중치
/// ===============================
const double kWStruct = 0.70; // 생활패턴
const double kWHobby = 0.10; // 취미
const double kWText = 0.10; // 소개글 톤
const double kWMbti = 0.10; // MBTI 궁합

// 틱톡 버튼 컬러 느낌(#FE2C55)
const Color kAccentRed = Color(0xFFFE2C55);

class UserListScreen extends StatefulWidget {
  const UserListScreen({super.key});

  @override
  State<UserListScreen> createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  Future<_RecBundle>? _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_RecBundle> _load() async {
    final meUid = _auth.currentUser?.uid;
    if (meUid == null) throw StateError('로그인 필요');

    final meDoc = await _db.collection('users').doc(meUid).get();
    if (!meDoc.exists) throw StateError('내 사용자 문서가 없습니다.');
    final me = AppUser.fromDoc(meDoc);

    final qs = await _db
        .collection('users')
        .where('userPass.pass', isEqualTo: true)
        .limit(200)
        .get();

    final others = qs.docs
        .where((d) => d.id != meUid)
        .map((d) => AppUser.fromDoc(d))
        .toList();

    final items = <_RecItem>[];
    for (final u in others) {
      final comp = scoreUsers(me, u); // breakdown + 사유
      final finalScore = comp.score;

      items.add(_RecItem(user: u, score: finalScore, compSim: comp));
    }
    items.sort((a, b) => b.score.compareTo(a.score));
    return _RecBundle(me: me, items: items);
  }

  String _pct(num v) => '${(v * 100).toStringAsFixed(0)}%';

  void _showExplainSheet({
    required AppUser me,
    required _RecItem item,
  }) {
    final other = item.user;
    final comp = item.compSim;

    final myFood = (me.hobby?.foodLike ?? const <dynamic>[])
        .cast<String>()
        .toSet();
    final otFood = (other.hobby?.foodLike ?? const <dynamic>[])
        .cast<String>()
        .toSet();
    final mySport = (me.hobby?.sportLike ?? const <dynamic>[])
        .cast<String>()
        .toSet();
    final otSport = (other.hobby?.sportLike ?? const <dynamic>[])
        .cast<String>()
        .toSet();
    final myInterest = (me.hobby?.interestLike ?? const <dynamic>[])
        .cast<String>()
        .toSet();
    final otInterest = (other.hobby?.interestLike ?? const <dynamic>[])
        .cast<String>()
        .toSet();

    final interFood = myFood.intersection(otFood).toList()..sort();
    final interSport = mySport.intersection(otSport).toList()..sort();
    final interInterest = myInterest.intersection(otInterest).toList()..sort();

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 헤더
                  Row(
                    children: [
                      const Icon(Icons.info_outline),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${other.displayName} 님과의 겹침정도',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      Text(
                        _pct(item.score),
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                  Divider(
                    color: Colors.black26,
                  ),
                  const SizedBox(height: 12),

                  // 변경:
                  _MetricRow(
                    label: '생활패턴(가중치 ${_pct(kWStruct)})',
                    value: comp.structSim,
                  ),
                  _MetricRow(
                    label: '취미(가중치 ${_pct(kWHobby)})',
                    value: comp.hobbySim,
                  ),
                  _MetricRow(
                    label: '자기소개 톤(가중치 ${_pct(kWText)})',
                    value: comp.textSim,
                  ),
                  _MetricRow(
                    label: 'MBTI 궁합(가중치 ${_pct(kWMbti)})', // ⬅️ 추가
                    value: comp.mbtiSim,
                  ),
                  Divider(
                    color: Colors.black26,
                  ),
                  const SizedBox(height: 12),

                  if (comp.reasons.isNotEmpty) ...[
                    Text(
                      '주요 매칭 포인트',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: comp.reasons
                          .map((r) => _PillActive(text: r))
                          .toList(),
                    ),
                    const SizedBox(height: 16),
                  ],

                  Text(
                    '겹치는 취미',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  _OverlapRow(title: '음식', items: interFood),
                  _OverlapRow(title: '운동', items: interSport),
                  _OverlapRow(title: '관심사', items: interInterest),
                  Divider(
                    color: Colors.black26,
                  ),
                  const SizedBox(height: 8),
                  if (interFood.isEmpty &&
                      interSport.isEmpty &&
                      interInterest.isEmpty)
                    Text(
                      '아직 ${other.displayName}님과 겹치는 취미가 아직 없어요.',
                      style: TextStyle(color: Colors.black38),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _startChat(AppUser partner) async {
    final meUid = _auth.currentUser!.uid;
    final chatRepo = ChatRepository();
    final chatId = await chatRepo.createChatRoom(meUid, partner.uid);

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          chatRoomId: chatId,
          partnerUid: partner.uid,
          partnerName: partner.displayName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('추천 유저'),
      ),
      body: FutureBuilder<_RecBundle>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  '오류가 발생했어요\n${snap.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final me = snap.data!.me;
          final items = snap.data!.items;

          if (items.isEmpty) {
            return const Center(
              child: Text(
                "아직 추천할 유저가 없어요.\n"
                "- 상대방도 프로필(생활패턴/공동성향/질병/자기소개)을 채워야 하고\n"
                "- 두 명 이상이 pass여야 추천이 의미 있게 떠요.",
                textAlign: TextAlign.center,
              ),
            );
          }

          return ListView.separated(
            itemCount: items.length + 1, // +1: "Suggested accounts" 헤더
            separatorBuilder: (_, __) => Padding(
              padding: const EdgeInsets.all(8.0),
              child: const Divider(height: 1),
            ),
            itemBuilder: (context, i) {
              if (i == 0) {
                // 헤더
                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
                  child: Row(
                    children: [
                      const Text(
                        '나와 잘 맞을듯한 룸메이트',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Tooltip(
                        message: '프로필을 많이 채운 유저 위주로 추천돼요',
                        triggerMode: TooltipTriggerMode.tap, // ← 탭으로 표시
                        waitDuration: const Duration(milliseconds: 150),
                        showDuration: const Duration(seconds: 3),
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        textStyle: const TextStyle(color: Colors.white),
                        child: Icon(
                          Icons.info_outline,
                          size: 18,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                );
              }

              final it = items[i - 1];
              return _SuggestedUserTile(
                me: me,
                item: it,
                onOpenExplain: () =>
                    _showExplainSheet(me: me, item: it), // 리스트 탭 → 바텀시트
                onChat: () => _startChat(it.user), // 버튼 → 채팅
                onOpenProfile: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => UserProfileView(targetUid: it.user.uid),
                    ),
                  );
                }, // 문서 아이콘 → 프로필/게시글
              );
            },
          );
        },
      ),
    );
  }
}

/// ─────────────────────────────────────────────────────────────────────────────
/// Suggested User Tile (틱톡 DM 스타일)
/// ─────────────────────────────────────────────────────────────────────────────
class _SuggestedUserTile extends StatelessWidget {
  final AppUser me;
  final _RecItem item;
  final VoidCallback onOpenExplain; // 타일 탭 액션(바텀시트)
  final VoidCallback onChat; // Chat 버튼
  final VoidCallback onOpenProfile; // 게시글 보기 아이콘

  const _SuggestedUserTile({
    required this.me,
    required this.item,
    required this.onOpenExplain,
    required this.onChat,
    required this.onOpenProfile,
  });

  String _summarySubtitle() {
    // 틱톡의 "Followed by ○○" 느낌으로 간단 요약
    final reasons = item.compSim.reasons;
    if (reasons.isNotEmpty) return reasons.join(' · ');
    // 없으면 구조/취미/텍스트 요약
    return '겹침정도 ${((item.score) * 100).toStringAsFixed(0)}%';
  }

  @override
  Widget build(BuildContext context) {
    final u = item.user;

    return InkWell(
      onTap: onOpenExplain, // ← 리스트 탭 시 상세 바텀시트
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        child: Row(
          children: [
            // 아바타
            CircleAvatar(
              radius: 24,
              backgroundImage: (u.photoURL != null && u.photoURL!.isNotEmpty)
                  ? NetworkImage(u.photoURL!)
                  : null,
              child: (u.photoURL == null || u.photoURL!.isEmpty)
                  ? const Icon(Icons.person, size: 24)
                  : null,
            ),
            const SizedBox(width: 12),

            // 이름 + 서브텍스트
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    u.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _summarySubtitle(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 12),

            // Chat 버튼
            SizedBox(
              height: 36,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(Sizes.size20),
                  ),
                ),
                onPressed: onChat,
                child: const Text('채팅 보내기'),
              ),
            ),
            const SizedBox(width: 8),

            // 게시글 보기 아이콘
            IconButton(
              tooltip: '상대 프로필 보기',
              onPressed: onOpenProfile,
              icon: const Icon(Icons.person_pin_rounded),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecBundle {
  final AppUser me;
  final List<_RecItem> items;
  _RecBundle({required this.me, required this.items});
}

class _RecItem {
  final AppUser user;
  final double score; // 최종 점수
  final Compatibility compSim; // breakdown/사유
  _RecItem({required this.user, required this.score, required this.compSim});
}

class _MetricRow extends StatelessWidget {
  final String label;
  final double value;
  const _MetricRow({required this.label, required this.value});

  String _pct(double v) => '${(v * 100).toStringAsFixed(0)}%';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(
            _pct(value),
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

/// 활성 Pill (앱 테마 프라이머리와 동일)
class _PillActive extends StatelessWidget {
  final String text;
  const _PillActive({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: Sizes.size4,
        horizontal: Sizes.size14,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor,
        borderRadius: BorderRadius.circular(Sizes.size18),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white),
      ),
    );
  }
}

class _OverlapRow extends StatelessWidget {
  final String title;
  final List<String> items;
  const _OverlapRow({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    final chips = items.map((x) => _PillActive(text: x)).toList();

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 64, child: Text(title)),
          const SizedBox(width: 8),
          Expanded(
            child: chips.isNotEmpty
                ? Wrap(spacing: 6, runSpacing: 6, children: chips)
                : Text('없음', style: Theme.of(context).textTheme.bodySmall),
          ),
        ],
      ),
    );
  }
}
