import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:roommate/constants/responsive_sizes.dart';
import 'package:roommate/class/app_user.dart';

/// 어떤 피드에 필터를 적용할지
enum FeedTarget { roomOwner, searcher }

/// 정렬 기준 (거리순은 미사용)
enum FeedSort {
  newest,
  oldest,
  recommend, // (Owner가 Searcher 글 볼 때) 유저 추천
  payMatch, // (확장용)
  roomMatch, // (확장용)
  distance, // (미사용)
}

/// 필터 스테이트 (모든 금액은 '만' 단위)
class FeedFilterState {
  final FeedTarget target; // 내부 유지(하위 호환), UI에선 외부 target 사용

  // 공통(보증금/계약개월)
  final int? depositMin;
  final int? depositMax;
  final int? contractMin; // 개월
  final int? contractMax; // 개월

  // Owner 글용
  final int? rentMin;
  final int? rentMax;
  final int? manageMin;
  final int? manageMax;

  // Searcher 글용(예산 범위와 겹침)
  final int? searcherBudgetMin; // 사용자가 원하는 월세 최솟값
  final int? searcherBudgetMax; // 사용자가 원하는 월세 최댓값

  // Searcher 글용(희망 조건)
  final Set<String>? wantAreas; // 희망 지역
  final Set<String>? wantRooms; // 희망 방 종류
  final Set<String>? wantPays; // 희망 지불 구조

  final FeedSort sort;

  const FeedFilterState({
    required this.target,
    this.depositMin,
    this.depositMax,
    this.contractMin,
    this.contractMax,
    this.rentMin,
    this.rentMax,
    this.manageMin,
    this.manageMax,
    this.searcherBudgetMin,
    this.searcherBudgetMax,
    this.wantAreas,
    this.wantRooms,
    this.wantPays,
    this.sort = FeedSort.newest,
  });

  /// 전체 활성(과거 호환). 화면에선 isActiveForTarget 사용 권장
  bool get isActive {
    final hasMoney =
        depositMin != null ||
        depositMax != null ||
        rentMin != null ||
        rentMax != null ||
        manageMin != null ||
        manageMax != null ||
        searcherBudgetMin != null ||
        searcherBudgetMax != null;

    final hasContract = contractMin != null || contractMax != null;
    final hasSearcherWants =
        (wantAreas?.isNotEmpty ?? false) ||
        (wantRooms?.isNotEmpty ?? false) ||
        (wantPays?.isNotEmpty ?? false);

    return hasMoney ||
        hasContract ||
        hasSearcherWants ||
        sort != FeedSort.newest;
  }

  /// 현재 보이는 목록의 타겟 기준으로 활성 여부 판단
  bool isActiveForTarget(FeedTarget viewTarget) {
    final hasCommon =
        depositMin != null ||
        depositMax != null ||
        contractMin != null ||
        contractMax != null;

    if (viewTarget == FeedTarget.roomOwner) {
      final hasOwner =
          rentMin != null ||
          rentMax != null ||
          manageMin != null ||
          manageMax != null;
      final hasSort =
          sort != FeedSort.newest; // owner에서 추천정렬은 노출 안 함(그냥 newest/oldest만)
      return hasCommon || hasOwner || hasSort;
    } else {
      final hasBudget = searcherBudgetMin != null || searcherBudgetMax != null;
      final hasWants =
          (wantAreas?.isNotEmpty ?? false) ||
          (wantRooms?.isNotEmpty ?? false) ||
          (wantPays?.isNotEmpty ?? false);
      final hasSort = sort != FeedSort.newest; // recommend 등
      return hasCommon || hasBudget || hasWants || hasSort;
    }
  }

