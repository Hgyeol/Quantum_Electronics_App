import 'package:candlesticks/candlesticks.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/endpoints.dart';
import '../api/models.dart';
import '../design/tokens.dart';
import '../providers/watchlist_provider.dart';
import '../utils/url_opener.dart';
import '../widgets/stock_logo.dart';

// ── 숫자 포맷 ─────────────────────────────────────────────────────────────────

String _fmt(double p) => p
    .toStringAsFixed(0)
    .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

// YYYYMMDD or YYYY-MM-DD → YY.MM.DD
String _fmtSimDate(String d) {
  final s = d.replaceAll('-', '');
  if (s.length < 8) return d;
  return '${s.substring(2, 4)}.${s.substring(4, 6)}.${s.substring(6, 8)}';
}

String _pct(double a, double b) {
  if (b == 0) return '—';
  final v = (a - b) / b * 100;
  return '${v >= 0 ? '+' : ''}${v.toStringAsFixed(1)}%';
}

String _userFacingError(Object error, {String subject = '분석 결과'}) {
  if (error is DioException) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return '$subject 응답이 지연되고 있어요. 잠시 후 다시 시도해주세요.';
      case DioExceptionType.connectionError:
        return '서버에 연결하지 못했어요. 네트워크 상태를 확인한 뒤 다시 시도해주세요.';
      case DioExceptionType.badResponse:
        return '$subject 를 불러오지 못했어요. 서버 오류가 발생했습니다. 잠시 후 다시 시도해주세요.';
      default:
        break;
    }
  }
  return '$subject 를 불러오지 못했어요. 잠시 후 다시 시도해주세요.';
}

const _periodOptions = ['1W', '1M', '3M', '6M', '1Y'];
const _periodLabels = ['1주', '1개월', '3개월', '6개월', '1년'];

// ── 메인 화면 ─────────────────────────────────────────────────────────────────

class StockDetailScreen extends ConsumerStatefulWidget {
  final String code;
  final String name;
  const StockDetailScreen({super.key, required this.code, required this.name});

  @override
  ConsumerState<StockDetailScreen> createState() => _State();
}

