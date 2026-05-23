import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:thing_note/core/database/database_provider.dart';
import '../domain/location_story_models.dart';

/// 位置故事服务提供者
final locationStoryServiceProvider = Provider<LocationStoryService>((ref) {
  return LocationStoryService(ref.read(databaseProvider.future));
});

/// 位置故事服务
class LocationStoryService {
  final Future<Database> _db;

  LocationStoryService(this._db);

  /// 获取所有位置故事
  Future<List<LocationStory>> getAllStories() async {
    final db = await _db;

    // 获取有位置信息的记录
    final records = await db.query(
      'episode_records',
      where: 'latitude IS NOT NULL AND longitude IS NOT NULL',
      orderBy: 'created_at DESC',
    );

    if (records.isEmpty) return [];

    // 按位置聚合
    final locationMap = <String, List<Map<String, dynamic>>>{};
    for (final record in records) {
      final lat = (record['latitude'] as num?)?.toDouble();
      final lng = (record['longitude'] as num?)?.toDouble();
      if (lat == null || lng == null) continue;

      // 简化精度到约100米
      final key = '${lat.toStringAsFixed(3)}_${lng.toStringAsFixed(3)}';
      locationMap.putIfAbsent(key, () => []);
      locationMap[key]!.add(record);
    }

    final stories = <LocationStory>[];
    int id = 1;

    for (final entry in locationMap.entries) {
      final locationRecords = entry.value;
      if (locationRecords.isEmpty) continue;

      final firstRecord = locationRecords.first;
      final lastRecord = locationRecords.last;

      final lat = (firstRecord['latitude'] as num).toDouble();
      final lng = (firstRecord['longitude'] as num).toDouble();

      // 计算总时长
      int totalSeconds = 0;
      for (final record in locationRecords) {
        totalSeconds += (record['duration_sec'] as int?) ?? 0;
      }

      // 获取地址
      String? address;
      try {
        final geocoded = await _reverseGeocode(lat, lng);
        address = geocoded;
      } catch (e) {
        address = firstRecord['address'] as String?;
      }

      stories.add(LocationStory(
        id: id++,
        locationName: address ?? '未知位置',
        latitude: lat,
        longitude: lng,
        address: address,
        firstVisit: DateTime.parse(firstRecord['created_at'] as String),
        lastVisit: DateTime.parse(lastRecord['created_at'] as String),
        visitCount: locationRecords.length,
        totalDuration: Duration(seconds: totalSeconds),
      ));
    }

    // 按访问次数排序
    stories.sort((a, b) => b.visitCount.compareTo(a.visitCount));

    return stories;
  }

  /// 获取单个位置的故事详情
  Future<LocationStory> getStoryDetails(int storyId) async {
    final db = await _db;
    final stories = await getAllStories();
    
    if (storyId > stories.length) {
      throw Exception('Story not found');
    }

    final story = stories[storyId - 1];

    // 获取该位置的所有记录
    final records = await db.query(
      'episode_records',
      where: 'latitude >= ? AND latitude <= ? AND longitude >= ? AND longitude <= ?',
      whereArgs: [
        story.latitude - 0.001,
        story.latitude + 0.001,
        story.longitude - 0.001,
        story.longitude + 0.001,
      ],
      orderBy: 'created_at DESC',
    );

    // 生成章节
    final chapters = _generateChapters(records);

    return LocationStory(
      id: story.id,
      locationName: story.locationName,
      latitude: story.latitude,
      longitude: story.longitude,
      address: story.address,
      chapters: chapters,
      firstVisit: story.firstVisit,
      lastVisit: story.lastVisit,
      visitCount: records.length,
      totalDuration: story.totalDuration,
    );
  }

  List<StoryChapter> _generateChapters(List<Map<String, dynamic>> records) {
    if (records.isEmpty) return [];

    final chapters = <StoryChapter>[];
    
    // 按日期分组
    final dateGroups = <String, List<Map<String, dynamic>>>{};
    for (final record in records) {
      final date = DateTime.parse(record['created_at'] as String);
      final dateKey = '${date.year}-${date.month}-${date.day}';
      dateGroups.putIfAbsent(dateKey, () => []);
      dateGroups[dateKey]!.add(record);
    }

    // 生成章节
    for (final entry in dateGroups.entries) {
      final parts = entry.key.split('-');
      final date = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
      final dayRecords = entry.value;

      // 获取照片
      final photos = <String>[];
      for (final record in dayRecords) {
        final photoPathsJson = record['photo_paths'] as String? ?? '[]';
        // 简单解析 JSON
        if (photoPathsJson.startsWith('[')) {
          final cleaned = photoPathsJson.substring(1, photoPathsJson.length - 1);
          if (cleaned.isNotEmpty) {
            photos.addAll(cleaned.split(',').map((p) => p.trim().replaceAll('"', '')));
          }
        }
      }

      // 计算时长
      int totalSeconds = 0;
      for (final record in dayRecords) {
        totalSeconds += (record['duration_sec'] as int?) ?? 0;
      }

      chapters.add(StoryChapter(
        date: date,
        title: _formatDateTitle(date),
        description: '${dayRecords.length} 条记录',
        recordIds: dayRecords.map((r) => r['id'] as int).toList(),
        photoPaths: photos.take(5).toList(),
        duration: Duration(seconds: totalSeconds),
      ));
    }

    return chapters;
  }

