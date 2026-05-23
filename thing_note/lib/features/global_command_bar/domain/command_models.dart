import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 全局命令栏命令项
class CommandItem {
  final String id;
  final String title;
  final String? subtitle;
  final IconData icon;
  final String route;
  final List<String> keywords;

  const CommandItem({
    required this.id,
    required this.title,
    this.subtitle,
    required this.icon,
    required this.route,
    required this.keywords,
  });
}

/// 所有可用命令
final allCommands = [
  const CommandItem(
    id: 'record',
    title: '新建记录',
    subtitle: '快速创建事件记录',
    icon: Icons.add_circle_outline,
    route: '/record/new',
    keywords: ['新建', '记录', 'add', 'new'],
  ),
  const CommandItem(
    id: 'search',
    title: '搜索',
    subtitle: '搜索记录、标签、事情',
    icon: Icons.search,
    route: '/search',
    keywords: ['搜索', 'search', 'find'],
  ),
  const CommandItem(
    id: 'timeline',
    title: '时间线',
    subtitle: '查看所有记录',
    icon: Icons.timeline,
    route: '/timeline',
    keywords: ['时间线', 'timeline'],
  ),
  const CommandItem(
    id: 'calendar',
    title: '日历',
    subtitle: '按日期查看记录',
    icon: Icons.calendar_month,
    route: '/calendar',
    keywords: ['日历', 'calendar'],
  ),
  const CommandItem(
    id: 'dashboard',
    title: '仪表盘',
    subtitle: '查看统计数据',
    icon: Icons.dashboard,
    route: '/dashboard',
    keywords: ['仪表盘', 'dashboard', '统计'],
  ),
  const CommandItem(
    id: 'goals',
    title: '目标',
    subtitle: '个人目标追踪',
    icon: Icons.flag,
    route: '/goals',
    keywords: ['目标', 'goals'],
  ),
  const CommandItem(
    id: 'habits',
    title: '习惯',
    subtitle: '习惯追踪打卡',
    icon: Icons.check_circle,
    route: '/habits',
    keywords: ['习惯', 'habits'],
  ),
  const CommandItem(
    id: 'mood',
    title: '情绪',
    subtitle: '记录每日情绪',
    icon: Icons.mood,
    route: '/mood',
    keywords: ['情绪', 'mood'],
  ),
  const CommandItem(
    id: 'focus',
    title: '专注模式',
    subtitle: '番茄钟专注计时',
    icon: Icons.timer,
    route: '/focus-mode',
    keywords: ['专注', 'focus', '番茄'],
  ),
  const CommandItem(
    id: 'settings',
    title: '设置',
    subtitle: '应用设置',
    icon: Icons.settings,
    route: '/settings',
    keywords: ['设置', 'settings'],
  ),
];

/// 搜索状态 Provider
final commandSearchProvider = StateNotifierProvider<CommandSearchNotifier, String>((ref) {
  return CommandSearchNotifier();
});

class CommandSearchNotifier extends StateNotifier<String> {
  CommandSearchNotifier() : super('');

  void search(String query) => state = query;
  void clear() => state = '';
}

/// 过滤后的命令列表
final filteredCommandsProvider = Provider<List<CommandItem>>((ref) {
  final query = ref.watch(commandSearchProvider).toLowerCase();
  if (query.isEmpty) return allCommands;

  return allCommands.where((cmd) {
    return cmd.title.toLowerCase().contains(query) ||
        cmd.keywords.any((k) => k.toLowerCase().contains(query));
  }).toList();
});

/// 全局命令栏显示状态
final commandBarVisibleProvider = StateProvider<bool>((ref) => false);