import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:thing_note/core/database/database_provider.dart';

/// 洞察卡片服务
final insightCardsServiceProvider = Provider<InsightCardsService>((ref) {
  final dbAsync = ref.watch(databaseProvider);
  return InsightCardsService(dbAsync);
});

final insightCardsProvider = FutureProvider<List<InsightCard>>((ref) async {
  final service = ref.watch(insightCardsServiceProvider);
  return service.getCards();
});

class InsightCardsService {
  final AsyncValue<Database> _dbAsync;

  InsightCardsService(this._dbAsync);

  Future<Database> get _db async {
    final db = _dbAsync.value;
    if (db == null) throw Exception('Database not initialized');
    return db;
  }

  Future<List<InsightCard>> getCards() async {
    final db = await _db;
    final maps = await db.query('insight_cards', orderBy: 'created_at DESC');
    return maps.map((m) => InsightCard.fromMap(m)).toList();
  }

  Future<int> createCard(InsightCard card) async {
    final db = await _db;
    return db.insert('insight_cards', card.toMap()..remove('id'));
  }

  Future<int> deleteCard(int id) async {
    final db = await _db;
    return db.delete('insight_cards', where: 'id = ?', whereArgs: [id]);
  }

  Future<CardStats> generateWeeklyStats() async {
    final db = await _db;
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));

    final records = await db.rawQuery('''
      SELECT COUNT(*) as count, COALESCE(SUM(duration_sec), 0) as duration
      FROM episode_records
      WHERE occurred_at >= ?
    ''', [weekAgo.toIso8601String()]);

    final habits = await db.rawQuery('''
      SELECT COUNT(*) as total, SUM(CASE WHEN completed = 1 THEN 1 ELSE 0 END) as completed
      FROM habits
      WHERE created_at >= ?
    ''', [weekAgo.toIso8601String()]);

    return CardStats(
      recordCount: records.first['count'] as int? ?? 0,
      totalMinutes: ((records.first['duration'] as int? ?? 0) / 60).round(),
      habitCompletion: habits.isNotEmpty
          ? ((habits.first['completed'] as int? ?? 0) / (habits.first['total'] as int? ?? 1) * 100)
          : 0.0,
    );
  }
}

class InsightCard {
  final int? id;
  final String cardType;
  final String title;
  final String? content;
  final String? imagePath;
  final DateTime createdAt;

  InsightCard({
    this.id,
    required this.cardType,
    required this.title,
    this.content,
    this.imagePath,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'card_type': cardType,
      'title': title,
      'content': content,
      'image_path': imagePath,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory InsightCard.fromMap(Map<String, dynamic> map) {
    return InsightCard(
      id: map['id'] as int?,
      cardType: map['card_type'] as String,
      title: map['title'] as String,
      content: map['content'] as String?,
      imagePath: map['image_path'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}

class CardStats {
  final int recordCount;
  final int totalMinutes;
  final double habitCompletion;

  CardStats({
    required this.recordCount,
    required this.totalMinutes,
    required this.habitCompletion,
  });

  String get formattedDuration {
    final hours = totalMinutes ~/ 60;
    final mins = totalMinutes % 60;
    if (hours > 0) return '${hours}h ${mins}m';
    return '${mins}m';
  }
}

class InsightCardsScreen extends ConsumerWidget {
  const InsightCardsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cardsAsync = ref.watch(insightCardsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('数据洞察卡片'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _generateCard(context, ref),
            tooltip: '生成卡片',
          ),
        ],
      ),
      body: cardsAsync.when(
        data: (cards) {
          if (cards.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.analytics, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('暂无洞察卡片'),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () => _generateCard(context, ref),
                    icon: const Icon(Icons.add),
                    label: const Text('生成卡片'),
                  ),
                ],
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.85,
            ),
            itemCount: cards.length,
            itemBuilder: (context, index) => _CardWidget(card: cards[index]),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('加载失败: $e')),
      ),
    );
  }

  void _generateCard(BuildContext context, WidgetRef ref) async {
    final service = ref.read(insightCardsServiceProvider);
    final stats = await service.generateWeeklyStats();

    await service.createCard(InsightCard(
      cardType: 'weekly',
      title: '本周数据洞察',
      content: '记录: ${stats.recordCount}条 | 时长: ${stats.formattedDuration} | 习惯完成: ${stats.habitCompletion.toStringAsFixed(0)}%',
    ));

    ref.invalidate(insightCardsProvider);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('卡片已生成')),
      );
    }
  }
}

class _CardWidget extends StatelessWidget {
  final InsightCard card;

  const _CardWidget({required this.card});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(_getCardIcon(card.cardType), color: _getCardColor(card.cardType)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    card.title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (card.content != null)
              Expanded(
                child: Text(
                  card.content!,
                  style: TextStyle(color: Colors.grey[600]),
                  maxLines: 5,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatDate(card.createdAt),
                  style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.share, size: 20),
                      onPressed: () {},
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 20),
                      onPressed: () {},
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCardIcon(String type) {
    switch (type) {
      case 'weekly':
        return Icons.calendar_view_week;
      case 'monthly':
        return Icons.calendar_month;
      case 'milestone':
        return Icons.emoji_events;
      default:
        return Icons.analytics;
    }
  }

  Color _getCardColor(String type) {
    switch (type) {
      case 'weekly':
        return Colors.blue;
      case 'monthly':
        return Colors.purple;
      case 'milestone':
        return Colors.amber;
      default:
        return Colors.green;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}';
  }
}