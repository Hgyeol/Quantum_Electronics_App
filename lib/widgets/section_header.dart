import 'package:flutter/material.dart';
import '../design/tokens.dart';

// 웹의 <header className="px-5 pt-4 pb-0 bg-white borderBottom"> 재현
class SectionHeader extends StatelessWidget {
  final List<Widget> tabs;
  final Widget? trailing;
  final int selectedIndex;
  final void Function(int) onTabSelected;

  const SectionHeader({
    super.key,
    required this.tabs,
    required this.selectedIndex,
    required this.onTabSelected,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Container(
      color: palette.cardBg,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailing != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  kHeaderPaddingH, 14, kHeaderPaddingH, 8),
              child: Row(
                children: [const Spacer(), trailing!],
              ),
            ),
          // 탭 행
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(tabs.length, (i) {
                final isActive = i == selectedIndex;
                return GestureDetector(
                  onTap: () => onTabSelected(i),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: isActive ? palette.ink : Colors.transparent,
                          width: 2,
                        ),
                      ),
                    ),
                    child: DefaultTextStyle(
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight:
                            isActive ? FontWeight.w700 : FontWeight.w500,
                        color: isActive ? palette.ink : palette.mutedStrong,
                      ),
                      child: tabs[i],
                    ),
                  ),
                );
              }),
            ),
          ),
          // 구분선
          Container(height: 1, color: palette.border),
        ],
      ),
    );
  }
}

// 상태 배지 (실시간 / 15초 갱신)
class RealtimeBadge extends StatelessWidget {
  final bool connected;
  const RealtimeBadge({super.key, required this.connected});

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    if (!connected) return const SizedBox.shrink();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _PulseDot(color: palette.tradingUp),
        const SizedBox(width: 4),
        Text(
          '실시간',
          style: TextStyle(
            fontSize: 12,
            color: palette.tradingUp,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class RefreshBadge extends StatelessWidget {
  final bool refreshing;
  final DateTime? lastUpdated;
  const RefreshBadge({super.key, required this.refreshing, this.lastUpdated});

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (refreshing) ...[
          SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(
              strokeWidth: 1.5,
              color: palette.muted,
              backgroundColor: palette.border,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '갱신 중',
            style: TextStyle(fontSize: 12, color: palette.muted),
          ),
        ] else ...[
          _PulseDot(color: palette.tradingUp),
          const SizedBox(width: 4),
          Text(
            '15초 갱신',
            style: TextStyle(
              fontSize: 12,
              color: palette.mutedStrong,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
        if (lastUpdated != null) ...[
          const SizedBox(width: 6),
          Text(
            '${lastUpdated!.hour.toString().padLeft(2, '0')}:'
            '${lastUpdated!.minute.toString().padLeft(2, '0')}:'
            '${lastUpdated!.second.toString().padLeft(2, '0')}',
            style: TextStyle(
              fontSize: 12,
              color: palette.muted,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ],
    );
  }
}

class _PulseDot extends StatefulWidget {
  final Color color;
  const _PulseDot({required this.color});

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1000))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) => Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.color.withAlpha(
              ((_ctrl.value * 0.6 + 0.4) * 255).round()),
        ),
      ),
    );
  }
}
