// ChatListScreen — 추가 정보 미입력 시 잠금 오버레이(마이페이지 이동 버튼)
// NOTE: MypageScreen 경로는 프로젝트 구조에 맞게 조정하세요.
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:roommate/features/chat/chat_screen.dart';
import 'package:roommate/class/chat_repository.dart';
import 'package:roommate/class/user_repository.dart';
import 'package:roommate/constants/responsive_sizes.dart';
import 'package:roommate/constants/gaps.dart';
import 'package:roommate/features/navigationbar/screens/mypage_screen.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    // 로그인 가드
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('로그인 후 이용해주세요.')),
      );
    }

    final uid = user.uid;
    final chatStream = FirebaseFirestore.instance
        .collection("chats")
        .where("participants", arrayContains: uid)
        .where("hasContent", isEqualTo: true) // ← 추가
        .orderBy("updatedAt", descending: true)
        .snapshots();

    // ✅ PASS 상태(추가 정보 입력 여부) 감시
    final passStream = UserRepository().watchUserPassStatus();

    return Scaffold(
      body: SafeArea(
        child: StreamBuilder<bool>(
          stream: passStream,
          builder: (context, lockSnap) {
            final isLocked = !(lockSnap.data ?? false); // true면 잠금

            // 채팅 목록 본문
            final chatListBody = StreamBuilder<QuerySnapshot>(
              stream: chatStream,
              builder: (context, snapshot) {
                // 1) 에러 먼저 처리 (무한로딩 방지)
                if (snapshot.hasError) {
                  final err = snapshot.error.toString();

                  // 인덱스 필요한 경우 안내
                  final isIndexError =
                      err.contains('FAILED_PRECONDITION') ||
                      err.contains('requires an index');

                  // 권한 거부 안내
                  final isPermError =
                      err.contains('PERMISSION_DENIED') ||
                      err.contains('permission-denied');

                  // 에러 메시지 안의 콘솔 링크 뽑기(있을 때)
                  String? consoleUrl;
                  final match = RegExp(
                    r'(https://console\.firebase\.google\.com[^\s]+)',
                  ).firstMatch(err);
                  if (match != null) consoleUrl = match.group(1);

                  return Padding(
                    padding: EdgeInsets.fromLTRB(
                      ResponsiveSizes.p(context, 20),
                      ResponsiveSizes.p(context, 24),
                      ResponsiveSizes.p(context, 20),
                      ResponsiveSizes.p(context, 24),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 40),
                        Gaps.v12(context),
                        Text(
                          '채팅 목록을 불러오는 중 오류가 발생했어요.',
                          style: Theme.of(context).textTheme.titleMedium,
                          textAlign: TextAlign.center,
                        ),
                        Gaps.v8(context),
                        SelectableText(
                          err,
                          style: TextStyle(
                            fontSize: ResponsiveSizes.f(context, 12),
                          ),
                        ),
                        Gaps.v16(context),
                        if (isIndexError) ...[
                          const Text(
                            '해결 방법: Firestore 복합 인덱스를 생성하세요.\n'
                            'Collection = chats, Fields = participants (array-contains), updatedAt (desc)',
                            textAlign: TextAlign.center,
                          ),
                          if (consoleUrl != null) ...[
                            Gaps.v8(context),
                            SelectableText(
                              consoleUrl,
                              style: TextStyle(
                                fontSize: ResponsiveSizes.f(context, 12),
                              ),
                            ),
                          ],
                        ],
                        if (isPermError) ...[
                          Gaps.v8(context),
                          const Text(
                            '해결 방법: Firestore 규칙에서 chats 읽기를 참여자로 제한하세요.\n'
                            '예) allow read: if request.auth != null && '
                            'request.auth.uid in resource.data.participants;',
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ],
                    ),
                  );
                }

                // 2) 로딩
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                // 3) 데이터 없음
                if (!snapshot.hasData) {
                  return const Center(child: Text('데이터가 없습니다.'));
                }

                final docs = snapshot.data!.docs;
                if (docs.isEmpty) {
                  return const Center(child: Text("채팅방이 없습니다."));
                }

                // 4) 정상 렌더링 — 카드 제거, 리스트 + 얇은 가로줄(맨 위/사이/맨 아래), 넉넉한 바깥 패딩
                return Padding(
                  padding: EdgeInsets.fromLTRB(
                    ResponsiveSizes.p(context, 20),
                    ResponsiveSizes.p(context, 16),
                    ResponsiveSizes.p(context, 20),
                    ResponsiveSizes.p(context, 24),
                  ),
                  child: ListView.builder(
                    itemCount: docs.length * 2 + 1,
                    // 패턴: [0]TopDivider, [1]Tile0, [2]Divider, [3]Tile1, ..., [2N]BottomDivider
                    itemBuilder: (context, i) {
                      // 모든 짝수 인덱스 = Divider (맨 위/사이/맨 아래)
                      if (i.isEven) {
                        return Divider(
                          height: 1,
                          thickness: 1,
                          color: Theme.of(
                            context,
                          ).dividerColor.withOpacity(0.7),
                        );
                      }

                      // 홀수 인덱스 = 채팅 행
                      final index = (i - 1) ~/ 2;
                      final raw = docs[index];
                      final data = raw.data() as Map<String, dynamic>;
                      final chatId = raw.id;

                      final lastMessage = (data["lastMessage"] ?? "") as String;
                      final updatedAt = (data["updatedAt"] as Timestamp?)
                          ?.toDate();

                      final participants = List<String>.from(
                        data["participants"] ?? [],
                      );
                      final partnerUid = participants.firstWhere(
                        (id) => id != uid,
                        orElse: () => "",
                      );

                      // ✅ 내 unreadCount 읽기
                      final unreadCounts = Map<String, dynamic>.from(
                        data["unreadCounts"] ?? {},
                      );
                      final int myUnread = ((unreadCounts[uid] ?? 0) as num)
                          .toInt();

                      if (partnerUid.isEmpty) {
                        return const ListTile(
                          dense: true,
                          title: Text("잘못된 채팅 데이터"),
                          subtitle: Text("참여자 정보를 확인할 수 없습니다."),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 10,
                          ),
                        );
                      }

                      return FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance
                            .collection("users")
                            .doc(partnerUid)
                            .get(),
                        builder: (context, userSnap) {
                          if (userSnap.hasError) {
                            return const ListTile(
                              dense: true,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 10,
                              ),
                            );
                          }
                          if (userSnap.connectionState ==
                                  ConnectionState.waiting ||
                              !userSnap.hasData) {
                            return const ListTile(
                              dense: true,
                              title: Text("로딩중..."),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 10,
                              ),
                            );
                          }

                          final userData =
                              userSnap.data!.data() as Map<String, dynamic>? ??
                              {};
                          final displayName =
                              (userData["displayName"] ?? "알 수 없음") as String;
                          final photoUrl =
                              (userData["photoUrl"] ??
                                      userData["profileImageUrl"])
                                  as String?;

                          return ListTile(
                            dense: true, // 라인 느낌을 살리기 위해 컴팩트하게
                            visualDensity: VisualDensity.compact,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: ResponsiveSizes.p(context, 8),
                              vertical: ResponsiveSizes.p(context, 10),
                            ),
                            leading: _RoundedSquareAvatar(
                              size: 44,
                              photoUrl: photoUrl,
                              fallbackText: displayName.isNotEmpty
                                  ? displayName[0]
                                  : '?',
                            ),
                            title: Text(
                              displayName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            subtitle: Text(
                              lastMessage,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            // ✅ 시간 + 배지
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  _formatTime(updatedAt),
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                if (myUnread > 0) Gaps.v6(context),
                                if (myUnread > 0)
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: ResponsiveSizes.p(context, 8),
                                      vertical: ResponsiveSizes.p(context, 2),
                                    ),
                                    decoration: BoxDecoration(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                      borderRadius: BorderRadius.circular(
                                        ResponsiveSizes.p(context, 999),
                                      ),
                                    ),
                                    constraints: BoxConstraints(
                                      minWidth: ResponsiveSizes.p(context, 22),
                                      minHeight: ResponsiveSizes.p(context, 20),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      myUnread > 99 ? '99+' : '$myUnread',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: ResponsiveSizes.f(
                                          context,
                                          11,
                                        ),
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            onTap: () async {
                              // ✅ 탭 시 선제적으로 읽음 처리(UX 개선)
                              try {
                                await ChatRepository().markChatRead(chatId);
                              } catch (_) {}
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ChatScreen(
                                    chatRoomId: chatId,
                                    partnerUid: partnerUid,
                                    partnerName: displayName,
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
              },
            );

            // ✅ 오버레이(잠금) 위젯
            final lockOverlay = Positioned.fill(
              child: IgnorePointer(
                ignoring: false, // 터치 막기
                child: Container(
                  color: Colors.white.withOpacity(0.85),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.lock_outline,
                        size: ResponsiveSizes.p(context, 56),
                        color: Colors.black54,
                      ),
                      SizedBox(height: ResponsiveSizes.p(context, 12)),
                      Text(
                        '추가 정보를 입력하면 채팅을 사용할 수 있어요',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      SizedBox(height: ResponsiveSizes.p(context, 12)),
                      FilledButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  const MypageScreen(isBlocked: true),
                            ),
                          );
                        },
                        child: const Text('마이페이지로 이동'),
                      ),
                    ],
                  ),
                ),
              ),
            );

            return Stack(
              children: [
                chatListBody,
                if (isLocked) lockOverlay,
              ],
            );
          },
        ),
      ),
    );
  }

  String _formatTime(DateTime? dt) {
    if (dt == null) return "";
    final now = DateTime.now();
    final sameDay =
        dt.year == now.year && dt.month == now.month && dt.day == now.day;
    if (sameDay) {
      final h = dt.hour.toString().padLeft(2, '0');
      final m = dt.minute.toString().padLeft(2, '0');
      return "$h:$m";
    } else {
      final mm = dt.month.toString().padLeft(2, '0');
      final dd = dt.day.toString().padLeft(2, '0');
      return "$mm/$dd";
    }
  }
}

