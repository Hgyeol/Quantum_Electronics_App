class WatchlistItem {
  final String stockCode;
  final String? stockName;
  final double? price;
  final double? change;
  final double? changeRate;
  final int? volume;
  final double? tradeValue;

  WatchlistItem({
    required this.stockCode,
    this.stockName,
    this.price,
    this.change,
    this.changeRate,
    this.volume,
    this.tradeValue,
  });

  factory WatchlistItem.fromJson(Map<String, dynamic> j) => WatchlistItem(
        stockCode: j['stock_code'] as String,
        stockName: j['stock_name'] as String?,
        price: (j['price'] as num?)?.toDouble(),
        change: (j['change'] as num?)?.toDouble(),
        changeRate: (j['change_rate'] as num?)?.toDouble(),
        volume: j['volume'] as int?,
        tradeValue: (j['trade_value'] as num?)?.toDouble(),
      );
}

class LiveTick {
  final String stockCode;
  final double price;
  final double change;
  final double changeRate;
  final int? volume;

  LiveTick({
    required this.stockCode,
    required this.price,
    required this.change,
    required this.changeRate,
    this.volume,
  });

  factory LiveTick.fromJson(Map<String, dynamic> j) => LiveTick(
        stockCode: j['stock_code'] as String,
        price: (j['price'] as num).toDouble(),
        change: (j['change'] as num).toDouble(),
        changeRate: (j['change_rate'] as num).toDouble(),
        volume: j['volume'] as int?,
      );
}

class RankItem {
  final int rank;
  final String stockCode;
  final String stockName;
  final double price;
  final double change;
  final double changeRate;
  final int volume;
  final double tradeValue;
  final double extraValue;

  RankItem({
    required this.rank,
    required this.stockCode,
    required this.stockName,
    required this.price,
    required this.change,
    required this.changeRate,
    required this.volume,
    required this.tradeValue,
    required this.extraValue,
  });

  factory RankItem.fromJson(Map<String, dynamic> j) => RankItem(
        rank: j['rank'] as int,
        stockCode: j['stock_code'] as String,
        stockName: j['stock_name'] as String,
        price: (j['price'] as num).toDouble(),
        change: (j['change'] as num).toDouble(),
        changeRate: (j['change_rate'] as num).toDouble(),
        volume: j['volume'] as int,
        tradeValue: (j['trade_value'] as num).toDouble(),
        extraValue: (j['extra_value'] as num).toDouble(),
      );
}

class ScreenerResult {
  final String stockCode;
  final String stockName;
  final double close;
  final int volume;
  final List<String> matchedConditions;

  ScreenerResult({
    required this.stockCode,
    required this.stockName,
    required this.close,
    required this.volume,
    required this.matchedConditions,
  });

  factory ScreenerResult.fromJson(Map<String, dynamic> j) => ScreenerResult(
        stockCode: j['stock_code'] as String,
        stockName: j['stock_name'] as String,
        close: (j['close'] as num).toDouble(),
        volume: j['volume'] as int,
        matchedConditions: List<String>.from(j['matched_conditions'] as List),
      );
}

class SectorItem {
  final String sector;
  final int stockCount;

  SectorItem({required this.sector, required this.stockCount});

  factory SectorItem.fromJson(Map<String, dynamic> j) => SectorItem(
        sector: j['sector'] as String,
        stockCount: j['stock_count'] as int,
      );
}

class SectorPick {
  final String stockCode;
  final String name;
  final String market;
  final double close;
  final double changeRate;
  final double score;

  SectorPick({
    required this.stockCode,
    required this.name,
    required this.market,
    required this.close,
    required this.changeRate,
    required this.score,
  });

  factory SectorPick.fromJson(Map<String, dynamic> j) => SectorPick(
        stockCode: j['stock_code'] as String,
        name: j['name'] as String,
        market: j['market'] as String,
        close: (j['close'] as num).toDouble(),
        changeRate: (j['change_rate'] as num).toDouble(),
        score: (j['score'] as num).toDouble(),
      );
}

class StockSearchResult {
  final String stockCode;
  final String corpName;

