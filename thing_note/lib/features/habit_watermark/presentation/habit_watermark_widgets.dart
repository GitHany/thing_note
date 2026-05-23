import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/habit_watermark/domain/habit_watermark_models.dart';

/// 习惯水印组件
class HabitWatermark extends StatelessWidget {
  final HabitCheckStatus status;
  final HabitWatermarkConfig config;
  final VoidCallback? onTap;

  const HabitWatermark({
    super.key,
    required this.status,
    required this.config,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (!config.enabled) return const SizedBox.shrink();

    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: config.opacity,
        child: _buildWatermark(context),
      ),
    );
  }

  Widget _buildWatermark(BuildContext context) {
    switch (config.style) {
      case WatermarkStyle.badge:
        return _buildBadgeStyle(context);
      case WatermarkStyle.dot:
        return _buildDotStyle(context);
      case WatermarkStyle.line:
        return _buildLineStyle(context);
      case WatermarkStyle.icon:
        return _buildIconStyle(context);
    }
  }

  Widget _buildBadgeStyle(BuildContext context) {
    final color = Color(status.statusColor);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (config.showIcon && status.icon != null) ...[
            Text(status.icon!, style: const TextStyle(fontSize: 12)),
            const SizedBox(width: 4),
          ],
          if (status.isCheckedToday)
            Icon(Icons.check_circle, size: 14, color: color)
          else
            Icon(Icons.circle_outlined, size: 14, color: color),
          if (config.showStreak) ...[
            const SizedBox(width: 4),
            Text(
              '${status.currentStreak}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDotStyle(BuildContext context) {
    final color = Color(status.statusColor);
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: status.isCheckedToday ? color : Colors.grey.shade300,
        border: Border.all(
          color: status.isCheckedToday ? color : Colors.grey,
          width: 2,
        ),
      ),
    );
  }

  Widget _buildLineStyle(BuildContext context) {
    final color = Color(status.statusColor);
    return Container(
      width: 4,
      height: 24,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildIconStyle(BuildContext context) {
    final color = Color(status.statusColor);
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(0.15),
      ),
      child: Text(
        status.icon ?? '✓',
        style: TextStyle(
          fontSize: 14,
          color: color,
        ),
      ),
    );
  }
}

/// 习惯水印列表
class HabitWatermarkRow extends StatelessWidget {
  final List<HabitCheckStatus> statuses;
  final HabitWatermarkConfig config;
  final void Function(HabitCheckStatus)? onTap;

  const HabitWatermarkRow({
    super.key,
    required this.statuses,
    required this.config,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (statuses.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: statuses.map((status) {
        return HabitWatermark(
          status: status,
          config: config,
          onTap: () => onTap?.call(status),
        );
      }).toList(),
    );
  }
}

/// 水印配置编辑器
class HabitWatermarkConfigEditor extends ConsumerWidget {
  const HabitWatermarkConfigEditor({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('习惯水印设置'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 开关
          SwitchListTile(
            title: const Text('启用水印'),
            subtitle: const Text('在记录列表中显示习惯打卡状态'),
            value: true,
            onChanged: (value) {},
          ),

          const Divider(),

          // 位置选择
          ListTile(
            title: const Text('显示位置'),
            subtitle: const Text('左上角'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),

          // 样式选择
          ListTile(
            title: const Text('水印样式'),
            subtitle: const Text('徽章'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),

          const Divider(),

          // 显示选项
          SwitchListTile(
            title: const Text('显示连续天数'),
            value: true,
            onChanged: (value) {},
          ),

          SwitchListTile(
            title: const Text('显示图标'),
            value: true,
            onChanged: (value) {},
          ),

          const Divider(),

          // 不透明度
          ListTile(
            title: const Text('不透明度'),
            subtitle: Slider(
              value: 0.8,
              onChanged: (value) {},
            ),
          ),

          const Divider(),

          // 选择显示的习惯
          ListTile(
            title: const Text('选择显示的习惯'),
            subtitle: const Text('已选择 3 个习惯'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}