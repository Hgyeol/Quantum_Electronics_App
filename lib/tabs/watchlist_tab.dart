import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/endpoints.dart';
import '../api/models.dart';
import '../api/realtime.dart';
import '../providers/watchlist_provider.dart';
import '../design/tokens.dart';
import '../widgets/stock_tile.dart';
import '../widgets/stock_logo.dart';
import '../widgets/section_header.dart';

const _sortTabs = ['기본', '거래량', '거래대금', '외국인', '기관'];
const _quickPicks = [
  ('005930', '삼성전자'),
  ('000660', 'SK하이닉스'),
  ('373220', 'LG에너지솔루션'),
  ('035420', 'NAVER'),
  ('035720', '카카오'),
];

int _kstMinutes() {
  final now = DateTime.now().toUtc();
  return (now.hour * 60 + now.minute + 9 * 60) % (24 * 60);
}

bool _isSortAvailable(int sortIndex) {
  if (sortIndex == 3) return _kstMinutes() >= 9 * 60 + 30;
  if (sortIndex == 4) return _kstMinutes() >= 10 * 60;
  return true;
}

const _sortNotYet = [
  null,
  null,
  null,
  '외국인 순매수는 오전 9:30부터 집계됩니다.',
  '기관 순매수는 오전 10:00부터 집계됩니다.',
];

class WatchlistTab extends ConsumerStatefulWidget {
  final void Function(String code, String name) onSelect;
  const WatchlistTab({super.key, required this.onSelect});

  @override
  ConsumerState<WatchlistTab> createState() => _WatchlistTabState();
}

