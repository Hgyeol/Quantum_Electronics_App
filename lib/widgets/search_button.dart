import 'package:flutter/material.dart';
import '../api/endpoints.dart';
import '../api/models.dart';
import '../design/tokens.dart';

class SearchButton extends StatelessWidget {
  final void Function(String code, String name) onSelect;
  const SearchButton({super.key, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);

    void openSearch() {
      showSearch(
        context: context,
        delegate: _StockSearchDelegate(onSelect),
      );
    }

    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: openSearch,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              height: 36,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: palette.bgSubtle,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: palette.borderMd),
              ),
              child: Row(
                children: [
                  Icon(Icons.search_rounded, size: 17, color: palette.muted),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      '종목코드 · 종목명 검색',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        color: palette.muted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          height: 36,
          child: FilledButton(
            onPressed: openSearch,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              minimumSize: const Size(0, 36),
              backgroundColor: palette.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              textStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            child: const Text('조회', maxLines: 1, softWrap: false),
          ),
        ),
      ],
    );
  }
}

class _StockSearchDelegate extends SearchDelegate<void> {
  final void Function(String code, String name) onSelect;

  _StockSearchDelegate(this.onSelect);

  @override
  String get searchFieldLabel => '종목 검색';

  @override
  List<Widget> buildActions(BuildContext context) => [
        if (query.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () => query = '',
          ),
      ];

  @override
  Widget buildLeading(BuildContext context) => IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => close(context, null),
      );

  @override
  Widget buildResults(BuildContext context) => _buildList(context);

  @override
  Widget buildSuggestions(BuildContext context) {
    final palette = AppPalette.of(context);
    if (query.isEmpty) return const SizedBox.shrink();
    return FutureBuilder<List<StockSearchResult>>(
      future: searchStocks(query),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: palette.primary));
        }
        if (snap.hasError) {
          return Center(
            child: Text('${snap.error}', style: TextStyle(color: palette.muted)),
          );
        }
        final results = snap.data ?? [];
        return ListView.separated(
          itemCount: results.length,
          separatorBuilder: (context, index) =>
              Divider(height: 1, color: palette.border),
          itemBuilder: (context, i) {
            final r = results[i];
            return ListTile(
              title: Text(r.corpName,
                  style: TextStyle(fontWeight: FontWeight.w600, color: palette.ink)),
              subtitle: Text(r.stockCode,
                  style: monoStyle(size: 12, color: palette.muted, weight: FontWeight.w400)),
              onTap: () {
                close(context, null);
                onSelect(r.stockCode, r.corpName);
              },
            );
          },
        );
      },
    );
  }

  Widget _buildList(BuildContext context) => buildSuggestions(context);
}