/// 둥근 사각형 아바타 위젯
class _RoundedSquareAvatar extends StatelessWidget {
  const _RoundedSquareAvatar({
    super.key,
    required this.size,
    this.photoUrl,
    this.fallbackText = '?',
    this.radius = 12,
  });

  final double size;
  final String? photoUrl;
  final String fallbackText;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final bg = Theme.of(context).colorScheme.surfaceContainerHighest;
    final fg = Theme.of(context).colorScheme.onSurfaceVariant;

    Widget child;
    if (photoUrl != null && photoUrl!.isNotEmpty) {
      child = ClipRRect(
        borderRadius: BorderRadius.circular(ResponsiveSizes.p(context, radius)),
        child: Image.network(
          photoUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          loadingBuilder: (ctx, w, progress) {
            if (progress == null) return w;
            return _loading(context, bg);
          },
          errorBuilder: (_, __, ___) => _fallback(context, bg, fg),
        ),
      );
    } else {
      child = _fallback(context, bg, fg);
    }

    return SizedBox(width: size, height: size, child: child);
  }

  Widget _loading(BuildContext context, Color bg) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(ResponsiveSizes.p(context, radius)),
      ),
      alignment: Alignment.center,
      child: SizedBox(
        width: ResponsiveSizes.p(context, 16),
        height: ResponsiveSizes.p(context, 16),
        child: const CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }

  Widget _fallback(BuildContext context, Color bg, Color fg) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(ResponsiveSizes.p(context, radius)),
      ),
      alignment: Alignment.center,
      child: Text(
        fallbackText.toUpperCase(),
        style: TextStyle(
          color: fg,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
