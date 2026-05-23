import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/energy_peak/data/energy_peak_provider.dart';
import 'package:thing_note/features/energy_peak/domain/energy_peak.dart';

class EnergyPeakScreen extends ConsumerStatefulWidget {
  const EnergyPeakScreen({super.key});

  @override
  ConsumerState<EnergyPeakScreen> createState() => _EnergyPeakScreenState();
}

class _EnergyPeakScreenState extends ConsumerState<EnergyPeakScreen> {
  @override
  Widget build(BuildContext context) {
    final statsAsync = ref.watch(energyStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('能量峰值'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Quick Record
            _buildQuickRecord(),
            const SizedBox(height: 24),

            // Stats
            statsAsync.when(
              data: (stats) => _buildStats(stats),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const Text('加载失败'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickRecord() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '记录当前能量',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(10, (index) {
                final level = index + 1;
                return GestureDetector(
                  onTap: () => _showRecordDialog(level),
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: _getEnergyColor(level),
                      borderRadius: BorderRadius.circular(8),
                    ),
child: Center(
                      child: Text(
                        '$level',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 8),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('低', style: TextStyle(fontSize: 10, color: Colors.grey)),
                Text('高', style: TextStyle(fontSize: 10, color: Colors.grey)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStats(EnergyStats stats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '能量曲线',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: _buildHourlyChart(stats),
        ),
        const SizedBox(height: 24),
        if (stats.bestHour != null)
          Card(
            child: ListTile(
              leading: const Icon(Icons.emoji_events, color: Colors.green),
              title: const Text('最佳能量时段'),
              subtitle: Text('${stats.bestHour}:00 - ${stats.bestHour! + 1}:00'),
            ),
          ),
      ],
    );
  }

  Widget _buildHourlyChart(EnergyStats stats) {
    return CustomPaint(
      size: const Size(double.infinity, 200),
      painter: _EnergyChartPainter(stats.hourlyAverage),
    );
  }

  Color _getEnergyColor(int level) {
    if (level <= 3) return Colors.red;
    if (level <= 6) return Colors.orange;
    return Colors.green;
  }

  void _showRecordDialog(int level) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('记录能量'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('能量等级: $level'),
            const SizedBox(height: 16),
            const TextField(
              decoration: InputDecoration(
                labelText: '当前活动（可选）',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              final peak = EnergyPeak(
                date: DateTime.now(),
                hour: DateTime.now().hour,
                energyLevel: level,
                createdAt: DateTime.now(),
              );
              ref.read(recordEnergyProvider).record(peak);
              Navigator.pop(context);
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }
}

class _EnergyChartPainter extends CustomPainter {
  final Map<int, double> hourlyAverage;
  
  _EnergyChartPainter(this.hourlyAverage);

  @override
  void paint(Canvas canvas, Size size) {
    if (hourlyAverage.isEmpty) {
      final paint = Paint()..color = Colors.grey;
      canvas.drawLine(
        Offset(0, size.height / 2),
        Offset(size.width, size.height / 2),
        paint,
      );
      return;
    }

    const maxEnergy = 10.0;
    final paint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final points = <Offset>[];
    for (int hour = 0; hour < 24; hour++) {
      final energy = hourlyAverage[hour] ?? 0;
      final x = (hour / 23) * size.width;
      final y = size.height - (energy / maxEnergy) * size.height;
      points.add(Offset(x, y));
    }

    final path = Path();
    path.moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      path.lineTo(point.dx, point.dy);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}