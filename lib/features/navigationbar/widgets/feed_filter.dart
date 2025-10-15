import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:roommate/constants/responsive_sizes.dart';
import 'package:roommate/class/app_user.dart';

/// 필터 스테이트 (모든 금액은 '만' 단위)
class FeedFilterState {
  // 집 필터
  final int? depositMin;
  final int? depositMax;
  final int? contractMin; // 개월
  final int? contractMax; // 개월
  final int? rentMin;
  final int? rentMax;
  final int? manageMin;
  final int? manageMax;

  // 사람 필터
  Coliving? colivingFilter;

  FeedFilterState({
    this.depositMin,
    this.depositMax,
    this.contractMin,
    this.contractMax,
    this.rentMin,
    this.rentMax,
    this.manageMin,
    this.manageMax,
    this.colivingFilter,
  });

  bool get isHouseFilterActive {
    return depositMin != null ||
        depositMax != null ||
        contractMin != null ||
        contractMax != null ||
        rentMin != null ||
        rentMax != null ||
        manageMin != null ||
        manageMax != null;
  }

  bool get isPersonFilterActive {
    if (colivingFilter == null) return false;
    return colivingFilter!.coSpace.isNotEmpty ||
        colivingFilter!.interaction.isNotEmpty ||
        colivingFilter!.bathroom.isNotEmpty ||
        colivingFilter!.cleanOption.isNotEmpty ||
        colivingFilter!.smoking == true ||
        colivingFilter!.pet.isNotEmpty;
  }

  bool get isActive => isHouseFilterActive || isPersonFilterActive;

  FeedFilterState copyWith({
    int? depositMin,
    int? depositMax,
    int? contractMin,
    int? contractMax,
    int? rentMin,
    int? rentMax,
    int? manageMin,
    int? manageMax,
    Coliving? colivingFilter,
    bool removeDeposit = false,
    bool removeContract = false,
    bool removeRent = false,
    bool removeManage = false,
    bool clearColiving = false,
  }) {
    return FeedFilterState(
      depositMin: removeDeposit ? null : (depositMin ?? this.depositMin),
      depositMax: removeDeposit ? null : (depositMax ?? this.depositMax),
      contractMin: removeContract ? null : (contractMin ?? this.contractMin),
      contractMax: removeContract ? null : (contractMax ?? this.contractMax),
      rentMin: removeRent ? null : (rentMin ?? this.rentMin),
      rentMax: removeRent ? null : (rentMax ?? this.rentMax),
      manageMin: removeManage ? null : (manageMin ?? this.manageMin),
      manageMax: removeManage ? null : (manageMax ?? this.manageMax),
      colivingFilter: clearColiving
          ? null
          : (colivingFilter ?? this.colivingFilter),
    );
  }

  static FeedFilterState initial = FeedFilterState();
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

  void clear() {
    _state = FeedFilterState();
    notifyListeners();
  }
}

/// 상단 요약 Chips — 활성 조건이 없으면 렌더링하지 않음
class FeedFilterChips extends StatelessWidget {
  final FeedFilterState state;
  final VoidCallback onOpenSheet;
  final VoidCallback onClear;

  FeedFilterChips({
    super.key,
    required this.state,
    required this.onOpenSheet,
    required this.onClear,
  });

  String _m(int? v) => v == null ? '-' : '$v만';

