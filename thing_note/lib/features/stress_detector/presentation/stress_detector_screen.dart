import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/utils/date_formatter.dart';
import '../domain/stress_models.dart';
import '../data/stress_repository.dart';

final stressProvider = StateNotifierProvider<StressNotifier, StressState>((ref) {
  return StressNotifier(ref.watch(stressRepositoryProvider));
});

final stressStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  return await ref.watch(stressRepositoryProvider).getStressStats();
});

final stressPatternsProvider = FutureProvider<List<StressPattern>>((ref) async {
  return await ref.watch(stressRepositoryProvider).getPatterns();
});

final strategyEffectivenessProvider = FutureProvider<Map<String, double>>((ref) async {
  return await ref.watch(stressRepositoryProvider).getStrategyEffectiveness();
});

class StressState {
  final List<StressIndicator> indicators;
  final bool isLoading;
  final String? error;

  StressState({this.indicators = const [], this.isLoading = false, this.error});

  StressState copyWith({List<StressIndicator>? indicators, bool? isLoading, String? error}) {
    return StressState(
      indicators: indicators ?? this.indicators,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class StressNotifier extends StateNotifier<StressState> {
  final StressRepository _repository;

  StressNotifier(this._repository) : super(StressState()) {
    loadData();
  }

  Future<void> loadData() async {
    state = state.copyWith(isLoading: true);
    try {
      final indicators = await _repository.getRecent(limit: 50);
      state = state.copyWith(indicators: indicators, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<void> add(StressIndicator indicator) async {
    try {
      await _repository.insert(indicator);
      await loadData();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> updateEffectiveness(int id, int rating) async {
    try {
      await _repository.updateEffectiveness(id, rating);
      await loadData();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}

class StressDetectorScreen extends ConsumerStatefulWidget {
  const StressDetectorScreen({super.key});

  @override
  ConsumerState<StressDetectorScreen> createState() => _StressDetectorScreenState();
}

class _StressDetectorScreenState extends ConsumerState<StressDetectorScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentStressLevel = 5;
  String _currentTriggerType = StressTriggerType.work;
  int _currentMood = 3;
  int _currentEnergy = 3;
  final Set<String> _selectedSymptoms = {};
  final Set<String> _selectedStrategies = {};
  final TextEditingController _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('压力检测'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.add_chart), text: '记录'),
            Tab(icon: Icon(Icons.analytics), text: '统计'),
            Tab(icon: Icon(Icons.insights), text: '分析'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildLogTab(),
          _buildStatsTab(),
          _buildAnalysisTab(),
        ],
      ),
    );
  }

  Widget _buildLogTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildQuickLogCard(),
          const SizedBox(height: 16),
          _buildDetailedLogCard(),
          const SizedBox(height: 16),
          _buildSymptomsCard(),
          const SizedBox(height: 16),
          _buildCopingStrategiesCard(),
          const SizedBox(height: 16),
          _buildNoteCard(),
          const SizedBox(height: 16),
          _buildSubmitButton(),
          const SizedBox(height: 24),
          _buildRecentEntries(),
        ],
      ),
    );
  }

  Widget _buildQuickLogCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.psychology, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text('当前压力水平', style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                '$_currentStressLevel',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: _getStressColor(_currentStressLevel),
                ),
              ),
            ),
            Center(
              child: Text(
                _getStressLabel(_currentStressLevel),
                style: TextStyle(
                  fontSize: 16,
                  color: _getStressColor(_currentStressLevel),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: _getStressColor(_currentStressLevel),
                thumbColor: _getStressColor(_currentStressLevel),
                overlayColor: _getStressColor(_currentStressLevel).withOpacity(0.2),
              ),
              child: Slider(
                value: _currentStressLevel.toDouble(),
                min: 1,
                max: 10,
                divisions: 9,
                label: '$_currentStressLevel',
                onChanged: (value) {
                  setState(() => _currentStressLevel = value.round());
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('1', style: TextStyle(color: Colors.grey[600])),
                Text('10', style: TextStyle(color: Colors.grey[600])),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailedLogCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('详细信息', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            Text('压力来源', style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: StressTriggerType.all.map((type) {
                final isSelected = _currentTriggerType == type;
                return FilterChip(
                  selected: isSelected,
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        StressTriggerType.getIcon(type),
                        size: 16,
                        color: isSelected ? Colors.white : null,
                      ),
                      const SizedBox(width: 4),
                      Text(StressTriggerType.getLabel(type)),
                    ],
                  ),
                  onSelected: (selected) {
                    setState(() => _currentTriggerType = type);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('情绪状态', style: TextStyle(color: Colors.grey[600])),
                      Row(
                        children: List.generate(5, (index) {
                          final value = index + 1;
                          return IconButton(
                            icon: Icon(
                              value <= _currentMood ? Icons.sentiment_very_satisfied : Icons.sentiment_neutral,
                              color: value <= _currentMood ? Colors.amber : Colors.grey,
                            ),
                            onPressed: () => setState(() => _currentMood = value),
                          );
                        }),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('精力水平', style: TextStyle(color: Colors.grey[600])),
                      Row(
                        children: List.generate(5, (index) {
                          final value = index + 1;
                          return IconButton(
                            icon: Icon(
                              value <= _currentEnergy ? Icons.battery_full : Icons.battery_0_bar,
                              color: value <= _currentEnergy ? Colors.green : Colors.grey,
                            ),
                            onPressed: () => setState(() => _currentEnergy = value),
                          );
                        }),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSymptomsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.health_and_safety, size: 20),
                const SizedBox(width: 8),
                Text('身体症状', style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 8),
            Text('可多选', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: StressSymptom.all.map((symptom) {
                final isSelected = _selectedSymptoms.contains(symptom);
                return FilterChip(
                  selected: isSelected,
                  avatar: Icon(
                    StressSymptom.getIcon(symptom),
                    size: 16,
                    color: isSelected ? Colors.white : Colors.grey,
                  ),
                  label: Text(symptom),
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedSymptoms.add(symptom);
                      } else {
                        _selectedSymptoms.remove(symptom);
                      }
                    });
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCopingStrategiesCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.self_improvement, size: 20),
                const SizedBox(width: 8),
                Text('应对策略', style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 8),
            Text('可多选', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: CopingStrategy.all.map((strategy) {
                final isSelected = _selectedStrategies.contains(strategy);
                return FilterChip(
                  selected: isSelected,
                  avatar: Icon(
                    CopingStrategy.getIcon(strategy),
                    size: 16,
                    color: isSelected ? Colors.white : Colors.grey,
                  ),
                  label: Text(strategy),
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedStrategies.add(strategy);
                      } else {
                        _selectedStrategies.remove(strategy);
                      }
                    });
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoteCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.note_add, size: 20),
                const SizedBox(width: 8),
                Text('备注', style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _noteController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: '记录更多关于这次压力的信息...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _logStress,
        icon: const Icon(Icons.save),
        label: const Text('保存记录'),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  Widget _buildRecentEntries() {
    final stressState = ref.watch(stressProvider);
    final indicators = stressState.indicators.take(10).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('最近记录', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        if (stressState.isLoading)
          const Center(child: CircularProgressIndicator())
        else if (indicators.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: Text('暂无记录')),
            ),
          )
        else
          ...indicators.map((i) => _buildIndicatorCard(i)),
      ],
    );
  }

  Widget _buildIndicatorCard(StressIndicator indicator) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: indicator.stressColor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              '${indicator.stressLevel}',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: indicator.stressColor,
              ),
            ),
          ),
        ),
        title: Row(
          children: [
            Icon(indicator.triggerTypeIcon, size: 16, color: Colors.grey),
            const SizedBox(width: 4),
            Text(indicator.triggerTypeLabel),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(indicator.stressLabel),
            if (indicator.copingStrategies.isNotEmpty)
              Wrap(
                spacing: 4,
                children: indicator.copingStrategies
                    .take(2)
                    .map((s) => Chip(
                          label: Text(s, style: const TextStyle(fontSize: 10)),
                          padding: EdgeInsets.zero,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ))
                    .toList(),
              ),
          ],
        ),
        trailing: Text(
          DateFormatter.formatDateTime(indicator.recordedAt),
          style: TextStyle(color: Colors.grey[600], fontSize: 12),
        ),
      ),
    );
  }

  Widget _buildStatsTab() {
    final statsAsync = ref.watch(stressStatsProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          statsAsync.when(
            data: (stats) => _buildStatsOverview(stats),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Error: $e'),
          ),
          const SizedBox(height: 16),
          _buildWeeklyTrend(),
          const SizedBox(height: 16),
          _buildStrategyEffectiveness(),
        ],
      ),
    );
  }

  Widget _buildStatsOverview(Map<String, dynamic> stats) {
    final avgStress = (stats['avg_stress'] as num?)?.toDouble() ?? 0;
    final maxStress = (stats['max_stress'] as num?)?.toInt() ?? 0;
    final totalEntries = (stats['total_entries'] as num?)?.toInt() ?? 0;
    final avgMood = (stats['avg_mood'] as num?)?.toDouble() ?? 0;
    final avgEnergy = (stats['avg_energy'] as num?)?.toDouble() ?? 0;
    final avgEffectiveness = (stats['avg_effectiveness'] as num?)?.toDouble() ?? 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('30天统计', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatColumn('平均压力', avgStress.toStringAsFixed(1), '/10',
                    _getStressColor(avgStress.toInt())),
                _buildStatColumn('最高压力', '$maxStress', '/10', Colors.red),
                _buildStatColumn('记录次数', '$totalEntries', '', Colors.blue),
              ],
            ),
            const Divider(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatColumn('平均情绪', avgMood.toStringAsFixed(1), '/5', Colors.amber),
                _buildStatColumn('平均精力', avgEnergy.toStringAsFixed(1), '/5', Colors.green),
                _buildStatColumn('策略效果', avgEffectiveness.toStringAsFixed(1), '/5', Colors.purple),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: avgStress / 10,
              backgroundColor: Colors.grey[300],
              color: _getStressColor(avgStress.toInt()),
            ),
            const SizedBox(height: 8),
            _buildStressInsight(avgStress),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, String suffix, Color color) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
            if (suffix.isNotEmpty)
              Text(suffix, style: TextStyle(fontSize: 14, color: color)),
          ],
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
      ],
    );
  }

  Widget _buildStressInsight(double avgStress) {
    String insight;
    Color color;
    IconData icon;

    if (avgStress >= 7) {
      insight = '⚠️ 您的压力水平较高，建议密切关注并采取行动';
      color = Colors.red;
      icon = Icons.warning;
    } else if (avgStress >= 5) {
      insight = '📌 您的压力处于中等水平，可以尝试一些减压方法';
      color = Colors.orange;
      icon = Icons.info;
    } else if (avgStress >= 3) {
      insight = '👍 您的压力水平较为健康';
      color = Colors.green;
      icon = Icons.check_circle;
    } else {
      insight = '✨ 您目前压力很低，继续保持！';
      color = Colors.green;
      icon = Icons.celebration;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 8),
          Expanded(child: Text(insight, style: TextStyle(color: color))),
        ],
      ),
    );
  }

  Widget _buildWeeklyTrend() {
    final patternsAsync = ref.watch(stressPatternsProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('压力触发分布', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            patternsAsync.when(
              data: (patterns) {
                if (patterns.isEmpty) {
                  return const Center(child: Text('暂无数据'));
                }
                return Column(
                  children: patterns.map((p) => _buildPatternItem(p)).toList(),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Error: $e'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPatternItem(StressPattern pattern) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(pattern.triggerIcon, color: pattern.severityColor),
              const SizedBox(width: 8),
              Text(pattern.triggerLabel),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: pattern.severityColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${pattern.avgStressLevel.toStringAsFixed(1)}/10',
                  style: TextStyle(color: pattern.severityColor, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text('出现 ${pattern.frequency} 次', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          const SizedBox(height: 4),
          Text(pattern.recommendation, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildStrategyEffectiveness() {
    final effectivenessAsync = ref.watch(strategyEffectivenessProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('策略有效性', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            effectivenessAsync.when(
              data: (effectiveness) {
                if (effectiveness.isEmpty) {
                  return const Center(child: Text('暂无数据'));
                }
                final sorted = effectiveness.entries.toList()
                  ..sort((a, b) => b.value.compareTo(a.value));
                return Column(
                  children: sorted.take(5).map((e) {
                    final effectiveness = e.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Icon(CopingStrategy.getIcon(e.key), size: 20),
                          const SizedBox(width: 8),
                          Expanded(child: Text(e.key)),
                          SizedBox(
                            width: 100,
                            child: LinearProgressIndicator(
                              value: effectiveness / 5,
                              backgroundColor: Colors.grey[300],
                              color: _getEffectivenessColor(effectiveness),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text('${effectiveness.toStringAsFixed(1)}/5'),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Error: $e'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalysisTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSuggestionsCard(),
          const SizedBox(height: 16),
          _buildSymptomsAnalysisCard(),
          const SizedBox(height: 16),
          _buildCopingTipsCard(),
        ],
      ),
    );
  }

  Widget _buildSuggestionsCard() {
    final statsAsync = ref.watch(stressStatsProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.lightbulb, color: Colors.amber),
                const SizedBox(width: 8),
                Text('个性化建议', style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 16),
            statsAsync.when(
              data: (stats) {
                final avgStress = (stats['avg_stress'] as num?)?.toDouble() ?? 5;
                final suggestions = StressSuggestion.generateForLevel(avgStress.toInt());
                return Column(
                  children: suggestions.map((s) => _buildSuggestionItem(s)).toList(),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Error: $e'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionItem(StressSuggestion suggestion) {
    Color priorityColor;
    switch (suggestion.priority) {
      case 'high':
        priorityColor = Colors.red;
        break;
      case 'medium':
        priorityColor = Colors.orange;
        break;
      default:
        priorityColor = Colors.green;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: priorityColor.withOpacity(0.5)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(suggestion.icon, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  suggestion.title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: priorityColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(suggestion.description, style: TextStyle(color: Colors.grey[600])),
          if (suggestion.steps.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...suggestion.steps.asMap().entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(left: 8, top: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${entry.key + 1}. ', style: TextStyle(color: Colors.grey[600])),
                    Expanded(child: Text(entry.value)),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildSymptomsAnalysisCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.medical_services, color: Colors.red),
                const SizedBox(width: 8),
                Text('常见压力症状', style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 16),
            _buildSymptomInfo('头痛', '长期压力可能导致紧张性头痛'),
            _buildSymptomInfo('肌肉紧张', '压力会使肌肉持续收缩，引起酸痛'),
            _buildSymptomInfo('疲劳', '心理压力消耗能量，导致持续疲劳感'),
            _buildSymptomInfo('失眠', '压力激素影响睡眠质量和入睡'),
          ],
        ),
      ),
    );
  }

  Widget _buildSymptomInfo(String symptom, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber, size: 20, color: Colors.orange[700]),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(symptom, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(description, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCopingTipsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.self_improvement, color: Colors.purple),
                const SizedBox(width: 8),
                Text('减压技巧', style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 16),
            _buildTipItem(Icons.air, '深呼吸', '4-7-8呼吸法：吸气4秒，屏气7秒，呼气8秒'),
            _buildTipItem(Icons.fitness_center, '适度运动', '每天30分钟中等强度运动可降低皮质醇'),
            _buildTipItem(Icons.self_improvement, '正念冥想', '每天10-15分钟专注当下，减轻焦虑'),
            _buildTipItem(Icons.chat, '倾诉', '与信任的人分享可减轻情绪负担'),
          ],
        ),
      ),
    );
  }

  Widget _buildTipItem(IconData icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 24, color: Colors.purple),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(description, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _logStress() {
    final indicator = StressIndicator(
      recordedAt: DateTime.now(),
      stressLevel: _currentStressLevel,
      triggerType: _currentTriggerType,
      physicalSymptoms: _selectedSymptoms.toList(),
      copingStrategies: _selectedStrategies.toList(),
      moodScore: _currentMood,
      energyLevel: _currentEnergy,
      note: _noteController.text.isNotEmpty ? _noteController.text : null,
    );

    ref.read(stressProvider.notifier).add(indicator);
    
    // Reset form
    setState(() {
      _currentStressLevel = 5;
      _currentMood = 3;
      _currentEnergy = 3;
      _selectedSymptoms.clear();
      _selectedStrategies.clear();
      _noteController.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('压力记录已保存'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Color _getStressColor(int level) {
    if (level >= 8) return Colors.red.shade700;
    if (level >= 6) return Colors.red.shade400;
    if (level >= 4) return Colors.orange;
    if (level >= 2) return Colors.yellow.shade700;
    return Colors.green;
  }

  String _getStressLabel(int level) {
    if (level >= 8) return '严重压力';
    if (level >= 6) return '较高压力';
    if (level >= 4) return '中等压力';
    if (level >= 2) return '轻度压力';
    return '无明显压力';
  }

  Color _getEffectivenessColor(double effectiveness) {
    if (effectiveness >= 4) return Colors.green;
    if (effectiveness >= 3) return Colors.lightGreen;
    if (effectiveness >= 2) return Colors.orange;
    return Colors.red;
  }
}
