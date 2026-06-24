import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../design/tokens.dart';
import '../tabs/watchlist_tab.dart';
import '../tabs/ranking_tab.dart';
import '../tabs/screener_tab.dart';
import '../tabs/sector_tab.dart';
import '../tabs/mypage_tab.dart';
import '../widgets/search_button.dart';
import 'stock_detail_screen.dart';

const _navItems = [
  (Icons.bookmark_border_rounded, Icons.bookmark_rounded, '관심종목'),
  (Icons.bar_chart_outlined,      Icons.bar_chart,        '시장현황'),
  (Icons.tune_outlined,           Icons.tune,             '조건검색'),
  (Icons.category_outlined,       Icons.category,         '업종추천'),
  (Icons.person_outline,          Icons.person,           '마이페이지'),
];

const _titles = ['관심종목', '시장현황', '조건 검색식', '업종 추천', '마이페이지'];

class HomeScreen extends ConsumerStatefulWidget {
  final VoidCallback onLogout;
  const HomeScreen({super.key, required this.onLogout});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _tab = 1;

  void _goDetail(String code, String name) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StockDetailScreen(code: code, name: name),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Scaffold(
      backgroundColor: palette.pageBg,
      appBar: AppBar(
        toolbarHeight: 48,
        backgroundColor: palette.cardBg,
        surfaceTintColor: palette.cardBg,
        elevation: 0,
        title: Text(
          _titles[_tab],
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: palette.ink,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Container(
            decoration: BoxDecoration(
              color: palette.cardBg,
              border: Border(bottom: BorderSide(color: palette.border)),
            ),
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: SearchButton(onSelect: _goDetail),
          ),
        ),
      ),
      body: IndexedStack(
        index: _tab,
        children: [
          WatchlistTab(onSelect: _goDetail),
          RankingTab(onSelect: _goDetail),
          ScreenerTab(onSelect: _goDetail),
          SectorTab(onSelect: _goDetail),
          MypageTab(onLogout: widget.onLogout),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: palette.cardBg,
          border: Border(top: BorderSide(color: palette.border)),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 60,
            child: Row(
              children: List.generate(_navItems.length, (i) {
                final active = i == _tab;
                final item = _navItems[i];
                return Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => setState(() => _tab = i),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          active ? item.$2 : item.$1,
                          size: 22,
                          color: active ? palette.primary : palette.muted,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          item.$3,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight:
                                active ? FontWeight.w700 : FontWeight.w400,
                            color: active ? palette.primary : palette.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}
