// Home Widget feature
// Note: Android/iOS home widgets require platform-specific implementation
// This is a placeholder service for widget data management

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum WidgetType {
  quickRecord,
  todayOverview,
  habitCheckin,
  dailyReminder,
}

class WidgetConfig {
  final WidgetType type;
  final bool enabled;
  final String title;
  final Map<String, dynamic> settings;

  WidgetConfig({
    required this.type,
    this.enabled = true,
    required this.title,
    this.settings = const {},
  });

  WidgetConfig copyWith({
    WidgetType? type,
    bool? enabled,
    String? title,
    Map<String, dynamic>? settings,
  }) {
    return WidgetConfig(
      type: type ?? this.type,
      enabled: enabled ?? this.enabled,
      title: title ?? this.title,
      settings: settings ?? this.settings,
    );
  }
}

class HomeWidgetService {
  static const String _prefsKey = 'home_widget_config';

  Future<List<WidgetConfig>> getWidgetConfigs() async {
    final prefs = await SharedPreferences.getInstance();
    final configsJson = prefs.getString(_prefsKey);
    
    if (configsJson == null) {
      return _getDefaultConfigs();
    }
    
    // Parse and return configs
    return _getDefaultConfigs();
  }

  List<WidgetConfig> _getDefaultConfigs() {
    return [
      WidgetConfig(
        type: WidgetType.quickRecord,
        title: '快速记录',
        settings: {'showOnHome': true},
      ),
      WidgetConfig(
        type: WidgetType.todayOverview,
        title: '今日概览',
        settings: {'showRecordCount': true, 'showHabits': true},
      ),
      WidgetConfig(
        type: WidgetType.habitCheckin,
        title: '习惯打卡',
        settings: {'maxHabits': 4},
      ),
      WidgetConfig(
        type: WidgetType.dailyReminder,
        title: '每日提醒',
        settings: {'reminderTime': '09:00'},
      ),
    ];
  }

  Future<void> saveWidgetConfigs(List<WidgetConfig> configs) async {
    // TODO: Save to prefs - config will be saved elsewhere
  }

  // Platform-specific widget update methods
  Future<void> updateWidget(WidgetType type) async {
    // This would trigger platform-specific widget updates
    // For Android: AppWidgetManager.updateAppWidget
    // For iOS: WidgetCenter.shared.reloadTimelines
  }
}

final homeWidgetServiceProvider = Provider<HomeWidgetService>((ref) {
  return HomeWidgetService();
});

final widgetConfigsProvider = FutureProvider<List<WidgetConfig>>((ref) async {
  final service = ref.watch(homeWidgetServiceProvider);
  return service.getWidgetConfigs();
});

class HomeWidgetScreen extends ConsumerWidget {
  const HomeWidgetScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final configsAsync = ref.watch(widgetConfigsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('桌面小组件'),
      ),
      body: configsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('错误: $e')),
        data: (configs) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Info card
              Card(
                color: Colors.blue.shade50,
                child: const Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Icon(Icons.widgets, size: 48, color: Colors.blue),
                      SizedBox(height: 8),
                      Text(
                        '桌面小组件',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '在手机主屏幕上添加小组件，快速访问功能',
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '可用小组件',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...configs.map((config) => _WidgetConfigCard(config: config)),
              const SizedBox(height: 24),
              // Instructions
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '添加小组件',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Text('1. 长按手机主屏幕空白处'),
                      const Text('2. 点击"小组件"或"添加组件"'),
                      const Text('3. 找到"事件记录"或"ThingNote"'),
                      const Text('4. 选择想要添加的小组件'),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: () {
                          // Open system settings
                        },
                        icon: const Icon(Icons.open_in_new),
                        label: const Text('打开系统设置'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _WidgetConfigCard extends StatelessWidget {
  final WidgetConfig config;

  const _WidgetConfigCard({required this.config});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          _getWidgetIcon(config.type),
          color: Colors.blue,
          size: 32,
        ),
        title: Text(config.title),
        subtitle: Text(_getWidgetDescription(config.type)),
        trailing: Switch(
          value: config.enabled,
          onChanged: (v) {
            // TODO: Toggle enabled
          },
        ),
      ),
    );
  }

  IconData _getWidgetIcon(WidgetType type) {
    switch (type) {
      case WidgetType.quickRecord: return Icons.add_circle;
      case WidgetType.todayOverview: return Icons.dashboard;
      case WidgetType.habitCheckin: return Icons.check_circle;
      case WidgetType.dailyReminder: return Icons.alarm;
    }
  }

  String _getWidgetDescription(WidgetType type) {
    switch (type) {
      case WidgetType.quickRecord: return '快速添加新记录';
      case WidgetType.todayOverview: return '显示今日统计';
      case WidgetType.habitCheckin: return '习惯打卡入口';
      case WidgetType.dailyReminder: return '每日提醒通知';
    }
  }
}