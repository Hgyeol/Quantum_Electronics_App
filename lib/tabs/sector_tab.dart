import 'package:flutter/material.dart';

import '../api/endpoints.dart';
import '../api/models.dart';
import '../design/tokens.dart';
import '../widgets/stock_tile.dart';

class _SectorMeta {
  final IconData icon;
  final Color color;
  const _SectorMeta(this.icon, this.color);
}

const _sectorMeta = <String, _SectorMeta>{
  '전기·전자': _SectorMeta(Icons.bolt_outlined, Color(0xFF3B82F6)),
  '제약': _SectorMeta(Icons.medication_outlined, Color(0xFF8B5CF6)),
  '화학': _SectorMeta(Icons.science_outlined, Color(0xFF10B981)),
  'IT 서비스': _SectorMeta(Icons.memory_outlined, Color(0xFF6366F1)),
  '금융': _SectorMeta(Icons.payments_outlined, Color(0xFFF59E0B)),
  '기타금융': _SectorMeta(Icons.account_balance_wallet_outlined, Color(0xFFF97316)),
  '건설': _SectorMeta(Icons.apartment_outlined, Color(0xFF78716C)),
  '운송·창고': _SectorMeta(Icons.local_shipping_outlined, Color(0xFF0EA5E9)),
  '운송장비·부품': _SectorMeta(Icons.directions_car_outlined, Color(0xFF64748B)),
  '음식료·담배': _SectorMeta(Icons.restaurant_outlined, Color(0xFFEF4444)),
  '의료·정밀기기': _SectorMeta(Icons.biotech_outlined, Color(0xFFEC4899)),
  '유통': _SectorMeta(Icons.storefront_outlined, Color(0xFF14B8A6)),
  '기계·장비': _SectorMeta(Icons.precision_manufacturing_outlined, Color(0xFF6B7280)),
  '금속': _SectorMeta(Icons.hardware_outlined, Color(0xFF9CA3AF)),
  '보험': _SectorMeta(Icons.shield_outlined, Color(0xFF2563EB)),
  '증권': _SectorMeta(Icons.show_chart_outlined, Color(0xFF16A34A)),
  '은행': _SectorMeta(Icons.account_balance_outlined, Color(0xFF1D4ED8)),
  '통신': _SectorMeta(Icons.wifi_tethering_outlined, Color(0xFF7C3AED)),
  '오락·문화': _SectorMeta(Icons.movie_outlined, Color(0xFFDB2777)),
  '일반서비스': _SectorMeta(Icons.business_center_outlined, Color(0xFF475569)),
  '섬유·의류': _SectorMeta(Icons.checkroom_outlined, Color(0xFFF43F5E)),
  '비금속': _SectorMeta(Icons.category_outlined, Color(0xFFA16207)),
  '부동산': _SectorMeta(Icons.home_work_outlined, Color(0xFF059669)),
  '종이·목재': _SectorMeta(Icons.forest_outlined, Color(0xFF15803D)),
  '전기·가스': _SectorMeta(Icons.electrical_services_outlined, Color(0xFFCA8A04)),
  '전기·가스·수도': _SectorMeta(Icons.electrical_services_outlined, Color(0xFFCA8A04)),
  '농업, 임업 및 어업': _SectorMeta(Icons.eco_outlined, Color(0xFF65A30D)),
  '기타제조': _SectorMeta(Icons.settings_outlined, Color(0xFF71717A)),
  '출판·매체복제': _SectorMeta(Icons.article_outlined, Color(0xFF7C3AED)),
};

const _groups = [
  ('IT·전자', ['전기·전자', 'IT 서비스', '통신', '오락·문화', '출판·매체복제']),
  ('제조업', ['화학', '기계·장비', '금속', '비금속', '종이·목재', '기타제조', '운송장비·부품', '섬유·의류']),
  ('바이오', ['제약', '의료·정밀기기']),
  ('금융', ['금융', '기타금융', '보험', '증권', '은행']),
  ('소비재', ['음식료·담배', '유통', '일반서비스']),
  ('인프라', ['건설', '부동산', '운송·창고', '전기·가스', '전기·가스·수도', '농업, 임업 및 어업']),
];

const _rankColors = [Color(0xFFF59E0B), Color(0xFF94A3B8), Color(0xFFC07940)];

class SectorTab extends StatefulWidget {
  final void Function(String code, String name) onSelect;
  const SectorTab({super.key, required this.onSelect});

  @override
  State<SectorTab> createState() => _SectorTabState();
}

class _SectorTabState extends State<SectorTab> {
  final _scrollController = ScrollController();
  List<SectorItem> _all = [];
  String? _selected;
  List<SectorPick> _picks = [];
  bool _loadingSectors = true;
  bool _loadingPicks = false;

