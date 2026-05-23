import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thing_note/features/smart_reminder/domain/reminder_analyzer.dart';

class ReminderPatternRepository {
  static const _keyPatterns = 'reminder_patterns';

  Future<List<ReminderPattern>> getSavedPatterns() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_keyPatterns);
      if (jsonStr == null) return [];

      final list = jsonDecode(jsonStr) as List;
      return list.map((map) => ReminderPattern(
        thingNameId: map['thingNameId'] as int?,
        thingName: map['thingName'] as String?,
        dayOfWeek: map['dayOfWeek'] as int?,
        suggestedHour: map['suggestedHour'] as int?,
        suggestedMinute: map['suggestedMinute'] as int?,
        confidence: (map['confidence'] as num?)?.toDouble() ?? 0.0,
      )).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> savePatterns(List<ReminderPattern> patterns) async {
    final prefs = await SharedPreferences.getInstance();
    final list = patterns.map((p) => {
      'thingNameId': p.thingNameId,
      'thingName': p.thingName,
      'dayOfWeek': p.dayOfWeek,
      'suggestedHour': p.suggestedHour,
      'suggestedMinute': p.suggestedMinute,
      'confidence': p.confidence,
    }).toList();
    await prefs.setString(_keyPatterns, jsonEncode(list));
  }

  Future<void> clearPatterns() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyPatterns);
  }
}