import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/quick_record_floating_models.dart';

/// 快速记录浮窗服务提供者
final quickRecordFloatingServiceProvider = Provider<QuickRecordFloatingService>((ref) {
  return QuickRecordFloatingService();
});

/// 快速记录浮窗服务
class QuickRecordFloatingService {
  /// 创建快速记录数据
  QuickRecordData createQuickRecord({
    String? note,
    int? thingNameId,
    String? thingName,
    int? durationMinutes,
    List<String> tags = const [],
    double? latitude,
    double? longitude,
    String? address,
    List<String> photoPaths = const [],
    String? audioPath,
    bool addReminder = false,
    DateTime? reminderTime,
  }) {
    return QuickRecordData(
      note: note,
      thingNameId: thingNameId,
      thingName: thingName,
      durationMinutes: durationMinutes,
      tags: tags,
      latitude: latitude,
      longitude: longitude,
      address: address,
      photoPaths: photoPaths,
      audioPath: audioPath,
      addReminder: addReminder,
      reminderTime: reminderTime,
    );
  }

  /// 获取默认持续时间选项
  List<int> get defaultDurationOptions => [5, 10, 15, 30, 45, 60, 90, 120];
}

/// 快速记录浮窗组件
class QuickRecordFloatingButton extends ConsumerStatefulWidget {
  final VoidCallback? onPressed;
  final FloatingStyle style;
  final FloatingSize size;
  final Color? backgroundColor;
  final IconData? icon;

  const QuickRecordFloatingButton({
    super.key,
    this.onPressed,
    this.style = FloatingStyle.fab,
    this.size = FloatingSize.medium,
    this.backgroundColor,
    this.icon,
  });

  @override
  ConsumerState<QuickRecordFloatingButton> createState() => _QuickRecordFloatingButtonState();
}

class _QuickRecordFloatingButtonState extends ConsumerState<QuickRecordFloatingButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sizeValue = _getSizeValue();
    final iconSize = _getIconSize();

    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onPressed?.call();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          width: sizeValue,
          height: sizeValue,
          decoration: BoxDecoration(
            color: widget.backgroundColor ?? Theme.of(context).colorScheme.primary,
            shape: widget.style == FloatingStyle.circular
                ? BoxShape.circle
                : BoxShape.rectangle,
            borderRadius: widget.style == FloatingStyle.pill
                ? BorderRadius.circular(sizeValue / 2)
                : BorderRadius.circular(sizeValue * 0.3),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(
            widget.icon ?? Icons.add,
            color: Colors.white,
            size: iconSize,
          ),
        ),
      ),
    );
  }

  double _getSizeValue() {
    switch (widget.size) {
      case FloatingSize.small:
        return 48;
      case FloatingSize.medium:
        return 56;
      case FloatingSize.large:
        return 64;
    }
  }

  double _getIconSize() {
    switch (widget.size) {
      case FloatingSize.small:
        return 24;
      case FloatingSize.medium:
        return 28;
      case FloatingSize.large:
        return 32;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

/// 快速记录浮窗内容
class QuickRecordFloatingSheet extends ConsumerStatefulWidget {
  final Function(QuickRecordData) onSubmit;

  const QuickRecordFloatingSheet({
    super.key,
    required this.onSubmit,
  });

  @override
  ConsumerState<QuickRecordFloatingSheet> createState() => _QuickRecordFloatingSheetState();
}

class _QuickRecordFloatingSheetState extends ConsumerState<QuickRecordFloatingSheet> {
  final _noteController = TextEditingController();
  // ignore: unused_field
  String? _selectedThingName;
  int _duration = 30;
  final List<String> _selectedTags = [];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 标题栏
          Row(
            children: [
              Icon(
                Icons.bolt,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                '快速记录',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 备注输入
          TextField(
            controller: _noteController,
            decoration: const InputDecoration(
              hintText: '快速记录一下...',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
            autofocus: true,
          ),
          const SizedBox(height: 16),

          // 快速持续时间选择
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [5, 15, 30, 60, 120].map((minutes) {
              final isSelected = _duration == minutes;
              return ChoiceChip(
                label: Text('$minutes 分钟'),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    setState(() => _duration = minutes);
                  }
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // 快速标签
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ['重要', '工作', '学习', '生活'].map((tag) {
              final isSelected = _selectedTags.contains(tag);
              return FilterChip(
                label: Text(tag),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedTags.add(tag);
                    } else {
                      _selectedTags.remove(tag);
                    }
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // 提交按钮
          FilledButton.icon(
            onPressed: _submit,
            icon: const Icon(Icons.check),
            label: const Text('记录'),
          ),
        ],
      ),
    );
  }

  void _submit() {
    final data = QuickRecordData(
      note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
      durationMinutes: _duration,
      tags: _selectedTags,
    );

    widget.onSubmit(data);
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }
}

/// 快速记录入口按钮
class QuickRecordEntryButton extends StatelessWidget {
  final VoidCallback onPressed;
  final int recordCount; // 今日记录数

  const QuickRecordEntryButton({
    super.key,
    required this.onPressed,
    this.recordCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.bolt,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
              const SizedBox(width: 8),
              Text(
                '快速记录',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (recordCount > 0) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$recordCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}