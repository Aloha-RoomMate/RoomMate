// ⬇️ MypageScreen 전체: 웹/모바일 겸용 프로필 이미지 업로드(Supabase) + 표시(signed URL)
import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:roommate/class/app_user.dart';
import 'package:roommate/class/room_owner_post.dart';
import 'package:roommate/class/room_owner_post_repository.dart';
import 'package:roommate/class/searcher_post.dart';
import 'package:roommate/class/searcher_post_repository.dart';
import 'package:roommate/class/user_repository.dart';
import 'package:roommate/constants/gaps.dart';
import 'package:roommate/constants/responsive_sizes.dart';
import 'package:roommate/constants/sizes.dart';
import 'package:roommate/features/authentication/login/login_screen.dart';
import 'package:roommate/features/authentication/userinfo/hobby_screen.dart';
import 'package:roommate/features/authentication/userinfo/userjob_screen.dart';
import 'package:roommate/features/category/coliving_screen.dart';
import 'package:roommate/features/category/daily_rythm_screen.dart';
import 'package:roommate/features/category/disease_screen.dart';
import 'package:roommate/features/category/introduction_screen.dart';
import 'package:roommate/features/navigationbar/widgets/accordion_widget.dart';
import 'package:roommate/features/navigationbar/widgets/chip_button.dart';
import 'package:roommate/features/view/room_owner_post_view.dart';
import 'package:roommate/features/view/searcher_post_view.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MypageScreen extends StatefulWidget {
  const MypageScreen({super.key, required this.isBlocked});
  final bool isBlocked;

  @override
  State<MypageScreen> createState() => _MypageScreenState();
}

