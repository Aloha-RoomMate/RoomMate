// 샤라웃 투 https://github.com/youngsoonoh/youtube_profile/tree/example1 오용순
import 'package:flutter/material.dart';
import 'package:roommate/constants/sizes.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:roommate/features/navigationbar/widgets/accordion_widget.dart';
import 'package:roommate/features/navigationbar/widgets/chip_button.dart';

class MypageScreen extends StatefulWidget {
  const MypageScreen({super.key});

  @override
  State<MypageScreen> createState() => _MypageScreenState();
}

class _MypageScreenState extends State<MypageScreen> {
  File? _profileImage;

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
              Divider(
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
                      Text(
                        "여기 닉네임이 들어가야함",
                        style: TextStyle(
                          fontSize: Sizes.size16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Divider(
                        height: 10,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 2),
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: const Text("달러사인 내 카테고리"),
            ),
          ),
          Divider(
            height: 1,
            color: Theme.of(context).primaryColor.withAlpha(100),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AccordionWidget(
                  title: " 내 생활패턴",
                  content: ChipButton(text: "asdf", isSelected: true),
                ),
                AccordionWidget(
                  title: " 내 출/퇴근 패턴",
                  content: ChipButton(text: "asdf", isSelected: true),
                ),
                AccordionWidget(
                  title: " 내 식사습관",
                  content: ChipButton(text: "asdf", isSelected: true),
                ),
                AccordionWidget(
                  title: " 내 질병",
                  content: Wrap(
                    spacing: 8,
                    children: [
                      ChipButton(text: "asdf", isSelected: true),
                      ChipButton(text: "text", isSelected: false),
                    ],
                  ),
                ),
                AccordionWidget(
                  title: " 내 청소습관",
                  content: ChipButton(text: "asdf", isSelected: true),
                ),
                AccordionWidget(
                  title: " 내 잠버릇",
                  content: ChipButton(text: "asdf", isSelected: true),
                ),
                AccordionWidget(
                  title: " 그 이외",
                  content: ChipButton(text: "asdf", isSelected: true),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