  FeedFilterState copyWith({
    FeedTarget? target,
    int? depositMin,
    int? depositMax,
    int? contractMin,
    int? contractMax,
    int? rentMin,
    int? rentMax,
    int? manageMin,
    int? manageMax,
    int? searcherBudgetMin,
    int? searcherBudgetMax,
    Set<String>? wantAreas,
    Set<String>? wantRooms,
    Set<String>? wantPays,
    FeedSort? sort,

    // one-shot removal flags
    bool removeDeposit = false,
    bool removeContract = false,
    bool removeRent = false,
    bool removeManage = false,
    bool removeSearcherBudget = false,
    bool clearWantAreas = false,
    bool clearWantRooms = false,
    bool clearWantPays = false,
    bool resetSort = false,
  }) {
    return FeedFilterState(
      target: target ?? this.target,

      depositMin: removeDeposit ? null : (depositMin ?? this.depositMin),
      depositMax: removeDeposit ? null : (depositMax ?? this.depositMax),

      contractMin: removeContract ? null : (contractMin ?? this.contractMin),
      contractMax: removeContract ? null : (contractMax ?? this.contractMax),

      rentMin: removeRent ? null : (rentMin ?? this.rentMin),
      rentMax: removeRent ? null : (rentMax ?? this.rentMax),

      manageMin: removeManage ? null : (manageMin ?? this.manageMin),
      manageMax: removeManage ? null : (manageMax ?? this.manageMax),

      searcherBudgetMin: removeSearcherBudget
          ? null
          : (searcherBudgetMin ?? this.searcherBudgetMin),
      searcherBudgetMax: removeSearcherBudget
          ? null
          : (searcherBudgetMax ?? this.searcherBudgetMax),

      wantAreas: clearWantAreas ? null : (wantAreas ?? this.wantAreas),
      wantRooms: clearWantRooms ? null : (wantRooms ?? this.wantRooms),
      wantPays: clearWantPays ? null : (wantPays ?? this.wantPays),

      sort: resetSort ? FeedSort.newest : (sort ?? this.sort),
    );
  }

  static const FeedFilterState initial = FeedFilterState(
    target: FeedTarget.roomOwner,
    sort: FeedSort.newest,
  );
}

/// 싱글턴 컨트롤러
class FeedFilterController extends ChangeNotifier {
  FeedFilterState _state = FeedFilterState.initial;
  static final FeedFilterController instance = FeedFilterController._();
  FeedFilterController._();

  FeedFilterState get state => _state;

  void apply(FeedFilterState next) {
    _state = next;
    notifyListeners();
  }

  void clear(FeedTarget keepTarget) {
    _state = FeedFilterState(target: keepTarget, sort: FeedSort.newest);
    notifyListeners();
  }
}

/// 상단 요약 Chips — 활성 조건이 없으면 렌더링하지 않음
class FeedFilterChips extends StatelessWidget {
  final FeedTarget target; // ← 현재 화면의 타겟
  final FeedFilterState state;
  final VoidCallback onOpenSheet; // 외부 아이콘과 연결해도 됨(칩 자체로 열기 버튼은 없음)
  final VoidCallback onClear;

  const FeedFilterChips({
    super.key,
    required this.target,
    required this.state,
    required this.onOpenSheet,
    required this.onClear,
  });

  String _m(int? v) => v == null ? '-' : '$v만';

