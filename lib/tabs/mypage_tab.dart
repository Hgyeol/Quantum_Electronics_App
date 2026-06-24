import 'package:flutter/material.dart';
import '../api/endpoints.dart';
import '../design/tokens.dart';

class MypageTab extends StatelessWidget {
  final VoidCallback onLogout;
  const MypageTab({super.key, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Container(
      color: palette.pageBg,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
        children: [
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
                      try { await logout(); } catch (_) {}
                      onLogout();
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: palette.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
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
