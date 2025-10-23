// lib/net/jsonp_web.dart
@JS()
library jsonp_web;

import 'dart:async';
import 'dart:convert' show jsonDecode;
import 'dart:js_interop';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// web/index.html 에서 정의한 전역 함수 시그니처
/// JS: window.__jsonpGetString(url) -> Promise<string>
@JS('__jsonpGetString')
external JSPromise<JSString> __jsonpGetString(JSString url);

/// Dart -> JS 호출 래퍼
Future<String> jsonpGetString(String url) async {
  final jsPromise = __jsonpGetString(url.toJS); // JSString로 변환
  final jsResult = await jsPromise.toDart; // JSPromise -> Future<JSString>
  return jsResult.toDart; // JSString -> String
}

/// VWorld 주소 → 좌표 (JSONP 버전, Web 전용)
Future<Map<String, double>?> addrToCoordinate(String address) async {
  final key = dotenv.env['VWORLD_API_KEY']!;
  final params = <String, String>{
    'service': 'address',
    'request': 'getcoord',
    'version': '2.0',
    'crs': 'epsg:4326',
    'address': address,
    'refine': 'true',
    'simple': 'false',
    'format': 'jsonp', // 핵심: JSONP
    'type': 'road', // 지번이면 'parcel'
    'key': key,
  };

  final query = params.entries
      .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
      .join('&');

  final url = 'https://api.vworld.kr/req/address?$query';

  try {
    final body = await jsonpGetString(url);
    final decoded = jsonDecode(body);

    if (decoded is Map &&
        decoded['response'] is Map &&
        decoded['response']['status'] == 'OK') {
      final p = decoded['response']['result']['point'];
      final lon = double.tryParse('${p['x']}');
      final lat = double.tryParse('${p['y']}');
      if (lat == null || lon == null) return null;
      return {'latitude': lat, 'longitude': lon};
    }
    return null;
  } catch (_) {
    return null;
  }
}
