import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/quick_review_model.dart';
import '../data/quick_review_repository.dart';

final dueCardsProvider = FutureProvider.autoDispose<List<QuickReviewCard>>((ref) async {
  final repo = ref.watch(quickReviewRepositoryProvider);
  return await repo.getDueCards();
});

final allCardsProvider = FutureProvider.autoDispose<List<QuickReviewCard>>((ref) async {
  final repo = ref.watch(quickReviewRepositoryProvider);
  return await repo.getAllCards();
});

final cardStatsProvider = FutureProvider.autoDispose<Map<String, int>>((ref) async {
  final repo = ref.watch(quickReviewRepositoryProvider);
  return await repo.getStatistics();
});

class QuickReviewScreen extends ConsumerStatefulWidget {
  const QuickReviewScreen({super.key});

  @override
  ConsumerState<QuickReviewScreen> createState() => _QuickReviewScreenState();
}

class _QuickReviewScreenState extends ConsumerState<QuickReviewScreen> {
  int _currentIndex = 0;
  bool _isFlipped = false;
  List<QuickReviewCard> _reviewCards = [];

  @override
  Widget build(BuildContext context) {
    final dueCards = ref.watch(dueCardsProvider);
    // Watch stats for potential future use
    ref.watch(cardStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quick Review'),
        actions: [
          IconButton(
            icon: const Icon(Icons.list),
            onPressed: () => _showAllCards(context),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddCardDialog(context),
          ),
        ],
      ),
      body: dueCards.when(
        data: (cards) {
          if (cards.isEmpty) {
            return _buildEmptyState();
          }
          _reviewCards = cards;
          return _buildReviewUI(cards);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildEmptyState() {
    final stats = ref.watch(cardStatsProvider);
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle, size: 64, color: Colors.green[400]),
          const SizedBox(height: 16),
          const Text(
            'All caught up!',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'No cards due for review',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          stats.when(
            data: (s) => Text(
              'Total: ${s['total_cards']} cards | Mastered: ${s['mastered_cards']}',
              style: TextStyle(color: Colors.grey[500]),
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => _showAllCards(context),
            icon: const Icon(Icons.library_books),
            label: const Text('Browse All Cards'),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewUI(List<QuickReviewCard> cards) {
    if (_currentIndex >= cards.length) {
      return _buildCompletionScreen(cards.length);
    }

    final card = cards[_currentIndex];
    
    return Column(
      children: [
        _buildProgress(cards.length),
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _isFlipped = !_isFlipped),
            child: Card(
              margin: const EdgeInsets.all(24),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: Text(
                        _isFlipped ? card.back : card.front,
                        key: ValueKey(_isFlipped),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _isFlipped ? 'Answer' : 'Tap to reveal',
                      style: TextStyle(color: Colors.grey[500]),
                    ),
                    if (_isFlipped && card.category != null) ...[
                      const SizedBox(height: 16),
                      Chip(label: Text(card.category!)),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
        if (_isFlipped) _buildRatingButtons(card),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildProgress(int total) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Card ${_currentIndex + 1} of $total',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                '${((_currentIndex / total) * 100).round()}%',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: (_currentIndex + 1) / total,
            backgroundColor: Colors.grey[200],
          ),
        ],
      ),
    );
  }

  Widget _buildRatingButtons(QuickReviewCard card) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const Text(
            'How well did you remember?',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildRatingButton(0, 'Again', Colors.red),
              _buildRatingButton(3, 'Hard', Colors.orange),
              _buildRatingButton(4, 'Good', Colors.green),
              _buildRatingButton(5, 'Easy', Colors.blue),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRatingButton(int quality, String label, Color color) {
    return ElevatedButton(
      onPressed: () => _handleRating(quality),
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.2),
        foregroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(
            _getQualityDescription(quality),
            style: const TextStyle(fontSize: 10),
          ),
        ],
      ),
    );
  }

  String _getQualityDescription(int quality) {
    switch (quality) {
      case 0: return 'Complete blackout';
      case 3: return 'Recalled with difficulty';
      case 4: return 'Recalled correctly';
      case 5: return 'Perfect recall';
      default: return '';
    }
  }

  Widget _buildCompletionScreen(int cardsReviewed) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.celebration, size: 64, color: Colors.amber),
          const SizedBox(height: 16),
          const Text(
            'Session Complete!',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'You reviewed $cardsReviewed cards',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {
              setState(() {
                _currentIndex = 0;
                _isFlipped = false;
              });
              ref.invalidate(dueCardsProvider);
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Review Again'),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => _showAllCards(context),
            child: const Text('Browse All Cards'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleRating(int quality) async {
    if (_currentIndex >= _reviewCards.length) return;
    
    final repo = ref.read(quickReviewRepositoryProvider);
    final card = _reviewCards[_currentIndex];
    
    // Record the review
    final review = CardReview(
      cardId: card.id!,
      reviewedAt: DateTime.now().toIso8601String(),
      quality: quality,
      easeFactor: card.easeFactor,
      intervalDays: card.intervalDays,
    );
    await repo.recordReview(review);
    
    // Update card with new SM-2 values
    final updatedCard = repo.updateCardWithReview(card, quality);
    await repo.updateCard(updatedCard);
    
    // Move to next card
    setState(() {
      _currentIndex++;
      _isFlipped = false;
    });
    
    ref.invalidate(dueCardsProvider);
  }

  void _showAllCards(BuildContext context) {
    final allCards = ref.read(allCardsProvider);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Text(
                    'All Cards',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: allCards.when(
                data: (cards) {
                  if (cards.isEmpty) {
                    return const Center(child: Text('No cards yet'));
                  }
                  return ListView.builder(
                    controller: scrollController,
                    itemCount: cards.length,
                    itemBuilder: (context, index) {
                      final card = cards[index];
                      return ListTile(
                        title: Text(card.front),
                        subtitle: card.category != null
                            ? Text(card.category!)
                            : null,
                        trailing: card.isDueForReview
                            ? const Chip(
                                label: Text('Due'),
                                backgroundColor: Colors.orange,
                              )
                            : null,
                        onTap: () {
                          Navigator.pop(context);
                          _editCard(card);
                        },
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, s) => Center(child: Text('Error: $e')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddCardDialog(BuildContext context) {
    final frontController = TextEditingController();
    final backController = TextEditingController();
    String? category;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Create Flashcard'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: frontController,
                  decoration: const InputDecoration(
                    labelText: 'Front (Question)',
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: backController,
                  decoration: const InputDecoration(
                    labelText: 'Back (Answer)',
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: const [
                    DropdownMenuItem(value: 'general', child: Text('General')),
                    DropdownMenuItem(value: 'language', child: Text('Language')),
                    DropdownMenuItem(value: 'science', child: Text('Science')),
                    DropdownMenuItem(value: 'history', child: Text('History')),
                    DropdownMenuItem(value: 'math', child: Text('Math')),
                  ],
                  onChanged: (value) {
                    setState(() => category = value);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (frontController.text.isNotEmpty && backController.text.isNotEmpty) {
                  _createCard(
                    frontController.text,
                    backController.text,
                    category,
                  );
                  Navigator.pop(context);
                }
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  void _editCard(QuickReviewCard card) {
    final frontController = TextEditingController(text: card.front);
    final backController = TextEditingController(text: card.back);
    String? category = card.category;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Edit Flashcard'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: frontController,
                  decoration: const InputDecoration(labelText: 'Front'),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: backController,
                  decoration: const InputDecoration(labelText: 'Back'),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: category,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: const [
                    DropdownMenuItem(value: 'general', child: Text('General')),
                    DropdownMenuItem(value: 'language', child: Text('Language')),
                    DropdownMenuItem(value: 'science', child: Text('Science')),
                    DropdownMenuItem(value: 'history', child: Text('History')),
                    DropdownMenuItem(value: 'math', child: Text('Math')),
                  ],
                  onChanged: (value) {
                    setState(() => category = value);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                _deleteCard(card);
                Navigator.pop(context);
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
            ElevatedButton(
              onPressed: () {
                if (frontController.text.isNotEmpty && backController.text.isNotEmpty) {
                  _updateCard(card.copyWith(
                    front: frontController.text,
                    back: backController.text,
                    category: category,
                  ));
                  Navigator.pop(context);
                }
              },
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createCard(String front, String back, String? category) async {
    final repo = ref.read(quickReviewRepositoryProvider);
    final now = DateTime.now().toIso8601String();
    final card = QuickReviewCard(
      front: front,
      back: back,
      category: category,
      createdAt: now,
      updatedAt: now,
    );
    await repo.insertCard(card);
    ref.invalidate(allCardsProvider);
    ref.invalidate(dueCardsProvider);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Card created!'), backgroundColor: Colors.green),
      );
    }
  }

  Future<void> _updateCard(QuickReviewCard card) async {
    final repo = ref.read(quickReviewRepositoryProvider);
    await repo.updateCard(card.copyWith(updatedAt: DateTime.now().toIso8601String()));
    ref.invalidate(allCardsProvider);
    ref.invalidate(dueCardsProvider);
  }

  Future<void> _deleteCard(QuickReviewCard card) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Card?'),
        content: Text('Delete "${card.front}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      final repo = ref.read(quickReviewRepositoryProvider);
      await repo.deleteCard(card.id!);
      ref.invalidate(allCardsProvider);
      ref.invalidate(dueCardsProvider);
    }
  }
}