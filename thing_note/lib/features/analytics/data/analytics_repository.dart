import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thing_note/features/analytics/domain/usage_analyzer.dart';

class AnalyticsRepository {
  static const _keyInsights = 'usage_insights';
  static const _keyLastAnalysis = 'last_analysis_time';

  Future<void> saveInsights(List<UsageInsight> insights) async {
    final prefs = await SharedPreferences.getInstance();
    final list = insights.map((i) => {
      'title': i.title,
      'description': i.description,
      'type': i.type.name,
      'score': i.score,
      'actionText': i.actionText,
      'actionRoute': i.actionRoute,
    }).toList();
    await prefs.setString(_keyInsights, jsonEncode(list));
    await prefs.setString(_keyLastAnalysis, DateTime.now().toIso8601String());
  }

  Future<List<UsageInsight>> getSavedInsights() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_keyInsights);
      if (jsonStr == null) return [];

      final list = jsonDecode(jsonStr) as List;
      return list.map((map) => UsageInsight(
        title: map['title'] as String,
        description: map['description'] as String,
        type: InsightType.values.firstWhere((e) => e.name == map['type']),
        score: (map['score'] as num).toDouble(),
        actionText: map['actionText'] as String?,
        actionRoute: map['actionRoute'] as String?,
      )).toList();
    } catch (_) {
      return [];
    }
  }

  Future<DateTime?> getLastAnalysisTime() async {
    final prefs = await SharedPreferences.getInstance();
    final timeStr = prefs.getString(_keyLastAnalysis);
    if (timeStr == null) return null;
    return DateTime.tryParse(timeStr);
  }

  Future<void> clearInsights() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyInsights);
    await prefs.remove(_keyLastAnalysis);
  }
}