import 'package:dio/dio.dart';

import 'models.dart';
import 'client.dart';

// ── 인증 ──────────────────────────────────────────────────────────────────────

Future<bool> checkAuth() async {
  try {
    final res = await api.dio.get('/auth/me');
    return res.statusCode == 200;
  } catch (_) {
    return false;
  }
}

Future<void> login(String username, String password) async {
  await api.dio.post('/auth/login', data: {
    'username': username,
    'password': password,
  });
}

Future<void> logout() async {
  await api.dio.post('/auth/logout');
}

// ── 관심종목 ──────────────────────────────────────────────────────────────────

Future<List<String>> fetchWatchlistCodes() async {
  final res = await api.dio.get('/me/watchlist');
  return List<String>.from(res.data as List);
}

Future<void> saveWatchlistCodes(List<String> codes) async {
  await api.dio.post('/me/watchlist', data: {'codes': codes});
}

Future<List<WatchlistItem>> fetchWatchlistItems(List<String> codes) async {
  if (codes.isEmpty) return [];
  final res = await api.dio.get('/watchlist',
      queryParameters: {'codes': codes.join(',')});
  return (res.data as List)
      .map((e) => WatchlistItem.fromJson(e as Map<String, dynamic>))
      .toList();
}

// ── 시장 순위 ─────────────────────────────────────────────────────────────────

Future<List<RankItem>> fetchVolumeRanking(String sort,
    {int limit = 30}) async {
  final res = await api.dio.get('/ranking/volume',
      queryParameters: {'sort': sort, 'limit': limit});
  return (res.data as List)
      .map((e) => RankItem.fromJson(e as Map<String, dynamic>))
      .toList();
}

Future<List<RankItem>> fetchFluctuationRanking({int limit = 30}) async {
  final res = await api.dio.get('/ranking/fluctuation',
      queryParameters: {'limit': limit});
  return (res.data as List)
      .map((e) => RankItem.fromJson(e as Map<String, dynamic>))
      .toList();
}

Future<List<RankItem>> fetchForeignRanking(String investor,
    {int limit = 30}) async {
  final res = await api.dio.get('/ranking/foreign',
      queryParameters: {'investor': investor, 'limit': limit});
  return (res.data as List)
      .map((e) => RankItem.fromJson(e as Map<String, dynamic>))
      .toList();
}

// ── 스크리너 ──────────────────────────────────────────────────────────────────

Future<List<ScreenerResult>> fetchScreener(
    List<String> conditions, Map<String, dynamic> params) async {
  final res = await api.dio.get('/screener', queryParameters: {
    'conditions': conditions.join(','),
    if (params.isNotEmpty) 'params': _jsonEncode(params),
  });
  return (res.data as List)
      .map((e) => ScreenerResult.fromJson(e as Map<String, dynamic>))
      .toList();
}

String _jsonEncode(Map<String, dynamic> m) {
  final buf = StringBuffer('{');
  var first = true;
  m.forEach((k, v) {
    if (!first) buf.write(',');
    buf.write('"$k":$v');
    first = false;
  });
  buf.write('}');
  return buf.toString();
}

// ── 업종 ──────────────────────────────────────────────────────────────────────

Future<List<SectorItem>> fetchSectors() async {
  final res = await api.dio.get('/sectors');
  return (res.data as List)
      .map((e) => SectorItem.fromJson(e as Map<String, dynamic>))
      .toList();
}

Future<List<SectorPick>> fetchSectorPicks(String sector) async {
  final res = await api.dio.get(
      '/sectors/${Uri.encodeComponent(sector)}/picks');
  return (res.data as List)
      .map((e) => SectorPick.fromJson(e as Map<String, dynamic>))
      .toList();
}

// ── 검색 ──────────────────────────────────────────────────────────────────────

Future<List<StockSearchResult>> searchStocks(String query) async {
  final res = await api.dio.get('/search', queryParameters: {'q': query});
  return (res.data as List)
      .map((e) => StockSearchResult.fromJson(e as Map<String, dynamic>))
      .toList();
}

// ── 차트 ──────────────────────────────────────────────────────────────────────

Future<ChartAnalysis> fetchChart(String code, {int days = 365}) async {
  final res = await api.dio.get('/chart/$code',
      queryParameters: {'days': days});
  return ChartAnalysis.fromJson(res.data as Map<String, dynamic>);
}

// ── 시세 ──────────────────────────────────────────────────────────────────────

Future<MarketQuote> fetchQuote(String code) async {
  final res = await api.dio.get('/quote/$code');
  return MarketQuote.fromJson(res.data as Map<String, dynamic>);
}

// ── 전망 분석 ─────────────────────────────────────────────────────────────────

Future<OutlookReport> fetchOutlook(String code) async {
  final res = await api.dio.get(
    '/outlook/stock/$code',
    options: Options(receiveTimeout: const Duration(seconds: 60)),
  );
  return OutlookReport.fromJson(res.data as Map<String, dynamic>);
}

// ── 유사 패턴 ─────────────────────────────────────────────────────────────────

Future<PatternMatchResult> fetchSimilarPatterns(
  String code, {
  required String start,
  required String end,
  int horizon = 20,
  int topK = 10,
  String metric = 'dtw',
  double minSimilarity = 0,
}) async {
  final res = await api.dio.get('/chart/$code/similar', queryParameters: {
    'start': start,
    'end': end,
    'horizon': horizon,
    'top_k': topK,
    'metric': metric,
    'min_similarity': minSimilarity,
  });
  return PatternMatchResult.fromJson(res.data as Map<String, dynamic>);
}
