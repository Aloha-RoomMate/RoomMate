/* import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:roommate/constants/sizes.dart';
import 'package:roommate/features/post/room_owner_post_screen.dart';
import 'package:roommate/features/post/widgets/form_button.dart';

class RoomOwnerPhoto extends StatefulWidget {
  const RoomOwnerPhoto({super.key});

  @override
  State<RoomOwnerPhoto> createState() => _PhotoSelectionScreenState();
}

class _PhotoSelectionScreenState extends State<RoomOwnerPhoto> {
  // 사용자가 선택한 사진 파일을 담을 리스트
  final List<XFile> _selectedImages = [];
  bool _isLoading = false;

  // 갤러리에서 여러 이미지를 선택하는 함수
  Future<void> _pickImages() async {
    final picker = ImagePicker();
    // pickMultiImage()를 사용해 여러 이미지를 한번에 가져옵니다.
    final List<XFile> images = await picker.pickMultiImage(
      imageQuality: 80, // 이미지 품질 조절
    );

    if (images.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(images);
      });
    }
  }

  bool _isNextAvailable() => (_selectedImages.isNotEmpty);

  // 선택 완료 버튼을 눌렀을 때 호출되는 함수
  void _onNextTap() {
    if (_isNextAvailable()) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) =>
              RoomOwnerPostScreen(selectedImages: _selectedImages),
        ),
      );
    }
  }

  // 선택된 이미지를 리스트에서 제거하는 함수
  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('사진 추가'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(Sizes.size16),
        child: Column(
          children: [
            ElevatedButton.icon(
              onPressed: _pickImages,
              icon: const Icon(Icons.photo_library),
              label: const Text('갤러리에서 사진 선택'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
            const SizedBox(height: Sizes.size16),
            Expanded(
              // 선택된 이미지를 그리드 형태로 보여줍니다.
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3, // 한 줄에 3개씩
                  crossAxisSpacing: 4.0,
                  mainAxisSpacing: 4.0,
                ),
                itemCount: _selectedImages.length,
                itemBuilder: (context, index) {
                  // ✅ GestureDetector와 Stack을 사용하여 삭제 기능 구현
                  return GestureDetector(
                    onTap: () => _removeImage(index),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // 이미지 표시
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8.0),
                          child: Image.file(
                            File(_selectedImages[index].path),
                            fit: BoxFit.cover,
                          ),
                        ),
                        // 오른쪽 위에 X 아이콘 표시
                        Positioned(
                          top: 4,
                          right: 4,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            GestureDetector(
              onTap: _onNextTap,
              child: FormButton(
                enabled: _isNextAvailable(),
                widget: _isLoading
                    ? Center(
                        child: CircularProgressIndicator(
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        '다음',
                        textAlign: TextAlign.center,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
*/
