import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:roommate/constants/gaps.dart';
import 'package:roommate/constants/sizes.dart';
import 'package:roommate/features/post/widgets/form_button.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';

class RoomOwnerPost extends StatefulWidget {
  const RoomOwnerPost({super.key});

  @override
  State<RoomOwnerPost> createState() => _RoomOwnerPostState();
}

class _RoomOwnerPostState extends State<RoomOwnerPost> {
  TextEditingController _titleCtrl = TextEditingController();
  TextEditingController _addrCtrl = TextEditingController();
  TextEditingController _depositCtrl = TextEditingController();
  TextEditingController _rentCtrl = TextEditingController();
  TextEditingController _manageFeeCtrl = TextEditingController();
  TextEditingController _corFloorCtrl = TextEditingController();
  TextEditingController _wholeFloorCtrl = TextEditingController();
  TextEditingController _areaCtrl = TextEditingController();
  TextEditingController _toiletCtrl = TextEditingController();
  TextEditingController _movingDateCtrl = TextEditingController();
  TextEditingController _minContractCtrl = TextEditingController();
  TextEditingController _maxContractCtrl = TextEditingController();
  TextEditingController _introductionCtrl = TextEditingController();

  final String _apiKey = "devU01TX0FVVEgyMDI1MDkwMjIxNTIzOTExNjEzOTc=";
  List<dynamic> _addresses = [];
  bool _isLoading = false;
  bool _isPosting = false;
  String _errorMessage = '';

