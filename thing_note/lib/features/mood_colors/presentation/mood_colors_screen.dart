import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/mood_colors/data/mood_colors_repository.dart';
import 'package:thing_note/features/mood_colors/domain/mood_color.dart';

class MoodColorsScreen extends ConsumerWidget {
  const MoodColorsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todayAsync = ref.watch(moodColorsTodayProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('情绪颜色'),
      ),
      body: todayAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('错误: $e')),
        data: (moodColor) => _buildContent(context, ref, moodColor),
      ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, MoodColor? moodColor) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Text('选择今日心情颜色', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('用颜色表达今天的情绪', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 24),
          // 当前颜色展示
          if (moodColor != null) ...[
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: moodColor.color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: moodColor.color.withOpacity(0.4), blurRadius: 20, spreadRadius: 4),
                ],
              ),
              child: Center(
                child: Text(
                  moodColor.primaryEmotion ?? '',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '情绪强度: ${(moodColor.intensity * 100).toInt()}%',
              style: const TextStyle(fontSize: 14),
            ),
            Slider(
              value: moodColor.intensity,
              onChanged: (v) {},
              min: 0.2,
              max: 1.0,
            ),
          ],
          const SizedBox(height: 24),
          // 颜色选择网格
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: MoodColorPresets.presets.map((preset) {
              final isSelected = moodColor?.colorHex == preset['color'];
              return GestureDetector(
                onTap: () async {
                  final now = DateTime.now();
                  final date = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
                  await ref.read(moodColorsRepositoryProvider).upsertMoodColor(
                    date,
                    preset['color'] as String,
                    preset['mood'] as int,
                    preset['label'] as String,
                    1.0,
                  );
                  ref.invalidate(moodColorsTodayProvider);
                },
                child: Column(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: Color(_parseHex(preset['color'] as String)),
                        shape: BoxShape.circle,
                        border: isSelected
                            ? Border.all(color: Colors.white, width: 3)
                            : null,
                        boxShadow: isSelected
                            ? [BoxShadow(color: Color(_parseHex(preset['color'] as String)).withOpacity(0.6), blurRadius: 12)]
                            : null,
                      ),
                      child: isSelected
                          ? const Icon(Icons.check, color: Colors.white, size: 24)
                          : null,
                    ),
                    const SizedBox(height: 4),
                    Text(preset['label'] as String, style: const TextStyle(fontSize: 12)),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          // 月度颜色趋势
          _MonthlyColorTrend(),
        ],
      ),
    );
  }

  int _parseHex(String hex) {
    hex = hex.replaceAll('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    return int.parse(hex, radix: 16);
  }
}

class _MonthlyColorTrend extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final repo = ref.watch(moodColorsRepositoryProvider);

    return FutureBuilder<List<MoodColor>>(
      future: repo.getMoodColorsForMonth(now.year, now.month),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }
        final colors = snapshot.data!;
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('本月已记录 ${colors.length} 天', style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: colors.map((c) {
                    final day = int.tryParse(c.date.split('-').last) ?? 0;
                    return Tooltip(
                      message: '${c.date} - ${c.primaryEmotion ?? "未知"}',
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: c.color,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Center(
                          child: Text('$day', style: const TextStyle(fontSize: 10, color: Colors.white)),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
