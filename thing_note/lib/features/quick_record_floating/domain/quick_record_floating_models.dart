/// 快速记录浮窗 - Quick Record Floating
/// 一键快速记录功能
library;

/// 快速记录配置
class QuickRecordConfig {
  final bool enabled;
  final bool showOnHome;
  final int defaultDuration;
  final List<String> quickTags;
  final List<QuickThingName> quickThingNames;

  QuickRecordConfig({
    this.enabled = true,
    this.showOnHome = true,
    this.defaultDuration = 30,
    this.quickTags = const [],
    this.quickThingNames = const [],
  });
}

/// 快速事情名称
class QuickThingName {
  final int id;
  final String name;
  final String? icon;
  final int color;

  QuickThingName({
    required this.id,
    required this.name,
    this.icon,
    this.color = 0xFF2196F3,
  });
}

/// 快速记录数据
class QuickRecordData {
  final String? note;
  final int? thingNameId;
  final String? thingName;
  final int? durationMinutes;
  final List<String> tags;
  final double? latitude;
  final double? longitude;
  final String? address;
  final List<String> photoPaths;
  final String? audioPath;
  final bool addReminder;
  final DateTime? reminderTime;

  QuickRecordData({
    this.note,
    this.thingNameId,
    this.thingName,
    this.durationMinutes,
    this.tags = const [],
    this.latitude,
    this.longitude,
    this.address,
    this.photoPaths = const [],
    this.audioPath,
    this.addReminder = false,
    this.reminderTime,
  });
}

/// 浮窗样式
enum FloatingStyle {
  circular, // 圆形按钮
  pill, // 胶囊形状
  fab, // FAB 样式
}

/// 浮窗大小
enum FloatingSize {
  small,
  medium,
  large,
}