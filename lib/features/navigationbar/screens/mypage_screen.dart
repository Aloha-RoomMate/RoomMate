// 샤라웃 투 https://github.com/youngsoonoh/youtube_profile/tree/example1 오용순
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:roommate/class/app_user.dart';
import 'package:roommate/class/user_repository.dart';
import 'package:roommate/constants/sizes.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:roommate/features/category/daily_rythm_screen.dart';
import 'package:roommate/features/navigationbar/widgets/accordion_widget.dart';
import 'package:roommate/features/navigationbar/widgets/chip_button.dart';

class MypageScreen extends StatefulWidget {
  const MypageScreen({super.key, required this.isBlocked});
  final bool isBlocked;

  @override
  State<MypageScreen> createState() => _MypageScreenState();
}

class _MypageScreenState extends State<MypageScreen> {
  File? _profileImage;

  void _onNextTap() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => DailyRhythmScreen()),
    );
  }

  Future<AppUser?> _getMyData() async {
    return await UserRepository().fetchMe();
  }

  Future<void> _getPhotoLibraryImage() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked == null) return;
    if (!mounted) return;
    setState(() => _profileImage = File(picked.path));
  }

  Future<void> _getCameraImage() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );
    if (picked == null) return;
    if (!mounted) return;
    setState(() => _profileImage = File(picked.path));
  }

  Future<void> _getBasicProfile() async {
    if (!mounted) return;
    setState(() => _profileImage = null);
  }

  Future<void> _showBottomSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () async {
                  Navigator.of(ctx).pop();
                  await _getCameraImage();
                },
                child: const Text('사진 찍기'),
              ),
              const SizedBox(height: Sizes.size3),
              ElevatedButton(
                onPressed: () async {
                  Navigator.of(ctx).pop();
                  await _getPhotoLibraryImage();
                },
                child: const Text('라이브러리에서 불러오기'),
              ),
              const SizedBox(height: Sizes.size3),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  _getBasicProfile();
                },
                child: const Text('기본 프로필로 설정'),
              ),
              const SizedBox(height: 20),
              const Divider(
                height: 0,
                thickness: 0,
                color: Colors.transparent,
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AppUser?>(
      future: _getMyData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
        if (!snapshot.hasData || snapshot.data == null) {
          return const Center(
            child: Text("데이터가 없습니다."),
          );
        }
        final data = snapshot.data!;
        final col = data.userPass?.coliving;

        return Padding(
          padding: const EdgeInsets.all(Sizes.size12),
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              const SizedBox(height: 12),
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.grey.shade200,
                      backgroundImage: _profileImage != null
                          ? FileImage(_profileImage!)
                          : null,
                      child: _profileImage == null
                          ? Icon(
                              Icons.person,
                              size: 48,
                              color: Colors.grey.shade600,
                            )
                          : null,
                    ),
                    const SizedBox(height: 2),
                    TextButton.icon(
                      onPressed: () => _showBottomSheet(),
                      icon: const Icon(Icons.photo_library_outlined),
                      label: const Text('프로필 사진 변경'),
                      style: TextButton.styleFrom(
                        foregroundColor: Theme.of(context).primaryColor,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 100, left: 100),
                      child: Column(
                        children: [
                          Text(data.displayName),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 2),

              Divider(
                height: 1,
                color: Theme.of(context).primaryColor.withAlpha(100),
              ),

              SingleChildScrollView(
                child: Stack(
                  children: [
                    Column(
                      children: [
                        AccordionWidget(
                          title: " 내 생활패턴",
                          content: Column(
                            spacing: 6,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              for (final day
                                  in data.userPass?.dailyRhythm?.workDays ?? [])
                                ChipButton(text: "출근일 $day", isSelected: true),
                              if (data.userPass?.dailyRhythm?.isJobLess ==
                                  true) ...[
                                ChipButton(
                                  text:
                                      "주말 기상시간 : ${data.userPass?.dailyRhythm?.weekAwakeMins}",
                                  isSelected: true,
                                ),
                                ChipButton(
                                  text:
                                      "주말 취침시간 : ${data.userPass?.dailyRhythm?.weekSleepMins}",
                                  isSelected: true,
                                ),
                              ],
                            ],
                          ),
                        ),
                        AccordionWidget(
                          title: " 내 공동 생활 성향",
                          content: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            spacing: 6,
                            children: [
                              ChipButton(
                                text: "${data.userPass?.coliving?.coSpace}",
                                isSelected: true,
                              ),
                              ChipButton(
                                text: "${data.userPass?.coliving?.bathroom}",
                                isSelected: true,
                              ),
                              ChipButton(
                                text: "${data.userPass?.coliving?.mbti}",
                                isSelected: true,
                              ),
                              if ((col?.pet ?? const []).isEmpty)
                                const ChipButton(
                                  text: '반려동물: 없음',
                                  isSelected: false,
                                )
                              else
                                for (final p in col!.pet)
                                  ChipButton(
                                    text: '반려동물: $p',
                                    isSelected: true,
                                  ),
                              if (col?.smoking != null)
                                ChipButton(
                                  text: col!.smoking ? '흡연' : '비흡연',
                                  isSelected: true,
                                )
                              else
                                const ChipButton(
                                  text: '흡연 정보 없음',
                                  isSelected: false,
                                ),
                            ],
                          ),
                        ),
                        AccordionWidget(
                          title: " 내 유저타입",
                          content: Column(
                            spacing: 8,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (data.userType == null) ...[
                                const ChipButton(
                                  text: '유저타입 없음',
                                  isSelected: false,
                                ),
                              ] else if (data.userType!.type ==
                                  "roomOwner") ...[
                                const ChipButton(
                                  text: 'RoomOwner',
                                  isSelected: true,
                                ),
                                ChipButton(
                                  text: (data.userType?.address ?? '주소 없음')
                                      .split('(')
                                      .first
                                      .trim(),
                                  isSelected: true,
                                ),
                              ] else ...[
                                const ChipButton(
                                  text: 'Searcher',
                                  isSelected: true,
                                ),

                                for (final area
                                    in (data.userType!.searchAreas ??
                                        const <String>[]))
                                  ChipButton(text: area, isSelected: true),

                                if ((data.userType!.searchAreas ??
                                        const <String>[])
                                    .isEmpty)
                                  const ChipButton(
                                    text: '선호 지역 없음',
                                    isSelected: false,
                                  ),
                              ],
                            ],
                          ),
                        ),
                        AccordionWidget(
                          title: " 내 취미",
                          content: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            spacing: 6,
                            children: [
                              for (final food in (data.hobby!.foodLike))
                                ChipButton(text: food, isSelected: true),
                              for (final interest in data.hobby!.interestLike)
                                ChipButton(text: interest, isSelected: true),
                              for (final sport in data.hobby!.sportLike)
                                ChipButton(text: sport, isSelected: true),
                            ],
                          ),
                        ),
                      ],
                    ),

                    if (data.userPass?.pass == false) ...[
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.transparent, Colors.white],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                      ),
                      Positioned.fill(
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              GestureDetector(
                                behavior:
                                    HitTestBehavior.opaque, // 아이콘 주변도 터치되게
                                onTap: _onNextTap,
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Icon(
                                    Icons.lock,
                                    color: Colors.black54,
                                    size: 48,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                "추가적인 유저 정보를 입력해면\n 사용하실수 있습니다.",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
