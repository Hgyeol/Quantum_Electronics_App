import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/endpoints.dart';
import '../design/tokens.dart';
import '../providers/theme_provider.dart';

class MypageTab extends ConsumerWidget {
  final VoidCallback onLogout;
  const MypageTab({super.key, required this.onLogout});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = AppPalette.of(context);
    final isDark = ref.watch(themeProvider).mode == AppThemeMode.dark;

    return Container(
      color: palette.pageBg,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
        children: [
          // ── 화면 설정 ──
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: palette.cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: palette.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('화면 설정',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: palette.ink)),
                const SizedBox(height: 6),
                Text('화면 테마를 선택하세요.',
                    style: TextStyle(fontSize: 13, color: palette.mutedStrong)),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Icon(
                      isDark
                          ? Icons.dark_mode_rounded
                          : Icons.light_mode_rounded,
                      size: 22,
                      color: palette.ink,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        isDark ? '다크 모드' : '라이트 모드',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: palette.ink,
                        ),
                      ),
                    ),
                    Switch(
                      value: isDark,
                      activeThumbColor: palette.primary,
                      onChanged: (v) => ref
                          .read(themeProvider.notifier)
                          .setMode(
                              v ? AppThemeMode.dark : AppThemeMode.light),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // ── 계정 ──
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: palette.cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: palette.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('마이페이지',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: palette.ink)),
                const SizedBox(height: 6),
                Text('계정 관련 작업을 여기서 관리합니다.',
                    style: TextStyle(fontSize: 13, color: palette.mutedStrong)),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: FilledButton(
                    onPressed: () async {
                      try {
                        await logout();
                      } catch (_) {}
                      onLogout();
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: palette.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      textStyle: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w800),
                    ),
                    child: const Text('로그아웃'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          Center(
            child: Text('Quantum Electronics',
                style: TextStyle(fontSize: 11, color: palette.muted)),
          ),
        ],
      ),
    );
  }
}