class _State extends ConsumerState<StockDetailScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  String _period = '3M';

  ChartAnalysis? _chart;
  OutlookReport? _outlook;
  MarketQuote? _quote;
  PatternMatchResult? _similar;

  bool _loadingChart = true;
  bool _loadingOutlook = false;
  bool _loadingQuote = true;
  bool _loadingSimilar = false;
  String? _outlookError;
  String? _similarError;

  int _windowDays = 40;
  int _horizon = 20;
  String _metric = 'dtw';
  String _topK = '10';
  String _minSimilarity = '0';
  SimilarCase? _comparingCase;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      // 전망 분석(index 2) 탭 선택 시 자동 로드
      if (_tabController.index == 2 && !_tabController.indexIsChanging) {
        _loadOutlook();
      }
      // 유사 패턴(index 1) 탭 선택 시 자동 로드
      if (_tabController.index == 1 && !_tabController.indexIsChanging) {
        _loadSimilar();
      }
      if (mounted) setState(() {});
    });
    fetchChart(widget.code)
        .then((d) {
          if (mounted) setState(() { _chart = d; _loadingChart = false; });
        })
        .catchError((_) {
          if (mounted) setState(() => _loadingChart = false);
        });
    fetchQuote(widget.code)
        .then((q) {
          if (mounted) setState(() { _quote = q; _loadingQuote = false; });
        })
        .catchError((_) {
          if (mounted) setState(() => _loadingQuote = false);
        });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadSimilar() async {
    if (_loadingSimilar) return;
    final ohlcv = _chart?.ohlcv ?? [];
    if (ohlcv.length < _windowDays + 1) {
      setState(() => _similarError = '차트 데이터가 부족합니다.');
      return;
    }
    setState(() {
      _loadingSimilar = true;
      _similarError = null;
      _similar = null;
      _comparingCase = null;
    });
    try {
      final sorted = List<OHLCVBar>.from(ohlcv)
        ..sort((a, b) => a.date.compareTo(b.date));
      final slice = sorted.sublist(sorted.length - _windowDays);
      final start = slice.first.date;
      final end = slice.last.date;
      final topK = _topK.trim().isEmpty ? 1000 : (int.tryParse(_topK) ?? 10);
      final minSim = _minSimilarity.trim().isEmpty
          ? 0.0
          : (double.tryParse(_minSimilarity) ?? 0.0).clamp(0.0, 100.0);
      final d = await fetchSimilarPatterns(
        widget.code,
        start: start,
        end: end,
        horizon: _horizon,
        topK: topK,
        metric: _metric,
        minSimilarity: minSim,
      );
      if (mounted) setState(() { _similar = d; _loadingSimilar = false; });
    } catch (e) {
      if (mounted) setState(() { _loadingSimilar = false; _similarError = _userFacingError(e, subject: '유사 패턴'); });
    }
  }

  Future<void> _loadOutlook() async {
    if (_outlook != null || _loadingOutlook) return;
    setState(() { _loadingOutlook = true; _outlookError = null; });
    try {
      final d = await fetchOutlook(widget.code);
      if (mounted) setState(() { _outlook = d; _loadingOutlook = false; });
    } catch (e) {
      if (mounted) setState(() { _loadingOutlook = false; _outlookError = _userFacingError(e, subject: '전망 분석'); });
    }
  }

  List<OHLCVBar> get _filteredOhlcv {
    final all = _chart?.ohlcv ?? [];
    if (all.isEmpty) return all;
    final now = DateTime.now();
    final DateTime cutoff;
    switch (_period) {
      case '1W': cutoff = now.subtract(const Duration(days: 7)); break;
      case '1M': cutoff = now.subtract(const Duration(days: 30)); break;
      case '3M': cutoff = now.subtract(const Duration(days: 90)); break;
      case '6M': cutoff = now.subtract(const Duration(days: 180)); break;
      default: return all;
    }
    final filtered = all.where((b) {
      try { return DateTime.parse(b.date).isAfter(cutoff); } catch (_) { return false; }
    }).toList();
    return filtered.isEmpty ? all : filtered;
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final inWatchlist = ref.read(watchlistProvider.notifier).contains(widget.code);

    return Scaffold(
      backgroundColor: palette.pageBg,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(inWatchlist),
            _buildPriceHeader(),
            Expanded(child: _buildContent()),
          ],
        ),
      ),
    );
  }

  // ── 상단 앱바 ───────────────────────────────────────────────────────────────

  Widget _buildAppBar(bool inWatchlist) {
    final palette = AppPalette.of(context);
    return Container(
      color: palette.cardBg,
      padding: const EdgeInsets.fromLTRB(4, 8, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 첫째 줄: 뒤로가기
          IconButton(
            icon: const Icon(Icons.chevron_left, size: 28),
            color: palette.ink,
            onPressed: () => Navigator.pop(context),
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 4),
            constraints: const BoxConstraints(minWidth: 36, minHeight: 32),
          ),
          // 둘째 줄: 로고 + 이름/코드 + 관심버튼
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 0, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                StockLogo(code: widget.code, name: widget.name, size: 42),
                const SizedBox(width: 12),
                // 이름 + 코드 한 줄 (Expanded로 남은 공간 채움)
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          widget.name,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: palette.ink,
                            height: 1.2,
                            letterSpacing: -0.3,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        widget.code,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: palette.mutedStrong,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // 관심 버튼 — 오른쪽 끝 고정
                GestureDetector(
                  onTap: () async {
                    final n = ref.read(watchlistProvider.notifier);
                    if (n.contains(widget.code)) {
                      await n.remove(widget.code);
                    } else {
                      await n.add(widget.code);
                    }
                    setState(() {});
                  },
                  child: Container(
                    height: 32,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: palette.bgSubtle,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      inWatchlist ? '★ 관심 해제' : '☆ 관심 추가',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: palette.body,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── 시세 헤더 ────────────────────────────────────────────────────────────────

  Widget _buildPriceHeader() {
    final palette = AppPalette.of(context);
    return Container(
      color: palette.cardBg,
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
      child: _loadingQuote
          ? Container(
              height: 44,
              decoration: BoxDecoration(
                  color: palette.hairline,
                  borderRadius: BorderRadius.circular(6)),
            )
          : _quote == null
              ? const SizedBox.shrink()
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 가격 행 — 현재가+원+등락  |  52주 최고/최저
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // 왼쪽: 현재가 + 원 + 등락 (baseline 정렬)
                        Expanded(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                _fmt(_quote!.price),
                                style: TextStyle(
                                  fontSize: 30,
                                  fontWeight: FontWeight.bold,
                                  color: palette.ink,
                                  height: 1.0,
                                  letterSpacing: -0.5,
                                  fontFeatures: const [FontFeature.tabularFigures()],
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '원',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: palette.muted,
                                ),
                              ),
                              const SizedBox(width: 8),
                              // 등락 (변동금액 + 변동률)
                              Builder(builder: (ctx) {
                                final q = _quote!;
                                final up = q.change > 0;
                                final zero = q.change == 0;
                                final color = zero
                                    ? palette.body
                                    : up
                                        ? palette.tradingUp
                                        : palette.tradingDown;
                                final sign = up ? '+' : '';
                                return Text(
                                  '$sign${_fmt(q.change)} ($sign${q.changeRate.toStringAsFixed(2)}%)',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: color,
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                        // 오른쪽: 52주 최고/최저 — 현재가 라인에 수직 중앙 정렬
                        if (_quote!.w52High != null)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '52주 최고  ${_fmt(_quote!.w52High!)}',
                                style: TextStyle(
                                    fontSize: 10, color: palette.muted),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '52주 최저  ${_fmt(_quote!.w52Low!)}',
                                style: TextStyle(
                                    fontSize: 10, color: palette.muted),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ],
                ),
    );
  }

  // ── 탭바 + 콘텐츠 ───────────────────────────────────────────────────────────

  Widget _buildContent() {
    final palette = AppPalette.of(context);
    return Column(
      children: [
        // 탭바 (가이드 언더라인 스타일)
        Container(
          decoration: BoxDecoration(
            color: palette.cardBg,
            border: Border(bottom: BorderSide(color: palette.border, width: 1)),
          ),
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            labelPadding: const EdgeInsets.only(right: 24),
            indicatorSize: TabBarIndicatorSize.label,
            indicator: UnderlineTabIndicator(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(999),
                topRight: Radius.circular(999),
              ),
              borderSide: BorderSide(color: palette.ink, width: 3),
            ),
            dividerColor: Colors.transparent,
            labelColor: palette.ink,
            unselectedLabelColor: palette.muted,
            labelStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            tabs: const [
              Tab(text: '차트 분석'),
              Tab(text: '유사 패턴'),
              Tab(text: '전망 분석'),
            ],
          ),
        ),
        // 탭 콘텐츠
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 24),
                child: _buildChartTab(),
              ),
              SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 24),
                child: _buildSimilarTab(),
              ),
              SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 24),
                child: _buildOutlookTab(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── 차트 탭 ──────────────────────────────────────────────────────────────────

  Widget _buildChartTab() {
    final palette = AppPalette.of(context);
    if (_loadingChart) {
      return SizedBox(
        height: 420,
        child: Center(
          child: CircularProgressIndicator(color: palette.primary),
        ),
      );
    }
    if (_chart == null) {
      return SizedBox(
        height: 240,
        child: Center(
          child: Text('차트 데이터를 불러오지 못했습니다.',
              style: TextStyle(color: palette.muted)),
        ),
      );
    }

    final candles = _filteredOhlcv.map((b) => Candle(
          date: DateTime.parse(b.date),
          high: b.high,
          low: b.low,
          open: b.open,
          close: b.close,
          volume: b.volume.toDouble(),
        )).toList();

    final hasInfo = _chart!.signal != null ||
        _chart!.supportLevels.isNotEmpty ||
        _chart!.resistanceLevels.isNotEmpty;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 차트 섹션 — 스크롤 없이 고정 높이
        Container(
          color: palette.cardBg,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: _PeriodSelector(
                  period: _period,
                  onPeriod: (p) => setState(() => _period = p),
                ),
              ),
              SizedBox(
                height: 340,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
                  child: Candlesticks(candles: candles),
                ),
              ),
            ],
          ),
        ),
        // 시그널·레벨 섹션 — 웹 모바일처럼 같은 페이지에 이어서 노출
        if (hasInfo)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              children: [
                if (_chart!.signal != null) ...[
                  _SignalSummaryCard(
                    signal: _chart!.signal!,
                    currentPrice: _quote?.price ?? _chart!.currentPrice,
                  ),
                  const SizedBox(height: 8),
                ],
                if (_chart!.supportLevels.isNotEmpty ||
                    _chart!.resistanceLevels.isNotEmpty)
                  _LevelsCard(
                    supports: _chart!.supportLevels,
                    resistances: _chart!.resistanceLevels,
                    currentPrice: _quote?.price ?? _chart!.currentPrice,
                  ),
              ],
              ),
            ),
      ],
    );
  }

  // ── 유사 패턴 탭 ─────────────────────────────────────────────────────────────

  static const _windowOpts = [20, 40, 60, 90];
  static const _horizonOpts = [5, 20, 60];
  static const _metricOpts = [
    ('dtw', 'DTW'),
    ('pearson', '피어슨'),
    ('spearman', '스피어만'),
  ];

  Widget _buildSimilarTab() {
    final palette = AppPalette.of(context);
    final ready = _chart != null && !_loadingSimilar;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── 컨트롤 패널 ──
        Container(
          color: palette.cardBg,
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 비교 구간
              _simLabel(context, '비교 구간'),
              const SizedBox(height: 6),
              _SegmentRow(
                options: _windowOpts.map((w) => '$w일').toList(),
                activeIndex: _windowOpts.indexOf(_windowDays),
                onSelect: (i) => setState(() => _windowDays = _windowOpts[i]),
              ),
              const SizedBox(height: 10),
              // 이후 기간
              _simLabel(context, '이후 기간'),
              const SizedBox(height: 6),
              _SegmentRow(
                options: _horizonOpts.map((h) => '$h일').toList(),
                activeIndex: _horizonOpts.indexOf(_horizon),
                onSelect: (i) => setState(() => _horizon = _horizonOpts[i]),
              ),
              const SizedBox(height: 10),
              // 유사도 방식
              _simLabel(context, '유사도 방식'),
              const SizedBox(height: 6),
              _SegmentRow(
                options: _metricOpts.map((m) => m.$2).toList(),
                activeIndex: _metricOpts.indexWhere((m) => m.$1 == _metric),
                onSelect: (i) => setState(() => _metric = _metricOpts[i].$1),
              ),
              const SizedBox(height: 10),
              // 결과 개수 + 최소 유사도 + 찾기
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _simLabel(context, '결과 개수'),
                        const SizedBox(height: 6),
                        _SimInput(
                          value: _topK,
                          hint: '전체',
                          keyboardType: TextInputType.number,
                          onChanged: (v) => _topK = v.replaceAll(RegExp(r'[^0-9]'), ''),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _simLabel(context, '최소 유사도'),
                        const SizedBox(height: 6),
                        _SimInput(
                          value: _minSimilarity,
                          hint: '없음',
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          onChanged: (v) => _minSimilarity = v.replaceAll(RegExp(r'[^0-9.]'), ''),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: ready ? _loadSimilar : null,
                    child: Container(
                      height: 36,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        color: ready ? palette.primary : palette.hairline,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: _loadingSimilar
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : Text(
                              _loadingSimilar ? '검색 중' : '찾기',
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                   color: ready ? Colors.white : palette.muted),
                            ),
                    ),
                  ),
                ],
              ),
              if (_similarError != null) ...[
                const SizedBox(height: 8),
                Text(_similarError!,
                    style: TextStyle(
                        fontSize: 12, color: palette.tradingDown)),
              ],
            ],
          ),
        ),
        Container(height: 1, color: palette.border),

        // ── 결과 영역 ──
        _buildSimilarResult(),
      ],
    );
  }

  Widget _buildSimilarResult() {
    final palette = AppPalette.of(context);
    if (_loadingSimilar) {
      return SizedBox(
        height: 220,
        child: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
          CircularProgressIndicator(color: palette.primary),
          const SizedBox(height: 12),
          Text('유사 패턴 탐색 중…',
              style: TextStyle(fontSize: 13, color: palette.muted)),
        ]),
        ),
      );
    }
    if (_similar == null) {
      return SizedBox(
        height: 220,
        child: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.query_stats_outlined, size: 48, color: palette.hairline),
          const SizedBox(height: 12),
          Text('유사 패턴 검색',
              style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w700, color: palette.ink)),
          const SizedBox(height: 4),
          Text('위 설정을 조정하고 찾기를 눌러보세요.',
              style: TextStyle(fontSize: 12, color: palette.muted)),
        ]),
        ),
      );
    }

    final cases = _similar!.cases;
    final stats = _similar!.stats;
    final queryBars = _getQueryBars();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── 통계 행 ──
        if (stats['count'] != null && (stats['count'] ?? 0) > 0)
          Container(
            color: palette.bgSubtle,
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: Row(
              children: [
                _StatCell2('유사 사례 평균', _fmtPct(stats['mean'])),
                Container(width: 1, height: 40, color: palette.border),
                _StatCell2('중앙값', _fmtPct(stats['median'])),
                Container(width: 1, height: 40, color: palette.border),
                _StatCell2('상승 비율',
                    stats['positive_ratio'] != null
                        ? '${stats['positive_ratio']!.toStringAsFixed(0)}%'
                        : '—'),
              ],
            ),
          ),

        // ── 사례 목록 ──
        if (cases.isEmpty)
          Padding(
            padding: const EdgeInsets.all(32),
            child: Center(
               child: Text('유사한 과거 사례를 찾지 못했습니다.',
                   style: TextStyle(fontSize: 13, color: palette.muted)),
            ),
          )
        else
          ...cases.asMap().entries.map((entry) {
            final i = entry.key;
            final c = entry.value;
            final isOpen = _comparingCase?.stockCode == c.stockCode &&
                _comparingCase?.startDate == c.startDate;
            return _SimilarCaseRow(
              c: c,
              isOpen: isOpen,
              isFirst: i == 0,
              queryBars: queryBars,
              onTap: () => setState(() =>
                  _comparingCase = isOpen ? null : c),
            );
          }),
      ],
    );
  }

  List<OHLCVBar> _getQueryBars() {
    final ohlcv = _chart?.ohlcv ?? [];
    final result = _similar;
    if (ohlcv.isEmpty || result == null) return [];
    final start = result.queryStart.replaceAll('-', '');
    final end = result.queryEnd.replaceAll('-', '');
    return ohlcv.where((b) {
      final d = b.date.replaceAll('-', '');
      return d.compareTo(start) >= 0 && d.compareTo(end) <= 0;
    }).toList();
  }

  // ── 전망 분석 탭 ─────────────────────────────────────────────────────────────

  Widget _buildOutlookTab() {
    final palette = AppPalette.of(context);
    if (_loadingOutlook) {
      return SizedBox(
        height: 220,
        child: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
          CircularProgressIndicator(color: palette.primary),
          const SizedBox(height: 14),
          Text('AI가 분석 중입니다…',
              style: TextStyle(fontSize: 13, color: palette.muted)),
        ]),
        ),
      );
    }
    if (_outlookError != null) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
          decoration: BoxDecoration(
            color: palette.cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: palette.border),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(_outlookError!,
              style: TextStyle(color: palette.tradingDown, fontSize: 13),
              textAlign: TextAlign.center),
          const SizedBox(height: 12),
          _PrimaryBtn(label: '다시 시도', onTap: _loadOutlook),
        ]),
        ),
      );
    }
    if (_outlook == null) {
      return SizedBox(
        height: 260,
        child: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.auto_awesome_outlined, size: 44, color: palette.hairline),
          const SizedBox(height: 12),
          Text('AI가 뉴스와 공시를 분석합니다.',
              style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w700, color: palette.ink)),
          const SizedBox(height: 4),
          Text('실적·수급·재무 관점으로 종합 점수를 매깁니다.',
              style: TextStyle(fontSize: 12, color: palette.muted)),
          const SizedBox(height: 20),
          _PrimaryBtn(label: '전망 분석 시작', onTap: _loadOutlook),
        ]),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_outlook!.score != null)
            _FinalVerdictCard(
              score: _outlook!.score!,
              summary: _outlook!.summary,
              aiSummary: _outlook!.aiSignals.isNotEmpty
                  ? _outlook!.aiSignals.first.summary
                  : null,
              confidence: _outlook!.aiSignals.isNotEmpty
                  ? _outlook!.aiSignals.first.confidence
                  : null,
            ),
          if (_outlook!.quantSignals.isNotEmpty ||
              _outlook!.financialSignals.isNotEmpty ||
              _outlook!.aiSignals.isNotEmpty) ...[
            const SizedBox(height: 16),
            _QuantSignalsTable(
              quant: _outlook!.quantSignals,
              financial: _outlook!.financialSignals,
              ai: _outlook!.aiSignals,
            ),
          ],
          if (_outlook!.evidence.isNotEmpty) ...[
            const SizedBox(height: 16),
            _EvidenceList(evidence: _outlook!.evidence),
          ],
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// ── 기간 선택기 ───────────────────────────────────────────────────────────────

