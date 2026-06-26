import 'package:flutter/material.dart';

import '../api/endpoints.dart';
import '../api/models.dart';
import '../design/tokens.dart';
import '../widgets/stock_tile.dart';

class _Cond {
  final String id;
  final String label;
  final String group;
  final bool live;
  final bool hasParams;
  bool selected;

  _Cond(
    this.id,
    this.label,
    this.group, {
    this.live = false,
    this.hasParams = false,
    this.selected = false,
  });
}

final _raw = <_Cond>[
  _Cond('consecutive_bull', '연속 양봉', '가격 패턴', hasParams: true),
  _Cond('consecutive_up', '연속 상승', '가격 패턴', hasParams: true),
  _Cond('higher_high_low', '고가/저가 동시 상승', '가격 패턴', hasParams: true),
  _Cond('break_prev_high', '전일 고가 돌파', '가격 패턴'),
  _Cond('new_high_5d', '5일 신고가 갱신', '가격 패턴'),
  _Cond('price_surge', '급등주', '가격 패턴', hasParams: true),
  _Cond('near_high', '신고가 근접', '가격 패턴', live: true),
  _Cond('upper_limit', '상한가 포착', '가격 패턴', live: true),
  _Cond('golden_cross', '골든크로스', '이동평균·추세', hasParams: true),
  _Cond('ma_alignment', '이동평균 정배열', '이동평균·추세'),
  _Cond('mao_up', 'MAO 상승돌파', '이동평균·추세'),
  _Cond('mao_signal_up', 'MAO Signal 돌파', '이동평균·추세'),
  _Cond('volume_golden_cross', '거래량 골든크로스', '이동평균·추세'),
  _Cond('macd_signal_cross', 'MACD Cross', '모멘텀·오실레이터'),
  _Cond('macd_osc_up', 'MACD Osc', '모멘텀·오실레이터'),
  _Cond('price_osc_up', 'Price Osc', '모멘텀·오실레이터'),
  _Cond('momentum_up', 'Momentum', '모멘텀·오실레이터', hasParams: true),
  _Cond('roc_up', 'ROC', '모멘텀·오실레이터', hasParams: true),
  _Cond('lrs_signal_up', 'LRS', '모멘텀·오실레이터'),
  _Cond('tsf_signal_up', 'TSF', '모멘텀·오실레이터'),
  _Cond('sonar_signal_up', 'Sonar', '모멘텀·오실레이터'),
  _Cond('volume_osc_up', 'Volume Osc', '모멘텀·오실레이터'),
  _Cond('volume_surge', '거래량 급등', '거래량·수급', hasParams: true, selected: true),
  _Cond('volume_power', '체결강도 상위', '거래량·수급', live: true),
  _Cond('obv_up', 'OBV 상승추세', '거래량·수급', hasParams: true),
  _Cond('obv_uturn', 'OBV U턴', '거래량·수급'),
  _Cond('frgn_buy', '외국인 연속 순매수', '거래량·수급', hasParams: true),
  _Cond('orgn_buy', '기관 연속 순매수', '거래량·수급', hasParams: true),
];

const _presets = [
  ('거래량 폭발', ['volume_surge', 'consecutive_bull', 'break_prev_high']),
  ('골든크로스', ['golden_cross', 'volume_surge']),
  ('눌림목 반등', ['ma_alignment', 'macd_signal_cross']),
  ('수급 주도', ['frgn_buy', 'orgn_buy', 'consecutive_up']),
];

class ScreenerTab extends StatefulWidget {
  final void Function(String code, String name) onSelect;
  const ScreenerTab({super.key, required this.onSelect});

  @override
  State<ScreenerTab> createState() => _ScreenerTabState();
}

class _ScreenerTabState extends State<ScreenerTab> {
  late final List<_Cond> _conds = _raw
      .map((c) => _Cond(c.id, c.label, c.group,
          live: c.live, hasParams: c.hasParams, selected: c.selected))
      .toList();
  List<ScreenerResult> _results = [];
  bool _loading = false;
  bool _searched = false;
  int _sortIndex = 0;
  final _scrollController = ScrollController();
  final _resultKey = GlobalKey();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  List<String> get _selected =>
      _conds.where((c) => c.selected).map((c) => c.id).toList();

  void _applyPreset(List<String> ids) {
    setState(() {
      for (final c in _conds) {
        c.selected = ids.contains(c.id);
      }
    });
  }

