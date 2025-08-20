import 'package:flutter/material.dart';
import 'package:roommate/constants/gaps.dart';
import 'package:roommate/constants/sizes.dart';
import 'package:roommate/features/category/widgets/form_button.dart';
import 'package:roommate/features/view/widget/view_button.dart';

class RoomOwnerPostView extends StatelessWidget {
  const RoomOwnerPostView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Room-Owner 게시글',
          style: TextStyle(
            fontSize: Sizes.size24,
          ),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.only(
          top: Sizes.size8,
          right: Sizes.size24,
          left: Sizes.size24,
          bottom: Sizes.size24,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.black,
                ),
                height: 200,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      '사진',
                      textAlign: TextAlign.start,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: Sizes.size32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Gaps.v16,
              Text(
                '위치',
                style: TextStyle(
                  fontSize: Sizes.size16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Gaps.v6,
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  ViewButton(text: '홍대입구역 200M'),
                ],
              ),
              Gaps.v16,
              Text(
                '방 구조',
                style: TextStyle(
                  fontSize: Sizes.size16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Gaps.v6,
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  ViewButton(text: '빌라'),
                  ViewButton(text: '2룸 / 1화장실'),
                ],
              ),
              Gaps.v16,
              Text(
                '보증금 / 월세 / 관리비',
                style: TextStyle(
                  fontSize: Sizes.size16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Gaps.v6,
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  ViewButton(text: '보증금 500'),
                  ViewButton(text: '월세 65'),
                  ViewButton(text: '관리비 7'),
                ],
              ),
              Gaps.v16,
              Text(
                '지불 구조',
                style: TextStyle(
                  fontSize: Sizes.size16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Gaps.v6,
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  ViewButton(text: '월세 분담'),
                  ViewButton(text: '관리비 분담'),
                  ViewButton(text: '공과금 분담'),
                ],
              ),
              Gaps.v16,
              Text(
                '해당층 / 건물층',
                style: TextStyle(
                  fontSize: Sizes.size16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Gaps.v6,
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  ViewButton(text: '2층 / 5층'),
                ],
              ),
              Gaps.v16,
              Text(
                '전용 면적',
                style: TextStyle(
                  fontSize: Sizes.size16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Gaps.v6,
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  ViewButton(text: '15평'),
                ],
              ),
              Gaps.v16,
              Text(
                '난방 구조',
                style: TextStyle(
                  fontSize: Sizes.size16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Gaps.v6,
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  ViewButton(text: '개별 난방'),
                ],
              ),
              Gaps.v16,
              Text(
                '엘리베이터',
                style: TextStyle(
                  fontSize: Sizes.size16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Gaps.v6,
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  ViewButton(text: '없음'),
                ],
              ),
              Gaps.v16,
              Text(
                '입주 가능일',
                style: TextStyle(
                  fontSize: Sizes.size16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Gaps.v6,
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  ViewButton(text: '2025-09-10'),
                ],
              ),
              Gaps.v16,
              Text(
                '거주 기간',
                style: TextStyle(
                  fontSize: Sizes.size16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Gaps.v6,
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  ViewButton(text: '최소 3개월'),
                ],
              ),
              Gaps.v16,
              Text(
                '소개글',
                style: TextStyle(
                  fontSize: Sizes.size16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Gaps.v6,
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  ViewButton(text: '안녕하세요, 홍대입구 초역세권에 살고 있고 남성으로 한 분 모십니다.'),
                ],
              ),
              Gaps.v24,
              GestureDetector(
                child: FormButton(
                  enabled: true,
                  text: "채팅 시작하기",
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