  @override
  void initState() {
    super.initState();
    fetchSectors().then((s) {
      if (mounted) setState(() { _all = s; _loadingSectors = false; });
    }).catchError((_) {
      if (mounted) setState(() => _loadingSectors = false);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _select(String sector) async {
    if (_selected == sector) {
      setState(() { _selected = null; _picks = []; });
      return;
    }
    setState(() { _selected = sector; _loadingPicks = true; _picks = []; });
    try {
      final picks = await fetchSectorPicks(sector);
      if (!mounted) return;
      setState(() { _picks = picks; _loadingPicks = false; });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
          );
        }
      });
    } catch (_) {
      if (mounted) setState(() => _loadingPicks = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final sectorSet = {for (final s in _all) s.sector};
    final countMap = {for (final s in _all) s.sector: s.stockCount};

    return Container(
      color: palette.cardBg,
      child: _loadingSectors
          ? const _SkeletonChips()
          : ListView(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(kHeaderPaddingH, 18, kHeaderPaddingH, 28),
              children: [
                Text(
                  '업종을 선택하면 모멘텀 상위 3종목을 보여드려요.',
                  style: TextStyle(fontSize: 13, height: 1.45, color: palette.mutedStrong),
                ),
                const SizedBox(height: 18),
                ..._groups.map((g) {
                  final keys = g.$2.where(sectorSet.contains).toList();
                  if (keys.isEmpty) return const SizedBox.shrink();
                  return _GroupSection(
                    groupLabel: g.$1,
                    keys: keys,
                    countMap: countMap,
                    selected: _selected,
                    onSelect: _select,
                  );
                }),
                if (_selected != null) ...[
                  Container(height: 1, color: palette.border, margin: const EdgeInsets.symmetric(vertical: 10)),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(children: [
                      Icon(_sectorMeta[_selected!]?.icon ?? Icons.category_outlined,
                          size: 15, color: _sectorMeta[_selected!]?.color ?? palette.primary),
                      const SizedBox(width: 6),
                      Text(_selected!,
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: palette.ink)),
                      const SizedBox(width: 6),
                      Text('모멘텀 top 3',
                          style: TextStyle(fontSize: 12, color: palette.muted)),
                    ]),
                  ),
                  if (_loadingPicks)
                    ...List.generate(3, (_) => const StockTileSkeleton())
                  else if (_picks.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 22),
                      child: Center(
                        child: Text('데이터가 충분한 종목이 없습니다.',
                            style: TextStyle(color: palette.muted)),
                      ),
                    )
                  else
                    ..._picks.asMap().entries.map((e) {
                      final idx = e.key;
                      final pick = e.value;
                      return Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 24,
                                height: 20,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: idx < _rankColors.length ? _rankColors[idx] : _rankColors.last,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text('${idx + 1}',
                                    style: const TextStyle(
                                        fontSize: 10,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800)),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: StockTile.fromSectorPick(
                                  pick,
                                  onTap: () => widget.onSelect(pick.stockCode, pick.name),
                                ),
                              ),
                            ],
                          ),
                          Container(height: 1, color: palette.border),
                        ],
                      );
                    }),
                ],
              ],
            ),
    );
  }
}

class _GroupSection extends StatelessWidget {
  final String groupLabel;
  final List<String> keys;
  final Map<String, int> countMap;
  final String? selected;
  final void Function(String) onSelect;

  const _GroupSection({
    required this.groupLabel,
    required this.keys,
    required this.countMap,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final selectedInGroup = keys.contains(selected);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(groupLabel,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: palette.ink)),
              if (selectedInGroup) ...[
                const SizedBox(width: 6),
                Container(width: 6, height: 6, decoration: BoxDecoration(color: palette.primary, shape: BoxShape.circle)),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: keys.map((key) {
              final meta = _sectorMeta[key] ?? const _SectorMeta(Icons.category_outlined, Color(0xFF6B7280));
              final isActive = selected == key;
              return GestureDetector(
                onTap: () => onSelect(key),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isActive ? meta.color.withAlpha(24) : Colors.transparent,
                    borderRadius: BorderRadius.circular(9999),
                    border: Border.all(color: isActive ? meta.color : palette.hairline),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(meta.icon, size: 13, color: isActive ? meta.color : palette.mutedStrong),
                      const SizedBox(width: 5),
                      Text(key,
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: isActive ? meta.color : palette.mutedStrong)),
                      if (countMap[key] != null) ...[
                        const SizedBox(width: 4),
                        Text('${countMap[key]}',
                            style: TextStyle(fontSize: 10, color: isActive ? meta.color : palette.muted)),
                      ],
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _SkeletonChips extends StatelessWidget {
  const _SkeletonChips();

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Padding(
      padding: const EdgeInsets.all(kHeaderPaddingH),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(4, (gi) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 11,
                decoration: BoxDecoration(color: palette.hairline, borderRadius: BorderRadius.circular(4)),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: List.generate(
                  gi % 3 + 2,
                  (_) => Container(
                    width: 64,
                    height: 28,
                    decoration: BoxDecoration(color: palette.hairline, borderRadius: BorderRadius.circular(9999)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          );
        }),
      ),
    );
  }
}
