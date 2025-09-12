import 'package:flutter/material.dart';
import 'package:roommate/constants/gaps.dart';
import 'package:roommate/constants/sizes.dart';
import 'package:roommate/features/view/widget/form_button.dart';
import 'package:roommate/features/view/widget/appbar_chip.dart';
import 'package:roommate/features/view/widget/view_button.dart';

class UserProfileView extends StatelessWidget {
  const UserProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'XXX의 프로필',
          style: TextStyle(
            fontSize: Sizes.size24,
          ),
        ),
        actions: [
          AppbarChip(
            text: 'PASS 인증',
            color: Colors.red,
          ),
          Gaps.h4,
          AppbarChip(
            text: '대학생 인증',
            color: Colors.green,
          ),
        ],
        actionsPadding: EdgeInsets.only(
          right: Sizes.size8,
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
                '하루 리듬 관련 성향',
                style: TextStyle(
                  fontSize: Sizes.size20,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              Gaps.v16,
              Text(
                '출근',
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
                  ViewButton(text: '월'),
                  ViewButton(text: '화'),
                  ViewButton(text: '수'),
                  ViewButton(text: '목'),
                  ViewButton(text: '금'),
                ],
              ),
              Gaps.v16,
              Text(
                '기상 시간 / 출근 시간',
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
                  ViewButton(text: '7시 기상'),
                  ViewButton(text: '9시 출근'),
                ],
              ),
              Gaps.v16,
              Text(
                '퇴근 시간 / 취침 시간',
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
                  ViewButton(text: '18시 퇴근'),
                  ViewButton(text: '00시 취침'),
                ],
              ),
              Gaps.v16,
              Text(
                '휴일 기상 / 휴일 취침',
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
                  ViewButton(text: '11시 기상'),
                  ViewButton(text: '02시 취침'),
                ],
              ),
              Gaps.v16,
              Text(
                '알람 횟수',
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
                  ViewButton(text: '3회 이상'),
                ],
              ),
              Gaps.v16,
              Divider(),
              Gaps.v16,
              Text(
                '늦은 귀가 패턴',
                style: TextStyle(
                  fontSize: Sizes.size20,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              Gaps.v16,
              Text(
                '주 야근/밤 공부 횟수',
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
                  ViewButton(text: '주 1-2회'),
                ],
              ),
              Gaps.v16,
              Text(
                '주 외출/음주 횟수',
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
                  ViewButton(text: '2-3회'),
                ],
              ),
              Gaps.v16,
              Divider(),
              Text(
                '식사 성향',
                style: TextStyle(
                  fontSize: Sizes.size20,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              Gaps.v16,
              Text(
                '주 요리 빈도',
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
                  ViewButton(text: '주 1-2회'),
                ],
              ),
              Gaps.v16,
              Text(
                '냄새 민감도',
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
                  ViewButton(text: '민감해요'),
                ],
              ),
              Gaps.v16,
              Text(
                '공용 식기 선호도',
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
                  ViewButton(text: '같이 써요'),
                ],
              ),
              Gaps.v16,
              Text(
                '주 배달 음식 횟수',
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
                  ViewButton(text: '3-4회'),
                ],
              ),
              Gaps.v16,
              Divider(),
              Text(
                '소리 민감도',
                style: TextStyle(
                  fontSize: Sizes.size20,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              Gaps.v16,
              Text(
                '잠귀 민감도',
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
                  ViewButton(text: '예민한 편이예요'),
                ],
              ),
              Gaps.v16,
              Text(
                '잠버릇',
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
                  ViewButton(text: '자주 코를 골아요'),
                  ViewButton(text: '자주 이를 갈아요'),
                ],
              ),
              Gaps.v16,
              Text(
                '선호하는 소리/진동/무음 모드',
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
                  ViewButton(text: '항상 진동'),
                  ViewButton(text: '잘 때 무음'),
                ],
              ),
              Gaps.v16,
              Text(
                '선호하는 이어폰 사용 형태',
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
                  ViewButton(text: '밤에만'),
                ],
              ),
              Gaps.v16,
              Divider(),
              Text(
                '청소 습관',
                style: TextStyle(
                  fontSize: Sizes.size20,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              Gaps.v16,
              Text(
                '방 청소 빈도',
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
                  ViewButton(text: '더러워지면 해요'),
                ],
              ),
              Gaps.v16,
              Text(
                '화장실 청소 선호도',
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
                  ViewButton(text: '주 1회 교대 청소해요'),
                ],
              ),
              Gaps.v16,
              Text(
                '정리정돈 성향',
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
                  ViewButton(text: '항상 제자리에 둬요'),
                  ViewButton(text: '일정 기준 아래로는 깔끔하게 유지해요'),
                ],
              ),
              Gaps.v16,
              Divider(),
              Text(
                '기타 생활 습관',
                style: TextStyle(
                  fontSize: Sizes.size20,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              Gaps.v16,
              Text(
                '흡연 여부',
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
                  ViewButton(text: '액상 전자담배'),
                ],
              ),
              Gaps.v16,
              Text(
                '실내 흡연 허용',
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
                  ViewButton(text: '절대 안 돼요'),
                ],
              ),
              Gaps.v16,
              Text(
                '키우는 반려 동물',
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
                  ViewButton(text: '없어요'),
                ],
              ),
              Gaps.v16,
              Divider(),
              Text(
                '질병',
                style: TextStyle(
                  fontSize: Sizes.size20,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              Gaps.v16,
              Text(
                '질병 유무',
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
                  ViewButton(text: '만성 비염'),
                ],
              ),
              Gaps.v16,
              Divider(),
              Text(
                '자기소개',
                style: TextStyle(
                  fontSize: Sizes.size20,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              Gaps.v16,
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  ViewButton(
                    text:
                        '안녕하세요, 20대 대학생입니다. IT쪽 진로 희망하고 있습니다. 희망 진로 비슷한 분 혹은 현업자 분하고 같이 살면 좋을 거 같네요.',
                  ),
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