  @override
  Widget build(BuildContext context) {
    if (!state.isActiveForTarget(target)) return const SizedBox.shrink();

    final chips = <Widget>[
      // 공통
      if (state.depositMin != null || state.depositMax != null)
        InputChip(
          label: Text('보증금 ${_m(state.depositMin)}~${_m(state.depositMax)}'),
          onDeleted: () => FeedFilterController.instance.apply(
            state.copyWith(removeDeposit: true),
          ),
        ),
      if (state.contractMin != null || state.contractMax != null)
        InputChip(
          label: Text(
            '계약 ${state.contractMin ?? "-"}~${state.contractMax ?? "-"}개월',
          ),
          onDeleted: () => FeedFilterController.instance.apply(
            state.copyWith(removeContract: true),
          ),
        ),

      if (target == FeedTarget.roomOwner) ...[
        if (state.rentMin != null || state.rentMax != null)
          InputChip(
            label: Text('월세 ${_m(state.rentMin)}~${_m(state.rentMax)}'),
            onDeleted: () => FeedFilterController.instance.apply(
              state.copyWith(removeRent: true),
            ),
          ),
        if (state.manageMin != null || state.manageMax != null)
          InputChip(
            label: Text('관리비 ${_m(state.manageMin)}~${_m(state.manageMax)}'),
            onDeleted: () => FeedFilterController.instance.apply(
              state.copyWith(removeManage: true),
            ),
          ),
      ] else ...[
        if (state.searcherBudgetMin != null || state.searcherBudgetMax != null)
          InputChip(
            label: Text(
              '예산 ${_m(state.searcherBudgetMin)}~${_m(state.searcherBudgetMax)}',
            ),
            onDeleted: () => FeedFilterController.instance.apply(
              state.copyWith(removeSearcherBudget: true),
            ),
          ),
        if (state.wantAreas?.isNotEmpty ?? false)
          InputChip(
            label: Text('지역 ${state.wantAreas!.join(", ")}'),
            onDeleted: () => FeedFilterController.instance.apply(
              state.copyWith(clearWantAreas: true),
            ),
          ),
        if (state.wantRooms?.isNotEmpty ?? false)
          InputChip(
            label: Text('방종류 ${state.wantRooms!.join(", ")}'),
            onDeleted: () => FeedFilterController.instance.apply(
              state.copyWith(clearWantRooms: true),
            ),
          ),
        if (state.wantPays?.isNotEmpty ?? false)
          InputChip(
            label: Text('지불 ${state.wantPays!.join(", ")}'),
            onDeleted: () => FeedFilterController.instance.apply(
              state.copyWith(clearWantPays: true),
            ),
          ),
      ],

      if (state.sort != FeedSort.newest)
        InputChip(
          label: Text(_sortLabel(state.sort)),
          onDeleted: () => FeedFilterController.instance.apply(
            state.copyWith(resetSort: true),
          ),
        ),

      ActionChip(
        label: const Text('전체 초기화'),
        onPressed: onClear,
      ),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveSizes.p(context, 12),
        vertical: ResponsiveSizes.p(context, 8),
      ),
      child: Wrap(spacing: 8, runSpacing: 4, children: chips),
    );
  }

  static String _sortLabel(FeedSort s) {
    switch (s) {
      case FeedSort.newest:
        return '최신순';
      case FeedSort.oldest:
        return '오래된 순';
      case FeedSort.recommend:
        return '추천 순';
      case FeedSort.payMatch:
        return '지불 구조 매칭';
      case FeedSort.roomMatch:
        return '방 종류 매칭';
      case FeedSort.distance:
        return '거리순(미사용)';
    }
  }
}

/// 바텀시트(필터 편집 UI) — 현재 뷰의 타겟을 외부에서 받음
class FeedFilterBottomSheet extends StatefulWidget {
  final AppUser? me;
  final FeedTarget target;

  /// Searcher 글에서 제공할 옵션 풀(현재 로드된 글 기준)
  final List<String> areas;
  final List<String> rooms;
  final List<String> pays;

  const FeedFilterBottomSheet({
    super.key,
    required this.me,
    required this.target,
    this.areas = const [],
    this.rooms = const [],
    this.pays = const [],
  });

  static Future<void> show(
    BuildContext context,
    AppUser? me, {
    required FeedTarget target,
    List<String> areas = const [],
    List<String> rooms = const [],
    List<String> pays = const [],
  }) {
    return showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => FeedFilterBottomSheet(
        me: me,
        target: target,
        areas: areas,
        rooms: rooms,
        pays: pays,
      ),
    );
  }

  @override
  State<FeedFilterBottomSheet> createState() => _FeedFilterBottomSheetState();
}

class _FeedFilterBottomSheetState extends State<FeedFilterBottomSheet> {
  late FeedFilterState _tmp;

  // 슬라이더 기본 범위(만 단위)
  static const int _depositMaxCap = 5000;
  static const int _rentMaxCap = 400;
  static const int _manageMaxCap = 80;

  // 계약기간 입력
  final _minCtr = TextEditingController();
  final _maxCtr = TextEditingController();

  // Searcher 희망 멀티 선택(임시 보관)
  late Set<String> _selAreas;
  late Set<String> _selRooms;
  late Set<String> _selPays;

  @override
  void initState() {
    super.initState();
    final current = FeedFilterController.instance.state;
    _tmp = current; // target은 외부(widget.target)로 제어

    _minCtr.text = _tmp.contractMin?.toString() ?? '';
    _maxCtr.text = _tmp.contractMax?.toString() ?? '';

    _selAreas = {...(_tmp.wantAreas ?? const <String>{})};
    _selRooms = {...(_tmp.wantRooms ?? const <String>{})};
    _selPays = {...(_tmp.wantPays ?? const <String>{})};
  }

