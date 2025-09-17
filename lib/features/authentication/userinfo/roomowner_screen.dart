import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:roommate/class/user_repository.dart';
import 'package:roommate/constants/gaps.dart';
import 'package:roommate/constants/sizes.dart';
import 'package:roommate/features/authentication/userinfo/hobby_screen.dart';
import 'package:roommate/features/authentication/widgets/form_button.dart';
import 'package:roommate/features/category/daily_rythm_screen.dart';

const _JUSO_KEY = "devU01TX0FVVEgyMDI1MDkxMTE3MzcyNzExNjE3NjI=";

class RoomownerScreen extends StatefulWidget {
  final String userType;
  final String jobKinds;

  const RoomownerScreen({
    super.key,
    required this.userType,
    required this.jobKinds,
  });

  @override
  State<RoomownerScreen> createState() => _RoomownerScreenState();
}

class _RoomownerScreenState extends State<RoomownerScreen> {
  final TextEditingController _addrCtrl = TextEditingController();
  final TextEditingController _searchCtrl = TextEditingController();

  List<dynamic> _addresses = [];
  bool _isLoading = false;
  String _errorMessage = '';

  bool get _isNextEnabled =>
      _addrCtrl.text.trim().isNotEmpty && _isAddressSelected;
  bool _isAddressSelected = false;

  Future<http.Response?> _safeGet(
    Uri uri, {
    Map<String, String>? headers,
  }) async {
    try {
      return await http
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 8));
    } catch (e) {
      debugPrint('[HTTP] GET error: $e');
      return null;
    }
  }

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
      'confmKey': _JUSO_KEY,
      'currentPage': '1',
      'countPerPage': '20',
      'keyword': keyword,
      'resultType': 'json',
    });

    final response = await _safeGet(url);
    if (!mounted) return;

    try {
      if (response != null && response.statusCode == 200) {
        final decodedData = jsonDecode(response.body);
        if (decodedData['results']?['juso'] != null) {
          setState(() {
            _addresses = decodedData['results']['juso'];
            if (_addresses.isEmpty) _errorMessage = '검색 결과가 없습니다.';
          });
        } else {
          final commonData = decodedData['results']?['common'];
          setState(() {
            _errorMessage = (commonData?['errorMessage'] ?? '알 수 없는 오류')
                .toString()
                .trim();
            _addresses = [];
          });
        }
      } else {
        setState(() {
          _errorMessage = 'API 서버 오류: ${response?.statusCode ?? '연결 실패'}';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = '데이터 요청 중 오류가 발생했습니다: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _onNextTap() async {
    debugPrint("qjxms snffla, $_isNextEnabled");
    if (!_isNextEnabled) {
      return;
    }

    final address = _addrCtrl.text.trim();

    if (address.isNotEmpty) {
      try {
        await UserRepository().setUserTypeData(
          uid: FirebaseAuth.instance.currentUser!.uid,
          type: widget.userType,
          jobKinds: widget.jobKinds,
          address: address,
          searchAreas: null,
        );
      } catch (e) {}
    }

    if (!mounted) return;
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const HobbyScreen(),
        transitionDuration: const Duration(milliseconds: 300),
        reverseTransitionDuration: const Duration(milliseconds: 300),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lightCard = Theme.of(context).colorScheme.primary.withOpacity(0.08);

    return Scaffold(
      appBar: AppBar(title: const Text('')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 20, left: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  '나의 위치찾기',
                  style: TextStyle(
                    fontSize: Sizes.size28,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "현재 거주하고있는 위치를 알려주세요 !",
                  style: TextStyle(
                    fontSize: Sizes.size14,
                    color: Colors.black87,
                    fontWeight: FontWeight.w300,
                  ),
                ),
                const SizedBox(height: Sizes.size16),
                const Divider(height: 1, color: Colors.black12),
                const SizedBox(height: Sizes.size16),
                TextField(
                  controller: _addrCtrl,
                  decoration: InputDecoration(
                    hintText: '주소 입력',
                    hintStyle: const TextStyle(color: Colors.grey),
                    // 👇 ValueListenableBuilder로 글자 유무 감지
                    suffixIcon: ValueListenableBuilder<TextEditingValue>(
                      valueListenable: _addrCtrl,
                      builder: (context, value, child) {
                        final hasText = value.text.isNotEmpty;
                        return hasText
                            ? IconButton(
                                icon: const Icon(Icons.close_rounded),
                                onPressed: () {
                                  _addrCtrl.clear();
                                  setState(() {
                                    _isAddressSelected = false;
                                  });
                                },
                              )
                            : const SizedBox.shrink();
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(Sizes.size18),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(Sizes.size18),
                      borderSide: BorderSide(
                        color: Theme.of(context).primaryColor,
                        width: Sizes.size2,
                      ),
                    ),
                  ),
                  onSubmitted: _searchAddress,
                ),

                Gaps.v16,
              ],
            ),
          ),
          if (_addresses.isNotEmpty || _isLoading || _errorMessage.isNotEmpty)
            Expanded(
              child: _buildResults(lightCard),
            ),
          Padding(
            padding: const EdgeInsets.all(Sizes.size16),
            child: GestureDetector(
              onTap: _onNextTap,
              child: FormButton(
                disabled: !_isNextEnabled,
                text: "다음",
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResults(Color lightCard) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    } else if (_errorMessage.isNotEmpty) {
      return Center(child: Text(_errorMessage));
    } else if (_addresses.isEmpty) {
      return const SizedBox();
    } else {
      return ListView.builder(
        itemCount: _addresses.length,
        itemBuilder: (context, index) {
          final address = _addresses[index] as Map<String, dynamic>;
          return Card(
            color: Colors.white,
            elevation: 0,
            shadowColor: Colors.white,
            margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadiusGeometry.circular(Sizes.size18),
              side: BorderSide(
                color: Theme.of(context).primaryColor.withAlpha(100),
                width: 1,
              ),
            ),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Theme.of(context).primaryColor,
                child: Text(
                  '${index + 1}',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              title: Text(
                address['roadAddr'] ?? '도로명 주소 없음',
                style: TextStyle(color: Colors.black),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                '[지번] ${address['jibunAddr'] ?? '지번 주소 없음'}',
                style: TextStyle(color: Colors.black54, fontSize: Sizes.size12),
              ),
              onTap: () {
                final road = (address['roadAddr'] as String?) ?? '';
                setState(() {
                  _addrCtrl.text = road; // 텍스트필드 값 반영
                  _addresses = []; // 카드 제거
                  _searchCtrl.clear();
                  _isAddressSelected = true; // 다음 버튼 활성화 조건 만족
                });
              },
            ),
          );
        },
      );
    }
  }
}
