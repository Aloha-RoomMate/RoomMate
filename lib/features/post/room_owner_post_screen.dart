import 'dart:convert';
import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:roommate/class/app_user.dart';
import 'package:roommate/class/room_owner_post.dart';
import 'package:roommate/class/room_owner_post_repository.dart';
import 'package:roommate/class/user_repository.dart';
import 'package:roommate/constants/gaps.dart';
import 'package:roommate/constants/sizes.dart';
import 'package:roommate/features/post/widgets/form_button.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';

class RoomOwnerPostScreen extends StatefulWidget {
  const RoomOwnerPostScreen({super.key});

  @override
  State<RoomOwnerPostScreen> createState() => _RoomOwnerPostState();
}

class _RoomOwnerPostState extends State<RoomOwnerPostScreen> {
  final UserRepository _userRepository = UserRepository();
  final OwnerPostRepository _postRepository = OwnerPostRepository();

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

  final String _apiKey = "devU01TX0FVVEgyMDI1MDkxMTE3MzcyNzExNjE3NjI=";
  List<dynamic> _addresses = [];
  bool _isLoading = false;
  bool _isPosting = false;
  String _errorMessage = '';
  AppUser? _currentUser;
  DateTime? _selectedMovingDate;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  /// 사용자 정보 불러오는 함수
  Future<void> _loadCurrentUser() async {
    _currentUser = await _userRepository.fetchMe();
    if (mounted) {
      setState(() {});
    }
  }

  /// 주소 검색 API를 호출하는 함수
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

  /// 도로명주소 좌표로 변환하는 함수
  Future<Map<String, double>?> _addrToCoordinate(String address) async {
    const KEY = '859C0BAE-5962-3698-97E5-FE4089A6517A';

    final url = Uri.https('api.vworld.kr', '/req/address', {
      'service': 'address',
      'request': 'getcoord',
      'version': '2.0',
      'crs': 'epsg:4326',
      'address': address,
      'refine': 'true',
      'simple': 'false',
      'format': 'json',
      'type': 'road',
      'key': KEY,
    });

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final decodedData = jsonDecode(response.body);

        if (decodedData['response']['status'] == 'OK') {
          final point = decodedData['response']['result']['point'];
          final double longitude = double.parse(point['x']); // 경도
          final double latitude = double.parse(point['y']); // 위도
          print('>> 변환된 경도: $longitude');
          print('>> 변환된 위도: $latitude');
          return {
            'longitude': longitude,
            'latitude': latitude,
          };
        } else {
          // API 에러 반환
          final errorMessage = decodedData['rponse']['error']['text'];
          print('>> API Error: $errorMessage');
          return null;
        }
      } else {
        // HTTP 요청 자체가 실패
        print('>> HTTP Error: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('Geocoding error: $e');
      return null;
    }
  }

  /// 위 함수에서 구한 좌표를 랜덤화하는 함수
  Map<String, double> _getRandomCoordinate(
    Map<String, double> center,
    radiusInMeters,
  ) {
    final random = Random();
    final double centerLongitude = center['longitude'] as double; // 원 중심 경도
    final double centerLatitude = center['latitude'] as double; // 원 중심 위도

    const earthRadius = 6371000;

    // 랜덤 거리와 각도 생성
    // sqrt로 원 가장자리에 쏠림 현상 방지
    final randomDist = sqrt(random.nextDouble()) * radiusInMeters;
    final randomAngle = random.nextDouble() * 2 * pi;

    // 경, 위도 변화량 계산
    final longitudeOffset =
        (randomDist * sin(randomAngle)) /
        (earthRadius * cos(centerLatitude * pi / 180));
    final latitudeOffset = (randomDist * cos(randomAngle)) / earthRadius;

    // 새 좌표 생성
    final double newLongitude = centerLongitude + longitudeOffset * 180 / pi;
    final double newLatitude = centerLatitude + latitudeOffset * 180 / pi;

    // 새 좌표 반환
    return {'longitude': newLongitude, 'latitude': newLatitude};
  }

  void _onScaffoldTap(BuildContext context) {
    FocusScope.of(context).unfocus();
  }

  void _onTimePickerChanged(DateTime date) {
    _selectedMovingDate = date;
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

  void _onNextTap() async {
    if (_isNextAvailable()) {
      try {
        setState(() {
          _isPosting = true;
        });

        final centerCoords = await _addrToCoordinate(_addrCtrl.text);

        if (centerCoords == null) {
          throw Exception('주소를 좌표로 변환하는데 실패했습니다.');
        }

        final randomCoordinate = _getRandomCoordinate(centerCoords, 200.0);

        final ownerPost = RoomOwnerPost(
          authorId: _currentUser!.uid,
          title: _titleCtrl.text,
          addr: GeoPoint(
            randomCoordinate['latitude']!,
            randomCoordinate['longitude']!,
          ),
          deposit: int.tryParse(_depositCtrl.text) ?? 0,
          rent: int.tryParse(_rentCtrl.text) ?? 0,
          manageFee: int.tryParse(_manageFeeCtrl.text) ?? 0,
          corFloor: int.tryParse(_corFloorCtrl.text) ?? 0,
          wholeFloor: int.tryParse(_wholeFloorCtrl.text) ?? 0,
          area: int.tryParse(_areaCtrl.text) ?? 0,
          toilet: int.tryParse(_toiletCtrl.text) ?? 0,
          movingDate: _selectedMovingDate != null
              ? Timestamp.fromDate(_selectedMovingDate!)
              : Timestamp.now(), // 선택된 날짜를 Timestamp로 변환
          minContract: int.tryParse(_minContractCtrl.text) ?? 0,
          maxContract: int.tryParse(_maxContractCtrl.text) ?? 0,
          introduction: _introductionCtrl.text,
        );

        await _postRepository.createPost(ownerPost);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('게시글 저장 완료~'),
            ),
          );
        }
        setState(() {
          _isPosting = false;
        });
        Navigator.of(context).pop();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$e'),
          ),
        );
      } finally {
        setState(() {
          _isPosting = false;
        });
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
