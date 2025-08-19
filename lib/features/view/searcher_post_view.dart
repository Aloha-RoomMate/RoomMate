import 'package:flutter/material.dart';
import 'package:roommate/constants/gaps.dart';
import 'package:roommate/constants/sizes.dart';
import 'package:roommate/features/category/widgets/form_button.dart';
import 'package:roommate/features/view/widget/view_button.dart';

class SearcherPostView extends StatelessWidget {
  const SearcherPostView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Searcher 게시글',
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
              Text(
                '[제목] 안녕하세요, 이재민입니다.',
                style: TextStyle(
                  fontSize: Sizes.size20,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              Gaps.v16,
              Text(
                '희망 지역',
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
                  ViewButton(text: '강남구 반포동'),
                  ViewButton(text: '서초구 압구정동'),
                ],
              ),
              Gaps.v16,
              Text(
                '희망 방 종류/구조',
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
                  ViewButton(text: '투 룸'),
                  ViewButton(text: '빌라'),
                  ViewButton(text: '아파트'),
                ],
              ),
              Gaps.v16,
              Text(
                '수용 가능 보증금 / 월세(관리비 포함)',
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
                  ViewButton(text: '월세 최소 50'),
                  ViewButton(text: '월세 최대 70'),
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
                  ViewButton(text: '보증금 분담'),
                  ViewButton(text: '월세 분담'),
                  ViewButton(text: '관리비 분담'),
                  ViewButton(text: '공과금 분담'),
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
                  ViewButton(text: '최대 24개월'),
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
                  ViewButton(text: '안녕하세요, 홍대입구 초역세권에 살고 싶어요.'),
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