  Future<void> _search() async {
    final ids = _selected;
    if (ids.isEmpty) return;
    setState(() => _loading = true);
    try {
      final res = await fetchScreener(ids, {});
      if (!mounted) return;
      setState(() {
        _results = res;
        _loading = false;
        _searched = true;
      });
      // 결과 영역으로 스무스 스크롤 (업종별 추천과 동일 패턴)
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final ctx = _resultKey.currentContext;
        if (ctx != null) {
          Scrollable.ensureVisible(
            ctx,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
          );
        }
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<ScreenerResult> get _sortedResults {
    final sorted = List<ScreenerResult>.from(_results);
    if (_sortIndex == 0) {
      sorted.sort((a, b) => b.volume.compareTo(a.volume));
    } else {
      sorted.sort((a, b) => (b.close * b.volume).compareTo(a.close * a.volume));
    }
    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final groups = <String, List<_Cond>>{};
    for (final c in _conds) {
      groups.putIfAbsent(c.group, () => []).add(c);
    }
    final selCount = _selected.length;

    return Container(
      color: palette.cardBg,
      child: ListView(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(kHeaderPaddingH, 16, kHeaderPaddingH, 28),
        children: [
          Text('DB 업데이트: —',
              style: TextStyle(fontSize: 12, color: palette.mutedStrong)),
          const SizedBox(height: 16),
          Text('빠른 선택',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: palette.mutedStrong)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _presets.map((p) {
              final ids = p.$2;
              final isActive = _selected.length == ids.length &&
                  ids.every((id) => _selected.contains(id));
              return _Pill(
                label: p.$1,
                active: isActive,
                onTap: () => _applyPreset(ids),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          ...groups.entries.map((entry) {
            final selectedInGroup = entry.value.where((c) => c.selected).length;
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(entry.key,
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: palette.ink)),
                      if (selectedInGroup > 0) ...[
                        const SizedBox(width: 5),
                        Text('$selectedInGroup',
                            style: TextStyle(
                                fontSize: 12,
                                color: palette.primary,
                                fontWeight: FontWeight.w800)),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: entry.value
                        .map((c) => _ConditionChip(
                              cond: c,
                              onTap: () => setState(() => c.selected = !c.selected),
                            ))
                        .toList(),
                  ),
                ],
              ),
            );
          }),
          Row(
            children: [
              SizedBox(
                height: 36,
                child: FilledButton(
                  onPressed: selCount > 0 && !_loading ? _search : null,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    backgroundColor: palette.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(selCount > 0 ? '검색 ($selCount개 조건)' : '조건을 선택하세요'),
                ),
              ),
              const SizedBox(width: 10),
              if (_searched)
                Text('${_results.length}개 종목',
                    style: TextStyle(fontSize: 12, color: palette.mutedStrong)),
            ],
          ),
          if (_searched) ...[
            SizedBox(key: _resultKey, height: 18),
            Container(height: 1, color: palette.border),
            const SizedBox(height: 12),
            if (_results.isNotEmpty)
              Row(
                children: [
                  _SortButton(label: '거래량', active: _sortIndex == 0, onTap: () => setState(() => _sortIndex = 0)),
                  const SizedBox(width: 8),
                  _SortButton(label: '거래대금', active: _sortIndex == 1, onTap: () => setState(() => _sortIndex = 1)),
                ],
              ),
            const SizedBox(height: 8),
            if (_results.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 28),
                child: Center(
                  child: Text('조건에 맞는 종목이 없습니다',
                      style: TextStyle(fontSize: 13, color: palette.muted)),
                ),
              )
            else
              ..._sortedResults.map((r) => Column(
                    children: [
                      StockTile.fromScreenerResult(
                        r,
                        onTap: () => widget.onSelect(r.stockCode, r.stockName),
                      ),
                      Container(height: 1, color: palette.border),
                    ],
                  )),
          ],
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _Pill({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: active ? palette.primary.withAlpha(22) : palette.bgSubtle,
          borderRadius: BorderRadius.circular(9999),
          border: Border.all(color: active ? palette.primary : palette.hairline),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: active ? palette.primary : palette.mutedStrong,
          ),
        ),
      ),
    );
  }
}

class _ConditionChip extends StatelessWidget {
  final _Cond cond;
  final VoidCallback onTap;
  const _ConditionChip({required this.cond, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final active = cond.selected;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: active ? palette.primary.withAlpha(22) : Colors.transparent,
          borderRadius: BorderRadius.circular(9999),
          border: Border.all(color: active ? palette.primary : palette.hairline),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              cond.label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: active ? palette.primary : palette.mutedStrong,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.info_outline_rounded,
                size: 12, color: active ? palette.primary : palette.muted),
            if (cond.hasParams) ...[
              const SizedBox(width: 3),
              Icon(Icons.tune_rounded,
                  size: 12, color: active ? palette.primary : palette.muted),
            ],
            if (cond.live) ...[
              const SizedBox(width: 5),
              Text('LIVE',
                  style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      color: palette.tradingUp)),
            ],
          ],
        ),
      ),
    );
  }
}

class _SortButton extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _SortButton({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: active ? palette.primary : palette.mutedStrong,
        ),
      ),
    );
  }
}
