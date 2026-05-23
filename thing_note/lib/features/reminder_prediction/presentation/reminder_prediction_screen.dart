import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/reminder_prediction/data/reminder_prediction_service.dart';

class ReminderPredictionScreen extends ConsumerStatefulWidget {
  const ReminderPredictionScreen({super.key});

  @override
  ConsumerState<ReminderPredictionScreen> createState() => _ReminderPredictionScreenState();
}

class _ReminderPredictionScreenState extends ConsumerState<ReminderPredictionScreen> {
  List<ReminderPrediction>? _predictions;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPredictions();
  }

  Future<void> _loadPredictions() async {
    setState(() {
      _isLoading = true;
    });

    final service = ref.read(reminderPredictionServiceProvider);
    final predictions = await service.suggestRecurringReminders();

    setState(() {
      _predictions = predictions;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('智能提醒预测'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPredictions,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _predictions == null || _predictions!.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.lightbulb_outline, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('暂无预测数据', style: TextStyle(fontSize: 18)),
                      SizedBox(height: 8),
                      Text(
                        '记录更多事件以发现你的提醒模式',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _predictions!.length,
                  itemBuilder: (context, index) {
                    final prediction = _predictions![index];
                    return _PredictionCard(prediction: prediction);
                  },
                ),
    );
  }
}

class _PredictionCard extends StatelessWidget {
  final ReminderPrediction prediction;

  const _PredictionCard({required this.prediction});

  @override
  Widget build(BuildContext context) {
    Color confidenceColor;
    if (prediction.confidence >= 0.8) {
      confidenceColor = Colors.green;
    } else if (prediction.confidence >= 0.6) {
      confidenceColor = Colors.orange;
    } else {
      confidenceColor = Colors.grey;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.access_time, color: Colors.blue, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    prediction.formattedTime,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    prediction.reason,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: confidenceColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    prediction.confidencePercent,
                    style: TextStyle(color: confidenceColor, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('已应用提醒时间')),
                    );
                  },
                  child: const Text('应用'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}