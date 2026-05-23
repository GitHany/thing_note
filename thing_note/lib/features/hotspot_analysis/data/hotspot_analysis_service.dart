import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/hotspot_analysis/domain/hotspot_analysis.dart';

class HotspotAnalysisService {
  /// Analyze records to find hotspot locations
  Future<HotspotAnalysis> analyzeHotspots(List<Map<String, dynamic>> records) async {
    // Find locations with multiple records
    final locationGroups = <String, List<Map<String, dynamic>>>{};

    for (final record in records) {
      final lat = record['latitude'] as double?;
      final lng = record['longitude'] as double?;

      if (lat != null && lng != null) {
        // Round to ~100m precision
        final key = '${lat.toStringAsFixed(3)},${lng.toStringAsFixed(3)}';
        locationGroups.putIfAbsent(key, () => []).add(record);
      }
    }

    // Convert to hotspot locations
    final locations = locationGroups.entries
        .where((e) => e.value.length >= 2) // At least 2 records
        .map((e) {
          final parts = e.key.split(',');
          return HotspotLocation(
            latitude: double.parse(parts[0]),
            longitude: double.parse(parts[1]),
            recordCount: e.value.length,
          );
        })
        .toList()
      ..sort((a, b) => b.recordCount.compareTo(a.recordCount));

    // Analyze time patterns
    final timeSlots = _analyzeTimeSlots(records);

    // Analyze tag distribution
    final tagDistribution = _analyzeTagDistribution(records);

    // Determine dominant pattern
    final dominantPattern = _determineDominantPattern(timeSlots, locations);

    return HotspotAnalysis(
      analyzedAt: DateTime.now(),
      locations: locations.take(10).toList(),
      timeSlots: timeSlots.take(5).toList(),
      tagDistribution: tagDistribution,
      dominantPattern: dominantPattern,
    );
  }

  List<HotspotTimeSlot> _analyzeTimeSlots(List<Map<String, dynamic>> records) {
    final hourGroups = <int, List<Map<String, dynamic>>>{};

    for (final record in records) {
      final occurredAt = DateTime.parse(record['occurred_at'] as String);
      final hour = occurredAt.hour;
      hourGroups.putIfAbsent(hour, () => []).add(record);
    }

    final timeSlots = hourGroups.entries.map((e) {
      final durationSum =
          e.value.fold<int>(0, (sum, r) => sum + ((r['duration_sec'] as int?) ?? 0));
      final avgDuration = e.value.isNotEmpty ? durationSum / e.value.length : 0.0;

      // Get common thing names
      final thingNameCounts = <int, int>{};
      for (final r in e.value) {
        final thingNameId = r['thing_name_id'] as int?;
        if (thingNameId != null) {
          thingNameCounts[thingNameId] = (thingNameCounts[thingNameId] ?? 0) + 1;
        }
      }
      final sortedEntries = thingNameCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final topThingNames = sortedEntries.take(3).map((e) => 'ThingName #${e.key}').toList();

      return HotspotTimeSlot(
        hour: e.key,
        recordCount: e.value.length,
        avgDuration: avgDuration,
        commonThingNames: topThingNames,
      );
    }).toList()
      ..sort((a, b) => b.recordCount.compareTo(a.recordCount));
    
    return timeSlots;
  }

  Map<String, int> _analyzeTagDistribution(List<Map<String, dynamic>> records) {
    final distribution = <String, int>{};
    // Simplified - in production would query record_tags
    return distribution;
  }

  String? _determineDominantPattern(
    List<HotspotTimeSlot> timeSlots,
    List<HotspotLocation> locations,
  ) {
    if (timeSlots.isEmpty && locations.isEmpty) {
      return 'No clear pattern';
    }

    if (timeSlots.isNotEmpty) {
      final topSlot = timeSlots.first;
      if (topSlot.hour >= 6 && topSlot.hour < 12) {
        return 'Morning person';
      } else if (topSlot.hour >= 12 && topSlot.hour < 18) {
        return 'Afternoon active';
      } else if (topSlot.hour >= 18 && topSlot.hour < 22) {
        return 'Evening recorder';
      } else {
        return 'Night owl';
      }
    }

    return null;
  }

  /// Get location-based suggestions
  List<String> generateSuggestions(HotspotAnalysis analysis) {
    final suggestions = <String>[];

    if (analysis.locations.length >= 3) {
      suggestions.add(
        'You have ${analysis.locations.length} favorite locations. '
        'Consider adding location-based reminders.',
      );
    }

    if (analysis.dominantPattern != null) {
      suggestions.add(
        'Your ${analysis.dominantPattern} pattern detected. '
        'Set reminders during your most active times.',
      );
    }

    if (analysis.timeSlots.isNotEmpty) {
      final peakHour = analysis.timeSlots.first.hour;
      suggestions.add(
        'Peak recording time: ${_formatHour(peakHour)}. '
        'This could be a good reminder time.',
      );
    }

    return suggestions;
  }

  String _formatHour(int hour) {
    if (hour == 0) return '12 AM';
    if (hour < 12) return '$hour AM';
    if (hour == 12) return '12 PM';
    return '${hour - 12} PM';
  }
}

final hotspotAnalysisServiceProvider = Provider<HotspotAnalysisService>((ref) {
  return HotspotAnalysisService();
});