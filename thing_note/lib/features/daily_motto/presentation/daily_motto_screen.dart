import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/daily_motto/data/daily_motto_repository.dart';
import 'package:thing_note/features/daily_motto/domain/daily_motto.dart';

class DailyMottoScreen extends ConsumerWidget {
  const DailyMottoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('每日箴言'),
        actions: [
          IconButton(
            icon: const Icon(Icons.shuffle),
            onPressed: () => _refreshQuote(ref),
          ),
        ],
      ),
      body: FutureBuilder<DailyMotto>(
        future: ref.read(dailyMottoRepositoryProvider).getOrCreateTodayMotto(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final motto = snapshot.data;
          if (motto == null) return const Center(child: Text('加载中...'));
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 40),
                const Icon(Icons.format_quote, size: 48, color: Colors.amber),
                const SizedBox(height: 16),
                Text(
                  motto.quote ?? '',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w500, height: 1.6),
                ),
                const SizedBox(height: 16),
                if (motto.author != null)
                  Text('—— ${motto.author}', style: TextStyle(fontSize: 16, color: Colors.grey.shade600)),
                const SizedBox(height: 40),
                const Divider(),
                const SizedBox(height: 16),
                const Text('今日反思', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                TextField(
                  maxLines: 4,
                  decoration: const InputDecoration(
                    hintText: '写下你对这句箴言的思考...',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    // 可以自动保存
                  },
                ),
                const SizedBox(height: 16),
                const Text('今日心情', style: TextStyle(fontSize: 16)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (i) {
                    final level = i + 1;
                    return IconButton(
                      icon: Icon(
                        level <= (motto.moodAfter ?? 0) ? Icons.sentiment_very_satisfied : Icons.sentiment_neutral,
                        color: _moodColor(level),
                        size: 36,
                      ),
                      onPressed: () async {
                        // 更新心情
                      },
                    );
                  }),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: Icon(
                        motto.isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: motto.isFavorite ? Colors.red : Colors.grey,
                      ),
                      onPressed: () {
                        ref.read(dailyMottoRepositoryProvider).toggleFavorite(motto.id!, !motto.isFavorite);
                        ref.invalidate(todayMottoProvider);
                      },
                    ),
                    const SizedBox(width: 16),
                    OutlinedButton.icon(
                      onPressed: () => _shareQuote(context, motto),
                      icon: const Icon(Icons.share),
                      label: const Text('分享'),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Color _moodColor(int level) {
    switch (level) {
      case 1: return Colors.red;
      case 2: return Colors.orange;
      case 3: return Colors.amber;
      case 4: return Colors.lightGreen;
      case 5: return Colors.green;
      default: return Colors.grey;
    }
  }

  void _refreshQuote(WidgetRef ref) {
    final repo = ref.read(dailyMottoRepositoryProvider);
    repo.getOrCreateTodayMotto().then((motto) async {
      final idx = DateTime.now().millisecond % MottoLibrary.defaultMottos.length;
      final selected = MottoLibrary.defaultMottos[idx];
      await repo.updateMotto(motto.copyWith(
        quote: selected['quote'],
        author: selected['author'],
      ));
      ref.invalidate(todayMottoProvider);
    });
  }

  void _shareQuote(BuildContext context, DailyMotto motto) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('分享: "${motto.quote}" —— ${motto.author}')),
    );
  }
}
