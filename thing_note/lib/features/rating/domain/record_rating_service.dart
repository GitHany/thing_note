import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 记录评分等级
enum RecordRating {
  none(0, 'None'),
  one(1, '⭐'),
  two(2, '⭐⭐'),
  three(3, '⭐⭐⭐'),
  four(4, '⭐⭐⭐⭐'),
  five(5, '⭐⭐⭐⭐⭐');

  final int value;
  final String emoji;

  const RecordRating(this.value, this.emoji);

  static RecordRating fromValue(int value) {
    return RecordRating.values.firstWhere(
      (r) => r.value == value,
      orElse: () => RecordRating.none,
    );
  }
}

/// 重要性等级
enum ImportanceLevel {
  low(1, 'Low', '🔵'),
  normal(2, 'Normal', '🟢'),
  medium(3, 'Medium', '🟡'),
  high(4, 'High', '🟠'),
  critical(5, 'Critical', '🔴');

  final int value;
  final String label;
  final String icon;

  const ImportanceLevel(this.value, this.label, this.icon);

  static ImportanceLevel fromValue(int value) {
    return ImportanceLevel.values.firstWhere(
      (l) => l.value == value,
      orElse: () => ImportanceLevel.normal,
    );
  }
}

/// 评分和重要性数据
class RecordRatingData {
  final int recordId;
  final RecordRating rating;
  final ImportanceLevel importance;
  final DateTime? ratedAt;
  final String? comment;

  RecordRatingData({
    required this.recordId,
    this.rating = RecordRating.none,
    this.importance = ImportanceLevel.normal,
    this.ratedAt,
    this.comment,
  });

  Map<String, dynamic> toJson() => {
        'recordId': recordId,
        'rating': rating.value,
        'importance': importance.value,
        'ratedAt': ratedAt?.toIso8601String(),
        'comment': comment,
      };

  factory RecordRatingData.fromJson(Map<String, dynamic> json) {
    return RecordRatingData(
      recordId: json['recordId'] as int,
      rating: RecordRating.fromValue(json['rating'] as int? ?? 0),
      importance: ImportanceLevel.fromValue(json['importance'] as int? ?? 2),
      ratedAt: json['ratedAt'] != null
          ? DateTime.parse(json['ratedAt'] as String)
          : null,
      comment: json['comment'] as String?,
    );
  }

  RecordRatingData copyWith({
    int? recordId,
    RecordRating? rating,
    ImportanceLevel? importance,
    DateTime? ratedAt,
    String? comment,
  }) {
    return RecordRatingData(
      recordId: recordId ?? this.recordId,
      rating: rating ?? this.rating,
      importance: importance ?? this.importance,
      ratedAt: ratedAt ?? this.ratedAt,
      comment: comment ?? this.comment,
    );
  }
}

/// 评分和重要性服务
class RatingImportanceService {
  static const _keyRatings = 'record_ratings';

  final SharedPreferences _prefs;

  RatingImportanceService(this._prefs);

  /// 获取记录评分
  RecordRatingData? getRatingData(int recordId) {
    final ratingsJson = _prefs.getString(_keyRatings);
    if (ratingsJson == null) return null;

    try {
      final ratings = jsonDecode(ratingsJson) as Map<String, dynamic>;
      if (ratings.containsKey(recordId.toString())) {
        return RecordRatingData.fromJson(
          ratings[recordId.toString()] as Map<String, dynamic>,
        );
      }
    } catch (_) {}

    return null;
  }

  /// 保存记录评分
  Future<void> saveRatingData(RecordRatingData data) async {
    final ratingsJson = _prefs.getString(_keyRatings);
    Map<String, dynamic> ratings = {};

    if (ratingsJson != null) {
      try {
        ratings = jsonDecode(ratingsJson) as Map<String, dynamic>;
      } catch (_) {}
    }

    ratings[data.recordId.toString()] = data.toJson();
    await _prefs.setString(_keyRatings, jsonEncode(ratings));
  }

  /// 删除记录评分
  Future<void> deleteRatingData(int recordId) async {
    final ratingsJson = _prefs.getString(_keyRatings);
    if (ratingsJson == null) return;

    try {
      final ratings = jsonDecode(ratingsJson) as Map<String, dynamic>;
      ratings.remove(recordId.toString());
      await _prefs.setString(_keyRatings, jsonEncode(ratings));
    } catch (_) {}
  }

