import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/weekly_theme_suggestions/data/weekly_theme_repository.dart';

final weeklyThemesProvider = FutureProvider<List<WeeklyTheme>>((ref) async {
  final repository = ref.watch(weeklyThemeRepositoryProvider);
  return repository.getAllThemes();
});

final currentThemeProvider = FutureProvider<WeeklyTheme?>((ref) async {
  final repository = ref.watch(weeklyThemeRepositoryProvider);
  return repository.getCurrentTheme();
});

class WeeklyTheme {
  final int? id;
  final String themeName;
  final String? colorScheme;
  final String? backgroundImage;
  final DateTime startDate;
  final DateTime? endDate;
  final bool isActive;
  final DateTime createdAt;

  WeeklyTheme({
    this.id,
    required this.themeName,
    this.colorScheme,
    this.backgroundImage,
    required this.startDate,
    this.endDate,
    this.isActive = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory WeeklyTheme.fromMap(Map<String, dynamic> map) {
    return WeeklyTheme(
      id: map['id'] as int?,
      themeName: map['theme_name'] as String,
      colorScheme: map['color_scheme'] as String?,
      backgroundImage: map['background_image'] as String?,
      startDate: DateTime.parse(map['start_date'] as String),
      endDate: map['end_date'] != null ? DateTime.parse(map['end_date'] as String) : null,
      isActive: (map['is_active'] as int?) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  List<Color> get colors {
    if (colorScheme == null) return [Colors.blue, Colors.purple];
    try {
      final parts = colorScheme!.split(',');
      return parts.map((p) => Color(int.parse(p.trim()))).toList();
    } catch (_) {
      return [Colors.blue, Colors.purple];
    }
  }
}

class WeeklyThemeSuggestionsScreen extends ConsumerWidget {
  const WeeklyThemeSuggestionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentAsync = ref.watch(currentThemeProvider);
    final themesAsync = ref.watch(weeklyThemesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('周主题建议'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCurrentThemeCard(context, currentAsync),
            const SizedBox(height: 24),
            _buildSuggestionSection(context, ref),
            const SizedBox(height: 24),
            _buildThemeHistory(context, themesAsync),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentThemeCard(BuildContext context, AsyncValue<WeeklyTheme?> currentAsync) {
    return Card(
      child: currentAsync.when(
        data: (theme) {
          if (theme == null) {
            return const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: Text('暂无当前主题')),
            );
          }

          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                colors: theme.colors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('本周主题', style: TextStyle(color: Colors.white70, fontSize: 12)),
                const SizedBox(height: 4),
                Text(
                  theme.themeName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Text(
                      '${theme.startDate.month}/${theme.startDate.day} - ${theme.endDate?.month ?? ""}/${theme.endDate?.day ?? ""}',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    const Spacer(),
                    if (theme.isActive)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity( 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text('进行中', style: TextStyle(color: Colors.white, fontSize: 12)),
                      ),
                  ],
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('加载失败: $e')),
      ),
    );
  }

  Widget _buildSuggestionSection(BuildContext context, WidgetRef ref) {
    final suggestions = [
      _ThemeSuggestion(
        name: '专注提升',
        emoji: '🎯',
        colors: [Colors.blue, Colors.indigo],
        description: '专注于效率和产出',
      ),
      _ThemeSuggestion(
        name: '健康生活',
        emoji: '💪',
        colors: [Colors.green, Colors.teal],
        description: '关注身体和心理健康',
      ),
      _ThemeSuggestion(
        name: '学习成长',
        emoji: '📚',
        colors: [Colors.orange, Colors.amber],
        description: '每天进步一点点',
      ),
      _ThemeSuggestion(
        name: '创意迸发',
        emoji: '✨',
        colors: [Colors.purple, Colors.pink],
        description: '释放你的创造力',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('推荐主题', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 12),
        ...suggestions.map((s) => _buildSuggestionCard(context, ref, s)),
      ],
    );
  }

  Widget _buildSuggestionCard(BuildContext context, WidgetRef ref, _ThemeSuggestion suggestion) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _applyTheme(context, ref, suggestion),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              colors: suggestion.colors.map((c) => c.withOpacity( 0.3)).toList(),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: suggestion.colors.first.withOpacity( 0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(suggestion.emoji, style: const TextStyle(fontSize: 24)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      suggestion.name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Text(
                      suggestion.description,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _applyTheme(BuildContext context, WidgetRef ref, _ThemeSuggestion suggestion) async {
    final repository = ref.read(weeklyThemeRepositoryProvider);
    final now = DateTime.now();
    final weekEnd = DateTime(now.year, now.month, now.day + (7 - now.weekday));

    await repository.createTheme(WeeklyTheme(
      themeName: suggestion.name,
      colorScheme: '${suggestion.colors[0].value},${suggestion.colors[1].value}',
      startDate: now,
      endDate: weekEnd,
      isActive: true,
    ));

    ref.invalidate(currentThemeProvider);
    ref.invalidate(weeklyThemesProvider);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('已应用主题: ${suggestion.name}')),
      );
    }
  }

  Widget _buildThemeHistory(BuildContext context, AsyncValue<List<WeeklyTheme>> themesAsync) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('历史主题', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 12),
        themesAsync.when(
          data: (themes) {
            if (themes.isEmpty) {
              return const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('暂无历史记录'),
                ),
              );
            }

            return Column(
              children: themes.take(5).map((theme) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: theme.colors),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  title: Text(theme.themeName),
                  subtitle: Text('${theme.startDate.month}/${theme.startDate.day} - ${theme.endDate?.month ?? ""}/${theme.endDate?.day ?? ""}'),
                  trailing: theme.isActive
                      ? const Icon(Icons.check_circle, color: Colors.green)
                      : null,
                ),
              )).toList(),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text('加载失败: $e'),
        ),
      ],
    );
  }
}

class _ThemeSuggestion {
  final String name;
  final String emoji;
  final List<Color> colors;
  final String description;

  _ThemeSuggestion({
    required this.name,
    required this.emoji,
    required this.colors,
    required this.description,
  });
}