class _WatchlistTabState extends ConsumerState<WatchlistTab> {
  int _sortIndex = 0;
  Map<String, double> _extraMap = {};
  WatchlistTickerChannel? _channel;
  StreamSubscription<WatchlistRealtimeEvent>? _subscription;
  String _codesKey = '';
  bool _wsConnected = false;
  bool _wsDisconnected = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _channel?.dispose();
    super.dispose();
  }

  void _ensureRealtime(List<String> codes) {
    final nextKey = codes.join(',');
    if (_codesKey == nextKey) return;
    _codesKey = nextKey;
    _subscription?.cancel();
    _subscription = null;
    _channel?.dispose();
    _channel = null;
    if (codes.isEmpty) {
      if (_wsConnected || _wsDisconnected) {
        setState(() {
          _wsConnected = false;
          _wsDisconnected = false;
        });
      }
      return;
    }

    final channel = WatchlistTickerChannel(codes: codes);
    _channel = channel;
    _subscription = channel.stream.listen((event) {
      if (!mounted) return;
      switch (event) {
        case WatchlistConnected():
          setState(() {
            _wsConnected = true;
            _wsDisconnected = false;
          });
        case WatchlistDisconnected(:final canReconnect):
          setState(() {
            _wsConnected = false;
            _wsDisconnected = canReconnect;
          });
        case WatchlistTickEvent(:final tick):
          ref.read(watchlistProvider.notifier).applyTick(tick);
        case WatchlistSnapshotEvent(:final items):
          ref.read(watchlistProvider.notifier).replaceItems(items);
      }
    });
    channel.start();
  }

  Future<void> _reconnectRealtime() async {
    setState(() => _wsDisconnected = false);
    await _channel?.reconnect();
  }

  Future<void> _loadExtraSort(int sortIndex) async {
    if (sortIndex < 3) { setState(() => _extraMap = {}); return; }
    if (!_isSortAvailable(sortIndex)) { setState(() => _extraMap = {}); return; }
    try {
      final investor = sortIndex == 3 ? 'foreign' : 'institution';
      final ranking = await fetchForeignRanking(investor, limit: 200);
      final map = <String, double>{};
      for (final r in ranking) {
        map[r.stockCode] = r.extraValue;
      }
      if (mounted) setState(() => _extraMap = map);
    } catch (_) {
      // ignore
    }
  }

  List<WatchlistItem> _sortedItems(List<WatchlistItem> items) {
    final sorted = List<WatchlistItem>.from(items);
    switch (_sortIndex) {
      case 1: // 거래량
        sorted.sort((a, b) => (b.volume ?? 0).compareTo(a.volume ?? 0));
        break;
      case 2: // 거래대금
        sorted.sort((a, b) => (b.tradeValue ?? 0).compareTo(a.tradeValue ?? 0));
        break;
      case 3: // 외국인
      case 4: // 기관
        sorted.sort((a, b) =>
            (_extraMap[b.stockCode] ?? 0).compareTo(_extraMap[a.stockCode] ?? 0));
        break;
    }
    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final state = ref.watch(watchlistProvider);
    final notifier = ref.read(watchlistProvider.notifier);
    final codes = notifier.codes;
    final hasItems = codes.isNotEmpty;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _ensureRealtime(codes);
    });

    return Container(
      color: palette.cardBg,
      child: Column(
        children: [
          // 헤더
          Container(
            color: palette.cardBg,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                      kHeaderPaddingH, 14, kHeaderPaddingH, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Text('빠른 조회',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: palette.mutedStrong)),
                        const Spacer(),
                        state.when(
                          data: (_) => _WatchlistStatus(
                            count: codes.length,
                            connected: _wsConnected,
                            disconnected: _wsDisconnected,
                            onReconnect: _reconnectRealtime,
                          ),
                          loading: () => const SizedBox.shrink(),
                          error: (error, stackTrace) => const SizedBox.shrink(),
                        ),
                      ]),
                      const SizedBox(height: 8),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: _quickPicks.map((pick) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: _QuickPickChip(
                                code: pick.$1,
                                name: pick.$2,
                                onTap: () => widget.onSelect(pick.$1, pick.$2),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
                if (hasItems)
                  SectionHeader(
                    tabs: _sortTabs.map((t) => Text(t)).toList(),
                    selectedIndex: _sortIndex,
                    onTabSelected: (i) {
                      setState(() => _sortIndex = i);
                      _loadExtraSort(i);
                    },
                  )
                else
                  Container(height: 1, color: palette.border),
              ],
            ),
          ),

          // 집계 시간 안내
          if (hasItems &&
              _sortIndex >= 3 &&
              !_isSortAvailable(_sortIndex))
            Container(
              width: double.infinity,
              color: palette.bgSubtle,
              padding: const EdgeInsets.symmetric(
                  horizontal: kHeaderPaddingH, vertical: 10),
              child: Text(
                _sortNotYet[_sortIndex]!,
                style: TextStyle(fontSize: 12, color: palette.muted),
              ),
            ),

          // 목록
          Expanded(
            child: state.when(
              loading: () => ListView.separated(
                itemCount: 5,
                separatorBuilder: (context, index) =>
                    Container(height: 1, color: palette.border),
                itemBuilder: (context, index) => const StockTileSkeleton(),
              ),
              error: (e, _) =>
                  Center(child: Text('$e', style: TextStyle(color: palette.muted))),
              data: (items) {
                if (items.isEmpty && notifier.codes.isEmpty) {
                  return const _EmptyWatchlist();
                }
                final sorted = _sortedItems(items);
                return ListView.separated(
                  itemCount: sorted.length,
                  separatorBuilder: (context, index) =>
                      Container(height: 1, color: palette.border),
                  itemBuilder: (_, i) {
                    final item = sorted[i];
                    return _WatchlistTile(
                      item: item,
                      onTap: () => widget.onSelect(
                          item.stockCode, item.stockName ?? item.stockCode),
                      onRemove: () async {
                        await notifier.remove(item.stockCode);
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── 관심종목 행 (삭제 버튼 포함) ──────────────────────────────────────────────

class _WatchlistTile extends StatelessWidget {
  final WatchlistItem item;
  final VoidCallback onTap;
  final VoidCallback onRemove;
  const _WatchlistTile({
    required this.item,
    required this.onTap,
    required this.onRemove,
  });

  String _fmtPrice(double p) => p
      .toStringAsFixed(0)
      .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final rate = item.changeRate;
    final Color rateColor;
    final Color rateBg;
    if (rate != null && rate > 0) {
      rateColor = palette.tradingUp;
      rateBg = palette.tradingUp.withAlpha(26);
    } else if (rate != null && rate < 0) {
      rateColor = palette.tradingDown;
      rateBg = palette.tradingDown.withAlpha(26);
    } else {
      rateColor = palette.muted;
      rateBg = palette.bgMuted;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: palette.hover,
        highlightColor: palette.hover,
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: kRowPaddingH, vertical: kRowPaddingV),
          child: Row(
            children: [
              StockLogo(
                  code: item.stockCode, name: item.stockName, size: 40),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.stockName ?? item.stockCode,
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: palette.ink),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 1),
                    Text(item.stockCode,
                        style: monoStyle(
                            size: 12,
                            color: palette.muted,
                            weight: FontWeight.w400)),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  RichText(
                    text: TextSpan(children: [
                      TextSpan(
                        text: item.price != null
                            ? _fmtPrice(item.price!)
                            : '—',
                        style: monoStyle(size: 15, color: palette.ink),
                      ),
                      if (item.price != null)
                        TextSpan(
                          text: '원',
                          style: TextStyle(
                              fontSize: 11,
                              color: palette.muted,
                              fontWeight: FontWeight.w400),
                        ),
                    ]),
                  ),
                  const SizedBox(height: 3),
                  if (rate != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                          color: rateBg,
                          borderRadius: BorderRadius.circular(9999)),
                      child: Text(
                        '${rate > 0 ? '+' : ''}${rate.toStringAsFixed(2)}%',
                        style: monoStyle(
                            size: 13,
                            color: rateColor,
                            weight: FontWeight.w700),
                      ),
                    )
                  else
                    Text('—',
                        style: monoStyle(
                            size: 13,
                            color: palette.muted,
                            weight: FontWeight.w400)),
                ],
              ),
              const SizedBox(width: 4),
              // 삭제 버튼
              GestureDetector(
                onTap: onRemove,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Icon(Icons.close, size: 16, color: palette.muted),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── 빈 상태 ───────────────────────────────────────────────────────────────────

class _EmptyWatchlist extends StatelessWidget {
  const _EmptyWatchlist();

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Column(
      children: [
        const SizedBox(height: 56),
        Icon(Icons.bookmark_border_rounded, size: 44, color: palette.hairline),
        const SizedBox(height: 14),
        Text('관심종목이 없어요',
            style: TextStyle(
                fontSize: 15, fontWeight: FontWeight.w700, color: palette.ink)),
        const SizedBox(height: 4),
        Text('종목 조회 후 ☆ 버튼으로 추가하세요.',
            style: TextStyle(fontSize: 13, color: palette.mutedStrong)),
      ],
    );
  }
}

class _QuickPickChip extends StatelessWidget {
  final String code;
  final String name;
  final VoidCallback onTap;

  const _QuickPickChip({
    required this.code,
    required this.name,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: palette.hover,
          borderRadius: BorderRadius.circular(9999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            StockLogo(code: code, name: name, size: 16),
            const SizedBox(width: 5),
            Text(
              name,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: palette.mutedStrong,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WatchlistStatus extends StatelessWidget {
  final int count;
  final bool connected;
  final bool disconnected;
  final VoidCallback onReconnect;

  const _WatchlistStatus({
    required this.count,
    required this.connected,
    required this.disconnected,
    required this.onReconnect,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$count개 종목',
          style: monoStyle(size: 12, color: palette.muted, weight: FontWeight.w400),
        ),
        const SizedBox(width: 8),
        if (connected)
          const RealtimeBadge(connected: true)
        else if (disconnected) ...[
          Text(
            '실시간 연결 끊김',
            style: TextStyle(
              fontSize: 12,
              color: palette.tradingDown,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onReconnect,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: palette.primary),
              ),
              child: Text(
                '재연결',
                style: TextStyle(
                  fontSize: 11,
                  color: palette.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ] else
          Text('장중 기준', style: TextStyle(fontSize: 12, color: palette.muted)),
      ],
    );
  }
}