  /// 获取所有评分记录
  Map<int, RecordRatingData> getAllRatings() {
    final ratingsJson = _prefs.getString(_keyRatings);
    if (ratingsJson == null) return {};

    try {
      final ratings = jsonDecode(ratingsJson) as Map<String, dynamic>;
      return ratings.map((key, value) => MapEntry(
            int.parse(key),
            RecordRatingData.fromJson(value as Map<String, dynamic>),
          ));
    } catch (_) {
      return {};
    }
  }

  /// 获取高重要性记录
  List<int> getHighImportanceRecordIds() {
    final allRatings = getAllRatings();
    return allRatings.entries
        .where((e) => e.value.importance.value >= ImportanceLevel.high.value)
        .map((e) => e.key)
        .toList();
  }

  /// 获取高评分记录
  List<int> getHighRatingRecordIds() {
    final allRatings = getAllRatings();
    return allRatings.entries
        .where((e) => e.value.rating.value >= RecordRating.three.value)
        .map((e) => e.key)
        .toList();
  }

  /// 获取统计数据
  Map<String, int> getStatistics() {
    final allRatings = getAllRatings();

    final stats = <String, int>{
      'total': allRatings.length,
      'rated': allRatings.values.where((r) => r.rating != RecordRating.none).length,
      'important': allRatings.values.where((r) => r.importance != ImportanceLevel.normal).length,
      'highImportance': allRatings.values.where((r) => r.importance.value >= ImportanceLevel.high.value).length,
      'fiveStars': allRatings.values.where((r) => r.rating == RecordRating.five).length,
    };

    // 按重要性分布
    for (final level in ImportanceLevel.values) {
      stats['importance_${level.value}'] = allRatings.values.where((r) => r.importance == level).length;
    }

    // 按评分分布
    for (final rating in RecordRating.values) {
      stats['rating_${rating.value}'] = allRatings.values.where((r) => r.rating == rating).length;
    }

    return stats;
  }
}

/// 评分和重要性 Provider
final ratingServiceProvider = Provider<RatingImportanceService>((ref) {
  throw UnimplementedError('Call initializeRatingService instead');
});

Future<RatingImportanceService> initializeRatingService() async {
  final prefs = await SharedPreferences.getInstance();
  return RatingImportanceService(prefs);
}

/// 记录评分状态
class RecordRatingNotifier extends StateNotifier<Map<int, RecordRatingData>> {
  final RatingImportanceService _service;

  RecordRatingNotifier(this._service) : super({}) {
    _loadRatings();
  }

  void _loadRatings() {
    state = _service.getAllRatings();
  }

  Future<void> setRating(int recordId, RecordRating rating) async {
    final existing = state[recordId] ?? RecordRatingData(recordId: recordId);
    final updated = existing.copyWith(
      rating: rating,
      ratedAt: DateTime.now(),
    );

    await _service.saveRatingData(updated);
    state = {...state, recordId: updated};
  }

  Future<void> setImportance(int recordId, ImportanceLevel importance) async {
    final existing = state[recordId] ?? RecordRatingData(recordId: recordId);
    final updated = existing.copyWith(
      importance: importance,
      ratedAt: DateTime.now(),
    );

    await _service.saveRatingData(updated);
    state = {...state, recordId: updated};
  }

  Future<void> setComment(int recordId, String comment) async {
    final existing = state[recordId] ?? RecordRatingData(recordId: recordId);
    final updated = existing.copyWith(comment: comment);

    await _service.saveRatingData(updated);
    state = {...state, recordId: updated};
  }

  Future<void> removeRating(int recordId) async {
    await _service.deleteRatingData(recordId);
    final newState = Map<int, RecordRatingData>.from(state);
    newState.remove(recordId);
    state = newState;
  }

  RecordRatingData? getRatingData(int recordId) {
    return state[recordId];
  }
}

final recordRatingProvider =
    StateNotifierProvider<RecordRatingNotifier, Map<int, RecordRatingData>>((ref) {
  throw UnimplementedError('Initialize with initializeRatingNotifier');
});

Future<StateNotifierProvider<RecordRatingNotifier, Map<int, RecordRatingData>>>
    initializeRatingNotifier(RatingImportanceService service) async {
  final notifier = RecordRatingNotifier(service);
  return StateNotifierProvider<RecordRatingNotifier, Map<int, RecordRatingData>>((ref) {
    return notifier;
  });
}

/// 统计 Provider
final ratingStatisticsProvider = Provider<Map<String, int>>((ref) {
  throw UnimplementedError('Initialize with initializeRatingService');
});

/// 高重要性记录 Provider
final highImportanceRecordsProvider = Provider<List<int>>((ref) {
  throw UnimplementedError('Initialize with initializeRatingService');
});