class _PeriodSelector extends StatelessWidget {
  final String period;
  final void Function(String) onPeriod;
  const _PeriodSelector({required this.period, required this.onPeriod});

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Container(
      height: 32,
      decoration: BoxDecoration(
        color: palette.bgMuted,
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        children: List.generate(_periodOptions.length, (i) {
          final isActive = _periodOptions[i] == period;
          return Expanded(
            child: GestureDetector(
              onTap: () => onPeriod(_periodOptions[i]),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                decoration: BoxDecoration(
                  color: isActive ? palette.cardBg : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: isActive
                      ? [BoxShadow(color: palette.border, blurRadius: 4)]
                      : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  _periodLabels[i],
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                    color: isActive ? palette.ink : palette.mutedStrong,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ── 매매 시그널 카드 ──────────────────────────────────────────────────────────

const _actionKo = {'buy': '매수 고려', 'hold': '관망', 'sell': '매도 고려'};
const _confidenceKo = {'low': '신호 약함', 'medium': '신호 보통', 'high': '신호 강함'};

class _SignalSummaryCard extends StatelessWidget {
  final EntryExitSignal signal;
  final double currentPrice;
  const _SignalSummaryCard({required this.signal, required this.currentPrice});

  Color _actionColor(AppPalette palette) => signal.action == 'buy'
      ? palette.tradingUp
      : signal.action == 'sell'
          ? palette.tradingDown
          : palette.primary;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final actionColor = _actionColor(palette);
    return Container(
      decoration: BoxDecoration(
        color: palette.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('매매 시그널',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: palette.ink)),
                const SizedBox(height: 6),
                Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: actionColor.withAlpha(25),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _actionKo[signal.action] ?? signal.action,
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: actionColor),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(_confidenceKo[signal.confidence] ?? '',
                      style: TextStyle(fontSize: 12, color: palette.mutedStrong)),
                ]),
              ],
            ),
          ),
          Container(height: 1, color: palette.border),
          // 매수 구간
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Row(
              children: [
                Row(children: [
                  Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                          color: palette.tradingUp, shape: BoxShape.circle)),
                  const SizedBox(width: 6),
                  Text('매수 구간',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: palette.tradingUp)),
                ]),
                const Spacer(),
                if (signal.entryZoneLow != null && signal.entryZoneHigh != null)
                  Text(
                    '${_fmt(signal.entryZoneLow!)} ~ ${_fmt(signal.entryZoneHigh!)}',
                    style: monoStyle(
                        size: 14, color: palette.ink, weight: FontWeight.w700),
                  )
                else
                  Text('현재 매수 구간 없음',
                      style: TextStyle(fontSize: 12, color: palette.muted)),
              ],
            ),
          ),
          Container(height: 1, color: palette.border),
          // 매도 목표
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Row(
              children: [
                Row(children: [
                  Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                          color: palette.tradingDown, shape: BoxShape.circle)),
                  const SizedBox(width: 6),
                  Text('매도 목표',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: palette.tradingDown)),
                ]),
                const Spacer(),
                if (signal.primaryTarget != null)
                  Row(children: [
                    Text(_fmt(signal.primaryTarget!),
                        style: monoStyle(
                            size: 16, color: palette.ink, weight: FontWeight.w700)),
                    const SizedBox(width: 6),
                    Text(
                      _pct(signal.primaryTarget!, currentPrice),
                      style: TextStyle(fontSize: 11, color: palette.mutedStrong),
                    ),
                  ])
                else
                  Text('저항선 없음',
                      style: TextStyle(fontSize: 12, color: palette.muted)),
              ],
            ),
          ),
          if (signal.riskRewardRatio != null) ...[
            Container(height: 1, color: palette.border),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
              child: Row(children: [
                Text('리스크 대비 수익',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: palette.mutedStrong)),
                const Spacer(),
                Text(
                  '1 : ${signal.riskRewardRatio!.toStringAsFixed(1)}',
                  style: monoStyle(
                      size: 18, color: palette.ink, weight: FontWeight.w700),
                ),
              ]),
            ),
          ],
        ],
      ),
    );
  }
}

