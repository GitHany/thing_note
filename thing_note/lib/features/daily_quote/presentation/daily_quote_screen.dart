import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/daily_quote/data/daily_quote_repository.dart';
import 'package:thing_note/features/daily_quote/domain/daily_quote.dart';

final todayQuoteProvider = FutureProvider<DailyQuote?>((ref) async {
  final repository = ref.watch(dailyQuoteRepositoryProvider);
  await repository.initializeDefaultQuotes();
  return repository.getTodayQuote();
});

final allQuotesProvider = FutureProvider<List<DailyQuote>>((ref) async {
  final repository = ref.watch(dailyQuoteRepositoryProvider);
  return repository.getAllQuotes();
});

class DailyQuoteScreen extends ConsumerWidget {
  const DailyQuoteScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quoteAsync = ref.watch(todayQuoteProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('每日一言'),
        actions: [
          IconButton(
            icon: const Icon(Icons.list),
            onPressed: () => _showAllQuotes(context, ref),
          ),
        ],
      ),
      body: quoteAsync.when(
        data: (quote) {
          if (quote == null) {
            return const Center(child: Text('暂无名言'));
          }
          return _buildQuoteCard(context, quote, ref);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('加载失败: $e')),
      ),
    );
  }

  Widget _buildQuoteCard(BuildContext context, DailyQuote quote, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Card(
            elevation: 4,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Theme.of(context).colorScheme.primaryContainer,
                    Theme.of(context).colorScheme.secondaryContainer,
                  ],
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.format_quote,
                    size: 48,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '"${quote.quoteText}"',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontStyle: FontStyle.italic,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  if (quote.author != null)
                    Text(
                      '—— ${quote.author}',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _getCategoryLabel(quote.category),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (quote.actionSuggestion != null) ...[
            const SizedBox(height: 24),
            Card(
              color: Theme.of(context).colorScheme.tertiaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      Icons.lightbulb,
                      color: Theme.of(context).colorScheme.onTertiaryContainer,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '行动建议',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onTertiaryContainer,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            quote.actionSuggestion!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onTertiaryContainer,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed: () => _shareQuote(context, quote),
                icon: const Icon(Icons.share),
                label: const Text('分享'),
              ),
              const SizedBox(width: 16),
              OutlinedButton.icon(
                onPressed: () => _toggleFavorite(context, ref, quote),
                icon: Icon(quote.isFavorite ? Icons.favorite : Icons.favorite_border),
                label: Text(quote.isFavorite ? '已收藏' : '收藏'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getCategoryLabel(String category) {
    switch (category) {
      case 'inspiration':
        return '励志';
      case 'wisdom':
        return '哲理';
      case 'motivation':
        return '名言';
      case 'poetry':
        return '诗词';
      default:
        return category;
    }
  }

  void _shareQuote(BuildContext context, DailyQuote quote) {
    final text = '"${quote.quoteText}"${quote.author != null ? "\n—— ${quote.author}" : ""}';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('分享内容已复制: $text')),
    );
  }

  Future<void> _toggleFavorite(BuildContext context, WidgetRef ref, DailyQuote quote) async {
    final repository = ref.read(dailyQuoteRepositoryProvider);
    await repository.toggleFavorite(quote.id!, !quote.isFavorite);
    ref.invalidate(todayQuoteProvider);
  }

  void _showAllQuotes(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) {
          final quotesAsync = ref.watch(allQuotesProvider);
          return Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Text('全部名言', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: quotesAsync.when(
                  data: (quotes) => ListView.builder(
                    controller: scrollController,
                    itemCount: quotes.length,
                    itemBuilder: (context, index) {
                      final quote = quotes[index];
                      return ListTile(
                        leading: Icon(
                          quote.isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: quote.isFavorite ? Colors.red : null,
                        ),
                        title: Text(quote.quoteText, maxLines: 2, overflow: TextOverflow.ellipsis),
                        subtitle: quote.author != null ? Text('—— ${quote.author}') : null,
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(_getCategoryLabel(quote.category), style: const TextStyle(fontSize: 12)),
                        ),
                      );
                    },
                  ),
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('加载失败: $e')),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}