class _MypageScreenState extends State<MypageScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _repo = UserRepository();
  final _postRepo = RoomOwnerPostRepository();
  final _searcherRepo = SearcherPostRepository();

  // ===== 프로필 이미지 상태 =====
  File? _profileImage; // 모바일 로컬 미리보기
  Uint8List? _profileBytes; // 웹 로컬 미리보기
  bool _isUploadingAvatar = false;
  String?
  _avatarPath; // Supabase Storage 경로 (FireStore users/{uid}.profileImagePath)
  static const String _bucket = 'RoomMate-image';
  final _supa = Supabase.instance.client;

  // ===== 기타 =====
  final _picker = ImagePicker();

  String _fmtHm(int? minutes, {bool use12h = false}) {
    if (minutes == null) return "-";
    final h24 = (minutes ~/ 60) % 24;
    final m = minutes % 60;
    if (!use12h) {
      return "${h24.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}";
    } else {
      final isAm = h24 < 12;
      final h12 = (h24 % 12 == 0) ? 12 : (h24 % 12);
      return "${isAm ? "오전" : "오후"} $h12:${m.toString().padLeft(2, '0')}";
    }
  }

  void _onNextTap() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const DailyRhythmScreen()),
    );
  }

  Future<AppUser?> _getMyData() async => _repo.fetchMe();

  // ====== 아바타 업로드/표시 유틸 ======
  String _guessMime(String ext) {
    switch (ext.toLowerCase()) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'heic':
        return 'image/heic';
      case 'jpg':
      case 'jpeg':
      default:
        return 'image/jpeg';
    }
  }

  Future<void> _uploadAndSaveAvatar(XFile file) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('로그인이 필요합니다.')),
      );
      return;
    }

    setState(() => _isUploadingAvatar = true);
    try {
      final uid = user.uid;
      final ext = (file.name.split('.').last);
      final filename = "${DateTime.now().millisecondsSinceEpoch}.$ext";
      final path = "avatars/$uid/$filename";

      final bytes = await file.readAsBytes();
      await _supa.storage
          .from(_bucket)
          .uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(
              contentType: _guessMime(ext),
              upsert: false,
              cacheControl: '3600',
            ),
          );

      // Firestore에 경로 저장(merge)
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'profileImagePath': path,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // 상태 갱신
      setState(() {
        _avatarPath = path;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('프로필 사진이 업로드되었습니다.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('업로드 실패: $e')),
      );
    } finally {
      if (mounted) setState(() => _isUploadingAvatar = false);
    }
  }

  Future<String?> _avatarSignedUrl() async {
    final path = _avatarPath;
    if (path == null || path.isEmpty) return null;
    try {
      // 30분 TTL
      return await _supa.storage.from(_bucket).createSignedUrl(path, 1800);
    } catch (_) {
      return null;
    }
  }

  Future<void> _getPhotoLibraryImage() async {
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (picked == null) return;

      if (kIsWeb) {
        final bytes = await picked.readAsBytes();
        setState(() {
          _profileBytes = bytes;
          _profileImage = null;
        });
      } else {
        setState(() {
          _profileImage = File(picked.path);
          _profileBytes = null;
        });
      }

      await _uploadAndSaveAvatar(picked);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이미지를 불러오지 못했어요.')),
      );
    }
  }

  Future<void> _getCameraImage() async {
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );
      if (picked == null) return;

      if (kIsWeb) {
        final bytes = await picked.readAsBytes();
        setState(() {
          _profileBytes = bytes;
          _profileImage = null;
        });
      } else {
        setState(() {
          _profileImage = File(picked.path);
          _profileBytes = null;
        });
      }

      await _uploadAndSaveAvatar(picked);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('카메라에서 이미지를 가져오지 못했어요.')),
      );
    }
  }

  Future<void> _getBasicProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (!mounted) return;
    setState(() {
      _profileImage = null;
      _profileBytes = null;
      _avatarPath = null;
    });

    if (user != null) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'profileImagePath': FieldValue.delete(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (_) {}
    }
  }

  Future<void> _showBottomSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      // useRootNavigator: true,
      useSafeArea: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(ResponsiveSizes.p(context, 25)),
        ),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              ResponsiveSizes.p(context, 16),
              ResponsiveSizes.p(context, 16),
              ResponsiveSizes.p(context, 16),
              ResponsiveSizes.p(context, 20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (!mounted) return;
                      _getCameraImage();
                    });
                  },
                  child: const Text('사진 찍기'),
                ),
                Gaps.v3(context),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (!mounted) return;
                      _getPhotoLibraryImage();
                    });
                  },
                  child: const Text('라이브러리에서 불러오기'),
                ),
                Gaps.v3(context),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (!mounted) return;
                      _getBasicProfile();
                    });
                  },
                  child: const Text('기본 프로필로 설정'),
                ),
                Divider(
                  height: ResponsiveSizes.p(context, 24),
                  thickness: 0,
                  color: Colors.transparent,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadMeAndAvatarPath();
  }

  Future<void> _loadMeAndAvatarPath() async {
    final me = await _repo.fetchMe();
    String? path;
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid ?? me?.uid;
      if (uid != null) {
        final snap = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .get();
        path = snap.data()?['profileImagePath'] as String?;
      }
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      // me는 FutureBuilder에서 다시 부르므로 여기선 avatarPath만 세팅
      _avatarPath = path;
    });
  }

  @override
  Widget build(BuildContext context) {
    // 모든 섹션의 라벨 폭 통일
    final double labelColW = 140.0;

    return FutureBuilder<AppUser?>(
      future: _getMyData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (!snapshot.hasData || snapshot.data == null) {
          return const Scaffold(body: Center(child: Text("데이터가 없습니다.")));
        }
        final me = snapshot.data!;

        final userDailyRhythm = me.dailyRhythm ?? me.dailyRhythm;
        final colivingPreference = me.coliving ?? me.coliving;
        final userHobby = me.hobby ?? me.hobby;
        final userTypeInfo = me.userType ?? me.userType;

        final intro = me.introduction?.toString() ?? "";

        // ===== 아바타 위젯 =====
        Widget avatar(double radius) {
          return FutureBuilder<String?>(
            future: (_profileImage == null && _profileBytes == null)
                ? _avatarSignedUrl()
                : Future<String?>.value(null),
            builder: (context, snap) {
              ImageProvider? provider;
              if (_profileBytes != null) {
                provider = MemoryImage(_profileBytes!);
              } else if (!kIsWeb && _profileImage != null) {
                provider = FileImage(_profileImage!);
              } else if (snap.hasData && (snap.data?.isNotEmpty ?? false)) {
                provider = NetworkImage(snap.data!);
              }

              return Stack(
                clipBehavior: Clip.none,
                children: [
                  CircleAvatar(
                    radius: radius,
                    backgroundColor: Colors.grey.shade200,
                    backgroundImage: provider,
                    child: provider == null
                        ? Icon(
                            Icons.person,
                            size: ResponsiveSizes.p(context, 48),
                            color: Colors.grey.shade600,
                          )
                        : null,
                  ),
                  Positioned(
                    right: -4,
                    bottom: -4,
                    child: FloatingActionButton.small(
                      backgroundColor: Colors.transparent,
                      elevation: 0,
                      heroTag: 'editAvatar',
                      onPressed: _showBottomSheet,
                      child: const Icon(Icons.photo_camera),
                    ),
                  ),
                  if (_isUploadingAvatar)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.25),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          );
        }

        return Scaffold(
          key: _scaffoldKey,
          appBar: AppBar(
            scrolledUnderElevation: 0,
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            foregroundColor: Colors.black,
            toolbarHeight: ResponsiveSizes.p(context, 40),
            title: const Text('마이페이지'),
            actions: [
              IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
              ),
            ],
          ),
          endDrawer: _MyPageEndDrawer(
            displayName: me.displayName,
            email: me.email ?? '',
            onOpenProfileSheet: _showBottomSheet,
            onSignOut: _signOut,
            parentContext: _scaffoldKey.currentContext ?? context,
            onEdited: () {
              if (mounted) setState(() {}); // 수정 후 리프레시
            },
          ),
          body: Padding(
            padding: EdgeInsets.all(ResponsiveSizes.p(context, 12)),
            child: StreamBuilder<bool>(
              stream: _repo.watchUserPassStatus(),
              builder: (context, lockSnap) {
                final isLocked = !(lockSnap.data ?? false);

                return Stack(
                  children: [
                    ListView(
                      padding: EdgeInsets.zero,
                      children: [
                        Gaps.v12(context),
                        Center(child: avatar(ResponsiveSizes.p(context, 60))),
                        Gaps.v2(context),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Gaps.v10(context),
                            Text(
                              me.displayName,
                              style: const TextStyle(
                                fontSize: Sizes.size16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Gaps.v6(context),
                            Text(userTypeInfo!.type),
                            Gaps.v6(context),
                          ],
                        ),
                        Divider(
                          height: 1,
                          color: Colors.black26,
                        ),
                        Column(
                          children: [
                            // 생활 패턴
                            AccordionWidget(
                              title: "생활 패턴",
                              content: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  LabeldRow(
                                    labelWidth: labelColW,
                                    label: "출근일",
                                    chips: [
                                      for (final day
                                          in (userDailyRhythm?.workDays ??
                                              const <String>[]))
                                        ChipButton(text: day, isSelected: true),
                                    ],
                                  ),
                                  LabeldRow(
                                    labelWidth: labelColW,
                                    label: "주중 시간",
                                    chips: [
                                      if (userDailyRhythm?.weekAwakeMins !=
                                          null)
                                        ChipButton(
                                          text:
                                              "기상 ${_fmtHm(userDailyRhythm!.weekAwakeMins)}",
                                          isSelected: true,
                                        ),
                                      if (userDailyRhythm?.weekSleepMins !=
                                          null)
                                        ChipButton(
                                          text:
                                              "취침 ${_fmtHm(userDailyRhythm!.weekSleepMins)}",
                                          isSelected: true,
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            // 공동 생활 성향
                            AccordionWidget(
                              title: "공동 생활 성향",
                              content: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  LabeldRow(
                                    labelWidth: labelColW,
                                    label: "공용 공간 선호",
                                    chips: [
                                      if ((colivingPreference?.coSpace ?? '')
                                          .isNotEmpty)
                                        ChipButton(
                                          text: colivingPreference!.coSpace,
                                          isSelected: true,
                                        ),
                                    ],
                                  ),
                                  LabeldRow(
                                    labelWidth: labelColW,
                                    label: "교류도",
                                    chips: [
                                      if ((colivingPreference?.interaction ??
                                              '')
                                          .isNotEmpty)
                                        ChipButton(
                                          text: colivingPreference!.interaction,
                                          isSelected: true,
                                        ),
                                    ],
                                  ),
                                  LabeldRow(
                                    labelWidth: labelColW,
                                    label: "정리 정돈",
                                    chips: [
                                      if ((colivingPreference?.cleanOption ??
                                              '')
                                          .isNotEmpty)
                                        ChipButton(
                                          text: colivingPreference!.cleanOption,
                                          isSelected: true,
                                        ),
                                    ],
                                  ),
                                  LabeldRow(
                                    labelWidth: labelColW,
                                    label: "화장실",
                                    chips: [
                                      if ((colivingPreference?.bathroom ?? '')
                                          .isNotEmpty)
                                        ChipButton(
                                          text: colivingPreference!.bathroom,
                                          isSelected: true,
                                        ),
                                    ],
                                  ),
                                  LabeldRow(
                                    labelWidth: labelColW,
                                    label: "MBTI",
                                    chips: [
                                      if ((colivingPreference?.mbti ?? '')
                                          .isNotEmpty)
                                        ChipButton(
                                          text: colivingPreference!.mbti,
                                          isSelected: true,
                                        ),
                                    ],
                                  ),
                                  LabeldRow(
                                    labelWidth: labelColW,
                                    label: "반려동물",
                                    chips:
                                        (colivingPreference?.pet ??
                                                const <String>[])
                                            .map(
                                              (pet) => ChipButton(
                                                text: pet,
                                                isSelected: true,
                                              ),
                                            )
                                            .toList(),
                                  ),
                                  LabeldRow(
                                    labelWidth: labelColW,
                                    label: "흡연",
                                    chips: [
                                      if (colivingPreference?.smoking != null)
                                        ChipButton(
                                          text: colivingPreference!.smoking
                                              ? '흡연'
                                              : '비흡연',
                                          isSelected: true,
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            // 취미/관심 (얕은 구분선 포함)
                            AccordionWidget(
                              title: "취미/관심",
                              content: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  LabeldRow(
                                    labelWidth: labelColW,
                                    label: "최애 음식",
                                    chips:
                                        (userHobby?.foodLike ??
                                                const <String>[])
                                            .map(
                                              (food) => ChipButton(
                                                text: food,
                                                isSelected: true,
                                              ),
                                            )
                                            .toList(),
                                  ),
                                  Divider(
                                    height: ResponsiveSizes.p(context, 14),
                                    thickness: 0.6,
                                    color: Colors.black12,
                                    indent: ResponsiveSizes.p(
                                      context,
                                      labelColW,
                                    ),
                                    endIndent: ResponsiveSizes.p(context, 8),
                                  ),
                                  LabeldRow(
                                    labelWidth: labelColW,
                                    label: "관심사",
                                    chips:
                                        (userHobby?.interestLike ??
                                                const <String>[])
                                            .map(
                                              (interest) => ChipButton(
                                                text: interest,
                                                isSelected: true,
                                              ),
                                            )
                                            .toList(),
                                  ),
                                  Divider(
                                    height: ResponsiveSizes.p(context, 14),
                                    thickness: 0.6,
                                    color: Colors.black12,
                                    indent: ResponsiveSizes.p(
                                      context,
                                      labelColW,
                                    ),
                                    endIndent: ResponsiveSizes.p(context, 8),
                                  ),
                                  LabeldRow(
                                    labelWidth: labelColW,
                                    label: "운동",
                                    chips:
                                        (userHobby?.sportLike ??
                                                const <String>[])
                                            .map(
                                              (sport) => ChipButton(
                                                text: sport,
                                                isSelected: true,
                                              ),
                                            )
                                            .toList(),
                                  ),
                                ],
                              ),
                            ),

                            // 자기소개
                            AccordionWidget(
                              title: "자기소개",
                              content: Container(
                                width: double.infinity,
                                padding: EdgeInsets.all(
                                  ResponsiveSizes.p(context, 12),
                                ),
                                decoration: BoxDecoration(
                                  color: Theme.of(
                                    context,
                                  ).primaryColor.withAlpha(12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  intro.isEmpty ? "자기소개가 아직 없습니다." : intro,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ),
                            ),

                            Gaps.v16(context),

                            // 내가 쓴 글
                            (() {
                              final isOwner = (userTypeInfo.type)
                                  .toString()
                                  .toLowerCase()
                                  .contains('owner');
                              if (isOwner) {
                                return _MyOwnerPostsSection(
                                  title: "내가 쓴 글",
                                  repo: _postRepo,
                                  currentUid: me.uid,
                                );
                              } else {
                                return _MySearcherPostsSection(
                                  title: "내가 쓴 글",
                                  repo: _searcherRepo,
                                  currentUid: me.uid,
                                );
                              }
                            }()),
                            Gaps.v24(context),
                          ],
                        ),
                      ],
                    ),
                    if (isLocked)
                      Positioned.fill(
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
                                '추가 정보를 입력하면 사용 가능해요',
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              SizedBox(height: ResponsiveSizes.p(context, 12)),
                              FilledButton(
                                onPressed: _onNextTap,
                                child: const Text('정보 입력하기'),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }
}

// -------------------- Drawer --------------------
class _MyPageEndDrawer extends StatelessWidget {
  final String displayName;
  final String email;
  final VoidCallback onOpenProfileSheet;
  final VoidCallback onSignOut;
  final BuildContext parentContext; // Scaffold context 전달받음
  final VoidCallback onEdited;

  const _MyPageEndDrawer({
    required this.displayName,
    required this.email,
    required this.onOpenProfileSheet,
    required this.onSignOut,
    required this.parentContext,
    required this.onEdited,
  });

  void _openEditPicker(BuildContext scaffoldCtx) {
    final pad = ResponsiveSizes.p(scaffoldCtx, 16);

    showModalBottomSheet<void>(
      context: scaffoldCtx,
      useRootNavigator: true, // ✅ 최상위 네비게이터에 붙임
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(ResponsiveSizes.p(scaffoldCtx, 20)),
        ),
      ),
      builder: (sheetCtx) {
        Widget tile({
          required IconData icon,
          required String title,
          required Widget Function() screenFactory,
          String? subtitle,
        }) {
          return ListTile(
            tileColor: Colors.white,
            leading: Icon(icon),
            title: Text(title),
            subtitle: subtitle == null ? null : Text(subtitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.pop(sheetCtx); // 1) 시트 닫기
              // 2) 진짜 '프레임 이후'에 push (마우스트래커 업데이트 구간 벗어나기)
              WidgetsBinding.instance.addPostFrameCallback((_) async {
                final res = await Navigator.of(scaffoldCtx).push(
                  MaterialPageRoute(builder: (_) => screenFactory()),
                );
                if (res == true) {
                  onEdited();
                  ScaffoldMessenger.of(scaffoldCtx).showSnackBar(
                    const SnackBar(content: Text('저장되었습니다.')),
                  );
                }
              });
            },
          );
        }

        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              pad,
              pad,
              pad,
              pad + ResponsiveSizes.p(scaffoldCtx, 6),
            ),
            child: Container(
              color: Colors.white,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  tile(
                    icon: Icons.badge_rounded,
                    title: '직업/유저 타입',
                    screenFactory: () =>
                        const UserjobScreen(returnAfterSave: true),
                  ),
                  tile(
                    icon: Icons.sports_esports_rounded,
                    title: '취미',
                    screenFactory: () =>
                        const HobbyScreen(returnAfterSave: true),
                  ),
                  tile(
                    icon: Icons.people_alt_rounded,
                    title: '공동 생활 성향',
                    screenFactory: () =>
                        const ColivingScreen(returnAfterSave: true),
                  ),
                  tile(
                    icon: Icons.schedule_rounded,
                    title: '생활 패턴',
                    screenFactory: () =>
                        const DailyRhythmScreen(returnAfterSave: true),
                  ),
                  tile(
                    icon: Icons.healing_rounded,
                    title: '질병/알레르기',
                    screenFactory: () =>
                        const DiseaseScreen(returnAfterSave: true),
                  ),
                  tile(
                    icon: Icons.short_text_rounded,
                    title: '자기소개',
                    screenFactory: () =>
                        const IntroductionScreen(returnAfterSave: true),
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
    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              currentAccountPicture: CircleAvatar(
                child: Text((displayName.isNotEmpty ? displayName[0] : '?')),
              ),
              accountName: Text(displayName),
              accountEmail: Text(email),
            ),
            ListTile(
              tileColor: Colors.white,
              leading: const Icon(Icons.photo),
              title: const Text('프로필 사진 변경'),
              onTap: () {
                Navigator.of(context).pop(); // Drawer 닫기
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (parentContext.mounted) onOpenProfileSheet();
                });
              },
            ),
            ListTile(
              tileColor: Colors.white,
              leading: const Icon(Icons.edit_rounded),
              title: const Text('내 정보 수정'),
              onTap: () {
                Navigator.of(context).pop(); // Drawer 닫기
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (parentContext.mounted) _openEditPicker(parentContext);
                });
              },
            ),

            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('로그아웃'),
              onTap: () {
                Navigator.pop(context);
                onSignOut();
              },
            ),
          ],
        ),
      ),
    );
  }
}

// -------------------- 라벨 + 칩 --------------------

class LabeldRow extends StatelessWidget {
  final String label;
  final List<Widget> chips;
  final double labelWidth;

  const LabeldRow({
    super.key,
    required this.label,
    required this.chips,
    this.labelWidth = 88,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: ResponsiveSizes.p(context, 12)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: ResponsiveSizes.p(context, labelWidth),
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
          Gaps.h8(context),
          Expanded(
            child: Wrap(
              spacing: ResponsiveSizes.p(context, 6),
              runSpacing: ResponsiveSizes.p(context, 6),
              children: chips,
            ),
          ),
        ],
      ),
    );
  }
}

// -------------------- 내가 쓴 글 (3열 그리드 + 무한 스크롤) --------------------

class _MyOwnerPostsSection extends StatefulWidget {
  final String title;
  final RoomOwnerPostRepository repo;
  final String currentUid;

  const _MyOwnerPostsSection({
    super.key,
    required this.title,
    required this.repo,
    required this.currentUid,
  });

  @override
  State<_MyOwnerPostsSection> createState() => _MyOwnerPostsSectionState();
}

class _MyOwnerPostsSectionState extends State<_MyOwnerPostsSection> {
  final _scrollController = ScrollController();
  final List<RoomOwnerPost> _posts = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  DocumentSnapshot? _lastDocument;

  @override
  void initState() {
    super.initState();
    _loadInitial();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadInitial() async {
    setState(() => _isLoading = true);
    final result = await widget.repo.fetchUserPostsPaged(
      uid: widget.currentUid,
      limit: 20,
    );
    if (!mounted) return;
    setState(() {
      _posts
        ..clear()
        ..addAll(result.posts);
      _lastDocument = result.lastDocument;
      _hasMore = result.posts.length == 20;
      _isLoading = false;
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        _hasMore) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    setState(() => _isLoadingMore = true);
    final result = await widget.repo.fetchUserPostsPaged(
      uid: widget.currentUid,
      lastItem: _lastDocument,
      limit: 20,
    );
    if (!mounted) return;
    setState(() {
      _posts.addAll(result.posts);
      _lastDocument = result.lastDocument;
      _hasMore = result.posts.length == 20;
      _isLoadingMore = false;
    });
  }

  Future<void> _refresh() async {
    _lastDocument = null;
    _hasMore = true;
    _posts.clear();
    await _loadInitial();
  }

  @override
  Widget build(BuildContext context) {
    final radius = ResponsiveSizes.p(context, 18);
    final h = MediaQuery.of(context).size.height;
    final boxHeight = (h * 0.60).clamp(
      ResponsiveSizes.p(context, 360),
      ResponsiveSizes.p(context, 720),
    );

    final header = Row(
      children: [
        Text(
          widget.title,
          style: TextStyle(
            fontSize: ResponsiveSizes.f(context, 18),
            fontWeight: FontWeight.w700,
          ),
        ),
        const Spacer(),
        if (!_isLoading)
          Text(
            "${_posts.length}${_hasMore ? '+' : ''}",
            style: Theme.of(context).textTheme.bodySmall,
          ),
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _isLoading ? null : _refresh,
          tooltip: '새로고침',
        ),
      ],
    );

    final grid = _isLoading
        ? const Center(child: CircularProgressIndicator())
        : RepaintBoundary(
            child: GridView.builder(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: ResponsiveSizes.p(context, 8),
                crossAxisSpacing: ResponsiveSizes.p(context, 8),
                childAspectRatio: 0.78,
              ),
              itemCount: _posts.length + (_hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index >= _posts.length) {
                  return const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  );
                }
                return _MiniOwnerPostTile(post: _posts[index]);
              },
            ),
          );

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveSizes.p(context, 12),
        vertical: ResponsiveSizes.p(context, 12),
      ),
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).primaryColor.withAlpha(100),
        ),
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          header,
          Gaps.v8(context),
          SizedBox(height: boxHeight, child: grid),
        ],
      ),
    );
  }
}

