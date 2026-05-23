import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/utils/date_formatter.dart';
import '../data/weather_correlation_repository.dart';
import '../domain/weather_correlation.dart';

/// 天气关联分析 Provider
final weatherProvider = StateNotifierProvider<WeatherNotifier, AsyncValue<WeatherState>>((ref) {
  return WeatherNotifier(ref.watch(weatherCorrelationRepositoryProvider));
});

class WeatherState {
  final List<WeatherCorrelation> records;
  final List<WeatherStats> weatherStats;
  final List<TemperatureRangeStats> temperatureStats;
  final String? bestWeatherCondition;
  final String? bestTemperatureRange;

  WeatherState({
    this.records = const [],
    this.weatherStats = const [],
    this.temperatureStats = const [],
    this.bestWeatherCondition,
    this.bestTemperatureRange,
  });

  WeatherState copyWith({
    List<WeatherCorrelation>? records,
    List<WeatherStats>? weatherStats,
    List<TemperatureRangeStats>? temperatureStats,
    String? bestWeatherCondition,
    String? bestTemperatureRange,
  }) {
    return WeatherState(
      records: records ?? this.records,
      weatherStats: weatherStats ?? this.weatherStats,
      temperatureStats: temperatureStats ?? this.temperatureStats,
      bestWeatherCondition: bestWeatherCondition ?? this.bestWeatherCondition,
      bestTemperatureRange: bestTemperatureRange ?? this.bestTemperatureRange,
    );
  }
}

class WeatherNotifier extends StateNotifier<AsyncValue<WeatherState>> {
  final WeatherCorrelationRepository _repository;

  WeatherNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadData();
  }

  Future<void> loadData() async {
    state = const AsyncValue.loading();
    try {
      final records = await _repository.getRecentRecords(30);
      final weatherStats = await _repository.getStatsByWeather();
      final temperatureStats = await _repository.getStatsByTemperature();
      final bestWeather = await _repository.getBestWeatherCondition();
      final bestTemp = await _repository.getBestTemperatureRange();

      state = AsyncValue.data(WeatherState(
        records: records,
        weatherStats: weatherStats,
        temperatureStats: temperatureStats,
        bestWeatherCondition: bestWeather,
        bestTemperatureRange: bestTemp,
      ));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addRecord(WeatherCorrelation record) async {
    await _repository.upsertRecord(record);
    await loadData();
  }

  Future<void> updateRecord(WeatherCorrelation record) async {
    await _repository.upsertRecord(record);
    await loadData();
  }

  Future<WeatherCorrelation?> getTodayRecord() async {
    return await _repository.getByDate(DateFormatter.formatDate(DateTime.now()));
  }
}

class WeatherCorrelationScreen extends ConsumerStatefulWidget {
  const WeatherCorrelationScreen({super.key});

  @override
  ConsumerState<WeatherCorrelationScreen> createState() => _WeatherCorrelationScreenState();
}

class _WeatherCorrelationScreenState extends ConsumerState<WeatherCorrelationScreen>
    with SingleTickerProviderStateMixin {
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
        title: const Text('天气关联分析'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '记录'),
            Tab(text: '天气统计'),
            Tab(text: '温度统计'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildRecordTab(),
          _buildWeatherStatsTab(),
          _buildTemperatureStatsTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddRecordDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildRecordTab() {
    final stateAsync = ref.watch(weatherProvider);

    return stateAsync.when(
      data: (state) {
        if (state.records.isEmpty) {
          return const Center(child: Text('暂无记录，点击右下角添加'));
        }

        return Column(
          children: [
            _buildTodayCard(context),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: state.records.length,
                itemBuilder: (context, index) {
                  final record = state.records[index];
                  return _buildRecordCard(context, record);
                },
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('错误: $e')),
    );
  }

  Widget _buildTodayCard(BuildContext context) {
    return FutureBuilder<WeatherCorrelation?>(
      future: ref.read(weatherProvider.notifier).getTodayRecord(),
      builder: (context, snapshot) {
        final record = snapshot.data;
        return Card(
          margin: const EdgeInsets.all(8),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text('今日天气', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                if (record != null) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStatItem('天气', record.condition.label),
                      _buildStatItem('温度', '${record.temperature ?? '-'}°C'),
                      _buildStatItem('湿度', '${record.humidity ?? '-'}%'),
                    ],
                  ),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStatItem('生产力', record.productivityScore.toStringAsFixed(1)),
                      _buildStatItem('情绪', '${record.moodScore}/10'),
                      _buildStatItem('能量', '${record.energyLevel}/10'),
                    ],
                  ),
                ] else ...[
                  const Text('今日尚未记录'),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => _showAddRecordDialog(context),
                    child: const Text('记录今日'),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildRecordCard(BuildContext context, WeatherCorrelation record) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: _getWeatherIcon(record.condition),
        title: Text('${record.date} - ${record.condition.label}'),
        subtitle: Text(
          '温度: ${record.temperature ?? '-'}>C | 生产力: ${record.productivityScore.toStringAsFixed(1)} | '
          '情绪: ${record.moodScore}/10 | 能量: ${record.energyLevel}/10',
        ),
        trailing: IconButton(
          icon: const Icon(Icons.edit),
          onPressed: () => _showAddRecordDialog(context, record: record),
        ),
      ),
    );
  }

  Widget _buildWeatherStatsTab() {
    final stateAsync = ref.watch(weatherProvider);

    return stateAsync.when(
      data: (state) {
        if (state.weatherStats.isEmpty) {
          return const Center(child: Text('暂无统计数据'));
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (state.bestWeatherCondition != null) ...[
                Card(
                  color: Colors.green.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber),
                        const SizedBox(width: 8),
                        Text('最佳天气: ${state.bestWeatherCondition}',
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              Text('按天气条件分组统计', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              ...state.weatherStats.map((stat) => _buildWeatherStatCard(stat)),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('错误: $e')),
    );
  }

  Widget _buildWeatherStatCard(WeatherStats stat) {
    final condition = WeatherCondition.fromString(stat.weatherCondition);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _getWeatherIcon(condition),
                const SizedBox(width: 8),
                Text(stat.weatherCondition, style: const TextStyle(fontWeight: FontWeight.bold)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text('${stat.count} 条记录'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMiniStat('平均温度', '${stat.avgTemperature.toStringAsFixed(1)}°C'),
                _buildMiniStat('生产力', stat.avgProductivity.toStringAsFixed(1)),
                _buildMiniStat('情绪', stat.avgMood.toStringAsFixed(1)),
                _buildMiniStat('能量', stat.avgEnergy.toStringAsFixed(1)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTemperatureStatsTab() {
    final stateAsync = ref.watch(weatherProvider);

    return stateAsync.when(
      data: (state) {
        if (state.temperatureStats.isEmpty) {
          return const Center(child: Text('暂无统计数据'));
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (state.bestTemperatureRange != null) ...[
                Card(
                  color: Colors.orange.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Icon(Icons.thermostat, color: Colors.red),
                        const SizedBox(width: 8),
                        Text('最佳温度: ${state.bestTemperatureRange}',
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              Text('按温度范围分组统计', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              ...state.temperatureStats.map((stat) => _buildTempStatCard(stat)),
              const SizedBox(height: 16),
              _buildSuggestionsCard(state),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('错误: $e')),
    );
  }

  Widget _buildTempStatCard(TemperatureRangeStats stat) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.thermostat, color: Colors.blue),
                const SizedBox(width: 8),
                Text(stat.rangeLabel, style: const TextStyle(fontWeight: FontWeight.bold)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text('${stat.count} 条记录'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMiniStat('生产力', stat.avgProductivity.toStringAsFixed(1)),
                _buildMiniStat('情绪', stat.avgMood.toStringAsFixed(1)),
                _buildMiniStat('能量', stat.avgEnergy.toStringAsFixed(1)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniStat(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildSuggestionsCard(WeatherState state) {
    // 计算平均值用于生成建议
    double avgProductivity = 0;
    double avgMood = 0;
    WeatherCondition condition = WeatherCondition.unknown;

    if (state.weatherStats.isNotEmpty) {
      avgProductivity = state.weatherStats.first.avgProductivity;
      avgMood = state.weatherStats.first.avgMood;
    }

    if (state.records.isNotEmpty) {
      condition = state.records.first.condition;
    }

    final suggestions = WeatherSuggestion.generateSuggestions(
      condition,
      state.records.isNotEmpty ? state.records.first.temperature : null,
      avgProductivity,
      avgMood,
    );

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
            const SizedBox(height: 12),
            ...suggestions.map((s) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s.suggestion, style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(s.reason, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _getWeatherIcon(WeatherCondition condition) {
    IconData icon;
    Color color;

    switch (condition) {
      case WeatherCondition.sunny:
        icon = Icons.wb_sunny;
        color = Colors.orange;
        break;
      case WeatherCondition.cloudy:
        icon = Icons.cloud;
        color = Colors.grey;
        break;
      case WeatherCondition.overcast:
        icon = Icons.cloud_queue;
        color = Colors.blueGrey;
        break;
      case WeatherCondition.rainy:
        icon = Icons.grain;
        color = Colors.blue;
        break;
      case WeatherCondition.thunderstorm:
        icon = Icons.flash_on;
        color = Colors.purple;
        break;
      case WeatherCondition.snowy:
        icon = Icons.ac_unit;
        color = Colors.lightBlue;
        break;
      case WeatherCondition.foggy:
        icon = Icons.blur_on;
        color = Colors.grey;
        break;
      case WeatherCondition.windy:
        icon = Icons.air;
        color = Colors.teal;
        break;
      case WeatherCondition.hazy:
        icon = Icons.blur_off;
        color = Colors.brown;
        break;
      default:
        icon = Icons.help_outline;
        color = Colors.grey;
    }

    return Icon(icon, color: color, size: 32);
  }

  void _showAddRecordDialog(BuildContext context, {WeatherCorrelation? record}) {
    final isEdit = record != null;
    final dateController = TextEditingController(
        text: isEdit ? record.date : DateFormatter.formatDate(DateTime.now()));
    final tempController = TextEditingController(text: record?.temperature?.toString() ?? '');
    final humidityController = TextEditingController(text: record?.humidity?.toString() ?? '');
    final productivityController =
        TextEditingController(text: record?.productivityScore.toString() ?? '7');
    final moodController = TextEditingController(text: record?.moodScore.toString() ?? '5');
    final energyController = TextEditingController(text: record?.energyLevel.toString() ?? '5');
    final noteController = TextEditingController(text: record?.note ?? '');

    WeatherCondition selectedCondition =
        isEdit ? WeatherCondition.fromString(record.weatherCondition) : WeatherCondition.sunny;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(isEdit ? '编辑记录' : '添加记录'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: dateController,
                  decoration: const InputDecoration(labelText: '日期 (YYYY-MM-DD)'),
                  readOnly: true,
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<WeatherCondition>(
                  value: selectedCondition,
                  decoration: const InputDecoration(labelText: '天气状况'),
                  items: WeatherCondition.values.map((c) {
                    return DropdownMenuItem(value: c, child: Text(c.label));
                  }).toList(),
                  onChanged: (v) => setState(() => selectedCondition = v!),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: tempController,
                  decoration: const InputDecoration(labelText: '温度 (°C)'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: humidityController,
                  decoration: const InputDecoration(labelText: '湿度 (%)'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: productivityController,
                  decoration: const InputDecoration(labelText: '生产力评分 (0-10)'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: moodController,
                  decoration: const InputDecoration(labelText: '情绪评分 (1-10)'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: energyController,
                  decoration: const InputDecoration(labelText: '能量等级 (1-10)'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: noteController,
                  decoration: const InputDecoration(labelText: '备注'),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () {
                final newRecord = WeatherCorrelation(
                  id: record?.id,
                  date: dateController.text,
                  temperature: double.tryParse(tempController.text),
                  humidity: double.tryParse(humidityController.text),
                  weatherCondition: selectedCondition.name,
                  productivityScore: double.tryParse(productivityController.text) ?? 7,
                  moodScore: int.tryParse(moodController.text) ?? 5,
                  energyLevel: int.tryParse(energyController.text) ?? 5,
                  note: noteController.text.isEmpty ? null : noteController.text,
                  createdAt: record?.createdAt ?? DateTime.now().toIso8601String(),
                );

                if (isEdit) {
                  ref.read(weatherProvider.notifier).updateRecord(newRecord);
                } else {
                  ref.read(weatherProvider.notifier).addRecord(newRecord);
                }

                Navigator.pop(context);
              },
              child: Text(isEdit ? '保存' : '添加'),
            ),
          ],
        ),
      ),
    );
  }
}