// ── 지지/저항선 카드 ──────────────────────────────────────────────────────────

const _sourceLabel = {
  'poc': 'POC', 'hvn': 'HVN', 'vwap': 'VWAP',
  'swing': '스윙', 'ma20': 'MA20', 'ma60': 'MA60',
  'bb_lower': 'BB하단', 'bb_upper': 'BB상단',
};

class _LevelsCard extends StatelessWidget {
  final List<Level> supports;
  final List<Level> resistances;
  final double currentPrice;
  const _LevelsCard({
    required this.supports,
    required this.resistances,
    required this.currentPrice,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Container(
      decoration: BoxDecoration(
        color: palette.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _LevelSection(
              label: '지지선',
              color: palette.tradingUp,
              levels: supports,
              currentPrice: currentPrice),
          Container(height: 1, color: palette.border),
          _LevelSection(
              label: '저항선',
              color: palette.tradingDown,
              levels: resistances,
              currentPrice: currentPrice),
        ],
      ),
    );
  }
}

class _LevelSection extends StatelessWidget {
  final String label;
  final Color color;
  final List<Level> levels;
  final double currentPrice;
  const _LevelSection({
    required this.label,
    required this.color,
    required this.levels,
    required this.currentPrice,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: Row(children: [
            Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: palette.ink)),
          ]),
        ),
        if (levels.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: Text('감지된 $label 없음',
                style: TextStyle(fontSize: 12, color: palette.muted)),
          )
        else
          ...levels.map((l) => Container(
                decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: palette.border))),
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                child: Row(children: [
                  Text(_fmt(l.price),
                      style: monoStyle(
                          size: 13, color: palette.ink, weight: FontWeight.w700)),
                  if (l.source != null && _sourceLabel[l.source] != null) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: palette.bgMuted,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(_sourceLabel[l.source]!,
                          style: TextStyle(
                              fontSize: 10,
                              color: palette.mutedStrong,
                              fontWeight: FontWeight.w600)),
                    ),
                  ],
                  const Spacer(),
                  Text(
                    _pct(l.price, currentPrice),
                    style: TextStyle(
                        fontSize: 11,
                        color: color,
                        fontFeatures: const [FontFeature.tabularFigures()]),
                  ),
                ]),
              )),
      ],
    );
  }
}