class _MiniOwnerPostTile extends StatelessWidget {
  _MiniOwnerPostTile({required this.post});

  final RoomOwnerPost post;

  static const String _bucket = 'RoomMate-image';
  static const int _urlTtl = 1800; // 30분
  final _supa = Supabase.instance.client;

  Future<String?> _firstSignedUrl() async {
    final paths = post.imageUrls ?? const <String>[];
    if (paths.isEmpty) return null;
    try {
      final url = await _supa.storage
          .from(_bucket)
          .createSignedUrl(paths.first, _urlTtl);
      if (url.isEmpty) return null;
      return url;
    } catch (_) {
      return null;
    }
  }

  String _price1() {
    final d = post.deposit ?? 0;
    return '보증금 $d';
  }

  String _price2() {
    final r = post.rent ?? 0;
    final m = post.manageFee ?? 0;
    return m > 0 ? '월세 $r + 관 $m' : '월세 $r';
  }

  String _addrShort() {
    final a = (post.roadAddress ?? '').trim();
    if (a.isEmpty) return '위치 비공개';
    return a.split('(').first.trim();
  }

  void _openDetail(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => RoomOwnerPostView(post: post)),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final radius = ResponsiveSizes.p(context, 12);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius),
      ),
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: () => _openDetail(context),
        child: Column(
          children: [
            Expanded(
              child: FutureBuilder<String?>(
                future: _firstSignedUrl(),
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    );
                  }
                  final url = snap.data;
                  if (url == null || url.isEmpty) {
                    return Image.asset(
                      'assets/house.jpg',
                      fit: BoxFit.cover,
                      width: double.infinity,
                    );
                  }
                  return Image.network(
                    url,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    errorBuilder: (_, __, ___) => Image.asset(
                      'assets/house.jpg',
                      fit: BoxFit.cover,
                      width: double.infinity,
                    ),
                    loadingBuilder: (c, w, p) => p == null
                        ? w
                        : const Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                  );
                },
              ),
            ),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(radius),
                ),
              ),
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  ResponsiveSizes.p(context, 8),
                  ResponsiveSizes.p(context, 8),
                  ResponsiveSizes.p(context, 8),
                  ResponsiveSizes.p(context, 10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _addrShort(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    SizedBox(height: ResponsiveSizes.p(context, 4)),
                    Text(
                      _price1(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.grey.shade800,
                        fontSize: 12,
                      ),
                    ),
                    SizedBox(height: ResponsiveSizes.p(context, 2)),
                    Text(
                      _price2(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// -------------------- Searcher용 (3열 그리드 + 무한 스크롤) --------------------

class _MySearcherPostsSection extends StatefulWidget {
  final String title;
  final SearcherPostRepository repo;
  final String currentUid;

  const _MySearcherPostsSection({
    super.key,
    required this.title,
    required this.repo,
    required this.currentUid,
  });

  @override
  State<_MySearcherPostsSection> createState() =>
      _MySearcherPostsSectionState();
}

class _MySearcherPostsSectionState extends State<_MySearcherPostsSection> {
  final _scrollController = ScrollController();
  final List<SearcherPost> _posts = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  DocumentSnapshot? _lastDocument;

  @override
  void initState() {
    super.initState();
    _loadInitial();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadInitial() async {
    setState(() => _isLoading = true);
    final result = await widget.repo.fetchUserPostsPaged(
      uid: widget.currentUid,
      limit: 20,
    );
    if (!mounted) return;
    setState(() {
      _posts
        ..clear()
        ..addAll(result.posts);
      _lastDocument = result.lastDocument;
      _hasMore = result.posts.length == 20;
      _isLoading = false;
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        _hasMore) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    setState(() => _isLoadingMore = true);
    final result = await widget.repo.fetchUserPostsPaged(
      uid: widget.currentUid,
      lastItem: _lastDocument,
      limit: 20,
    );
    if (!mounted) return;
    setState(() {
      _posts.addAll(result.posts);
      _lastDocument = result.lastDocument;
      _hasMore = result.posts.length == 20;
      _isLoadingMore = false;
    });
  }

  Future<void> _refresh() async {
    _lastDocument = null;
    _hasMore = true;
    _posts.clear();
    await _loadInitial();
  }

  @override
  Widget build(BuildContext context) {
    final radius = ResponsiveSizes.p(context, 18);
    final h = MediaQuery.of(context).size.height;
    final boxHeight = (h * 0.60).clamp(
      ResponsiveSizes.p(context, 360),
      ResponsiveSizes.p(context, 720),
    );

    final header = Row(
      children: [
        Text(
          widget.title,
          style: TextStyle(
            fontSize: ResponsiveSizes.f(context, 18),
            fontWeight: FontWeight.w700,
          ),
        ),
        const Spacer(),
        if (!_isLoading)
          Text(
            "${_posts.length}${_hasMore ? '+' : ''}",
            style: Theme.of(context).textTheme.bodySmall,
          ),
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _isLoading ? null : _refresh,
          tooltip: '새로고침',
        ),
      ],
    );

    final grid = _isLoading
        ? const Center(child: CircularProgressIndicator())
        : GridView.builder(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: ResponsiveSizes.p(context, 8),
              crossAxisSpacing: ResponsiveSizes.p(context, 8),
              childAspectRatio: 0.9,
            ),
            itemCount: _posts.length + (_hasMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index >= _posts.length) {
                return const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                );
              }
              return _MiniSearcherPostTile(post: _posts[index]);
            },
          );

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveSizes.p(context, 12),
        vertical: ResponsiveSizes.p(context, 12),
      ),
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).primaryColor.withAlpha(100),
        ),
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          header,
          Gaps.v8(context),
          SizedBox(height: boxHeight, child: grid),
        ],
      ),
    );
  }
}

