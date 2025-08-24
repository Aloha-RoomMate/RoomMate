import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:roommate/constants/gaps.dart';
import 'package:roommate/constants/sizes.dart';
import 'package:roommate/features/category/widgets/form_button.dart';
import 'package:roommate/features/category/widgets/selection_chip.dart';

class RoomOwnerPost extends StatefulWidget {
  const RoomOwnerPost({super.key});

  @override
  State<RoomOwnerPost> createState() => _RoomOwnerPostState();
}

class _RoomOwnerPostState extends State<RoomOwnerPost> {
  List<List<bool>> _chipOptionSelected = [
    List.filled(4, false),
    List.filled(4, false),
    List.filled(2, false),
    List.filled(2, false),
  ];
  TextEditingController _controller = TextEditingController();

  bool _checkNextButtonAvailable() {
    for (final groupState in _chipOptionSelected) {
      if (!groupState.contains(true)) {
        return false;
      }
    }
    return true;
  }

  void _onScaffoldTap(BuildContext context) {
    FocusScope.of(context).unfocus();
  }

  void _onChipTap(int groupIndex, int buttonIndex) {
    setState(() {
      _chipOptionSelected[groupIndex][buttonIndex] =
          !_chipOptionSelected[groupIndex][buttonIndex];
    });
  }

  void _onTimePickerChanged(DateTime date) {
    final textDate = date.toString().split(' ')[0];
    _controller.value = TextEditingValue(text: textDate);
  }

  void _onTimeFieldTap() async {
    await showModalBottomSheet(
      context: context,
      builder: (context) {
        return CupertinoDatePicker(
          mode: CupertinoDatePickerMode.date,
          onDateTimeChanged: _onTimePickerChanged,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _onScaffoldTap(context),
      child: Scaffold(
        appBar: AppBar(
          elevation: 10,
          title: Text(
            '게시글 작성',
            style: TextStyle(
              fontSize: Sizes.size24,
            ),
          ),
        ),
        body: Padding(
          padding: EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '제목을 입력해주세요!',
                  style: TextStyle(
                    fontSize: Sizes.size16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Gaps.v6,
                TextField(
                  decoration: InputDecoration(
                    hintText: '제목 입력',
                    border: OutlineInputBorder(),
                  ),
                ),
                Gaps.v24,
                Text(
                  '거주 위치를 입력해주세요!',
                  style: TextStyle(
                    fontSize: Sizes.size16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '보안을 위해 지하철역과의 거리로 입력 받습니다.',
                  style: TextStyle(
                    fontSize: Sizes.size14,
                    color: Colors.grey,
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: '지하철역 입력.',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    Gaps.h12,
                    Expanded(
                      child: TextField(
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: '거리 입력 (m).',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                Gaps.v24,
                Wrap(
                  children: [
                    SelectionChip(
                      textOptions: ['원 룸', '투 룸', '빌라', '아파트'],
                      onChipTap: _onChipTap,
                      checkList: _chipOptionSelected,
                      indexOfQuestion: 0,
                      question: '방 종류/구조',
                    ),
                  ],
                ),
                Gaps.v24,
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: "보증금(만 원)",
                          hintStyle: TextStyle(
                            fontSize: Sizes.size12,
                          ),
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    Gaps.h8,
                    Expanded(
                      child: TextField(
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          hintText: "월세(만 원)",
                          hintStyle: TextStyle(
                            fontSize: Sizes.size12,
                          ),
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    Gaps.h8,
                    Expanded(
                      child: TextField(
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: "관리비(만 원)",
                          hintStyle: TextStyle(
                            fontSize: Sizes.size12,
                          ),
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                Gaps.v24,
                Wrap(
                  children: [
                    SelectionChip(
                      textOptions: ['보증금 분담', '월세 분담', '관리비 분담', '공과금 분담'],
                      onChipTap: _onChipTap,
                      checkList: _chipOptionSelected,
                      indexOfQuestion: 1,
                      question: '지불 구조',
                    ),
                  ],
                ),
                Gaps.v24,
                Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: TextField(
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: '해당층',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    Gaps.h12,
                    Expanded(
                      child: TextField(
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: '건물층',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                Gaps.v24,
                Text(
                  '전용 면적 / 화장실 개수',
                  style: TextStyle(
                    fontSize: Sizes.size16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Gaps.v6,
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: '(평)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    Gaps.h12,
                    Expanded(
                      child: TextField(
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: '화장실 개수',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                Gaps.v24,
                SelectionChip(
                  textOptions: ['중앙 난방', '개별 난방'],
                  onChipTap: _onChipTap,
                  checkList: _chipOptionSelected,
                  indexOfQuestion: 2,
                  question: '난방 구조',
                ),
                Gaps.v24,
                SelectionChip(
                  textOptions: ['있음', '없음'],
                  onChipTap: _onChipTap,
                  checkList: _chipOptionSelected,
                  indexOfQuestion: 3,
                  question: '엘리베이터',
                ),
                Gaps.v24,
                Text(
                  '입주가능일',
                  style: TextStyle(
                    fontSize: Sizes.size16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Gaps.v6,
                TextField(
                  onTap: _onTimeFieldTap,
                  controller: _controller,
                  readOnly: true,
                  decoration: InputDecoration(
                    suffixIcon: Padding(
                      padding: EdgeInsets.all(10),
                      child: FaIcon(
                        FontAwesomeIcons.calendar,
                      ),
                    ),
                    hintText: '입주 가능일',
                    border: OutlineInputBorder(),
                  ),
                ),
                Gaps.v24,
                Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: TextField(
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: '최소 거주 기간(개월)',
                          hintStyle: TextStyle(
                            fontSize: Sizes.size14,
                          ),
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    Gaps.h12,
                    Expanded(
                      child: TextField(
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: '최대 거주 기간(개월)',
                          hintStyle: TextStyle(
                            fontSize: Sizes.size14,
                          ),
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                Gaps.v24,
                TextField(
                  minLines: 3,
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                  decoration: InputDecoration(
                    hintText:
                        '자유롭게 글을 작성해주세요!\n취미, 희망 진로, 동거 규칙에 대해 작성해주시면 좋아요!',
                    hintStyle: TextStyle(
                      fontSize: Sizes.size14,
                    ),
                    border: OutlineInputBorder(),
                  ),
                ),
                Gaps.v24,
                FormButton(enabled: true, text: '다음'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
