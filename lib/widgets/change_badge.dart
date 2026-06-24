import 'package:flutter/material.dart';
import '../design/tokens.dart';

class ChangeBadge extends StatelessWidget {
  final double? rate;
  const ChangeBadge({super.key, required this.rate});

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    if (rate == null) {
      return Text(
        '—',
        style: monoStyle(size: 15, color: palette.muted, weight: FontWeight.w400),
      );
    }
    final Color color;
    final Color bg;
    final String sign;
    if (rate! > 0) {
      color = palette.tradingUp;
      bg = palette.tradingUp.withAlpha(26); // 10%
      sign = '+';
    } else if (rate! < 0) {
      color = palette.tradingDown;
      bg = palette.tradingDown.withAlpha(26);
      sign = '';
    } else {
      color = palette.muted;
      bg = palette.bgMuted;
      sign = '';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(9999),
      ),
      child: Text(
        '$sign${rate!.toStringAsFixed(2)}%',
        style: monoStyle(size: 15, color: color, weight: FontWeight.w700),
      ),
    );
  }
}