  @override
  Widget build(BuildContext context) {
    if (!state.isActive) return const SizedBox.shrink();

    final chips = <Widget>[
      // 집 필터
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

      // 사람 필터
      if (state.colivingFilter?.coSpace.isNotEmpty ?? false)
        InputChip(
          label: Text('공용공간: ${state.colivingFilter!.coSpace}'),
          onDeleted: () => FeedFilterController.instance.apply(
            state.copyWith(
              colivingFilter: state.colivingFilter!.copyWith(coSpace: ""),
            ),
          ),
        ),
      if (state.colivingFilter?.interaction.isNotEmpty ?? false)
        InputChip(
          label: Text('교류: ${state.colivingFilter!.interaction}'),
          onDeleted: () => FeedFilterController.instance.apply(
            state.copyWith(
              colivingFilter: state.colivingFilter!.copyWith(interaction: ""),
            ),
          ),
        ),
      if (state.colivingFilter?.cleanOption.isNotEmpty ?? false)
        InputChip(
          label: Text('정리정돈: ${state.colivingFilter!.cleanOption}'),
          onDeleted: () => FeedFilterController.instance.apply(
            state.copyWith(
              colivingFilter: state.colivingFilter!.copyWith(cleanOption: ""),
            ),
          ),
        ),
      if (state.colivingFilter?.bathroom.isNotEmpty ?? false)
        InputChip(
          label: Text('화장실: ${state.colivingFilter!.bathroom}'),
          onDeleted: () => FeedFilterController.instance.apply(
            state.copyWith(
              colivingFilter: state.colivingFilter!.copyWith(bathroom: ""),
            ),
          ),
        ),
      if (state.colivingFilter?.smoking == true)
        InputChip(
          label: const Text('흡연'),
          onDeleted: () => FeedFilterController.instance.apply(
            state.copyWith(
              colivingFilter: state.colivingFilter!.copyWith(smoking: false),
            ),
          ),
        ),
      if (state.colivingFilter?.pet.isNotEmpty ?? false)
        InputChip(
          label: Text('반려동물: ${state.colivingFilter!.pet.join(", ")}'),
          onDeleted: () => FeedFilterController.instance.apply(
            state.copyWith(
              colivingFilter: state.colivingFilter!.copyWith(pet: []),
            ),
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
}

/// 바텀시트(필터 편집 UI)
class FeedFilterBottomSheet extends StatefulWidget {
  const FeedFilterBottomSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => const FeedFilterBottomSheet(),
    );
  }

  @override
  State<FeedFilterBottomSheet> createState() => _FeedFilterBottomSheetState();
}

class _FeedFilterBottomSheetState extends State<FeedFilterBottomSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late FeedFilterState _tmp;

  // 슬라이더 기본 범위(만 단위)
  static const int _depositMaxCap = 5000;
  static const int _rentMaxCap = 400;
  static const int _manageMaxCap = 80;

  // 계약기간 입력
  final _minCtr = TextEditingController();
  final _maxCtr = TextEditingController();

  // 공동생활 성향 옵션 (coliving_screen.dart 기반)
  final _coSpaceOptions = ['활발', '중간', '거의 사용 안 함'];
  final _interactionOptions = ['친하게', '적당히 거리두며', '거의 없이'];
  final _cleanOptions = ['항상 제자리에 둬요', '대체로 정돈된 편이예요', '어지르는 편이예요'];
  final _bathroomOptions = ['둔감해요', '보통이에요', '예민해요'];
  final _petOptions = [
    '없음',
    '강아지',
    '고양이',
    '물고기',
    '양서류',
    '파충류',
    '무척추동물(기타)',
    '조류',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    final current = FeedFilterController.instance.state;
    _tmp = current;

    _minCtr.text = _tmp.contractMin?.toString() ?? '';
    _maxCtr.text = _tmp.contractMax?.toString() ?? '';
  }

  @override
  void dispose() {
    _tabController.dispose();
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

    var next = _tmp.copyWith(
      contractMin: minC,
      contractMax: maxC,
    );

    FeedFilterController.instance.apply(next);
    Navigator.pop(context);
  }

  void _clear() {
    FeedFilterController.instance.clear();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final p12 = ResponsiveSizes.p(context, 12);
    final fs16 = ResponsiveSizes.f(context, 16);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          p12,
          p12,
          p12,
          p12 + MediaQuery.of(context).padding.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: '집'),
                Tab(text: '사람'),
              ],
            ),
            Flexible(
              child: SingleChildScrollView(
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.6,
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildHouseFilter(fs16),
                      _buildPersonFilter(fs16),
                    ],
                  ),
                ),
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
    );
  }

  Widget _buildHouseFilter(double fs16) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
          const SizedBox(height: 12),
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
        ],
      ),
    );
  }

  Widget _buildPersonFilter(double fs16) {
    _tmp.colivingFilter ??= const Coliving(
      coSpace: '',
      interaction: '',
      bathroom: '',
      cleanOption: '',
      smoking: false,
      pet: [],
      mbti: '',
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '공용 공간 사용 선호도',
            style: TextStyle(fontSize: fs16, fontWeight: FontWeight.w600),
          ),
          _SingleChoiceChips(
            options: _coSpaceOptions,
            selected: _tmp.colivingFilter!.coSpace,
            onChanged: (s) => setState(() {
              _tmp = _tmp.copyWith(
                colivingFilter: _tmp.colivingFilter!.copyWith(coSpace: s),
              );
            }),
          ),
          const SizedBox(height: 12),
          Text(
            '룸메이트와의 선호 교류 타입',
            style: TextStyle(fontSize: fs16, fontWeight: FontWeight.w600),
          ),
          _SingleChoiceChips(
            options: _interactionOptions,
            selected: _tmp.colivingFilter!.interaction,
            onChanged: (s) => setState(() {
              _tmp = _tmp.copyWith(
                colivingFilter: _tmp.colivingFilter!.copyWith(interaction: s),
              );
            }),
          ),
          const SizedBox(height: 12),
          Text(
            '정리정돈 성향',
            style: TextStyle(fontSize: fs16, fontWeight: FontWeight.w600),
          ),
          _SingleChoiceChips(
            options: _cleanOptions,
            selected: _tmp.colivingFilter!.cleanOption,
            onChanged: (s) => setState(() {
              _tmp = _tmp.copyWith(
                colivingFilter: _tmp.colivingFilter!.copyWith(cleanOption: s),
              );
            }),
          ),
          const SizedBox(height: 12),
          Text(
            '화장실 청결 민감도',
            style: TextStyle(fontSize: fs16, fontWeight: FontWeight.w600),
          ),
          _SingleChoiceChips(
            options: _bathroomOptions,
            selected: _tmp.colivingFilter!.bathroom,
            onChanged: (s) => setState(() {
              _tmp = _tmp.copyWith(
                colivingFilter: _tmp.colivingFilter!.copyWith(bathroom: s),
              );
            }),
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            title: Text(
              '흡연 여부',
              style: TextStyle(fontSize: fs16, fontWeight: FontWeight.w600),
            ),
            value: _tmp.colivingFilter!.smoking,
            onChanged: (v) => setState(() {
              _tmp = _tmp.copyWith(
                colivingFilter: _tmp.colivingFilter!.copyWith(smoking: v),
              );
            }),
          ),
          const SizedBox(height: 12),
          Text(
            '반려동물 여부',
            style: TextStyle(fontSize: fs16, fontWeight: FontWeight.w600),
          ),
          _MultiChips(
            options: _petOptions,
            selected: _tmp.colivingFilter!.pet.toSet(),
            onChanged: (s) => setState(() {
              _tmp = _tmp.copyWith(
                colivingFilter: _tmp.colivingFilter!.copyWith(pet: s.toList()),
              );
            }),
          ),
        ],
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

/// 단일 선택 칩
class _SingleChoiceChips extends StatelessWidget {
  final List<String> options;
  final String selected;
  final ValueChanged<String> onChanged;

  const _SingleChoiceChips({
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options
          .map(
            (opt) => ChoiceChip(
              label: Text(opt),
              selected: selected == opt,
              onSelected: (v) {
                if (v) onChanged(opt);
              },
            ),
          )
          .toList(),
    );
  }
}

extension ColivingCopyWith on Coliving {
  Coliving copyWith({
    String? coSpace,
    String? interaction,
    String? bathroom,
    String? cleanOption,
    bool? smoking,
    List<String>? pet,
    String? mbti,
  }) {
    return Coliving(
      coSpace: coSpace ?? this.coSpace,
      interaction: interaction ?? this.interaction,
      bathroom: bathroom ?? this.bathroom,
      cleanOption: cleanOption ?? this.cleanOption,
      smoking: smoking ?? this.smoking,
      pet: pet ?? this.pet,
      mbti: mbti ?? this.mbti,
    );
  }
}
