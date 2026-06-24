import 'dart:async';
import 'package:flutter/material.dart';
import '../api/endpoints.dart';
import '../api/models.dart';
import '../design/tokens.dart';
import '../widgets/stock_tile.dart';
import '../widgets/section_header.dart';

const _tabs = [
  ('volume', '거래량'),
  ('amount', '거래대금'),
  ('gainer', '급등주'),
  ('foreign', '외국인'),
  ('institution', '기관'),
];

bool _isRealtime(String tab) =>
    tab == 'volume' || tab == 'amount' || tab == 'gainer';

class RankingTab extends StatefulWidget {
  final void Function(String code, String name) onSelect;
  const RankingTab({super.key, required this.onSelect});

  @override
  State<RankingTab> createState() => _RankingTabState();
}

class _RankingTabState extends State<RankingTab> {
  int _tabIndex = 0;
  List<RankItem> _items = [];
  bool _loading = false;
  bool _refreshing = false;
  DateTime? _lastUpdated;
  Timer? _timer;

  String get _activeTab => _tabs[_tabIndex].$1;

  @override
  void initState() {
    super.initState();
    _load(_tabIndex);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _load(int tabIndex, {bool refresh = false}) async {
    _timer?.cancel();
    final tab = _tabs[tabIndex].$1;
    if (!refresh) {
      setState(() { _loading = true; });
    } else {
      setState(() { _refreshing = true; });
    }
    try {
      List<RankItem> data;
      if (tab == 'volume' || tab == 'amount') {
        data = await fetchVolumeRanking(tab);
      } else if (tab == 'gainer') {
        data = await fetchFluctuationRanking();
      } else {
        data = await fetchForeignRanking(tab);
      }
      if (!mounted) return;
      setState(() {
        _items = data;
        _loading = false;
        _refreshing = false;
        _lastUpdated = DateTime.now();
      });
      if (_isRealtime(tab)) {
        _timer = Timer.periodic(const Duration(seconds: 15),
            (_) => _load(_tabIndex, refresh: true));
      }
    } catch (_) {
      if (mounted) setState(() { _loading = false; _refreshing = false; });
    }
  }

  void _switchTab(int i) {
    setState(() { _tabIndex = i; _items = []; _lastUpdated = null; });
    _load(i);
  }

  String _extraValue(RankItem item) {
    final tab = _activeTab;
    if (tab == 'volume' || tab == 'gainer') {
      return '${item.volume.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}주';
    }
    if (tab == 'amount') {
      final n = item.tradeValue;
      if (n >= 1e12) return '${(n / 1e12).toStringAsFixed(1)}조';
      if (n >= 1e8)  return '${(n / 1e8).toStringAsFixed(0)}억';
      return '${(n / 1e4).toStringAsFixed(0)}만';
    }
    return '${item.extraValue.toStringAsFixed(0)}주';
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Container(
      color: palette.cardBg,
      child: Column(
        children: [
          SectionHeader(
            tabs: _tabs.map((t) => Text(t.$2)).toList(),
            selectedIndex: _tabIndex,
            onTabSelected: _switchTab,
            trailing: _isRealtime(_activeTab)
                ? RefreshBadge(refreshing: _refreshing, lastUpdated: _lastUpdated)
                : null,
          ),
          StockListHeader(hasRank: true, changeLabel: '등락률', extraLabel: null),
          Expanded(
            child: _loading
                ? ListView.separated(
                    itemCount: 10,
                    separatorBuilder: (context, index) => Container(height: 1, color: palette.border),
                    itemBuilder: (context, index) => const StockTileSkeleton(hasRank: true),
                  )
                : ListView.separated(
                    itemCount: _items.isEmpty ? 1 : _items.length,
                    separatorBuilder: (context, index) => Container(height: 1, color: palette.border),
                    itemBuilder: (_, i) {
                      if (_items.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 56),
                          child: Column(
                            children: [
                              Text('데이터가 없습니다',
                                  style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: palette.ink)),
                              const SizedBox(height: 6),
                              Text('장 마감 후에는 데이터가 제공되지 않을 수 있습니다.',
                                  style: TextStyle(fontSize: 13, color: palette.mutedStrong)),
                            ],
                          ),
                        );
                      }
                      final item = _items[i];
                      return StockTile.fromRankItem(
                        item,
                        extraValue: _extraValue(item),
                        onTap: () => widget.onSelect(item.stockCode, item.stockName),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