// ── FinalVerdictCard (전망 분석 종합) ─────────────────────────────────────────

class _VerdictMeta {
  final String label;
  final String sub;
  final Color textColor;
  final Color bgColor;
  _VerdictMeta(this.label, this.sub, this.textColor, this.bgColor);
}

_VerdictMeta _verdictMeta(String direction, AppPalette palette) {
  if (direction == 'positive') {
    return _VerdictMeta('긍정적', '상승 우세 신호', palette.tradingUp,
        palette.tradingUp.withAlpha(20));
  }
  if (direction == 'negative') {
    return _VerdictMeta('부정적', '하락 우세 신호', palette.tradingDown,
        palette.tradingDown.withAlpha(20));
  }
  return _VerdictMeta('중립', '방향성 불명확', palette.muted,
      palette.bgMuted);
}

class _FinalVerdictCard extends StatelessWidget {
  final ScoreBreakdown score;
  final String? summary;
  final String? aiSummary;
  final double? confidence;
  const _FinalVerdictCard(
      {required this.score, this.summary, this.aiSummary, this.confidence});

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final meta = _verdictMeta(score.direction, palette);
    final totalStr =
        '${score.totalScore > 0 ? '+' : ''}${score.totalScore}';

    return Container(
      decoration: BoxDecoration(
        color: palette.cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: palette.border),
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        children: [
          // ── 상단 버딕트 바 ──
          Container(
            color: meta.bgColor,
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(meta.label,
                          style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: meta.textColor,
                              height: 1.1)),
                      const SizedBox(height: 6),
                      Text(meta.sub,
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: palette.mutedStrong)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('합산 점수',
                        style: TextStyle(
                            fontSize: 12, color: palette.muted)),
                    const SizedBox(height: 2),
                    Text(
                      totalStr,
                      style: TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.w900,
                        color: meta.textColor,
                        height: 1,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── AI 요약 ──
          if ((aiSummary != null && aiSummary!.isNotEmpty) ||
              (summary != null && summary!.isNotEmpty))
            Container(
              decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: palette.border))),
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (aiSummary != null && aiSummary!.isNotEmpty)
                    Text(
                      aiSummary!,
                      style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w500,
                          color: palette.ink,
                          height: 1.6),
                    ),
                  if (summary != null && summary!.isNotEmpty) ...[
                    if (aiSummary != null && aiSummary!.isNotEmpty)
                      const SizedBox(height: 8),
                    Text(
                      summary!,
                      style: TextStyle(
                          fontSize: 15,
                          color: palette.body,
                          height: 1.6),
                    ),
                  ],
                  if (confidence != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: palette.bgSubtle,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'confidence ${(confidence! * 100).toStringAsFixed(0)}%',
                        style: monoStyle(
                            size: 13,
                            color: palette.muted,
                            weight: FontWeight.w500),
                      ),
                    ),
                  ],
                ],
              ),
            ),

          // ── 점수 바 ──
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF1B1F25)
                  : const Color(0xFFFBFBFC),
              border: Border(top: BorderSide(color: palette.border)),
            ),
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
            child: Column(
              children: [
                _ScoreBar(
                    label: 'Quant · 가격·수급 신호',
                    score: score.quantScore,
                    max: 8),
                const SizedBox(height: 20),
                _ScoreBar(
                    label: 'LLM · 공시·뉴스 해석',
                    score: score.aiScore,
                    max: 8),
                const SizedBox(height: 20),
                _ScoreBar(
                    label: 'Financial · 재무지표',
                    score: score.financialScore,
                    max: 7),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoreBar extends StatelessWidget {
  final String label;
  final int score;
  final int max;
  const _ScoreBar({required this.label, required this.score, required this.max});

  Color _color(AppPalette palette) => score > 0
      ? palette.tradingUp
      : score < 0
          ? palette.tradingDown
          : palette.muted;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final barColor = _color(palette);
    final pct = (score.abs() / max).clamp(0.0, 1.0);
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(fontSize: 13, color: palette.body)),
            Text(
              '${score > 0 ? '+' : ''}$score',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: barColor,
                  fontFeatures: const [FontFeature.tabularFigures()]),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(9999),
          child: SizedBox(
            height: 6,
            child: Row(children: [
              Flexible(
                flex: (pct * 100).round(),
                child: Container(color: barColor),
              ),
              Flexible(
                flex: ((1 - pct) * 100).round(),
                child: Container(color: palette.hairline),
              ),
            ]),
          ),
        ),
      ],
    );
  }
}

