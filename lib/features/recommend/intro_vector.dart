import 'dart:math';

List<double> hashBigramVector(String text, {int dim = 512}) {
  final v = List<double>.filled(dim, 0);
  final s = text.replaceAll(RegExp(r'\s+'), ' ').trim();
  for (var i = 0; i < s.length - 1; i++) {
    final g = s.substring(i, i + 2);
    // FNV-1a 간단 해시
    int h = 2166136261;
    for (final c in g.codeUnits) {
      h ^= c;
      h = (h * 16777619) & 0x7fffffff;
    }
    final idx = h % dim;
    v[idx] += 1;
  }
  final norm = sqrt(v.fold<double>(0, (s, x) => s + x * x));
  if (norm > 0) {
    for (var i = 0; i < v.length; i++) v[i] = v[i] / norm;
  }
  return v;
}
