import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/habit_tournament/data/tournament_repository.dart';

class PrivacySettingsScreen extends ConsumerWidget {
  const PrivacySettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(privacySettingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('隐私设置'),
      ),
      body: settingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('错误: $e')),
        data: (settings) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildSection(
              title: '数据可见性',
              children: [
                _SettingSwitch(
                  title: '隐藏照片',
                  subtitle: '在列表中隐藏照片缩略图',
                  icon: Icons.photo,
                  value: settings['hide_photos'] == 'true',
                  onChanged: (v) => _saveSetting(ref, 'hide_photos', v.toString()),
                ),
                _SettingSwitch(
                  title: '隐藏视频',
                  subtitle: '在列表中隐藏视频缩略图',
                  icon: Icons.videocam,
                  value: settings['hide_videos'] == 'true',
                  onChanged: (v) => _saveSetting(ref, 'hide_videos', v.toString()),
                ),
                _SettingSwitch(
                  title: '隐藏音频',
                  subtitle: '不显示音频波形预览',
                  icon: Icons.audiotrack,
                  value: settings['hide_audio'] == 'true',
                  onChanged: (v) => _saveSetting(ref, 'hide_audio', v.toString()),
                ),
                _SettingSwitch(
                  title: '隐藏位置',
                  subtitle: '不显示位置信息',
                  icon: Icons.location_off,
                  value: settings['hide_location'] == 'true',
                  onChanged: (v) => _saveSetting(ref, 'hide_location', v.toString()),
                ),
                _SettingSwitch(
                  title: '隐藏笔记',
                  subtitle: '使用****代替笔记内容',
                  icon: Icons.note,
                  value: settings['hide_notes'] == 'true',
                  onChanged: (v) => _saveSetting(ref, 'hide_notes', v.toString()),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildSection(
              title: '通知隐私',
              children: [
                _SettingSwitch(
                  title: '隐藏通知内容',
                  subtitle: '通知不显示详细内容',
                  icon: Icons.notifications_off,
                  value: settings['hide_notification_content'] == 'true',
                  onChanged: (v) => _saveSetting(ref, 'hide_notification_content', v.toString()),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildSection(
              title: '统计隐私',
              children: [
                _SettingSwitch(
                  title: '隐藏统计数据',
                  subtitle: '不在仪表盘显示统计数据',
                  icon: Icons.bar_chart,
                  value: settings['hide_statistics'] == 'true',
                  onChanged: (v) => _saveSetting(ref, 'hide_statistics', v.toString()),
                ),
                _SettingSwitch(
                  title: '隐藏排行榜',
                  subtitle: '不显示习惯排行榜',
                  icon: Icons.leaderboard,
                  value: settings['hide_leaderboard'] == 'true',
                  onChanged: (v) => _saveSetting(ref, 'hide_leaderboard', v.toString()),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.warning, color: Colors.orange),
                        SizedBox(width: 8),
                        Text(
                          '隐私模式提示',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    Text(
                      '启用隐私设置后，对应的内容将被隐藏或模糊处理。这些设置仅影响应用内的显示，不会影响实际数据。',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey),
        ),
        const SizedBox(height: 8),
        Card(
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  void _saveSetting(WidgetRef ref, String key, String value) {
    ref.read(privacySettingsProvider.notifier).setSetting(key, value);
  }
}

class _SettingSwitch extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool value;
  final Function(bool) onChanged;

  const _SettingSwitch({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      title: Text(title),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      secondary: Icon(icon),
      value: value,
      onChanged: onChanged,
    );
  }
}