  StockSearchResult({required this.stockCode, required this.corpName});

  factory StockSearchResult.fromJson(Map<String, dynamic> j) =>
      StockSearchResult(
        stockCode: j['stock_code'] as String,
        corpName: j['corp_name'] as String,
      );
}

class OHLCVBar {
  final String date;
  final double open;
  final double high;
  final double low;
  final double close;
  final int volume;

  OHLCVBar({
    required this.date,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    required this.volume,
  });

  factory OHLCVBar.fromJson(Map<String, dynamic> j) => OHLCVBar(
        date: j['date'] as String,
        open: (j['open'] as num).toDouble(),
        high: (j['high'] as num).toDouble(),
        low: (j['low'] as num).toDouble(),
        close: (j['close'] as num).toDouble(),
        volume: j['volume'] as int,
      );
}

class MarketQuote {
  final double price;
  final double change;
  final double changeRate;
  final double? high;
  final double? low;
  final int? volume;
  final double? w52High;
  final double? w52Low;

  MarketQuote({
    required this.price,
    required this.change,
    required this.changeRate,
    this.high,
    this.low,
    this.volume,
    this.w52High,
    this.w52Low,
  });

  factory MarketQuote.fromJson(Map<String, dynamic> j) => MarketQuote(
        price: (j['price'] as num).toDouble(),
        change: (j['change'] as num).toDouble(),
        changeRate: (j['change_rate'] as num).toDouble(),
        high: (j['high'] as num?)?.toDouble(),
        low: (j['low'] as num?)?.toDouble(),
        volume: j['volume'] as int?,
        w52High: (j['w52_high'] as num?)?.toDouble(),
        w52Low: (j['w52_low'] as num?)?.toDouble(),
      );
}

class ScoreBreakdown {
  final int quantScore;
  final int aiScore;
  final int financialScore;
  final int totalScore;
  final String direction;

  ScoreBreakdown({
    required this.quantScore,
    required this.aiScore,
    required this.financialScore,
    required this.totalScore,
    required this.direction,
  });

  factory ScoreBreakdown.fromJson(Map<String, dynamic> j) => ScoreBreakdown(
        quantScore: (j['quant_score'] as num).toInt(),
        aiScore: (j['ai_score'] as num).toInt(),
        financialScore: (j['financial_score'] as num).toInt(),
        totalScore: (j['total_score'] as num).toInt(),
        direction: (j['direction'] as String?) ?? 'neutral',
      );
}

class AISignal {
  final String label;
  final String direction;
  final int score;
  final String? summary;
  final double? confidence;

  AISignal({
    required this.label,
    required this.direction,
    required this.score,
    this.summary,
    this.confidence,
  });

  factory AISignal.fromJson(Map<String, dynamic> j) => AISignal(
        label: (j['label'] as String?) ?? '',
        direction: (j['direction'] as String?) ?? 'neutral',
        score: (j['score'] as num).toInt(),
        summary: j['summary'] as String?,
        confidence: (j['confidence'] as num?)?.toDouble(),
      );
}

class QuantSignal {
  final String label;
  final String direction;
  final int score;
  final String? value;

  QuantSignal({
    required this.label,
    required this.direction,
    required this.score,
    this.value,
  });

  factory QuantSignal.fromJson(Map<String, dynamic> j) => QuantSignal(
        label: (j['label'] as String?) ?? '',
        direction: (j['direction'] as String?) ?? 'neutral',
        score: (j['score'] as num).toInt(),
        value: j['value']?.toString(),
      );
}

class FinancialSignal {
  final String label;
  final String direction;
  final int score;
  final String? reason;

  FinancialSignal({
    required this.label,
    required this.direction,
    required this.score,
    this.reason,
  });

  factory FinancialSignal.fromJson(Map<String, dynamic> j) => FinancialSignal(
        label: (j['label'] as String?) ?? '',
        direction: (j['direction'] as String?) ?? 'neutral',
        score: (j['score'] as num).toInt(),
        reason: j['reason'] as String?,
      );
}

