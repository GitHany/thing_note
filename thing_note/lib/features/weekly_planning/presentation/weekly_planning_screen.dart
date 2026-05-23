import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/weekly_planning/domain/weekly_planning.dart';

class WeeklyPlanningScreen extends ConsumerStatefulWidget {
  const WeeklyPlanningScreen({super.key});

  @override
  ConsumerState<WeeklyPlanningScreen> createState() => _WeeklyPlanningScreenState();
}

class _WeeklyPlanningScreenState extends ConsumerState<WeeklyPlanningScreen> {
  final List<PlanDay> _days = List.generate(
    7,
    (index) => PlanDay(dayOfWeek: index + 1, items: []),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('周计划'),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy_all),
            onPressed: () => _copyFromLastWeek(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: _days.map((day) => _buildDayColumn(day)).toList(),
        ),
      ),
    );
  }

  Widget _buildDayColumn(PlanDay day) {
    return Container(
      width: 120,
      margin: const EdgeInsets.all(8),
      child: Column(
        children: [
          // Day Header
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _getDayColor(day.dayOfWeek),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                _getDayName(day.dayOfWeek),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Items
          ...day.items.map((item) => Card(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Checkbox(
                    value: item.isCompleted,
                    onChanged: (value) {
                      // Toggle completion
                    },
                  ),
                  Expanded(child: Text(item.content, style: const TextStyle(fontSize: 12))),
                ],
              ),
            ),
          )),

          // Add Button
          IconButton(
            onPressed: () => _showAddItemDialog(context, day.dayOfWeek),
            icon: const Icon(Icons.add_circle_outline),
          ),
        ],
      ),
    );
  }

  Color _getDayColor(int dayOfWeek) {
    switch (dayOfWeek) {
      case 1:
        return Colors.red;
      case 2:
        return Colors.orange;
      case 3:
        return Colors.yellow.shade700;
      case 4:
        return Colors.green;
      case 5:
        return Colors.blue;
      case 6:
        return Colors.indigo;
      case 7:
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String _getDayName(int dayOfWeek) {
    const days = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    return days[dayOfWeek - 1];
  }

  void _showAddItemDialog(BuildContext context, int dayOfWeek) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${_getDayName(dayOfWeek)}计划'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: '输入计划事项',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                // Add item to day
                Navigator.pop(context);
              }
            },
            child: const Text('添加'),
          ),
        ],
      ),
    );
  }

  void _copyFromLastWeek(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('复制上周计划'),
        content: const Text('这将从上周的计划复制所有未完成的项目'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              // Copy from last week
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('已复制上周计划')),
              );
            },
            child: const Text('复制'),
          ),
        ],
      ),
    );
  }
}