  // 주소 검색 API를 호출하는 함수
  Future<void> _searchAddress(String keyword) async {
    if (keyword.isEmpty) {
      setState(() {
        _errorMessage = '검색어를 입력해주세요.';
        _addresses = [];
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    final url = Uri.https('www.juso.go.kr', '/addrlink/addrLinkApi.do', {
      'confmKey': _apiKey,
      'currentPage': '1',
      'countPerPage': '20',
      'keyword': keyword,
      'resultType': 'json',
    });

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        // jsonDecode: json -> Map
        final decodedData = jsonDecode(response.body);

        // API 결과 구조 확인 후 'juso' 리스트 추출
        if (decodedData['results'] != null &&
            decodedData['results']['juso'] != null) {
          setState(() {
            _addresses = decodedData['results']['juso'];

            if (_addresses.isEmpty) {
              _errorMessage = '검색 결과가 없습니다.';
            }
          });
        } else {
          // 'common' 객체에서 에러 메시지 확인
          final commonData = decodedData['results']['common'];
          setState(() {
            _errorMessage = commonData['errorMessage'] ?? '알 수 없는 오류가 발생했습니다.';
            _addresses = [];
          });
        }
      } else {
        setState(() {
          _errorMessage = 'API 서버 오류: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = '데이터 요청 중 오류가 발생했습니다: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onScaffoldTap(BuildContext context) {
    FocusScope.of(context).unfocus();
  }

  void _onTimePickerChanged(DateTime date) {
    _movingDateCtrl.text =
        "${date.year.toString()}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  void _onTimeFieldTap() async {
    await showModalBottomSheet(
      context: context,
      builder: (context) {
        return CupertinoDatePicker(
          mode: CupertinoDatePickerMode.date,
          onDateTimeChanged: (date) => _onTimePickerChanged(date),
          minimumDate: DateTime.now(),
          initialDateTime: DateTime.now(),
        );
      },
    );
  }

  bool _isNextAvailable() {
    return _titleCtrl.text.isNotEmpty &&
        _addrCtrl.text.isNotEmpty &&
        _depositCtrl.text.isNotEmpty &&
        _rentCtrl.text.isNotEmpty &&
        _manageFeeCtrl.text.isNotEmpty &&
        _corFloorCtrl.text.isNotEmpty &&
        _wholeFloorCtrl.text.isNotEmpty &&
        _areaCtrl.text.isNotEmpty &&
        _toiletCtrl.text.isNotEmpty &&
        _movingDateCtrl.text.isNotEmpty &&
        _minContractCtrl.text.isNotEmpty &&
        _maxContractCtrl.text.isNotEmpty &&
        _introductionCtrl.text.isNotEmpty;
  }

  Map<String, dynamic> _buildPayload() {
    return {
      'title': _titleCtrl.text,
      'address': _addrCtrl.text,
      'deposit': _depositCtrl.text,
      'rent': _rentCtrl.text,
      'manageFee': _manageFeeCtrl.text,
      'corFloor': _corFloorCtrl.text,
      'wholeFloor': _wholeFloorCtrl.text,
      'minContract': _minContractCtrl.text,
      'maxContract': _maxContractCtrl.text,
      'introduction': _introductionCtrl.text,
      'updatedAt': DateTime.now().toIso8601String(),
    };
  }

  void _onNextTap() async {
    if (_isNextAvailable()) {
      try {
        setState(() {
          _isPosting = true;
        });
        final payload = _buildPayload();
        await FirebaseFirestore.instance
            .collection('roomOwnerPost')
            .add(payload);

        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('글 포스팅 성공~')));
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('오류 발생~')));
          Navigator.of(context).pop();
        }
      } finally {
        if (mounted) {
          setState(() {
            _isPosting = false;
          });
        }
      }
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _addrCtrl.dispose();
    _depositCtrl.dispose();
    _rentCtrl.dispose();
    _manageFeeCtrl.dispose();
    _corFloorCtrl.dispose();
    _wholeFloorCtrl.dispose();
    _areaCtrl.dispose();
    _toiletCtrl.dispose();
    _movingDateCtrl.dispose();
    _minContractCtrl.dispose();
    _maxContractCtrl.dispose();
    _introductionCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _onScaffoldTap(context),
      child: Scaffold(
        appBar: AppBar(
          elevation: 10,
          title: Text('게시글 작성', style: TextStyle(fontSize: Sizes.size24)),
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
                  controller: _titleCtrl,
                  decoration: InputDecoration(
                    hintText: '제목 입력',
                    border: OutlineInputBorder(),
                  ),
                ),
                Gaps.v24,
                Text(
                  '주소를 입력해주세요!',
                  style: TextStyle(
                    fontSize: Sizes.size16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '다른 유저에게는 XX동 \'부근\'으로 보여져요. \n지도에는 실제 주소 반경 200m 내의 랜덤한 위치로 나타나요',
                  style: TextStyle(fontSize: Sizes.size14, color: Colors.grey),
                ),
                Gaps.v6,
                Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: TextField(
                        controller: _addrCtrl,
                        decoration: InputDecoration(
                          hintText: '주소 입력.',
                          border: OutlineInputBorder(),
                        ),
                        onSubmitted: (value) => _searchAddress(value),
                      ),
                    ),
                    Gaps.h12,
                  ],
                ),
                Gaps.v24,
                SizedBox(
                  height: _addresses.isNotEmpty ? 300 : 0,
                  child: _buildResults(),
                ),
                Gaps.v12,
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _depositCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: "보증금(만 원)",
                          hintStyle: TextStyle(fontSize: Sizes.size12),
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    Gaps.h8,
                    Expanded(
                      child: TextField(
                        controller: _rentCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          hintText: "월세(만 원)",
                          hintStyle: TextStyle(fontSize: Sizes.size12),
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    Gaps.h8,
                    Expanded(
                      child: TextField(
                        controller: _manageFeeCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: "관리비(만 원)",
                          hintStyle: TextStyle(fontSize: Sizes.size12),
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                Gaps.v24,
                Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: TextField(
                        controller: _corFloorCtrl,
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
                        controller: _wholeFloorCtrl,
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
                        controller: _areaCtrl,
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
                        controller: _toiletCtrl,
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
                  controller: _movingDateCtrl,
                  readOnly: true,
                  decoration: InputDecoration(
                    suffixIcon: Padding(
                      padding: EdgeInsets.all(10),
                      child: FaIcon(FontAwesomeIcons.calendar),
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
                        controller: _minContractCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: '최소 거주 기간(개월)',
                          hintStyle: TextStyle(fontSize: Sizes.size14),
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    Gaps.h12,
                    Expanded(
                      child: TextField(
                        controller: _maxContractCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: '최대 거주 기간(개월)',
                          hintStyle: TextStyle(fontSize: Sizes.size14),
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                Gaps.v24,
                TextField(
                  controller: _introductionCtrl,
                  minLines: 3,
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                  decoration: InputDecoration(
                    hintText:
                        '자유롭게 글을 작성해주세요!\n취미, 희망 진로, 동거 규칙에 대해 작성해주시면 좋아요!',
                    hintStyle: TextStyle(fontSize: Sizes.size14),
                    border: OutlineInputBorder(),
                  ),
                ),
                Gaps.v24,
                GestureDetector(
                  onTap: _onNextTap,
                  child: FormButton(
                    enabled: _isNextAvailable(),
                    widget: _isPosting
                        ? CircularProgressIndicator()
                        : Text('다음'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResults() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    } else if (_errorMessage.isNotEmpty) {
      return Center(child: Text(_errorMessage));
    } else {
      return ListView.builder(
        itemCount: _addresses.length,
        itemBuilder: (context, index) {
          final address = _addresses[index];
          return GestureDetector(
            onTap: () {
              setState(() {
                _addrCtrl.text = address['roadAddr'] ?? '';
                _addresses = [];
              });
            },
            child: Card(
              margin: const EdgeInsets.symmetric(vertical: 6),
              child: ListTile(
                leading: CircleAvatar(child: Text('${index + 1}')),
                title: Text(address['roadAddr'] ?? '도로명 주소 없음'), // 도로명 주소
                subtitle: Text(
                  '[지번] ${address['jibunAddr'] ?? '지번 주소 없음'}',
                ), // 지번 주소
              ),
            ),
          );
        },
      );
    }
  }
}