class Evidence {
  final String evidenceId;
  final String kind; // 'news' | 'disclosure' | 'financial' | 'market' | 'quant'
  final String source;
  final String title;
  final String? publishedAt;
  final String? url;

  Evidence({
    required this.evidenceId,
    required this.kind,
    required this.source,
    required this.title,
    this.publishedAt,
    this.url,
  });

  factory Evidence.fromJson(Map<String, dynamic> j) => Evidence(
        evidenceId: (j['evidence_id'] as String?) ?? '',
        kind: (j['kind'] as String?) ?? 'quant',
        source: (j['source'] as String?) ?? '',
        title: (j['title'] as String?) ?? '',
        publishedAt: j['published_at'] as String?,
        url: j['url'] as String?,
      );
}

class OutlookReport {
  final String stockCode;
  final String? stockName;
  final String? generatedAt;
  final String? summary;
  final ScoreBreakdown? score;
  final List<QuantSignal> quantSignals;
  final List<AISignal> aiSignals;
  final List<FinancialSignal> financialSignals;
  final List<Evidence> evidence;
  final MarketQuote? marketQuote;

  OutlookReport({
    required this.stockCode,
    this.stockName,
    this.generatedAt,
    this.summary,
    this.score,
    required this.quantSignals,
    required this.aiSignals,
    required this.financialSignals,
    this.evidence = const [],
    this.marketQuote,
  });

  factory OutlookReport.fromJson(Map<String, dynamic> j) => OutlookReport(
        stockCode: j['stock_code'] as String,
        stockName: j['stock_name'] as String?,
        generatedAt: j['generated_at'] as String?,
        summary: j['summary'] as String?,
        score: j['score'] != null
            ? ScoreBreakdown.fromJson(j['score'] as Map<String, dynamic>)
            : null,
        quantSignals: (j['quant_signals'] as List? ?? [])
            .map((e) => QuantSignal.fromJson(e as Map<String, dynamic>))
            .toList(),
        aiSignals: (j['ai_signals'] as List? ?? [])
            .map((e) => AISignal.fromJson(e as Map<String, dynamic>))
            .toList(),
        financialSignals: (j['financial_signals'] as List? ?? [])
            .map((e) => FinancialSignal.fromJson(e as Map<String, dynamic>))
            .toList(),
        evidence: (j['evidence'] as List? ?? [])
            .map((e) => Evidence.fromJson(e as Map<String, dynamic>))
            .toList(),
        marketQuote: j['market_quote'] != null
            ? MarketQuote.fromJson(j['market_quote'] as Map<String, dynamic>)
            : null,
      );
}

class SimilarCase {
  final String stockCode;
  final String? stockName;
  final String startDate;
  final String endDate;
  final double similarity;
  final double? forwardReturn;
  final List<double> windowCloses;
  final List<double> forwardCloses;

  SimilarCase({
    required this.stockCode,
    this.stockName,
    required this.startDate,
    required this.endDate,
    required this.similarity,
    this.forwardReturn,
    required this.windowCloses,
    required this.forwardCloses,
  });

  factory SimilarCase.fromJson(Map<String, dynamic> j) => SimilarCase(
        stockCode: (j['stock_code'] as String?) ?? '',
        stockName: j['stock_name'] as String?,
        startDate: (j['start_date'] as String?) ?? '',
        endDate: (j['end_date'] as String?) ?? '',
        similarity: (j['similarity'] as num?)?.toDouble() ?? 0,
        forwardReturn: (j['forward_return'] as num?)?.toDouble(),
        windowCloses: (j['window_closes'] as List? ?? [])
            .map((e) => (e as num).toDouble())
            .toList(),
        forwardCloses: (j['forward_closes'] as List? ?? [])
            .map((e) => (e as num).toDouble())
            .toList(),
      );
}

class PatternMatchResult {
  final String stockCode;
  final String queryStart;
  final String queryEnd;
  final int windowLength;
  final int horizon;
  final List<SimilarCase> cases;
  final Map<String, double?> stats;

  PatternMatchResult({
    required this.stockCode,
    required this.queryStart,
    required this.queryEnd,
    required this.windowLength,
    required this.horizon,
    required this.cases,
    required this.stats,
  });

