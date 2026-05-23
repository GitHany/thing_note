import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/utils/date_formatter.dart';
import '../data/energy_repository.dart';
import '../domain/energy_record.dart';

final energyProvider = StateNotifierProvider<EnergyNotifier, AsyncValue<List<EnergyRecord>>>((ref) {
  return EnergyNotifier(ref.watch(energyRepositoryProvider));
});

final energyTipProvider = FutureProvider.family<List<EnergyTip>, int>((ref, level) async {
  final repository = ref.watch(energyRepositoryProvider);
  await repository.initializeDefaultTips();
  return await repository.getTipsForLevel(level);
});

class EnergyNotifier extends StateNotifier<AsyncValue<List<EnergyRecord>>> {
  final EnergyRepository _repository;

  EnergyNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadEnergyRecords();
  }

  Future<void> loadEnergyRecords() async {
    state = const AsyncValue.loading();
    try {
      final now = DateTime.now();
      final weekAgo = now.subtract(const Duration(days: 7));
      final records = await _repository.getEnergyByDateRange(
        DateFormatter.formatDate(weekAgo),
        DateFormatter.formatDate(now),
      );
      state = AsyncValue.data(records);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addEnergyRecord(EnergyRecord record) async {
    await _repository.insertEnergyRecord(record);
    await loadEnergyRecords();
  }

  Future<void> updateEnergyRecord(EnergyRecord record) async {
    await _repository.updateEnergyRecord(record);
    await loadEnergyRecords();
  }

  Future<EnergyRecord?> getTodayRecord() async {
    return await _repository.getEnergyByDate(DateFormatter.formatDate(DateTime.now()));
  }
}

class EnergyTrackerScreen extends ConsumerStatefulWidget {
  const EnergyTrackerScreen({super.key});

  @override
  ConsumerState<EnergyTrackerScreen> createState() => _EnergyTrackerScreenState();
}

class _EnergyTrackerScreenState extends ConsumerState<EnergyTrackerScreen> {
  @override
  void initState() {
    super.initState();
    _loadTodayStatus();
  }

  Future<void> _loadTodayStatus() async {
    final record = await ref.read(energyProvider.notifier).getTodayRecord();
    if (record != null) {
      ref.read(currentEnergyProvider.notifier).state = record.level;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentLevel = ref.watch(currentEnergyProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('精力追踪'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTodayCard(context, currentLevel),
            const SizedBox(height: 24),
            _buildWeeklyChart(context),
            const SizedBox(height: 24),
            _buildTipsSection(context, currentLevel),
          ],
        ),
      ),
    );
  }

  Widget _buildTodayCard(BuildContext context, int currentLevel) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text('今日精力', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                final level = index + 1;
                return GestureDetector(
                  onTap: () => _updateEnergyLevel(level),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: level <= currentLevel
                          ? EnergyRecord.getLevelColor(level)
                          : Colors.grey[300],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        '$level',
                        style: TextStyle(
                          color: level <= currentLevel ? Colors.white : Colors.grey,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 16),
            Text(
              EnergyRecord.getLevelLabel(currentLevel),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: EnergyRecord.getLevelColor(currentLevel),
              ),
            ),
            const SizedBox(height: 8),
            Text('点击上方数字记录今天的精力状态', style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }

  Future<void> _updateEnergyLevel(int level) async {
    ref.read(currentEnergyProvider.notifier).state = level;
    final record = EnergyRecord(
      date: DateFormatter.formatDate(DateTime.now()),
      level: level,
      createdAt: DateTime.now().toIso8601String(),
    );
    await ref.read(energyProvider.notifier).addEnergyRecord(record);
  }

  Widget _buildWeeklyChart(BuildContext context) {
    final recordsAsync = ref.watch(energyProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('本周精力趋势', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 16),
        recordsAsync.when(
          data: (records) {
            if (records.isEmpty) {
              return const Card(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: Text('暂无数据')),
                ),
              );
            }

            return Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  height: 150,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: List.generate(7, (index) {
                      final date = DateTime.now().subtract(Duration(days: 6 - index));
                      final dateStr = DateFormatter.formatDate(date);
                      final record = records.where((r) => r.date == dateStr).firstOrNull;
                      final level = record?.level ?? 0;
                      final height = level > 0 ? (level / 5) * 100 : 10.0;

                      return Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            width: 30,
                            height: height,
                            decoration: BoxDecoration(
                              color: level > 0 ? EnergyRecord.getLevelColor(level) : Colors.grey[300],
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            ['一', '二', '三', '四', '五', '六', '日'][date.weekday - 1],
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      );
                    }),
                  ),
                ),
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('错误: $e')),
        ),
      ],
    );
  }

  Widget _buildTipsSection(BuildContext context, int currentLevel) {
    final tipsAsync = ref.watch(energyTipProvider(currentLevel));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('建议', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 16),
        tipsAsync.when(
          data: (tips) {
            if (tips.isEmpty) {
              return const Card(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: Text('记录精力后获取建议')),
                ),
              );
            }

            return Card(
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: tips.length,
                separatorBuilder: (_, __) => const Divider(),
                itemBuilder: (context, index) {
                  return ListTile(
                    leading: const Icon(Icons.lightbulb, color: Colors.amber),
                    title: Text(tips[index].content),
                  );
                },
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => const Center(child: Text('获取建议失败')),
        ),
      ],
    );
  }
}

final currentEnergyProvider = StateProvider<int>((ref) => 3);