  @override
  void dispose() {
    _minCtr.dispose();
    _maxCtr.dispose();
    super.dispose();
  }

  int? _toInt(String s) {
    final t = s.trim();
    if (t.isEmpty) return null;
    return int.tryParse(t);
  }

  void _apply() {
    final minC = _toInt(_minCtr.text);
    final maxC = _toInt(_maxCtr.text);

    // target은 바꾸지 않는다(현재 탭이 정의)
    var next = _tmp.copyWith(
      contractMin: minC,
      contractMax: maxC,
    );

    if (widget.target == FeedTarget.searcher) {
      next = next.copyWith(
        wantAreas: _selAreas,
        wantRooms: _selRooms,
        wantPays: _selPays,
      );
    }

    FeedFilterController.instance.apply(next);
    Navigator.pop(context);
  }

  void _clear() {
    FeedFilterController.instance.clear(widget.target);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final p12 = ResponsiveSizes.p(context, 12);
    final fs16 = ResponsiveSizes.f(context, 16);

    final myType = widget.me?.userType?.type ?? '';
    final isOwner = myType == 'roomOwner';
    // final isSearcher = myType.toLowerCase() == 'searcher';

    final sortOptions = <FeedSort, String>{
      FeedSort.newest: '최신순',
      FeedSort.oldest: '오래된 순',
      if (widget.target == FeedTarget.searcher && isOwner)
        FeedSort.recommend: '유저 추천 순',
    };

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          p12,
          p12,
          p12,
          p12 + MediaQuery.of(context).padding.bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 타겟 전환 UI 제거 — 현재 탭이 타겟을 결정
              // 금액: 보증금
              Text(
                '보증금(만 단위)',
                style: TextStyle(fontSize: fs16, fontWeight: FontWeight.w600),
              ),
              _RangeField(
                min: _tmp.depositMin ?? 0,
                max: _tmp.depositMax ?? _depositMaxCap,
                cap: _depositMaxCap,
                onChanged: (a, b) => setState(() {
                  _tmp = _tmp.copyWith(depositMin: a, depositMax: b);
                }),
              ),
              const SizedBox(height: 12),

              // 타겟별 금액 슬라이더
              if (widget.target == FeedTarget.roomOwner) ...[
                Text(
                  '월세(만 단위)',
                  style: TextStyle(fontSize: fs16, fontWeight: FontWeight.w600),
                ),
                _RangeField(
                  min: _tmp.rentMin ?? 0,
                  max: _tmp.rentMax ?? _rentMaxCap,
                  cap: _rentMaxCap,
                  onChanged: (a, b) => setState(() {
                    _tmp = _tmp.copyWith(rentMin: a, rentMax: b);
                  }),
                ),
                const SizedBox(height: 12),
                Text(
                  '관리비(만 단위)',
                  style: TextStyle(fontSize: fs16, fontWeight: FontWeight.w600),
                ),
                _RangeField(
                  min: _tmp.manageMin ?? 0,
                  max: _tmp.manageMax ?? _manageMaxCap,
                  cap: _manageMaxCap,
                  onChanged: (a, b) => setState(() {
                    _tmp = _tmp.copyWith(manageMin: a, manageMax: b);
                  }),
                ),
              ] else ...[
                Text(
                  '희망 월세 예산(만 단위)',
                  style: TextStyle(fontSize: fs16, fontWeight: FontWeight.w600),
                ),
                _RangeField(
                  min: _tmp.searcherBudgetMin ?? 0,
                  max: _tmp.searcherBudgetMax ?? _rentMaxCap,
                  cap: _rentMaxCap,
                  onChanged: (a, b) => setState(() {
                    _tmp = _tmp.copyWith(
                      searcherBudgetMin: a,
                      searcherBudgetMax: b,
                    );
                  }),
                ),
                const SizedBox(height: 12),
              ],

              // 계약기간
              Text(
                '계약 기간(개월)',
                style: TextStyle(fontSize: fs16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _minCtr,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        hintText: '최소',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text('~'),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _maxCtr,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        hintText: '최대',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Searcher 희망 조건 멀티선택(옵션 있을 때만 표시)
              if (widget.target == FeedTarget.searcher) ...[
                if (widget.areas.isNotEmpty) ...[
                  Text(
                    '희망 지역',
                    style: TextStyle(
                      fontSize: fs16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _MultiChips(
                    options: widget.areas,
                    selected: _selAreas,
                    onChanged: (s) => setState(() => _selAreas = s),
                  ),
                  const SizedBox(height: 12),
                ],
                if (widget.rooms.isNotEmpty) ...[
                  Text(
                    '희망 방 종류',
                    style: TextStyle(
                      fontSize: fs16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _MultiChips(
                    options: widget.rooms,
                    selected: _selRooms,
                    onChanged: (s) => setState(() => _selRooms = s),
                  ),
                  const SizedBox(height: 12),
                ],
                if (widget.pays.isNotEmpty) ...[
                  Text(
                    '희망 지불 구조',
                    style: TextStyle(
                      fontSize: fs16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _MultiChips(
                    options: widget.pays,
                    selected: _selPays,
                    onChanged: (s) => setState(() => _selPays = s),
                  ),
                  const SizedBox(height: 12),
                ],
              ],

              // 정렬
              Text(
                '정렬',
                style: TextStyle(fontSize: fs16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              ...sortOptions.entries.map(
                (e) => RadioListTile<FeedSort>(
                  value: e.key,
                  groupValue: _tmp.sort,
                  onChanged: (v) => setState(() {
                    if (v != null) _tmp = _tmp.copyWith(sort: v);
                  }),
                  title: Text(e.value),
                  dense: true,
                ),
              ),

              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _clear,
                      child: const Text('초기화'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _apply,
                      child: const Text('적용'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 슬라이더 + 직접입력 콤보
class _RangeField extends StatefulWidget {
  final int min;
  final int max;
  final int cap;
  final void Function(int min, int max) onChanged;
  const _RangeField({
    required this.min,
    required this.max,
    required this.cap,
    required this.onChanged,
  });

  @override
  State<_RangeField> createState() => _RangeFieldState();
}

class _RangeFieldState extends State<_RangeField> {
  late RangeValues _values;
  late TextEditingController _a;
  late TextEditingController _b;

  @override
  void initState() {
    super.initState();
    _values = RangeValues(widget.min.toDouble(), widget.max.toDouble());
    _a = TextEditingController(text: widget.min.toString());
    _b = TextEditingController(text: widget.max.toString());
  }

  @override
  void dispose() {
    _a.dispose();
    _b.dispose();
    super.dispose();
  }

  void _emit() {
    final mi = int.tryParse(_a.text) ?? _values.start.round();
    final mx = int.tryParse(_b.text) ?? _values.end.round();
    final clampedMin = mi.clamp(0, widget.cap);
    final clampedMax = mx.clamp(0, widget.cap);
    final a = math.min(clampedMin, clampedMax);
    final b = math.max(clampedMin, clampedMax);
    widget.onChanged(a, b);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        RangeSlider(
          min: 0,
          max: widget.cap.toDouble(),
          divisions: widget.cap,
          values: _values,
          labels: RangeLabels(
            '${_values.start.round()}만',
            '${_values.end.round()}만',
          ),
          onChanged: (v) => setState(() {
            _values = v;
            _a.text = v.start.round().toString();
            _b.text = v.end.round().toString();
            _emit();
          }),
        ),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _a,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  isDense: true,
                  border: OutlineInputBorder(),
                  suffixText: '만',
                ),
                onChanged: (_) => _emit(),
              ),
            ),
            const SizedBox(width: 8),
            const Text('~'),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _b,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  isDense: true,
                  border: OutlineInputBorder(),
                  suffixText: '만',
                ),
                onChanged: (_) => _emit(),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// 멀티 선택 칩
class _MultiChips extends StatelessWidget {
  final List<String> options;
  final Set<String> selected;
  final ValueChanged<Set<String>> onChanged;

  const _MultiChips({
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final chips = <Widget>[
      for (final opt in options)
        FilterChip(
          label: Text(opt),
          selected: selected.contains(opt),
          onSelected: (v) {
            final next = {...selected};
            if (v) {
              next.add(opt);
            } else {
              next.remove(opt);
            }
            onChanged(next);
          },
        ),
      if (selected.isNotEmpty)
        ActionChip(
          label: const Text('선택 초기화'),
          onPressed: () => onChanged(<String>{}),
        ),
    ];

    return Wrap(spacing: 8, runSpacing: 8, children: chips);
  }
}
