import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/endpoints.dart';
import '../api/models.dart';
import '../api/realtime.dart';

class WatchlistNotifier extends AsyncNotifier<List<WatchlistItem>> {
  final List<String> _codes = [];

  List<String> get codes => List.unmodifiable(_codes);

  @override
  Future<List<WatchlistItem>> build() async {
    try {
      final codes = await fetchWatchlistCodes();
      _codes
        ..clear()
        ..addAll(codes);
    } catch (_) {}
    if (_codes.isEmpty) return [];
    return fetchWatchlistItems(_codes);
  }

  void applyTick(WatchlistTick tick) {
    final current = state.valueOrNull ?? [];
    state = AsyncData(current.map((item) {
      if (item.stockCode != tick.stockCode) return item;
      return WatchlistItem(
        stockCode: item.stockCode,
        stockName: item.stockName,
        price: tick.price,
        change: tick.change,
        changeRate: tick.changeRate,
        volume: tick.volume ?? item.volume,
        tradeValue: tick.tradeValue ?? item.tradeValue,
      );
    }).toList());
  }

  void replaceItems(List<WatchlistItem> items) {
    state = AsyncData(items);
  }

  Future<void> add(String code) async {
    if (_codes.contains(code)) return;
    _codes.add(code);
    await _sync();
    await _reload();
  }

  Future<void> remove(String code) async {
    _codes.remove(code);
    await _sync();
    await _reload();
  }

  bool contains(String code) => _codes.contains(code);

  Future<void> _sync() async {
    try {
      await saveWatchlistCodes(_codes);
    } catch (_) {}
  }

  Future<void> _reload() async {
    state = const AsyncLoading();
    try {
      final items = await fetchWatchlistItems(_codes);
      state = AsyncData(items);
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
    }
  }
}

final watchlistProvider =
    AsyncNotifierProvider<WatchlistNotifier, List<WatchlistItem>>(
        WatchlistNotifier.new);