// ── 신호 상세 표 (아코디언) ────────────────────────────────────────────────────

class _SignalRow {
  final String key;
  final String direction;
  final int score;
  final String source;
  final String title;
  final String value;
  final String? detail;
  _SignalRow({
    required this.key,
    required this.direction,
    required this.score,
    required this.source,
    required this.title,
    required this.value,
    this.detail,
  });
}

class _QuantSignalsTable extends StatefulWidget {
  final List<QuantSignal> quant;
  final List<FinancialSignal> financial;
  final List<AISignal> ai;
  const _QuantSignalsTable({
    required this.quant,
    required this.financial,
    required this.ai,
  });

  @override
  State<_QuantSignalsTable> createState() => _QuantSignalsTableState();
}

class _QuantSignalsTableState extends State<_QuantSignalsTable> {
  String? _openKey;

  String _fmtNum(String? v) {
    if (v == null || v.isEmpty) return '—';
    return v;
  }

  List<_SignalRow> _buildRows() => [
        ...widget.quant.asMap().entries.map((e) => _SignalRow(
              key: 'q-${e.key}',
              direction: e.value.direction,
              score: e.value.score,
              source: 'quant',
              title: e.value.label,
              value: _fmtNum(e.value.value),
              detail: _quantDetail(e.value.label),
            )),
        ...widget.financial.asMap().entries.map((e) => _SignalRow(
              key: 'f-${e.key}',
              direction: e.value.direction,
              score: e.value.score,
              source: 'financial',
              title: e.value.label,
              value: '—',
              detail: e.value.reason,
            )),
        ...widget.ai.asMap().entries.map((e) => _SignalRow(
              key: 'a-${e.key}',
              direction: e.value.direction,
              score: e.value.score,
              source: 'gpt',
              title: 'LLM: ${e.value.label}',
              value: e.value.confidence != null
                  ? 'conf ${(e.value.confidence! * 100).toStringAsFixed(0)}%'
                  : '—',
              detail: e.value.summary,
            )),
      ];

  String _quantDetail(String label) {
    if (label.contains('골든크로스')) return '단기(MA5) > 장기(MA20) 상향 돌파(+2) / 하향 돌파(-2)';
    if (label.contains('이격도')) return '현재가 / MA20 × 100. <90 과매도(+2), >110 과매수(-2)';
    if (label.contains('모멘텀')) return '60일 수익률. ≥+30%(+1) / ≤-20%(-1) / 그 외 중립';
    if (label.contains('외인') || label.contains('외국인')) return '최근 3 거래일 외국인 순매수 합. >0 positive(+2), <0 negative(-2)';
    if (label.contains('거래량')) return '당일 거래량 / 20일 평균. ≥2.0 급증(+1), ≤0.5 위축(-1)';
    return '상세 정보 없음';
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final rows = _buildRows();

    return Container(
      decoration: BoxDecoration(
        color: palette.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.border),
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: palette.hairline)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('신호 상세 표',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: palette.ink)),
                const SizedBox(height: 4),
                Text('행을 탭하면 계산 근거를 펼쳐볼 수 있습니다.',
                    style: TextStyle(fontSize: 12, color: palette.mutedStrong)),
              ],
            ),
          ),
          // 행 목록
          ...rows.map((row) => _buildRow(row, palette)),
        ],
      ),
    );
  }

  Widget _buildRow(_SignalRow row, AppPalette palette) {
    final isOpen = _openKey == row.key;
    final scoreColor = row.score > 0
        ? palette.tradingUp
        : row.score < 0
            ? palette.tradingDown
            : palette.muted;
    final dirColor = row.direction == 'positive'
        ? palette.tradingUp
        : row.direction == 'negative'
            ? palette.tradingDown
            : palette.muted;
    final dirGlyph = row.direction == 'positive'
        ? '▲'
        : row.direction == 'negative'
            ? '▼'
            : '·';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => setState(() => _openKey = isOpen ? null : row.key),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: palette.hairline)),
            ),
            child: Row(
              children: [
                // 방향 글리프 24px
                SizedBox(
                  width: 20,
                  child: Text(dirGlyph,
                      style: TextStyle(fontSize: 12, color: dirColor)),
                ),
                // 출처 120px
                SizedBox(
                  width: 90,
                  child: Text(row.source,
                      style: monoStyle(size: 11, color: palette.mutedStrong),
                      overflow: TextOverflow.ellipsis),
                ),
                // 이름 (flex)
                Expanded(
                  child: Text(row.title,
                      style: TextStyle(fontSize: 13, color: palette.ink),
                      overflow: TextOverflow.ellipsis),
                ),
                // 값 80px
                SizedBox(
                  width: 80,
                  child: Text(row.value,
                      style: monoStyle(size: 12, color: palette.body),
                      textAlign: TextAlign.right,
                      overflow: TextOverflow.ellipsis),
                ),
                const SizedBox(width: 12),
                // 점수 + 화살표
                SizedBox(
                  width: 52,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        '${row.score > 0 ? '+' : ''}${row.score}',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: scoreColor,
                            fontFeatures: const [FontFeature.tabularFigures()]),
                      ),
                      const SizedBox(width: 6),
                      AnimatedRotation(
                        turns: isOpen ? 0.25 : 0,
                        duration: const Duration(milliseconds: 150),
                        child: Text('▶',
                            style:
                                TextStyle(fontSize: 9, color: palette.muted)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        if (isOpen && row.detail != null && row.detail!.isNotEmpty)
          Container(
            margin: const EdgeInsets.fromLTRB(24, 0, 24, 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: palette.bgSubtle,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: palette.border),
            ),
            child: Text(
              row.detail!,
              style: TextStyle(
                  fontSize: 12, color: palette.mutedStrong, height: 1.6),
            ),
          ),
      ],
    );
  }
}

