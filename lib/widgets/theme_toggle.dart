import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../design/tokens.dart';
import '../providers/theme_provider.dart';

/// 우측 하단에 떠 있는 라이트 ↔ 다크 토글 (웹 ThemeToggle.tsx와 1:1).
class ThemeToggle extends ConsumerWidget {
  const ThemeToggle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeProvider);
    final isDark = theme.mode == AppThemeMode.dark;
    final palette = AppPalette.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => ref.read(themeProvider.notifier).toggleTheme(),
        customBorder: const CircleBorder(),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: isDark ? palette.elevatedBg : palette.cardBg,
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
          child: Icon(
            isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
            color: palette.ink,
            size: 20,
          ),
        ),
      ),
    );
  }
}
