import 'package:sqflite/sqflite.dart';
import 'dart:convert';
import 'package:thing_note/features/smart_tag_clustering/domain/smart_tag_model.dart';

/// Repository for Smart Tag Clustering data operations
class SmartTagRepository {
  final Database db;

  SmartTagRepository(this.db);

  /// Get all tags from records
  Future<List<String>> getAllTags() async {
    final List<Map<String, dynamic>> records = await db.query('episode_records');
    final tagSet = <String>{};
    
    for (final record in records) {
      final annotations = record['annotations'] as String?;
      if (annotations != null && annotations.isNotEmpty) {
        try {
          final annotationMap = jsonDecode(annotations);
          if (annotationMap is Map && annotationMap.containsKey('tags')) {
            final tags = annotationMap['tags'];
            if (tags is List) {
              for (final tag in tags) {
                if (tag is String && tag.isNotEmpty) {
                  tagSet.add(tag.trim());
                }
              }
            }
          }
        } catch (e) {
          // Skip invalid JSON
        }
      }
    }
    
    return tagSet.toList()..sort();
  }

  /// Get tag co-occurrence matrix
  Future<Map<String, Map<String, int>>> getTagCooccurrenceMatrix() async {
    final records = await db.query('episode_records');
    final matrix = <String, Map<String, int>>{};
    
    for (final record in records) {
      final annotations = record['annotations'] as String?;
      if (annotations != null && annotations.isNotEmpty) {
        try {
          final annotationMap = jsonDecode(annotations);
          if (annotationMap is Map && annotationMap.containsKey('tags')) {
            final tags = annotationMap['tags'];
            if (tags is List && tags.length > 1) {
              final tagList = tags.whereType<String>().map((t) => t.trim()).toList();
              
              for (int i = 0; i < tagList.length; i++) {
                for (int j = i + 1; j < tagList.length; j++) {
                  final tag1 = tagList[i];
                  final tag2 = tagList[j];
                  
                  matrix[tag1] ??= {};
                  matrix[tag2] ??= {};
                  matrix[tag1]![tag2] = (matrix[tag1]![tag2] ?? 0) + 1;
                  matrix[tag2]![tag1] = (matrix[tag2]![tag1] ?? 0) + 1;
                }
              }
            }
          }
        } catch (e) {
          // Skip invalid JSON
        }
      }
    }
    
    return matrix;
  }

  /// Get top co-occurring tag pairs
  Future<List<TagCooccurrence>> getTopCooccurrences({int limit = 20}) async {
    final matrix = await getTagCooccurrenceMatrix();
    final cooccurrences = <TagCooccurrence>[];
    
    for (final tag1 in matrix.keys) {
      for (final tag2 in matrix[tag1]!.keys) {
        final count = matrix[tag1]![tag2]!;
        // Get total occurrences for confidence calculation
        final tag1Records = await _getTagOccurrenceCount(tag1);
        final tag2Records = await _getTagOccurrenceCount(tag2);
        final confidence = count.toDouble() / (tag1Records + tag2Records - count);
        
        cooccurrences.add(TagCooccurrence(
          tag1: tag1,
          tag2: tag2,
          cooccurrenceCount: count,
          confidence: confidence,
        ));
      }
    }
    
    cooccurrences.sort((a, b) => b.cooccurrenceCount.compareTo(a.cooccurrenceCount));
    return cooccurrences.take(limit).toList();
  }

  Future<int> _getTagOccurrenceCount(String tag) async {
    final records = await db.query('episode_records');
    int count = 0;
    
    for (final record in records) {
      final annotations = record['annotations'] as String?;
      if (annotations != null && annotations.isNotEmpty) {
        try {
          final annotationMap = jsonDecode(annotations);
          if (annotationMap is Map && annotationMap.containsKey('tags')) {
            final tags = annotationMap['tags'];
            if (tags is List && tags.contains(tag)) {
              count++;
            }
          }
        } catch (e) {
          // Skip
        }
      }
    }
    
    return count;
  }

