import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:roommate/class/user_repository.dart';
import 'package:roommate/constants/gaps.dart';
import 'package:roommate/constants/sizes.dart';
import 'package:roommate/features/authentication/widgets/form_button.dart';
import 'package:roommate/features/category/daily_rythm_screen.dart';
import 'package:roommate/features/category/hobby_screen.dart';

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

  bool get _isNextEnabled => _addrCtrl.text.trim().isNotEmpty;

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
    if (_addresses.isNotEmpty || _isLoading || _errorMessage.isNotEmpty) return;

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
      } catch (e) {
        debugPrint("저장 실패: $e");
      }
    }

    if (!mounted) return;
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const HobbyScreen(),
        transitionDuration: const Duration(milliseconds: 300),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lightCard = Theme.of(context).colorScheme.primary.withOpacity(0.08);

    return Scaffold(
      appBar: AppBar(title: const Text('거주지역 선택')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(Sizes.size16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  '현재 거주하고있는 위치를 알려주세요',
                  style: TextStyle(
                    fontSize: Sizes.size16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Gaps.v12,
                TextField(
                  controller: _addrCtrl,
                  decoration: const InputDecoration(
                    hintText: '주소 입력',
                    border: OutlineInputBorder(),
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
            color: lightCard,
            margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Theme.of(context).primaryColor,
                child: Text('${index + 1}'),
              ),
              title: Text(address['roadAddr'] ?? '도로명 주소 없음'),
              subtitle: Text('[지번] ${address['jibunAddr'] ?? '지번 주소 없음'}'),
              onTap: () {
                final road = (address['roadAddr'] as String?) ?? '';
                setState(() {
                  _addrCtrl.text = road;
                  _addresses = [];
                  _searchCtrl.clear();
                });
              },
            ),
          );
        },
      );
    }
  }
}