// ── 근거 자료 목록 ─────────────────────────────────────────────────────────────

class _EvidenceList extends StatelessWidget {
  final List<Evidence> evidence;
  const _EvidenceList({required this.evidence});

  static const _kindLabel = {
    'news': '뉴스',
    'disclosure': '공시',
    'financial': '재무',
    'market': '시장',
    'quant': '퀀트',
  };

  Future<void> _openUrl(BuildContext context, String? rawUrl) async {
    if (rawUrl == null || rawUrl.isEmpty) return;
    final uri = Uri.tryParse(rawUrl);
    if (uri == null || !uri.hasScheme) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('열 수 없는 링크입니다.')),
      );
      return;
    }

    final opened = await openExternalUrl(uri.toString());
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('원문 링크를 열지 못했어요.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Container(
      decoration: BoxDecoration(
        color: palette.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.border),
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: palette.hairline)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text('근거 자료',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: palette.ink)),
                Text('${evidence.length}건',
                    style: monoStyle(size: 12, color: palette.muted)),
              ],
            ),
          ),
          // 항목 목록
          ...evidence.map((item) => InkWell(
                onTap: item.url == null ? null : () => _openUrl(context, item.url),
                child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 14),
                decoration: BoxDecoration(
                  border:
                      Border(top: BorderSide(color: palette.hairline)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 종류 뱃지
                    Container(
                      margin: const EdgeInsets.only(top: 2),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: palette.bgSubtle,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _kindLabel[item.kind] ?? item.kind,
                        style:
                            monoStyle(size: 11, color: palette.muted),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // 제목 + 출처 + 날짜
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            style: TextStyle(
                              fontSize: 13,
                              color: item.url != null
                                  ? palette.primary
                                  : palette.ink,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              if (item.source.isNotEmpty)
                                Text(item.source,
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: palette.mutedStrong)),
                              if (item.publishedAt != null &&
                                  item.publishedAt!.length >= 10) ...[
                                const SizedBox(width: 10),
                                Text(
                                  item.publishedAt!.substring(0, 10),
                                  style: monoStyle(
                                      size: 11,
                                      color: palette.mutedStrong),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                ),
              )),
        ],
      ),
    );
  }
}

// ── 기본 버튼 ─────────────────────────────────────────────────────────────────

class _PrimaryBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _PrimaryBtn({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
            color: palette.primary, borderRadius: BorderRadius.circular(8)),
        child: Text(label,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w700)),
      ),
    );
  }
}

// ── 유사패턴 컨트롤 헬퍼 ─────────────────────────────────────────────────────

String _fmtPct(double? v) {
  if (v == null) return '—';
  return '${v > 0 ? '+' : ''}${v.toStringAsFixed(2)}%';
}

Widget _simLabel(BuildContext context, String text) {
  final palette = AppPalette.of(context);
  return Text(
      text,
      style: TextStyle(
          fontSize: 13, fontWeight: FontWeight.w500, color: palette.muted),
    );
}

class _SegmentRow extends StatelessWidget {
  final List<String> options;
  final int activeIndex;
  final void Function(int) onSelect;
  const _SegmentRow(
      {required this.options,
      required this.activeIndex,
      required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: palette.bgSubtle,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: options.asMap().entries.map((e) {
          final active = e.key == activeIndex;
          return GestureDetector(
            onTap: () => onSelect(e.key),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: active ? palette.cardBg : Colors.transparent,
                borderRadius: BorderRadius.circular(9),
                boxShadow: active
                    ? [
                        BoxShadow(
                            color: palette.border,
                            blurRadius: 3,
                            offset: const Offset(0, 1))
                      ]
                    : null,
              ),
              child: Text(
                e.value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: active ? palette.ink : palette.mutedStrong,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _SimInput extends StatefulWidget {
  final String value;
  final String hint;
  final TextInputType keyboardType;
  final void Function(String) onChanged;
  const _SimInput(
      {required this.value,
      required this.hint,
      required this.keyboardType,
      required this.onChanged});

  @override
  State<_SimInput> createState() => _SimInputState();
}

class _SimInputState extends State<_SimInput> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.value);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: palette.bgSubtle,
        borderRadius: BorderRadius.circular(10),
      ),
      child: TextField(
        controller: _ctrl,
        keyboardType: widget.keyboardType,
        style: monoStyle(size: 14, color: palette.ink, weight: FontWeight.w600),
        decoration: InputDecoration(
          hintText: widget.hint,
          hintStyle: TextStyle(
              fontSize: 14,
              color: palette.muted,
              fontWeight: FontWeight.w400),
          border: InputBorder.none,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
        ),
        onChanged: widget.onChanged,
      ),
    );
  }
}

// ── 유사패턴 통계 셀 ──────────────────────────────────────────────────────────

class _StatCell2 extends StatelessWidget {
  final String label;
  final String value;
  const _StatCell2(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Expanded(
      child: Column(children: [
        Text(label,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: palette.muted),
            textAlign: TextAlign.center),
        const SizedBox(height: 4),
        Text(value,
            style: monoStyle(size: 20, color: palette.ink, weight: FontWeight.w700),
            textAlign: TextAlign.center),
      ]),
    );
  }
}