class _MiniSearcherPostTile extends StatelessWidget {
  const _MiniSearcherPostTile({required this.post});
  final SearcherPost post;

  String _area() {
    final a = post.wantArea ?? const <String>[];
    if (a.isEmpty) return '희망 위치 미지정';
    return a.take(2).join(', ') + (a.length > 2 ? ' 외' : '');
  }

  String _price() {
    final d = post.deposit ?? 0;
    final lo = post.minRent ?? 0;
    final hi = post.maxRent ?? 0;
    final range = (lo > 0 && hi > 0) ? '$lo~$hi' : (hi > 0 ? '~$hi' : '$lo~');
    return '보증금 $d / 월 $range';
  }

  void _openDetail(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => SearcherPostView(post: post)),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final radius = ResponsiveSizes.p(context, 12);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius),
      ),
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      child: Container(
        color: Colors.white,
        padding: EdgeInsets.fromLTRB(
          ResponsiveSizes.p(context, 10),
          ResponsiveSizes.p(context, 10),
          ResponsiveSizes.p(context, 10),
          ResponsiveSizes.p(context, 12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              // ✅ 클릭 가능
              onTap: () => _openDetail(context), // ✅ 상세로 이동
              mouseCursor: SystemMouseCursors.click,
              child: Container(
                color: Colors.white,
                padding: EdgeInsets.fromLTRB(
                  ResponsiveSizes.p(context, 10),
                  ResponsiveSizes.p(context, 10),
                  ResponsiveSizes.p(context, 10),
                  ResponsiveSizes.p(context, 12),
                ),
                child: Column(
                  // 🔧 중요: shrink-wrap 하도록 설정
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (post.title ?? '제목 없음'),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    SizedBox(height: ResponsiveSizes.p(context, 6)),
                    Row(
                      children: [
                        const Icon(Icons.place_outlined, size: 14),
                        SizedBox(width: ResponsiveSizes.p(context, 4)),
                        Expanded(
                          child: Text(
                            _area(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.grey.shade800,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: ResponsiveSizes.p(context, 4)),
                    Row(
                      children: [
                        const Icon(Icons.payments_outlined, size: 14),
                        SizedBox(width: ResponsiveSizes.p(context, 4)),
                        Expanded(
                          child: Text(
                            _price(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
