import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/smart_tag/data/smart_tag_service.dart';
import 'package:thing_note/features/smart_tag/domain/tag_recommendation.dart';

/// 智能标签推荐widget
class SmartTagSuggestions extends ConsumerWidget {
  final String? note;
  final String? thingName;
  final DateTime? occurredAt;
  final List<String> existingTags;
  final void Function(String tagName)? onTagSelected;

  const SmartTagSuggestions({
    super.key,
    this.note,
    this.thingName,
    this.occurredAt,
    this.existingTags = const [],
    this.onTagSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final smartTag = ref.watch(smartTagProvider);
    
    return FutureBuilder<List<TagRecommendation>>(
      future: smartTag.getRecommendations(
        note: note ?? '',
        thingName: thingName,
        occurredAt: occurredAt,
        existingTags: existingTags,
      ),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }

        final recommendations = snapshot.data!;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                '推荐标签',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: recommendations.map((rec) {
                  return _RecommendationChip(
                    recommendation: rec,
                    onTap: () => onTagSelected?.call(rec.tagName),
                  );
                }).toList(),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _RecommendationChip extends StatelessWidget {
  final TagRecommendation recommendation;
  final VoidCallback? onTap;

  const _RecommendationChip({
    required this.recommendation,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color chipColor;
    IconData icon;
    
    switch (recommendation.type) {
      case RecommendationType.keyword:
        chipColor = Colors.blue;
        icon = Icons.text_fields;
        break;
      case RecommendationType.time:
        chipColor = Colors.orange;
        icon = Icons.schedule;
        break;
      case RecommendationType.frequency:
        chipColor = Colors.green;
        icon = Icons.trending_up;
        break;
      case RecommendationType.thingName:
        chipColor = Colors.purple;
        icon = Icons.label;
        break;
      case RecommendationType.cooccurrence:
        chipColor = Colors.teal;
        icon = Icons.link;
        break;
    }

    return Tooltip(
      message: '${recommendation.reason}\n置信度: ${recommendation.score.toInt()}%',
      child: ActionChip(
        avatar: Icon(icon, size: 16, color: chipColor),
        label: Text(recommendation.tagName),
        backgroundColor: chipColor.withOpacity(0.1),
        side: BorderSide(color: chipColor.withOpacity(0.3)),
        onPressed: onTap,
      ),
    );
  }
}

/// 标签共现分析widget
class TagCooccurrenceWidget extends ConsumerWidget {
  const TagCooccurrenceWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final smartTag = ref.watch(smartTagProvider);

    return FutureBuilder<Map<String, List<String>>>(
      future: smartTag.getTagCooccurrence(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Text('暂无标签共现数据'),
          );
        }

        final cooccurrence = snapshot.data!;
        
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: cooccurrence.length,
          itemBuilder: (context, index) {
            final entry = cooccurrence.entries.elementAt(index);
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: const Icon(Icons.link, color: Colors.teal),
                title: Text(entry.key),
                subtitle: Text('常与: ${entry.value.join(", ")}'),
                trailing: Chip(
                  label: Text('${entry.value.length}个'),
                  backgroundColor: Colors.teal.withOpacity(0.1),
                ),
              ),
            );
          },
        );
      },
    );
  }
}