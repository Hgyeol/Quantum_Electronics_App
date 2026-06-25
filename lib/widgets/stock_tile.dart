import 'package:flutter/material.dart';
import '../api/models.dart';
import '../design/tokens.dart';
import 'change_badge.dart';
import 'stock_logo.dart';

String _fmtPrice(double p) => p
    .toStringAsFixed(0)
    .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

String _fmtVolume(int v) =>
    v.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

class StockTile extends StatelessWidget {
  final String code;
  final String? name;
  final double? price;
  final double? changeRate;
  final String? extraValue;
  final int? rank;
  final List<String> matchedConditions;
  final bool isActive;
  final VoidCallback? onTap;

  const StockTile({
    super.key,
    required this.code,
    this.name,
    this.price,
    this.changeRate,
    this.extraValue,
    this.rank,
    this.matchedConditions = const [],
    this.isActive = false,
    this.onTap,
  });

  factory StockTile.fromWatchlistItem(WatchlistItem item,
      {bool isActive = false, VoidCallback? onTap}) =>
      StockTile(
        code: item.stockCode,
        name: item.stockName,
        price: item.price,
        changeRate: item.changeRate,
        isActive: isActive,
        onTap: onTap,
      );

  factory StockTile.fromRankItem(RankItem item,
      {String? extraValue, VoidCallback? onTap}) =>
      StockTile(
        code: item.stockCode,
        name: item.stockName,
        price: item.price,
        changeRate: item.changeRate,
        rank: item.rank,
        extraValue: extraValue,
        onTap: onTap,
      );

  factory StockTile.fromScreenerResult(ScreenerResult item,
      {VoidCallback? onTap}) =>
      StockTile(
        code: item.stockCode,
        name: item.stockName,
        price: item.close,
        changeRate: null,
        extraValue: '${_fmtVolume(item.volume)}주',
        matchedConditions: item.matchedConditions,
        onTap: onTap,
      );

  factory StockTile.fromSectorPick(SectorPick item,
      {int? rank, VoidCallback? onTap}) =>
      StockTile(
        code: item.stockCode,
        name: item.name,
        price: item.close,
        changeRate: item.changeRate,
        rank: rank,
        onTap: onTap,
      );

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Material(
      color: isActive ? palette.primary.withAlpha(15) : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: palette.hover,
        highlightColor: palette.hover,
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: kRowPaddingH, vertical: kRowPaddingV),
          child: Row(
            children: [
              // 순위 번호 (있을 때만)
              if (rank != null) ...[
                SizedBox(
                  width: 28,
                  child: Text(
                    '$rank',
                    style: monoStyle(
                      size: 14,
                      color: rank! <= 3 ? palette.primary : palette.muted,
                      weight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              // 종목 로고
              StockLogo(code: code, name: name, size: 40),
              const SizedBox(width: 12),
              // 종목명 + 코드
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name ?? code,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isActive ? palette.primary : palette.ink,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 1),
                    Text(
                      code,
                      style: monoStyle(
                          size: 12, color: palette.muted, weight: FontWeight.w400),
                    ),
                    if (matchedConditions.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: matchedConditions
                            .take(3)
                            .map((c) => Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: palette.primary.withAlpha(20),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    c,
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: palette.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ))
                            .toList(),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // 가격 + 등락률/부가정보
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: price != null ? _fmtPrice(price!) : '—',
                          style: monoStyle(size: 15, color: palette.ink),
                        ),
                        if (price != null)
                          TextSpan(
                            text: '원',
                            style: TextStyle(
                              fontSize: 11,
                              color: palette.muted,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 3),
                  if (extraValue != null && changeRate == null)
                    Text(
                      extraValue!,
                      style: monoStyle(
                          size: 13,
                          color: palette.mutedStrong,
                          weight: FontWeight.w400),
                    )
                  else
                    ChangeBadge(rate: changeRate),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// 컬럼 헤더 행
class StockListHeader extends StatelessWidget {
  final bool hasRank;
  final String priceLabel;
  final String changeLabel;
  final String? extraLabel;

  const StockListHeader({
    super.key,
    this.hasRank = false,
    this.priceLabel = '현재가',
    this.changeLabel = '등락률',
    this.extraLabel,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Container(
      color: palette.bgSubtle,
      padding: const EdgeInsets.symmetric(
          horizontal: kRowPaddingH, vertical: 8),
      child: Row(
        children: [
          if (hasRank) const SizedBox(width: 36),
          const SizedBox(width: 52),
          Expanded(
            child: Text(
              '종목명',
              style: TextStyle(
                fontSize: 10,
                color: palette.muted,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(width: 8),
          if (extraLabel != null) ...[
            SizedBox(
              width: 96,
              child: Text(
                extraLabel!,
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 10,
                  color: palette.muted,
                  letterSpacing: 1.0,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ] else ...[
            SizedBox(
              width: 96,
              child: Text(
                priceLabel,
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 10,
                  color: palette.muted,
                  letterSpacing: 1.0,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          SizedBox(
            width: 88,
            child: Text(
              changeLabel,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 10,
                color: palette.muted,
                letterSpacing: 1.0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// 스켈레톤 행
class StockTileSkeleton extends StatelessWidget {
  final bool hasRank;
  const StockTileSkeleton({super.key, this.hasRank = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: kRowPaddingH, vertical: kRowPaddingV),
      child: Row(
        children: [
          if (hasRank) ...[
            const _Shimmer(width: 20, height: 14),
            const SizedBox(width: 8),
          ],
          const _Shimmer(width: 40, height: 40),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                _Shimmer(width: 100, height: 14),
                SizedBox(height: 4),
                _Shimmer(width: 48, height: 11),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: const [
              _Shimmer(width: 72, height: 14),
              SizedBox(height: 4),
              _Shimmer(width: 56, height: 22),
            ],
          ),
        ],
      ),
    );
  }
}

class _Shimmer extends StatefulWidget {
  final double width;
  final double height;
  const _Shimmer({required this.width, required this.height});

  @override
  State<_Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<_Shimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    // 다크/century에서도 자연스럽도록 토큰 기반 보간 색 두 단계.
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: Color.lerp(palette.hairline, palette.elevatedBg, _ctrl.value),
          borderRadius: BorderRadius.circular(
              widget.width == widget.height && widget.width == 40 ? 10 : 4),
        ),
      ),
    );
  }
}