  /// Get tag clusters based on co-occurrence
  Future<List<TagCluster>> detectClusters({int minCooccurrence = 2}) async {
    final cooccurrences = await getTopCooccurrences(limit: 100);
    final clusters = <List<String>>[];
    final processed = <String>{};
    
    for (final cooc in cooccurrences) {
      if (cooc.cooccurrenceCount < minCooccurrence) continue;
      
      final tag1 = cooc.tag1;
      final tag2 = cooc.tag2;
      
      if (processed.contains(tag1) && processed.contains(tag2)) continue;
      
      // Find or create cluster
      int foundClusterIdx = -1;
      for (int i = 0; i < clusters.length; i++) {
        if (clusters[i].contains(tag1)) {
          foundClusterIdx = i;
          break;
        }
        if (clusters[i].contains(tag2)) {
          foundClusterIdx = i;
          break;
        }
      }
      
      if (foundClusterIdx >= 0) {
        if (!clusters[foundClusterIdx].contains(tag1)) {
          clusters[foundClusterIdx].add(tag1);
        }
        if (!clusters[foundClusterIdx].contains(tag2)) {
          clusters[foundClusterIdx].add(tag2);
        }
      } else {
        clusters.add([tag1, tag2]);
      }
      
      processed.add(tag1);
      processed.add(tag2);
    }
    
    // Convert to TagCluster objects
    return clusters.map((tags) {
      int totalCooc = 0;
      int pairCount = 0;
      for (final cooc in cooccurrences) {
        if (tags.contains(cooc.tag1) && tags.contains(cooc.tag2)) {
          totalCooc += cooc.cooccurrenceCount;
          pairCount++;
        }
      }
      
      return TagCluster(
        clusterName: _generateClusterName(tags),
        tags: tags,
        usageCount: totalCooc,
        avgCooccurrence: pairCount > 0 ? totalCooc / pairCount : 0,
      );
    }).toList();
  }

  String _generateClusterName(List<String> tags) {
    // Simple naming: combine first 2 tags
    if (tags.length <= 2) {
      return tags.join(' + ');
    }
    return '${tags[0]} + ${tags[1]} (+${tags.length - 2} more)';
  }

  /// Get suggested tags based on existing tags
  Future<List<String>> getSuggestedTags(List<String> existingTags, {int limit = 5}) async {
    if (existingTags.isEmpty) {
      final allTags = await getAllTags();
      return allTags.take(limit).toList();
    }
    
    final matrix = await getTagCooccurrenceMatrix();
    final tagScores = <String, int>{};
    
    for (final existingTag in existingTags) {
      if (matrix.containsKey(existingTag)) {
        for (final cooccTag in matrix[existingTag]!.keys) {
          if (!existingTags.contains(cooccTag)) {
            tagScores[cooccTag] = (tagScores[cooccTag] ?? 0) + matrix[existingTag]![cooccTag]!;
          }
        }
      }
    }
    
    final sortedTags = tagScores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return sortedTags.take(limit).map((e) => e.key).toList();
  }

  /// Get tag usage statistics
  Future<Map<String, int>> getTagUsageStats() async {
    final records = await db.query('episode_records');
    final stats = <String, int>{};
    
    for (final record in records) {
      final annotations = record['annotations'] as String?;
      if (annotations != null && annotations.isNotEmpty) {
        try {
          final annotationMap = jsonDecode(annotations);
          if (annotationMap is Map && annotationMap.containsKey('tags')) {
            final tags = annotationMap['tags'];
            if (tags is List) {
              for (final tag in tags) {
                if (tag is String && tag.isNotEmpty) {
                  stats[tag.trim()] = (stats[tag.trim()] ?? 0) + 1;
                }
              }
            }
          }
        } catch (e) {
          // Skip
        }
      }
    }
    
    return stats;
  }
}