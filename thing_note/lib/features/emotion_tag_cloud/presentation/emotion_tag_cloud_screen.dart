import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:thing_note/core/database/database_provider.dart';

class EmotionTag {
  final int? id;
  final String tagName;
  final String tagType;
  final double intensity;
  final String? emotionCategory;
  final int occurrenceCount;
  final String? lastUsedAt;
  final String createdAt;

  EmotionTag({
    this.id,
    required this.tagName,
    required this.tagType,
    this.intensity = 1.0,
    this.emotionCategory,
    this.occurrenceCount = 0,
    this.lastUsedAt,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id, 'tag_name': tagName, 'tag_type': tagType,
    'intensity': intensity, 'emotion_category': emotionCategory,
    'occurrence_count': occurrenceCount, 'last_used_at': lastUsedAt, 'created_at': createdAt,
  };

  factory EmotionTag.fromMap(Map<String, dynamic> m) => EmotionTag(
    id: m['id'] as int?, tagName: m['tag_name'] as String, tagType: m['tag_type'] as String,
    intensity: (m['intensity'] as num?)?.toDouble() ?? 1.0,
    emotionCategory: m['emotion_category'] as String?,
    occurrenceCount: m['occurrence_count'] as int? ?? 0,
    lastUsedAt: m['last_used_at'] as String?, createdAt: m['created_at'] as String,
  );
}

final emotionTagCloudProvider = StateNotifierProvider<EmotionTagCloudNotifier, List<EmotionTag>>((ref) {
  return EmotionTagCloudNotifier(ref);
});

class EmotionTagCloudNotifier extends StateNotifier<List<EmotionTag>> {
  final Ref ref;
  EmotionTagCloudNotifier(this.ref) : super([]) { initAndLoad(); }

  Future<Database> get _db => ref.read(databaseProvider.future);

  Future<void> initAndLoad() async {
    await _initDefaultTags();
    await loadTags();
  }

  Future<void> _initDefaultTags() async {
    final db = await _db;
    final existing = await db.query('emotion_tags');
    if (existing.isEmpty) {
      final defaults = [
        ('开心', 'positive', 'happy'),
        ('兴奋', 'positive', 'excited'),
        ('感激', 'positive', 'grateful'),
        ('满足', 'positive', 'satisfied'),
        ('平静', 'neutral', 'calm'),
        ('专注', 'neutral', 'focused'),
        ('期待', 'neutral', 'anticipating'),
        ('焦虑', 'negative', 'anxious'),
        ('悲伤', 'negative', 'sad'),
        ('愤怒', 'negative', 'angry'),
        ('疲惫', 'negative', 'tired'),
        ('压力大', 'negative', 'stressed'),
      ];
      for (final (name, type, cat) in defaults) {
        await db.insert('emotion_tags', {
          'tag_name': name, 'tag_type': type, 'emotion_category': cat,
          'created_at': DateTime.now().toIso8601String(),
        });
      }
    }
  }

  Future<void> loadTags() async {
    final db = await _db;
    final maps = await db.query('emotion_tags', orderBy: 'occurrence_count DESC');
    state = maps.map((m) => EmotionTag.fromMap(m)).toList();
  }

  Future<void> recordEmotion(String tagName) async {
    final db = await _db;
    final existing = await db.query('emotion_tags', where: 'tag_name = ?', whereArgs: [tagName]);
    if (existing.isNotEmpty) {
      await db.rawUpdate('UPDATE emotion_tags SET occurrence_count = occurrence_count + 1, last_used_at = ? WHERE tag_name = ?',
        [DateTime.now().toIso8601String(), tagName]);
    } else {
      await db.insert('emotion_tags', {
        'tag_name': tagName, 'tag_type': 'custom', 'emotion_category': 'custom',
        'created_at': DateTime.now().toIso8601String(),
      });
    }
    await loadTags();
  }
}

class EmotionTagCloudScreen extends ConsumerStatefulWidget {
  const EmotionTagCloudScreen({super.key});
  @override
  ConsumerState<EmotionTagCloudScreen> createState() => _EmotionTagCloudScreenState();
}

class _EmotionTagCloudScreenState extends ConsumerState<EmotionTagCloudScreen> {
  String _filter = 'all';

  @override
  Widget build(BuildContext context) {
    final tags = ref.watch(emotionTagCloudProvider);
    final filtered = _filter == 'all' ? tags : tags.where((t) => t.tagType == _filter).toList();
    final maxCount = filtered.isEmpty ? 1 : filtered.map((t) => t.occurrenceCount).reduce((a, b) => a > b ? a : b);

    return Scaffold(
      appBar: AppBar(
        title: const Text('情感标签云'),
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: () => _showAddDialog()),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _buildFilterChip('all', '全部'),
                const SizedBox(width: 8),
                _buildFilterChip('positive', '😊 正面'),
                const SizedBox(width: 8),
                _buildFilterChip('neutral', '😐 中性'),
                const SizedBox(width: 8),
                _buildFilterChip('negative', '😢 负面'),
              ],
            ),
          ),
          Expanded(
            child: filtered.isEmpty
                ? const Center(child: Text('暂无标签', style: TextStyle(color: Colors.grey)))
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      alignment: WrapAlignment.center,
                      children: filtered.map((tag) {
                        final scale = maxCount > 0 ? tag.occurrenceCount / maxCount : 0.0;
                        final fontSize = 14.0 + scale * 16;
                        final color = _getColorForType(tag.tagType);
                        
                        return GestureDetector(
                          onTap: () => _recordEmotion(tag.tagName),
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8 + scale * 8),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: color.withOpacity(0.5)),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(tag.tagName, style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w600, color: color)),
                                Text('${tag.occurrenceCount}次', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String type, String label) {
    final selected = _filter == type;
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => setState(() => _filter = type),
    );
  }

  Color _getColorForType(String type) {
    switch (type) {
      case 'positive': return Colors.green;
      case 'neutral': return Colors.blue;
      case 'negative': return Colors.red;
      default: return Colors.purple;
    }
  }

  void _recordEmotion(String tagName) async {
    await ref.read(emotionTagCloudProvider.notifier).recordEmotion(tagName);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('已记录情感: $tagName')));
    }
  }

  void _showAddDialog() {
    final ctrl = TextEditingController();
    String selectedType = 'positive';
    
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('添加情感标签'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: ctrl, decoration: const InputDecoration(labelText: '标签名称', border: OutlineInputBorder())),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedType,
                decoration: const InputDecoration(labelText: '情感类型', border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: 'positive', child: Text('😊 正面')),
                  DropdownMenuItem(value: 'neutral', child: Text('😐 中性')),
                  DropdownMenuItem(value: 'negative', child: Text('😢 负面')),
                ],
                onChanged: (v) => setState(() => selectedType = v ?? 'positive'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
            ElevatedButton(
              onPressed: () async {
                if (ctrl.text.isNotEmpty) {
                  await ref.read(emotionTagCloudProvider.notifier).recordEmotion(ctrl.text);
                  if (!mounted) return;
                  Navigator.pop(ctx);
                }
              },
              child: const Text('添加'),
            ),
          ],
        ),
      ),
    );
  }
}