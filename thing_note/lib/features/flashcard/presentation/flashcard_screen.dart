import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/flashcard/domain/flashcard.dart';
import 'package:thing_note/features/flashcard/data/flashcard_provider.dart';

class FlashcardScreen extends ConsumerStatefulWidget {
  const FlashcardScreen({super.key});

  @override
  ConsumerState<FlashcardScreen> createState() => _FlashcardScreenState();
}

class _FlashcardScreenState extends ConsumerState<FlashcardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('闪卡学习'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '学习'),
            Tab(text: '全部'),
            Tab(text: '分类'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _StudyTab(),
          _AllCardsTab(),
          _CategoriesTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => const _FlashcardEditor(),
    );
  }
}

class _StudyTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dueAsync = ref.watch(dueFlashcardsProvider);

    return dueAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('错误: $e')),
      data: (flashcards) {
        if (flashcards.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle, size: 64, color: Colors.green),
                SizedBox(height: 16),
                Text('太棒了！今天没有需要复习的卡片'),
                SizedBox(height: 8),
                Text('点击右下角添加新卡片'),
              ],
            ),
          );
        }
        return _ReviewSession(flashcards: flashcards);
      },
    );
  }
}

class _ReviewSession extends ConsumerStatefulWidget {
  final List<Flashcard> flashcards;
  
  const _ReviewSession({required this.flashcards});

  @override
  ConsumerState<_ReviewSession> createState() => _ReviewSessionState();
}

class _ReviewSessionState extends ConsumerState<_ReviewSession> {
  int _currentIndex = 0;
  bool _showAnswer = false;

  @override
  Widget build(BuildContext context) {
    if (_currentIndex >= widget.flashcards.length) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.celebration, size: 64, color: Colors.amber),
            const SizedBox(height: 16),
            Text('完成！已复习 ${widget.flashcards.length} 张卡片'),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _currentIndex = 0;
                  _showAnswer = false;
                });
              },
              child: const Text('重新开始'),
            ),
          ],
        ),
      );
    }

    final card = widget.flashcards[_currentIndex];

    return Column(
      children: [
        LinearProgressIndicator(
          value: _currentIndex / widget.flashcards.length,
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: GestureDetector(
              onTap: () => setState(() => _showAnswer = !_showAnswer),
              child: Card(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (!_showAnswer) ...[
                        Text(
                          card.front,
                          style: Theme.of(context).textTheme.headlineMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),
                        const Text('点击显示答案', style: TextStyle(color: Colors.grey)),
                      ] else ...[
                        Text(
                          card.front,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                        const Divider(height: 32),
                        Text(
                          card.back,
                          style: Theme.of(context).textTheme.headlineMedium,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        if (_showAnswer)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _ReviewButton(
                  label: '忘了',
                  color: Colors.red,
                  onPressed: () => _review(0),
                ),
                _ReviewButton(
                  label: '困难',
                  color: Colors.orange,
                  onPressed: () => _review(2),
                ),
                _ReviewButton(
                  label: '一般',
                  color: Colors.yellow.shade700,
                  onPressed: () => _review(3),
                ),
                _ReviewButton(
                  label: '简单',
                  color: Colors.green,
                  onPressed: () => _review(5),
                ),
              ],
            ),
          ),
      ],
    );
  }

  void _review(int quality) {
    final card = widget.flashcards[_currentIndex];
    ref.read(flashcardNotifierProvider.notifier).reviewFlashcard(card, quality);
    setState(() {
      _currentIndex++;
      _showAnswer = false;
    });
  }
}

class _ReviewButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onPressed;

  const _ReviewButton({
    required this.label,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(backgroundColor: color),
      child: Text(label),
    );
  }
}

class _AllCardsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cardsAsync = ref.watch(flashcardNotifierProvider);

    return cardsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('错误: $e')),
      data: (cards) {
        if (cards.isEmpty) {
          return const Center(child: Text('还没有卡片'));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: cards.length,
          itemBuilder: (context, index) {
            final card = cards[index];
            return _FlashcardListItem(
              flashcard: card,
              onTap: () => _showEditDialog(context, ref, card),
              onDelete: () => ref.read(flashcardNotifierProvider.notifier).deleteFlashcard(card.id!),
            );
          },
        );
      },
    );
  }

  void _showEditDialog(BuildContext context, WidgetRef ref, Flashcard card) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _FlashcardEditor(existingCard: card),
    );
  }
}

class _FlashcardListItem extends StatelessWidget {
  final Flashcard flashcard;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _FlashcardListItem({
    required this.flashcard,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(flashcard.front),
        subtitle: Text(flashcard.back),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (flashcard.category != null)
              Chip(label: Text(flashcard.category!, style: const TextStyle(fontSize: 10))),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: onDelete,
            ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}

class _CategoriesTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(flashcardCategoriesProvider);

    return categoriesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('错误: $e')),
      data: (categories) {
        if (categories.isEmpty) {
          return const Center(child: Text('还没有分类'));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final category = categories[index];
            return ListTile(
              leading: const Icon(Icons.folder),
              title: Text(category),
              onTap: () {
                // TODO: Navigate to category detail
              },
            );
          },
        );
      },
    );
  }
}

class _FlashcardEditor extends ConsumerStatefulWidget {
  final Flashcard? existingCard;

  const _FlashcardEditor({this.existingCard});

  @override
  ConsumerState<_FlashcardEditor> createState() => _FlashcardEditorState();
}

class _FlashcardEditorState extends ConsumerState<_FlashcardEditor> {
  final _frontController = TextEditingController();
  final _backController = TextEditingController();
  final _categoryController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.existingCard != null) {
      _frontController.text = widget.existingCard!.front;
      _backController.text = widget.existingCard!.back;
      _categoryController.text = widget.existingCard!.category ?? '';
    }
  }

  @override
  void dispose() {
    _frontController.dispose();
    _backController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.existingCard == null ? '添加卡片' : '编辑卡片',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _frontController,
              decoration: const InputDecoration(
                labelText: '正面',
                hintText: '问题',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _backController,
              decoration: const InputDecoration(
                labelText: '背面',
                hintText: '答案',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _categoryController,
              decoration: const InputDecoration(
                labelText: '分类 (可选)',
                hintText: '例如：英语、数学',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _save,
                child: const Text('保存'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _save() {
    if (_frontController.text.isEmpty || _backController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请填写正面和背面')),
      );
      return;
    }

    final now = DateTime.now();
    final flashcard = Flashcard(
      id: widget.existingCard?.id,
      front: _frontController.text.trim(),
      back: _backController.text.trim(),
      category: _categoryController.text.isEmpty ? null : _categoryController.text.trim(),
      linkedRecordId: widget.existingCard?.linkedRecordId,
      easeFactor: widget.existingCard?.easeFactor ?? 2.5,
      intervalDays: widget.existingCard?.intervalDays ?? 1,
      nextReviewAt: widget.existingCard?.nextReviewAt,
      reviewCount: widget.existingCard?.reviewCount ?? 0,
      createdAt: widget.existingCard?.createdAt ?? now,
      updatedAt: now,
    );

    if (widget.existingCard == null) {
      ref.read(flashcardNotifierProvider.notifier).addFlashcard(flashcard);
    } else {
      ref.read(flashcardNotifierProvider.notifier).updateFlashcard(flashcard);
    }

    Navigator.pop(context);
  }
}