// ── 유사패턴 사례 행 (클릭 시 차트 비교 확장) ────────────────────────────────

class _SimilarCaseRow extends StatelessWidget {
  final SimilarCase c;
  final bool isOpen;
  final bool isFirst;
  final List<OHLCVBar> queryBars;
  final VoidCallback onTap;

  const _SimilarCaseRow({
    required this.c,
    required this.isOpen,
    required this.isFirst,
    required this.queryBars,
    required this.onTap,
  });

  Color _retColor(AppPalette palette) =>
      (c.forwardReturn ?? 0) >= 0 ? palette.tradingUp : palette.tradingDown;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Column(
      children: [
        if (!isFirst) Container(height: 1, color: palette.border),
        // 행 헤더
        GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Container(
            color: isOpen ? palette.bgSubtle : palette.cardBg,
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              children: [
                StockLogo(
                    code: c.stockCode,
                    name: c.stockName ?? c.stockCode,
                    size: 28),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(c.stockName ?? c.stockCode,
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: palette.ink),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      Text(
                        '${_fmtSimDate(c.startDate)} ~ ${_fmtSimDate(c.endDate)}',
                        style: monoStyle(
                            size: 11,
                            color: palette.muted,
                            weight: FontWeight.w400),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('유사도 ${c.similarity.toStringAsFixed(0)}%',
                        style: TextStyle(fontSize: 11, color: palette.muted)),
                    Text(
                      '이후 ${_fmtPct(c.forwardReturn)}',
                      style: monoStyle(
                          size: 13,
                          color: _retColor(palette),
                          weight: FontWeight.w700),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        // 차트 비교 패널 (확장 시)
        if (isOpen)
          Container(
            color: palette.bgSubtle,
            padding:
                const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: _RealCompare(
              queryBars: queryBars,
              caseStock: c,
            ),
          ),
      ],
    );
  }
}

// ── 실제 차트 비교 ────────────────────────────────────────────────────────────

class _RealCompare extends StatefulWidget {
  final List<OHLCVBar> queryBars;
  final SimilarCase caseStock;

  const _RealCompare(
      {required this.queryBars, required this.caseStock});

  @override
  State<_RealCompare> createState() => _RealCompareState();
}

class _RealCompareState extends State<_RealCompare> {
  List<OHLCVBar>? _caseBars;
  bool _loading = true;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    try {
      final data = await fetchChart(widget.caseStock.stockCode);
      if (!mounted) return;
      final startN =
          widget.caseStock.startDate.replaceAll('-', '');
      final windowCount = widget.caseStock.windowCloses.length +
          widget.caseStock.forwardCloses.length;
      final from = data.ohlcv
          .where((b) => b.date.replaceAll('-', '').compareTo(startN) >= 0)
          .toList();
      setState(() {
        _caseBars = from.take(windowCount).toList();
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() { _loading = false; _error = true; });
    }
  }

  List<Candle> _toCandles(List<OHLCVBar> bars) => bars
      .map((b) => Candle(
            date: DateTime.tryParse(b.date) ??
                DateTime.now(),
            high: b.high,
            low: b.low,
            open: b.open,
            close: b.close,
            volume: b.volume.toDouble(),
          ))
      .toList();

  Widget _miniChart(List<OHLCVBar> bars) {
    final palette = AppPalette.of(context);
    if (bars.isEmpty) {
      return SizedBox(
        height: 180,
        child: Center(
          child: Text('데이터 없음',
              style: TextStyle(fontSize: 12, color: palette.muted)),
        ),
      );
    }
    return SizedBox(
      height: 180,
      child: Candlesticks(candles: _toCandles(bars)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Column(
      children: [
        // 현재 종목 · 고른 구간
        Container(
          margin: const EdgeInsets.only(top: 8, bottom: 8),
          decoration: BoxDecoration(
            color: palette.cardBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: palette.border),
          ),
          clipBehavior: Clip.hardEdge,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                decoration: BoxDecoration(
                    border:
                        Border(bottom: BorderSide(color: palette.border))),
                child: Row(children: [
                  Text('현재 종목 · 고른 구간',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: palette.primary)),
                ]),
              ),
              _miniChart(widget.queryBars),
            ],
          ),
        ),
        // 사례 종목 · 유사 구간 + 이후
        Container(
          decoration: BoxDecoration(
            color: palette.cardBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: palette.border),
          ),
          clipBehavior: Clip.hardEdge,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                decoration: BoxDecoration(
                    border:
                        Border(bottom: BorderSide(color: palette.border))),
                child: Row(children: [
                  Expanded(
                    child: Text(
                      '${widget.caseStock.stockName ?? widget.caseStock.stockCode} · 유사 구간 + 이후',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: palette.body),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (widget.caseStock.forwardReturn != null)
                    Text(
                      _fmtPct(widget.caseStock.forwardReturn),
                      style: monoStyle(
                          size: 12,
                          color: (widget.caseStock.forwardReturn! >= 0)
                              ? palette.tradingUp
                              : palette.tradingDown,
                          weight: FontWeight.w700),
                    ),
                ]),
              ),
              if (_loading)
                SizedBox(
                  height: 180,
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(palette.primary)),
                        ),
                        const SizedBox(width: 8),
                          Text('차트 불러오는 중…',
                            style:
                                TextStyle(fontSize: 12, color: palette.muted)),
                      ],
                    ),
                  ),
                )
              else if (_error)
                SizedBox(
                  height: 180,
                  child: Center(
                    child: Text('차트를 불러오지 못했습니다.',
                        style: TextStyle(
                            fontSize: 12, color: palette.tradingDown)),
                  ),
                )
              else
                _miniChart(_caseBars ?? []),
              if (!_loading && !_error)
                Container(
                  padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
                  decoration: BoxDecoration(
                      border:
                          Border(top: BorderSide(color: palette.border))),
                  child: Text(
                    '왼쪽이 현재 종목과 유사한 구간, 오른쪽이 실제로 흘러간 흐름입니다.',
                    style: TextStyle(fontSize: 11, color: palette.muted),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
