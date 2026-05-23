import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MoodMatrixScreen extends ConsumerWidget {
  const MoodMatrixScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('情绪矩阵'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildMatrix(context),
            const SizedBox(height: 24),
            _buildLegend(context),
            const SizedBox(height: 24),
            _buildInsights(),
          ],
        ),
      ),
    );
  }

  Widget _buildMatrix(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            '能量-情绪矩阵',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          AspectRatio(
            aspectRatio: 1,
            child: CustomPaint(
              painter: _MatrixPainter(),
              child: const Center(),
            ),
          ),
          const SizedBox(height: 16),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('低能量 ← → 高能量', style: TextStyle(fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegend(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('矩阵说明', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          SizedBox(height: 12),
          _LegendItem(color: Colors.green, label: 'Q1: 高能量 + 正向情绪 (最佳状态)'),
          _LegendItem(color: Colors.blue, label: 'Q2: 高能量 + 负向情绪 (需要调整)'),
          _LegendItem(color: Colors.orange, label: 'Q3: 低能量 + 负向情绪 (需要关注)'),
          _LegendItem(color: Colors.grey, label: 'Q4: 低能量 + 正向情绪 (恢复期)'),
        ],
      ),
    );
  }

  Widget _buildInsights() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('💡 洞察', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          SizedBox(height: 12),
          Text('• 运动后通常进入高能量正向状态'),
          Text('• 工作压力大时容易进入高能量负向状态'),
          Text('• 周末休息有助于恢复正向状态'),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }
}

class _MatrixPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // Draw grid
    paint.color = Colors.grey.withOpacity(0.3);

    // Vertical line
    canvas.drawLine(
      Offset(size.width / 2, 0),
      Offset(size.width / 2, size.height),
      paint,
    );

    // Horizontal line
    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      paint,
    );

    // Draw quadrants
    final quadrants = [
      (Colors.green.withOpacity(0.2), const Offset(0, 0), 'Q1'),
      (Colors.blue.withOpacity(0.2), Offset(size.width / 2, 0), 'Q2'),
      (Colors.orange.withOpacity(0.2), Offset(size.width / 2, size.height / 2), 'Q3'),
      (Colors.grey.withOpacity(0.2), Offset(0, size.height / 2), 'Q4'),
    ];

    for (final q in quadrants) {
      paint.color = q.$1;
      paint.style = PaintingStyle.fill;
      canvas.drawRect(
        Rect.fromLTWH(q.$2.dx, q.$2.dy, size.width / 2, size.height / 2),
        paint,
      );
    }

    // Labels
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    textPainter.text = const TextSpan(
      text: '高',
      style: TextStyle(color: Colors.grey, fontSize: 12),
    );
    textPainter.layout();
    textPainter.paint(canvas, const Offset(8, 8));

    textPainter.text = const TextSpan(
      text: '低',
      style: TextStyle(color: Colors.grey, fontSize: 12),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(8, size.height - 20));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}