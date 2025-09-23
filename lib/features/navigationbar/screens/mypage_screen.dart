// 샤라웃 투 https://github.com/youngsoonoh/youtube_profile/tree/example1 오용순
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:roommate/class/app_user.dart';
import 'package:roommate/class/user_repository.dart';
import 'package:roommate/constants/gaps.dart';
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
        final ut = data.userType;
        final h = data.hobby;

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
                          content: Builder(
                            builder: (_) {
                              final dr = data.userPass?.dailyRhythm;
                              final workDays = dr?.workDays ?? const <String>[];
                              final hasWorkDays = workDays.isNotEmpty;

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  LabeldRow(
                                    label: "출근일 :",
                                    chips: [
                                      for (final d in workDays)
                                        ChipButton(text: d, isSelected: true),
                                    ],
                                  ),
                                  if (hasWorkDays)
                                    LabeldRow(
                                      label: "주말 시간",
                                      chips: [
                                        if (dr?.weekAwakeMins != null)
                                          ChipButton(
                                            text: "기상 ${dr!.weekAwakeMins}",
                                            isSelected: true,
                                          ),
                                        if (dr?.weekSleepMins != null)
                                          ChipButton(
                                            text: "취침 ${dr!.weekSleepMins}",
                                            isSelected: true,
                                          ),
                                      ],
                                    ),
                                  if (!hasWorkDays)
                                    const LabeldRow(
                                      label: "주말 시간",
                                      chips: [],
                                    ), // '입력 없음' 표시
                                ],
                              );
                            },
                          ),
                        ),

                        AccordionWidget(
                          title: " 내 공동 생활 성향",
                          content: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              LabeldRow(
                                label: "공용공간 사용 선호도 :",
                                chips: [
                                  if ((col?.coSpace ?? '').isNotEmpty)
                                    ChipButton(
                                      text: col!.coSpace,
                                      isSelected: true,
                                    ),
                                ],
                              ),
                              LabeldRow(
                                label: "화장실 청결 민감도 : ",
                                chips: [
                                  if ((col?.bathroom ?? '').isNotEmpty)
                                    ChipButton(
                                      text: col!.bathroom,
                                      isSelected: true,
                                    ),
                                ],
                              ),
                              LabeldRow(
                                label: "MBTI : ",
                                chips: [
                                  if ((col?.mbti ?? '').isNotEmpty)
                                    ChipButton(
                                      text: col!.mbti,
                                      isSelected: true,
                                    ),
                                ],
                              ),
                              LabeldRow(
                                label: "반려동물 : ",
                                chips: (col?.pet ?? const <String>[])
                                    .map(
                                      (p) =>
                                          ChipButton(text: p, isSelected: true),
                                    )
                                    .toList(),
                              ),
                              LabeldRow(
                                label: "흡연 : ",
                                chips: [
                                  if (col?.smoking != null)
                                    ChipButton(
                                      text: col!.smoking ? '흡연' : '비흡연',
                                      isSelected: true,
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        AccordionWidget(
                          title: " 내 유저타입",
                          content: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              LabeldRow(
                                label: "유저타입 :",
                                chips: [
                                  ChipButton(
                                    text: (ut?.type == "roomOwner")
                                        ? "RoomOwner"
                                        : "Searcher",
                                    isSelected: true,
                                  ),
                                ],
                              ),
                              if (ut?.type == "roomOwner")
                                LabeldRow(
                                  label: "주소",
                                  chips: [
                                    ChipButton(
                                      text: (ut?.address ?? '주소 없음')
                                          .split('(')
                                          .first
                                          .trim(),
                                      isSelected: true,
                                    ),
                                  ],
                                )
                              else
                                LabeldRow(
                                  label: "선호하는 지역 : ",
                                  chips: (ut?.searchAreas ?? const <String>[])
                                      .map(
                                        (a) => ChipButton(
                                          text: a,
                                          isSelected: true,
                                        ),
                                      )
                                      .toList(),
                                ),
                            ],
                          ),
                        ),
                        AccordionWidget(
                          title: " 내 취미",
                          content: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              LabeldRow(
                                label: "최애 음식 :",
                                chips: (h?.foodLike ?? const <String>[])
                                    .map(
                                      (x) =>
                                          ChipButton(text: x, isSelected: true),
                                    )
                                    .toList(),
                              ),
                              LabeldRow(
                                label: "요즘 관심사 :",
                                chips: (h?.interestLike ?? const <String>[])
                                    .map(
                                      (x) =>
                                          ChipButton(text: x, isSelected: true),
                                    )
                                    .toList(),
                              ),
                              LabeldRow(
                                label: "운동 :",
                                chips: (h?.sportLike ?? const <String>[])
                                    .map(
                                      (x) =>
                                          ChipButton(text: x, isSelected: true),
                                    )
                                    .toList(),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          height: 20,
                        ),
                        SizedBox(
                          height: 80,
                          child: ListView(
                            scrollDirection: Axis.vertical,
                            children: <Widget>[
                              ListTile(
                                leading: Icon(Icons.home),
                                title: Text("one"),
                                trailing: Icon(Icons.navigate_next_rounded),
                                onTap: () {},
                              ),
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
                                behavior: HitTestBehavior.opaque,
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
                                "추가적인 유저 정보를 입력하면\n 사용하실수 있습니다.",
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
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: labelWidth,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Wrap(spacing: 6, runSpacing: 6, children: chips),
          ),
        ],
      ),
    );
  }
}
