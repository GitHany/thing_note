import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/quick_review_flash/data/flash_card_repository.dart';
import 'package:thing_note/features/quick_review_flash/domain/quick_flash_card.dart';

class QuickReviewFlashScreen extends ConsumerStatefulWidget {
  const QuickReviewFlashScreen({super.key});

  @override
  ConsumerState<QuickReviewFlashScreen> createState() => _QuickReviewFlashScreenState();
}

class _QuickReviewFlashScreenState extends ConsumerState<QuickReviewFlashScreen> {
  int _reviewIndex = 0;
  bool _showBack = false;

  @override
  Widget build(BuildContext context) {
    final dueCardsAsync = ref.watch(flashCardsDueProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('快速闪卡'),
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: () => _showAddDialog(context)),
        ],
      ),
      body: dueCardsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('错误: $e')),
        data: (cards) {
          if (cards.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.school, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('暂无需要复习的卡片', style: TextStyle(fontSize: 18)),
                  const SizedBox(height: 8),
                  const Text('添加新卡片开始学习', style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _showAddDialog(context),
                    icon: const Icon(Icons.add),
                    label: const Text('添加卡片'),
                  ),
                ],
              ),
            );
          }
          return _buildReviewCard(cards);
        },
      ),
    );
  }

  Widget _buildReviewCard(List<QuickFlashCard> cards) {
    if (_reviewIndex >= cards.length) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, size: 64, color: Colors.green),
            const SizedBox(height: 16),
            const Text('今日复习完成！', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('已复习 ${cards.length} 张卡片', style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: () => setState(() { _reviewIndex = 0; _showBack = false; }), child: const Text('重新开始')),
          ],
        ),
      );
    }

    final card = cards[_reviewIndex];
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text('${_reviewIndex + 1} / ${cards.length}', style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 24),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _showBack = !_showBack),
              child: Card(
                elevation: 4,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(32),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _showBack ? card.back : card.front,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 22),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          _showBack ? '答案 (点击查看问题)' : '点击查看答案',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (_showBack)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _ReviewButton(label: '忘记', color: Colors.red, onTap: () => _review(card, 0)),
                _ReviewButton(label: '困难', color: Colors.orange, onTap: () => _review(card, 2)),
                _ReviewButton(label: '一般', color: Colors.amber, onTap: () => _review(card, 3)),
                _ReviewButton(label: '简单', color: Colors.green, onTap: () => _review(card, 4)),
                _ReviewButton(label: '完美', color: Colors.blue, onTap: () => _review(card, 5)),
              ],
            ),
        ],
      ),
    );
  }

  void _review(QuickFlashCard card, int quality) {
    ref.read(flashCardRepositoryProvider).reviewCard(card.id!, quality);
    setState(() {
      _showBack = false;
      _reviewIndex++;
    });
  }

  void _showAddDialog(BuildContext context) {
    final frontCtrl = TextEditingController();
    final backCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('新建闪卡'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: frontCtrl, decoration: const InputDecoration(labelText: '正面 (问题)'), maxLines: 2),
            const SizedBox(height: 8),
            TextField(controller: backCtrl, decoration: const InputDecoration(labelText: '背面 (答案)'), maxLines: 2),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          TextButton(
            onPressed: () {
              if (frontCtrl.text.trim().isEmpty || backCtrl.text.trim().isEmpty) return;
              final now = DateTime.now();
              final card = QuickFlashCard(
                front: frontCtrl.text.trim(),
                back: backCtrl.text.trim(),
                createdAt: now,
                updatedAt: now,
              );
              ref.read(flashCardRepositoryProvider).insertCard(card);
              ref.invalidate(flashCardsDueProvider);
              Navigator.pop(ctx);
            },
            child: const Text('创建'),
          ),
        ],
      ),
    );
  }
}

class _ReviewButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ReviewButton({required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(backgroundColor: color, foregroundColor: Colors.white),
      child: Text(label),
    );
  }
}
