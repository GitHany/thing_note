import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:thing_note/app/theme/app_theme.dart';
import 'package:thing_note/app/theme/spacing_constants.dart';
import 'package:thing_note/features/record/data/record_repository_impl.dart';
import 'package:thing_note/features/record/presentation/providers/record_provider.dart';
import 'package:thing_note/l10n/generated/app_localizations.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isUltraSmall = AppSpacing.isUltraSmall(screenWidth);
    final isSmall = AppSpacing.isSmall(screenWidth);
    final isWideScreen = AppSpacing.isLarge(screenWidth);

    // Unified spacing based on screen size
    final itemPaddingH = isUltraSmall ? 10.0 : (isSmall ? 12.0 : (isWideScreen ? 20.0 : 16.0));
    final sectionSpacing = isUltraSmall ? 10.0 : (isSmall ? 12.0 : (isWideScreen ? 18.0 : 14.0));

    // Touch target minimum 44px (Material Design guideline)
    final listItemVerticalPadding = isUltraSmall ? 8.0 : (isSmall ? 10.0 : 12.0);
    final listItemIconSize = isUltraSmall ? 18.0 : (isSmall ? 20.0 : AppSpacing.mediumIconSize);
    final titleFontSize = isUltraSmall ? 12.0 : (isSmall ? 13.0 : 14.0);
    final subtitleFontSize = isUltraSmall ? 10.0 : (isSmall ? 11.0 : 12.0);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.settings),
      ),
      body: ListView(
        padding: EdgeInsets.symmetric(horizontal: itemPaddingH, vertical: sectionSpacing),
        children: [
          Container(
            decoration: AppTheme.softCardDecoration(context),
            child: Column(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.symmetric(horizontal: itemPaddingH, vertical: listItemVerticalPadding),
                  leading: Icon(Icons.label, size: listItemIconSize),
                  title: Text(AppLocalizations.of(context)!.tagManagement, style: TextStyle(fontSize: titleFontSize)),
                  subtitle: Text(AppLocalizations.of(context)!.tagManagementDesc, style: TextStyle(fontSize: subtitleFontSize)),
                  trailing: Icon(Icons.chevron_right, size: listItemIconSize),
                  onTap: () => context.push('/settings/tags'),
                ),
                Divider(height: 1, indent: itemPaddingH + listItemIconSize + 16),
                ListTile(
                  contentPadding: EdgeInsets.symmetric(horizontal: itemPaddingH, vertical: listItemVerticalPadding),
                  leading: Icon(Icons.calendar_month, size: listItemIconSize),
                  title: Text(AppLocalizations.of(context)!.calendar, style: TextStyle(fontSize: titleFontSize)),
                  subtitle: Text(AppLocalizations.of(context)!.selectDayToViewRecords, style: TextStyle(fontSize: subtitleFontSize)),
                  trailing: Icon(Icons.chevron_right, size: listItemIconSize),
                  onTap: () => context.push('/calendar'),
                ),
                Divider(height: 1, indent: itemPaddingH + listItemIconSize + 16),
                ListTile(
                  contentPadding: EdgeInsets.symmetric(horizontal: itemPaddingH, vertical: listItemVerticalPadding),
                  leading: Icon(Icons.bar_chart, size: listItemIconSize),
                  title: Text(AppLocalizations.of(context)!.statistics, style: TextStyle(fontSize: titleFontSize)),
                  subtitle: Text(AppLocalizations.of(context)!.statisticsDesc, style: TextStyle(fontSize: subtitleFontSize)),
                  trailing: Icon(Icons.chevron_right, size: listItemIconSize),
                  onTap: () => context.push('/statistics'),
                ),
                Divider(height: 1, indent: itemPaddingH + listItemIconSize + 16),
                ListTile(
                  contentPadding: EdgeInsets.symmetric(horizontal: itemPaddingH, vertical: listItemVerticalPadding),
                  leading: Icon(Icons.timeline, size: listItemIconSize),
                  title: Text(AppLocalizations.of(context)!.timeline, style: TextStyle(fontSize: titleFontSize)),
                  subtitle: Text(AppLocalizations.of(context)!.timelineDesc, style: TextStyle(fontSize: subtitleFontSize)),
                  trailing: Icon(Icons.chevron_right, size: listItemIconSize),
                  onTap: () => context.push('/timeline'),
                ),
              ],
            ),
          ),
          SizedBox(height: sectionSpacing),
          Container(
            decoration: AppTheme.softCardDecoration(context),
            child: Column(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.symmetric(horizontal: itemPaddingH, vertical: listItemVerticalPadding),
                  leading: Icon(Icons.flag, size: listItemIconSize),
                  title: Text('目标追踪', style: TextStyle(fontSize: titleFontSize)),
                  subtitle: Text('设定并追踪你的目标', style: TextStyle(fontSize: subtitleFontSize)),
                  trailing: Icon(Icons.chevron_right, size: listItemIconSize),
                  onTap: () => context.push('/goals'),
                ),
                Divider(height: 1, indent: itemPaddingH + listItemIconSize + 16),
                ListTile(
                  contentPadding: EdgeInsets.symmetric(horizontal: itemPaddingH, vertical: listItemVerticalPadding),
                  leading: Icon(Icons.mood, size: listItemIconSize),
                  title: Text('情绪记录', style: TextStyle(fontSize: titleFontSize)),
                  subtitle: Text('记录每日心情变化', style: TextStyle(fontSize: subtitleFontSize)),
                  trailing: Icon(Icons.chevron_right, size: listItemIconSize),
                  onTap: () => context.push('/mood'),
                ),
                Divider(height: 1, indent: itemPaddingH + listItemIconSize + 16),
                ListTile(
                  contentPadding: EdgeInsets.symmetric(horizontal: itemPaddingH, vertical: listItemVerticalPadding),
                  leading: Icon(Icons.repeat, size: listItemIconSize),
                  title: Text('习惯追踪', style: TextStyle(fontSize: titleFontSize)),
                  subtitle: Text('培养好习惯', style: TextStyle(fontSize: subtitleFontSize)),
                  trailing: Icon(Icons.chevron_right, size: listItemIconSize),
                  onTap: () => context.push('/habits'),
                ),
                Divider(height: 1, indent: itemPaddingH + listItemIconSize + 16),
                ListTile(
                  contentPadding: EdgeInsets.symmetric(horizontal: itemPaddingH, vertical: listItemVerticalPadding),
                  leading: Icon(Icons.folder, size: listItemIconSize),
                  title: Text('项目管理', style: TextStyle(fontSize: titleFontSize)),
                  subtitle: Text('管理你的项目', style: TextStyle(fontSize: subtitleFontSize)),
                  trailing: Icon(Icons.chevron_right, size: listItemIconSize),
                  onTap: () => context.push('/projects'),
                ),
              ],
            ),
          ),
          SizedBox(height: sectionSpacing),
          Container(
            decoration: AppTheme.softCardDecoration(context),
            child: Column(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.symmetric(horizontal: itemPaddingH, vertical: listItemVerticalPadding),
                  leading: Icon(Icons.dashboard, size: listItemIconSize),
                  title: Text('数据仪表盘', style: TextStyle(fontSize: titleFontSize)),
                  subtitle: Text('查看数据概览和趋势', style: TextStyle(fontSize: subtitleFontSize)),
                  trailing: Icon(Icons.chevron_right, size: listItemIconSize),
                  onTap: () => context.push('/dashboard'),
                ),
                Divider(height: 1, indent: itemPaddingH + listItemIconSize + 16),
                ListTile(
                  contentPadding: EdgeInsets.symmetric(horizontal: itemPaddingH, vertical: listItemVerticalPadding),
                  leading: Icon(Icons.lightbulb, size: listItemIconSize),
                  title: Text('智能提醒预测', style: TextStyle(fontSize: titleFontSize)),
                  subtitle: Text('AI分析最佳提醒时间', style: TextStyle(fontSize: subtitleFontSize)),
                  trailing: Icon(Icons.chevron_right, size: listItemIconSize),
                  onTap: () => context.push('/reminder-prediction'),
                ),
                Divider(height: 1, indent: itemPaddingH + listItemIconSize + 16),
                ListTile(
                  contentPadding: EdgeInsets.symmetric(horizontal: itemPaddingH, vertical: listItemVerticalPadding),
                  leading: Icon(Icons.sticky_note_2, size: listItemIconSize),
                  title: Text('快捷便签', style: TextStyle(fontSize: titleFontSize)),
                  subtitle: Text('快速记录临时想法', style: TextStyle(fontSize: subtitleFontSize)),
                  trailing: Icon(Icons.chevron_right, size: listItemIconSize),
                  onTap: () => context.push('/quick-notes'),
                ),
                Divider(height: 1, indent: itemPaddingH + listItemIconSize + 16),
                ListTile(
                  contentPadding: EdgeInsets.symmetric(horizontal: itemPaddingH, vertical: listItemVerticalPadding),
                  leading: Icon(Icons.collections_bookmark, size: listItemIconSize),
                  title: Text('收藏集', style: TextStyle(fontSize: titleFontSize)),
                  subtitle: Text('整理和分组记录', style: TextStyle(fontSize: subtitleFontSize)),
                  trailing: Icon(Icons.chevron_right, size: listItemIconSize),
                  onTap: () => context.push('/collections'),
                ),
              ],
            ),
          ),
          SizedBox(height: sectionSpacing),
          Container(
            decoration: AppTheme.softCardDecoration(context),
            child: Column(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.symmetric(horizontal: itemPaddingH, vertical: listItemVerticalPadding),
                  leading: Icon(Icons.notifications, size: listItemIconSize),
                  title: Text('通知中心', style: TextStyle(fontSize: titleFontSize)),
                  subtitle: Text('查看系统通知', style: TextStyle(fontSize: subtitleFontSize)),
                  trailing: Icon(Icons.chevron_right, size: listItemIconSize),
                  onTap: () => context.push('/notifications'),
                ),
                Divider(height: 1, indent: itemPaddingH + listItemIconSize + 16),
                ListTile(
                  contentPadding: EdgeInsets.symmetric(horizontal: itemPaddingH, vertical: listItemVerticalPadding),
                  leading: Icon(Icons.analytics, size: listItemIconSize),
                  title: Text('数据分析报告', style: TextStyle(fontSize: titleFontSize)),
                  subtitle: Text('生成统计报告', style: TextStyle(fontSize: subtitleFontSize)),
                  trailing: Icon(Icons.chevron_right, size: listItemIconSize),
                  onTap: () => context.push('/report'),
                ),
                Divider(height: 1, indent: itemPaddingH + listItemIconSize + 16),
                ListTile(
                  contentPadding: EdgeInsets.symmetric(horizontal: itemPaddingH, vertical: listItemVerticalPadding),
                  leading: Icon(Icons.palette, size: listItemIconSize),
                  title: Text('自定义主题', style: TextStyle(fontSize: titleFontSize)),
                  subtitle: Text('选择你喜欢的主题', style: TextStyle(fontSize: subtitleFontSize)),
                  trailing: Icon(Icons.chevron_right, size: listItemIconSize),
                  onTap: () => context.push('/theme'),
                ),
                Divider(height: 1, indent: itemPaddingH + listItemIconSize + 16),
                ListTile(
                  contentPadding: EdgeInsets.symmetric(horizontal: itemPaddingH, vertical: listItemVerticalPadding),
                  leading: Icon(Icons.file_upload, size: listItemIconSize),
                  title: Text('数据导入', style: TextStyle(fontSize: titleFontSize)),
                  subtitle: Text('从其他应用导入数据', style: TextStyle(fontSize: subtitleFontSize)),
                  trailing: Icon(Icons.chevron_right, size: listItemIconSize),
                  onTap: () => context.push('/importer'),
                ),
              ],
            ),
          ),
          SizedBox(height: sectionSpacing),
          Container(
            decoration: AppTheme.softCardDecoration(context),
            child: ListTile(
              contentPadding: EdgeInsets.symmetric(horizontal: itemPaddingH, vertical: listItemVerticalPadding + 2),
              leading: Icon(Icons.folder_zip, size: listItemIconSize),
              title: Text(AppLocalizations.of(context)!.viewBackupZips, style: TextStyle(fontSize: titleFontSize)),
              subtitle: Text(AppLocalizations.of(context)!.viewBackupZipsDesc, style: TextStyle(fontSize: subtitleFontSize)),
              trailing: Icon(Icons.chevron_right, size: listItemIconSize),
              onTap: () => context.push('/settings/backups'),
            ),
          ),
          SizedBox(height: sectionSpacing),
          Container(
            decoration: AppTheme.softCardDecoration(
              context,
              color: Theme.of(context).colorScheme.errorContainer.withOpacity(0.1),
            ),
            child: ListTile(
              contentPadding: EdgeInsets.symmetric(horizontal: itemPaddingH, vertical: listItemVerticalPadding + 2),
              leading: Icon(
                Icons.delete_forever,
                size: listItemIconSize,
                color: Theme.of(context).colorScheme.error,
              ),
              title: Text(
                AppLocalizations.of(context)!.clearAllData,
                style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: titleFontSize),
              ),
              onTap: () => _showClearDataDialog(context, ref),
            ),
          ),
          SizedBox(height: sectionSpacing * 2),
          Center(
            child: Text(
              AppLocalizations.of(context)!.version('0.0.12'),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  void _showClearDataDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(ctx)!.confirmClear),
        content: Text(AppLocalizations.of(ctx)!.confirmClearData),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppLocalizations.of(ctx)!.cancel),
          ),
          TextButton(
            onPressed: () async {
              await ref.read(recordRepositoryProvider).deleteAll();
              ref.invalidate(recordListProvider);
              if (ctx.mounted) Navigator.pop(ctx);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(AppLocalizations.of(context)!.allDataCleared)),
                );
              }
            },
            child: Text(AppLocalizations.of(ctx)!.confirmClearBtn),
          ),
        ],
      ),
    );
  }
}