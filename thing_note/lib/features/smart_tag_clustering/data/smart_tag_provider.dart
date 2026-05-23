// Smart Tag Clustering feature
// Version: 1.0
// Description: 智能标签聚类分析，发现标签之间的关系和共现模式

import 'package:sqflite/sqflite.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/core/database/database_provider.dart';

// Smart Tag Clustering Provider
final tagClustersProvider = FutureProvider<List<TagCluster>>((ref) async {
  final db = await ref.watch(databaseProvider.future);
  
  // Get all record tags
  final records = await db.query('episode_records', columns: ['id', 'thing_name_id']);
  
  // Build co-occurrence matrix
  final Map<String, Map<String, int>> coOccurrence = {};
  final Map<String, int> tagCount = {};
  
  for (final record in records) {
    final thingNameId = record['thing_name_id'] as int?;
    if (thingNameId != null) {
      final thingNames = await db.query(
        'thing_names',
        where: 'id = ?',
        whereArgs: [thingNameId],
      );
      
      if (thingNames.isNotEmpty) {
        final tag = thingNames.first['name'] as String;
        tagCount[tag] = (tagCount[tag] ?? 0) + 1;
      }
    }
    
    // Get tags for this record
    final tags = await db.query(
      'record_tags',
      where: 'record_id = ?',
      whereArgs: [record['id']],
    );
    
    for (final tagEntry in tags) {
      final tagName = tagEntry['tag_name'] as String;
      tagCount[tagName] = (tagCount[tagName] ?? 0) + 1;
      
      // Build co-occurrence
      for (final otherTag in tags) {
        if (tagEntry['id'] != otherTag['id']) {
          final otherTagName = otherTag['tag_name'] as String;
          coOccurrence.putIfAbsent(tagName, () => {});
          coOccurrence[tagName]![otherTagName] = (coOccurrence[tagName]![otherTagName] ?? 0) + 1;
        }
      }
    }
  }
  
  // Create clusters based on co-occurrence
  final clusters = <TagCluster>[];
  final processedTags = <String>{};
  
  for (final tag in tagCount.keys) {
    if (processedTags.contains(tag)) continue;
    
    final cluster = _buildCluster(tag, coOccurrence, tagCount, processedTags);
    if (cluster.tags.length > 1) {
      clusters.add(cluster);
    }
  }
  
  // Sort by total frequency
  clusters.sort((a, b) => b.totalFrequency.compareTo(a.totalFrequency));
  
  return clusters;
});

final tagSuggestionsProvider = FutureProvider<List<TagSuggestion>>((ref) async {
  final db = await ref.watch(databaseProvider.future);
  
  // Get recent records
  final recentRecords = await db.query(
    'episode_records',
    orderBy: 'created_at DESC',
    limit: 10,
  );
  
  final suggestions = <TagSuggestion>[];
  
  // Analyze patterns
  for (final record in recentRecords) {
    final thingNameId = record['thing_name_id'] as int?;
    if (thingNameId != null) {
      final thingNames = await db.query(
        'thing_names',
        where: 'id = ?',
        whereArgs: [thingNameId],
      );
      
      if (thingNames.isNotEmpty) {
        final thingName = thingNames.first['name'] as String;
        
        // Find related tags
        final relatedTags = await _findRelatedTags(db, thingName);
        
        suggestions.add(TagSuggestion(
          thingName: thingName,
          suggestedTags: relatedTags,
          confidence: _calculateConfidence(relatedTags.length),
        ));
      }
    }
  }
  
  return suggestions;
});

class TagCluster {
  final String name;
  final List<String> tags;
  final int totalFrequency;
  final List<TagPair> topPairs;

  TagCluster({
    required this.name,
    required this.tags,
    required this.totalFrequency,
    required this.topPairs,
  });
}

class TagPair {
  final String tag1;
  final String tag2;
  final int coOccurrenceCount;

  TagPair({
    required this.tag1,
    required this.tag2,
    required this.coOccurrenceCount,
  });
}

class TagSuggestion {
  final String thingName;
  final List<String> suggestedTags;
  final double confidence;

  TagSuggestion({
    required this.thingName,
    required this.suggestedTags,
    required this.confidence,
  });
}

TagCluster _buildCluster(
  String startTag,
  Map<String, Map<String, int>> coOccurrence,
  Map<String, int> tagCount,
  Set<String> processedTags,
) {
  final clusterTags = <String>[startTag];
  processedTags.add(startTag);
  
  // Find strongly connected tags
  final related = coOccurrence[startTag] ?? {};
  final sortedRelated = related.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  
  for (final entry in sortedRelated.take(5)) {
    if (entry.value >= 3 && !processedTags.contains(entry.key)) {
      // Check if strongly connected
      final reverseCount = coOccurrence[entry.key]?[startTag] ?? 0;
      if (reverseCount >= 2 || entry.value >= 5) {
        clusterTags.add(entry.key);
        processedTags.add(entry.key);
      }
    }
  }
  
  // Calculate total frequency
  int totalFreq = 0;
  for (final tag in clusterTags) {
    totalFreq += tagCount[tag] ?? 0;
  }
  
  // Find top pairs
  final topPairs = <TagPair>[];
  for (int i = 0; i < clusterTags.length; i++) {
    for (int j = i + 1; j < clusterTags.length; j++) {
      final count1 = coOccurrence[clusterTags[i]]?[clusterTags[j]] ?? 0;
      final count2 = coOccurrence[clusterTags[j]]?[clusterTags[i]] ?? 0;
      final totalCount = count1 + count2;
      
      if (totalCount > 0) {
        topPairs.add(TagPair(
          tag1: clusterTags[i],
          tag2: clusterTags[j],
          coOccurrenceCount: totalCount,
        ));
      }
    }
  }
  topPairs.sort((a, b) => b.coOccurrenceCount.compareTo(a.coOccurrenceCount));
  
  return TagCluster(
    name: startTag,
    tags: clusterTags,
    totalFrequency: totalFreq,
    topPairs: topPairs.take(3).toList(),
  );
}

Future<List<String>> _findRelatedTags(Database db, String thingName) async {
  // Find records with this thing name
  final records = await db.query(
    'episode_records',
    where: 'thing_name_id = (SELECT id FROM thing_names WHERE name = ?)',
    whereArgs: [thingName],
    limit: 10,
  );
  
  final relatedTags = <String>{};
  
  for (final record in records) {
    final tags = await db.query(
      'record_tags',
      where: 'record_id = ?',
      whereArgs: [record['id']],
    );
    
    for (final tag in tags) {
      relatedTags.add(tag['tag_name'] as String);
    }
  }
  
  return relatedTags.toList();
}

double _calculateConfidence(int relatedCount) {
  if (relatedCount >= 5) return 0.9;
  if (relatedCount >= 3) return 0.7;
  if (relatedCount >= 1) return 0.5;
  return 0.3;
}