  factory PatternMatchResult.fromJson(Map<String, dynamic> j) =>
      PatternMatchResult(
        stockCode: (j['query_stock_code'] as String?) ?? '',
        queryStart: (j['query_start'] as String?) ?? '',
        queryEnd: (j['query_end'] as String?) ?? '',
        windowLength: j['window_length'] as int? ?? 0,
        horizon: j['horizon'] as int? ?? 20,
        cases: (j['cases'] as List? ?? [])
            .map((e) => SimilarCase.fromJson(e as Map<String, dynamic>))
            .toList(),
        stats: Map<String, double?>.fromEntries(
          (j['stats'] as Map<String, dynamic>? ?? {}).entries.map(
            (e) => MapEntry(e.key, (e.value as num?)?.toDouble()),
          ),
        ),
      );
}

class Level {
  final double price;
  final String? source;
  final String? strength;
  Level({required this.price, this.source, this.strength});
  factory Level.fromJson(Map<String, dynamic> j) => Level(
        price: (j['price'] as num).toDouble(),
        source: j['source'] as String?,
        strength: j['strength'] as String?,
      );
}

class EntryExitSignal {
  final String action;
  final String confidence;
  final double? entryZoneLow;
  final double? entryZoneHigh;
  final double? primaryTarget;
  final double? secondaryTarget;
  final double? stopLoss;
  final double? riskRewardRatio;
  final List<String> reasoning;

  EntryExitSignal({
    required this.action,
    required this.confidence,
    this.entryZoneLow,
    this.entryZoneHigh,
    this.primaryTarget,
    this.secondaryTarget,
    this.stopLoss,
    this.riskRewardRatio,
    this.reasoning = const [],
  });

  factory EntryExitSignal.fromJson(Map<String, dynamic> j) => EntryExitSignal(
        action: j['action'] as String,
        confidence: j['confidence'] as String,
        entryZoneLow: (j['entry_zone_low'] as num?)?.toDouble(),
        entryZoneHigh: (j['entry_zone_high'] as num?)?.toDouble(),
        primaryTarget: (j['primary_target'] as num?)?.toDouble(),
        secondaryTarget: (j['secondary_target'] as num?)?.toDouble(),
        stopLoss: (j['stop_loss'] as num?)?.toDouble(),
        riskRewardRatio: (j['risk_reward_ratio'] as num?)?.toDouble(),
        reasoning: List<String>.from(j['reasoning'] as List? ?? []),
      );
}

class ChartAnalysis {
  final String stockCode;
  final String? stockName;
  final double currentPrice;
  final int analysisPeriodDays;
  final List<OHLCVBar> ohlcv;
  final List<Level> supportLevels;
  final List<Level> resistanceLevels;
  final EntryExitSignal? signal;

  ChartAnalysis({
    required this.stockCode,
    this.stockName,
    required this.currentPrice,
    this.analysisPeriodDays = 365,
    required this.ohlcv,
    this.supportLevels = const [],
    this.resistanceLevels = const [],
    this.signal,
  });

  factory ChartAnalysis.fromJson(Map<String, dynamic> j) => ChartAnalysis(
        stockCode: j['stock_code'] as String,
        stockName: j['stock_name'] as String?,
        currentPrice: (j['current_price'] as num).toDouble(),
        analysisPeriodDays: j['analysis_period_days'] as int? ?? 365,
        ohlcv: (j['ohlcv'] as List)
            .map((e) => OHLCVBar.fromJson(e as Map<String, dynamic>))
            .toList(),
        supportLevels: (j['support_levels'] as List? ?? [])
            .map((e) => Level.fromJson(e as Map<String, dynamic>))
            .toList(),
        resistanceLevels: (j['resistance_levels'] as List? ?? [])
            .map((e) => Level.fromJson(e as Map<String, dynamic>))
            .toList(),
        signal: j['signal'] != null
            ? EntryExitSignal.fromJson(j['signal'] as Map<String, dynamic>)
            : null,
      );
}
