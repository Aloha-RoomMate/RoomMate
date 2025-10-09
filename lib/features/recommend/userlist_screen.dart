import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:roommate/class/app_user.dart';
import 'package:roommate/class/chat_repository.dart';
import 'package:roommate/features/chat/chat_screen.dart';
import 'package:roommate/constants/sizes.dart';

// 추천 스코어 계산 유틸 (struct/hobby/text + 이유)
import 'package:roommate/features/recommend/compatibility.dart';

/// ===============================
/// 가중치
/// ===============================
/// 합이 1일 필요는 없지만 보통 1.0로 맞출 것을 추천
const double kWStruct = 0.70; // 생활패턴(구조) 가중치
const double kWHobby = 0.15; // 취미 가중치
const double kWText = 0.15; // 소개글(톤) 가중치

class UserListScreen extends StatefulWidget {
  const UserListScreen({super.key});

  @override
  State<UserListScreen> createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  // late → nullable 로 전환 (build에서 ??= 로 게으른 초기화)
  Future<_RecBundle>? _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_RecBundle> _load() async {
    final meUid = _auth.currentUser?.uid;
    if (meUid == null) {
      throw StateError('로그인 필요');
    }

    // 내 문서
    final meDoc = await _db.collection('users').doc(meUid).get();
    if (!meDoc.exists) {
      throw StateError('내 사용자 문서가 없습니다.');
    }
    final me = AppUser.fromDoc(meDoc);

    // 후보: pass == true 인 유저만, 나 제외
    final qs = await _db
        .collection('users')
        .where('userPass.pass', isEqualTo: true)
        .limit(200)
        .get();

    final others = qs.docs
        .where((d) => d.id != meUid)
        .map((d) => AppUser.fromDoc(d))
        .toList();

    // 로컬 호환도 계산 (+ 가중치로 최종점수 재계산)
    final items = <_RecItem>[];
    for (final u in others) {
      final comp = scoreUsers(me, u); // struct/hobby/text 유사도 + 이유
      final finalScore =
          kWStruct * comp.structSim +
          kWHobby * comp.hobbySim +
          kWText * comp.textSim;

      items.add(
        _RecItem(
          user: u,
          score: finalScore, // ⬅️ 가중치 적용한 최종 점수 사용
          compSim: comp, // ⬅️ breakdown/이유는 comp에서 그대로 활용
        ),
      );
    }

    // 스코어 내림차순 정렬
    items.sort((a, b) => b.score.compareTo(a.score));

    return _RecBundle(me: me, items: items);
  }

  String _pct(num v) => '${(v * 100).toStringAsFixed(0)}%';

  // 상세설명 시트
  void _showExplainSheet({
    required AppUser me,
    required _RecItem item,
  }) {
    final other = item.user;
    final comp = item.compSim;

    // 취미 겹침 (food/sport/interest)
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
                          '${other.displayName} 님과의 호환도',
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
                  const SizedBox(height: 12),

                  // 분해 지표 (가중치 표기도 동적으로)
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
                          .map(
                            (r) => _PillActive(text: r),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // 취미 겹침
                  Text(
                    '겹치는 취미',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  _OverlapRow(title: '음식', items: interFood),
                  _OverlapRow(title: '운동', items: interSport),
                  _OverlapRow(title: '관심사', items: interInterest),

                  const SizedBox(height: 8),
                  if (interFood.isEmpty &&
                      interSport.isEmpty &&
                      interInterest.isEmpty)
                    Text(
                      '겹치는 취미가 아직 없어요. 관심사/취미를 더 채우면 추천 품질이 올라가요!',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("추천 유저")),
      body: FutureBuilder<_RecBundle>(
        future: _future ??= _load(), // nullable 안전장치
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
          final data = snap.data!;
          final items = data.items;

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
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final it = items[i];
              final u = it.user;
              final title = u.displayName;
              final subtitle = [
                if (it.compSim.reasons.isNotEmpty)
                  it.compSim.reasons.join(' · '),
              ].where((e) => e.isNotEmpty).join('\n');

              return ListTile(
                leading: CircleAvatar(
                  backgroundImage:
                      (u.photoURL != null && u.photoURL!.isNotEmpty)
                      ? NetworkImage(u.photoURL!)
                      : null,
                  child: (u.photoURL == null || u.photoURL!.isEmpty)
                      ? const Icon(Icons.person)
                      : null,
                ),
                title: Text(title),
                subtitle: subtitle.isNotEmpty ? Text(subtitle) : null,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _pct(it.score),
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    IconButton(
                      tooltip: '왜 이 점수인가요?',
                      icon: const Icon(Icons.info_outline),
                      onPressed: () => _showExplainSheet(me: data.me, item: it),
                    ),
                  ],
                ),
                onTap: () async {
                  final meUid = _auth.currentUser!.uid;
                  final partnerUid = u.uid;
                  final partnerName = u.displayName;

                  final chatRepo = ChatRepository();
                  final chatId = await chatRepo.createChatRoom(
                    meUid,
                    partnerUid,
                  );

                  if (!context.mounted) return;
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatScreen(
                        chatRoomId: chatId,
                        partnerUid: partnerUid,
                        partnerName: partnerName,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
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
  final double score; // 최종 점수 (가중치 적용)
  final Compatibility compSim; // 구조/취미/텍스트 유사도 + 이유
  _RecItem({
    required this.user,
    required this.score,
    required this.compSim,
  });
}

class _MetricRow extends StatelessWidget {
  final String label;
  final double value; // 0.0 ~ 1.0
  const _MetricRow({required this.label, required this.value});

  String _pct(double v) => '${(v * 100).toStringAsFixed(0)}%';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(_pct(value)),
        ],
      ),
    );
  }
}

/// 카테고리 버튼의 "활성화된" 상태와 동일한 비주얼의 Pill
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
        color: Theme.of(context).primaryColor, // 활성화: 초록색(앱 테마 프라이머리)
        borderRadius: BorderRadius.circular(Sizes.size18),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white, // 활성화: 흰색 텍스트
        ),
      ),
    );
  }
}

/// “겹치는 취미” 섹션: 활성화된 카테고리 버튼 스타일로 출력
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
                : Text(
                    '없음',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
          ),
        ],
      ),
    );
  }
}
