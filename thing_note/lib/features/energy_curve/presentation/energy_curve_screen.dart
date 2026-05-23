import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/core/database/database_provider.dart';
import 'package:thing_note/features/energy_curve/data/energy_curve_provider.dart';
import 'package:thing_note/features/energy_curve/domain/energy_curve_models.dart';

class EnergyCurveScreen extends ConsumerStatefulWidget {
  const EnergyCurveScreen({super.key});

  @override
  ConsumerState<EnergyCurveScreen> createState() => _EnergyCurveScreenState();
}

class _EnergyCurveScreenState extends ConsumerState<EnergyCurveScreen> {
  late EnergyCurve _todayCurve;

  @override
  void initState() {
    super.initState();
    _todayCurve = EnergyCurve(date: DateTime.now().toIso8601String().substring(0, 10));
  }

  @override
  Widget build(BuildContext context) {
    final todayAsync = ref.watch(todayEnergyProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('精力曲线'),
        actions: [
          IconButton(
            icon: const Icon(Icons.insights),
            onPressed: () => _showInsights(context),
          ),
        ],
      ),
      body: todayAsync.when(
        data: (curve) {
          _todayCurve = curve;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDateHeader(curve.date),
                const SizedBox(height: 24),
                _buildEnergyChart(curve),
                const SizedBox(height: 24),
                _buildEnergyInput(curve),
                const SizedBox(height: 24),
                _buildWeeklyOverview(),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildDateHeader(String date) {
    final dateTime = DateTime.parse(date);
    final weekday = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'][dateTime.weekday - 1];
    
    return Row(
      children: [
        Text(
          '${dateTime.month}月${dateTime.day}日 $weekday',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const Spacer(),
        if (date == DateTime.now().toIso8601String().substring(0, 10))
          Chip(
            label: const Text('今天'),
            backgroundColor: Colors.blue.shade50,
          ),
      ],
    );
  }

  Widget _buildEnergyChart(EnergyCurve curve) {
    final hours = [
      ('6-8点', curve.hour6To8),
      ('8-10点', curve.hour8To10),
      ('10-12点', curve.hour10To12),
      ('12-14点', curve.hour12To14),
      ('14-16点', curve.hour14To16),
      ('16-18点', curve.hour16To18),
      ('18-20点', curve.hour18To20),
      ('20-22点', curve.hour20To22),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '今日精力分布',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                Text(
                  '平均: ${curve.averageEnergy.toStringAsFixed(1)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 180,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: hours.map((h) {
                  return Expanded(
                    child: _buildBar(h.$1, h.$2),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBar(String label, int value) {
    final height = value > 0 ? value * 28.0 : 8.0;
    final color = _getEnergyColor(value);
    
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          height: height,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 10),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Color _getEnergyColor(int value) {
    switch (value) {
      case 1:
        return Colors.red.shade200;
      case 2:
        return Colors.orange.shade200;
      case 3:
        return Colors.yellow.shade200;
      case 4:
        return Colors.lightGreen.shade200;
      case 5:
        return Colors.green.shade400;
      default:
        return Colors.grey.shade200;
    }
  }

  Widget _buildEnergyInput(EnergyCurve curve) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '记录你的精力',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            _buildTimeSlotInput('6-8点', curve.hour6To8, (v) {
              setState(() => _todayCurve = _todayCurve.copyWith(hour6To8: v));
              _saveEnergyCurve();
            }),
            _buildTimeSlotInput('8-10点', curve.hour8To10, (v) {
              setState(() => _todayCurve = _todayCurve.copyWith(hour8To10: v));
              _saveEnergyCurve();
            }),
            _buildTimeSlotInput('10-12点', curve.hour10To12, (v) {
              setState(() => _todayCurve = _todayCurve.copyWith(hour10To12: v));
              _saveEnergyCurve();
            }),
            _buildTimeSlotInput('12-14点', curve.hour12To14, (v) {
              setState(() => _todayCurve = _todayCurve.copyWith(hour12To14: v));
              _saveEnergyCurve();
            }),
            _buildTimeSlotInput('14-16点', curve.hour14To16, (v) {
              setState(() => _todayCurve = _todayCurve.copyWith(hour14To16: v));
              _saveEnergyCurve();
            }),
            _buildTimeSlotInput('16-18点', curve.hour16To18, (v) {
              setState(() => _todayCurve = _todayCurve.copyWith(hour16To18: v));
              _saveEnergyCurve();
            }),
            _buildTimeSlotInput('18-20点', curve.hour18To20, (v) {
              setState(() => _todayCurve = _todayCurve.copyWith(hour18To20: v));
              _saveEnergyCurve();
            }),
            _buildTimeSlotInput('20-22点', curve.hour20To22, (v) {
              setState(() => _todayCurve = _todayCurve.copyWith(hour20To22: v));
              _saveEnergyCurve();
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSlotInput(String label, int value, Function(int) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 70,
            child: Text(label),
          ),
          Expanded(
            child: Row(
              children: List.generate(5, (i) {
                final rating = i + 1;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => onChanged(rating),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      height: 32,
                      decoration: BoxDecoration(
                        color: value >= rating ? _getEnergyColor(rating) : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Center(
                        child: Text(
                          '$rating',
                          style: TextStyle(
                            color: value >= rating ? Colors.white : Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveEnergyCurve() async {
    final db = await ref.read(databaseProvider.future);
    final existing = await db.query(
      'energy_curves',
      where: 'date = ?',
      whereArgs: [_todayCurve.date],
    );
    
    if (existing.isNotEmpty) {
      await db.update(
        'energy_curves',
        _todayCurve.toMap(),
        where: 'date = ?',
        whereArgs: [_todayCurve.date],
      );
    } else {
      await db.insert('energy_curves', _todayCurve.toMap());
    }
  }

  Widget _buildWeeklyOverview() {
    final weeklyAsync = ref.watch(weeklyEnergyProvider);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '本周概览',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            weeklyAsync.when(
              data: (curves) {
                if (curves.isEmpty) {
                  return const Center(
                    child: Text('暂无数据，开始记录你的精力吧'),
                  );
                }
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: curves.map((curve) {
                    final weekday = ['一', '二', '三', '四', '五', '六', '日'][
                      DateTime.parse(curve.date).weekday - 1
                    ];
                    return _buildDayChip(weekday, curve.averageEnergy);
                  }).toList(),
                );
              },
              loading: () => const CircularProgressIndicator(),
              error: (e, _) => Text('Error: $e'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDayChip(String day, double avg) {
    Color bgColor;
    if (avg >= 4) {
      bgColor = Colors.green.shade100;
    } else if (avg >= 3) {
      bgColor = Colors.yellow.shade100;
    } else if (avg > 0) {
      bgColor = Colors.orange.shade100;
    } else {
      bgColor = Colors.grey.shade100;
    }
    
    return Chip(
      avatar: CircleAvatar(
        backgroundColor: bgColor,
        child: Text(day, style: const TextStyle(fontSize: 12)),
      ),
      label: Text(avg > 0 ? avg.toStringAsFixed(1) : '-'),
    );
  }

  void _showInsights(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.lightbulb, color: Colors.amber),
                    const SizedBox(width: 8),
                    Text(
                      '精力洞察',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ],
                ),
                const Divider(),
                Expanded(
                  child: ref.watch(energyInsightsProvider).when(
                    data: (insights) {
                      if (insights.isEmpty) {
                        return const Center(
                          child: Text('坚持记录，我会帮你发现精力模式'),
                        );
                      }
                      return ListView.builder(
                        controller: scrollController,
                        itemCount: insights.length,
                        itemBuilder: (context, index) {
                          final insight = insights[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: Icon(
                                insight.type == 'peak'
                                    ? Icons.trending_up
                                    : insight.type == 'low'
                                        ? Icons.trending_down
                                        : Icons.info_outline,
                                color: insight.type == 'peak'
                                    ? Colors.green
                                    : insight.type == 'low'
                                        ? Colors.orange
                                        : Colors.blue,
                              ),
                              title: Text(insight.title),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(insight.description),
                                  const SizedBox(height: 4),
                                  Text(
                                    insight.recommendation,
                                    style: TextStyle(
                                      color: Colors.grey.shade700,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ],
                              ),
                              trailing: Text(
                                '${insight.confidence}%',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                          );
                        },
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(child: Text('Error: $e')),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}