  String _formatDateTitle(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date).inDays;

    if (diff == 0) return '今天';
    if (diff == 1) return '昨天';
    if (diff < 7) return '$diff 天前';
    return '${date.month}月${date.day}日';
  }

  /// 获取位置时间线
  Future<LocationTimeline> getLocationTimeline({int days = 30}) async {
    final db = await _db;
    final now = DateTime.now();
    final startDate = now.subtract(Duration(days: days));

    final records = await db.query(
      'episode_records',
      where: 'created_at >= ? AND latitude IS NOT NULL AND longitude IS NOT NULL',
      whereArgs: [startDate.toIso8601String()],
      orderBy: 'created_at ASC',
    );

    final items = <TimelineItem>[];

    for (final record in records) {
      final date = DateTime.parse(record['created_at'] as String);
      final duration = (record['duration_sec'] as int?) ?? 0;

      // 获取事情名称
      String? thingName;
      final thingNameId = record['thing_name_id'] as int?;
      if (thingNameId != null) {
        final thingNames = await db.query('thing_names', where: 'id = ?', whereArgs: [thingNameId]);
        if (thingNames.isNotEmpty) {
          thingName = thingNames.first['name'] as String;
        }
      }

      // 获取照片
      final photoPathsJson = record['photo_paths'] as String? ?? '[]';
      final photos = <String>[];
      if (photoPathsJson.startsWith('[')) {
        final cleaned = photoPathsJson.substring(1, photoPathsJson.length - 1);
        if (cleaned.isNotEmpty) {
          photos.addAll(cleaned.split(',').map((p) => p.trim().replaceAll('"', '')));
        }
      }

      items.add(TimelineItem(
        date: date,
        type: duration > 0 ? TimelineItemType.activity : TimelineItemType.note,
        title: thingName ?? record['note'] as String? ?? '记录',
        subtitle: record['note'] as String?,
        photoPaths: photos,
        duration: Duration(seconds: duration),
      ));
    }

    return LocationTimeline(
      items: items,
      startDate: startDate,
      endDate: now,
    );
  }

  /// 反向地理编码（简单实现）
  Future<String?> _reverseGeocode(double lat, double lng) async {
    // 这里可以使用实际的地理编码 API
    // 简单返回坐标
    return '${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}';
  }

  /// 获取位置聚类
  Future<List<LocationCluster>> getLocationClusters() async {
    final stories = await getAllStories();

    if (stories.isEmpty) return [];

    final clusters = <LocationCluster>[];

    // 简单聚类：按距离
    final processed = <int>{};

    for (final story in stories) {
      if (processed.contains(story.id)) continue;

      final nearbyStories = stories.where((s) {
        if (processed.contains(s.id)) return false;
        final distance = _calculateDistance(
          story.latitude, story.longitude,
          s.latitude, s.longitude,
        );
        return distance < 0.5; // 约500米内
      }).toList();

      if (nearbyStories.isEmpty) continue;

      // 计算中心点
      double centerLat = 0, centerLng = 0;
      int totalRecords = 0;
      int totalSeconds = 0;

      for (final s in nearbyStories) {
        centerLat += s.latitude;
        centerLng += s.longitude;
        totalRecords += s.visitCount;
        totalSeconds += s.totalDuration.inSeconds;
        processed.add(s.id);
      }

      centerLat /= nearbyStories.length;
      centerLng /= nearbyStories.length;

      clusters.add(LocationCluster(
        name: nearbyStories.first.locationName,
        centerLatitude: centerLat,
        centerLongitude: centerLng,
        recordCount: totalRecords,
        totalDuration: Duration(seconds: totalSeconds),
        stories: nearbyStories,
      ));
    }

    return clusters;
  }

  double _calculateDistance(double lat1, double lng1, double lat2, double lng2) {
    // 简单的欧几里得距离（实际应该用 Haversine 公式）
    final dLat = lat2 - lat1;
    final dLng = lng2 - lng1;
    return (dLat * dLat + dLng * dLng);
  }
}