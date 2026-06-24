import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../design/tokens.dart';
import '../providers/theme_provider.dart';

/// ThemeToggle 위에 떠 있는 일반 ↔ 큰글씨 토글 (웹 CenturyToggle.tsx와 1:1).
class CenturyToggle extends ConsumerWidget {
  const CenturyToggle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeProvider);
    final isCentury = theme.font == FontMode.century;
    final palette = AppPalette.of(context);

    // 웹: 일반일 때 🔎 + "큰글씨", century일 때 🖥 + "일반"
    final emoji = isCentury ? '🖥' : '🔎';
    final label = isCentury ? '일반' : '큰글씨';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => ref.read(themeProvider.notifier).toggleCentury(),
        customBorder: const CircleBorder(),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: isCentury ? palette.elevatedBg : palette.cardBg,
            shape: BoxShape.circle,
            border: Border.all(color: palette.borderMd, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          alignment: Alignment.center,
          // 토글 안 글씨는 textScaler 영향을 받지 않게 고정 (button 자체가 1.3배로 다시 부풀지 않도록).
          child: MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(1.0)),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  emoji,
                  style: const TextStyle(fontSize: 14, height: 1.0),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                    color: palette.ink,
                    height: 1.0,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
