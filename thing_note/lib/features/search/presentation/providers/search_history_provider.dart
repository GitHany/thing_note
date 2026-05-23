import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Search history provider
class SearchHistoryNotifier extends AsyncNotifier<List<String>> {
  static const _key = 'search_history';
  static const _maxHistory = 20;

  @override
  Future<List<String>> build() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_key) ?? [];
  }

  Future<void> addSearch(String query) async {
    if (query.trim().isEmpty) return;

    final trimmed = query.trim();
    final current = state.valueOrNull ?? [];
    final updated = [trimmed, ...current.where((q) => q != trimmed)].take(_maxHistory).toList();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, updated);

    state = AsyncData(updated);
  }

  Future<void> removeSearch(String query) async {
    final current = state.valueOrNull ?? [];
    final updated = current.where((q) => q != query).toList();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, updated);

    state = AsyncData(updated);
  }

  Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);

    state = const AsyncData([]);
  }
}

final searchHistoryProvider = AsyncNotifierProvider<SearchHistoryNotifier, List<String>>(() {
  return SearchHistoryNotifier();
});

// Search suggestions provider
final searchSuggestionsProvider = Provider<List<String>>((ref) {
  // These are default suggestions shown when search is empty
  return [
    '今日记录',
    '本周统计',
    '收藏内容',
    '待办提醒',
    '搜索技巧',
  ];
});