import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final privacySettingsProvider = StateNotifierProvider<PrivacySettingsNotifier, Map<String, String>>((ref) {
  return PrivacySettingsNotifier();
});

class PrivacySettingsNotifier extends StateNotifier<Map<String, String>> {
  PrivacySettingsNotifier() : super({
    'hide_photos': 'false',
    'hide_videos': 'false',
    'hide_audio': 'false',
    'hide_notes': 'false',
    'hide_location': 'true',
    'auto_lock': 'true',
    'biometric_enabled': 'false',
  });

  void updateSetting(String key, String value) {
    state = {...state, key: value};
  }
}

class PrivacyCenterScreen extends ConsumerWidget {
  const PrivacyCenterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(privacySettingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('隐私中心'),
        actions: [
          IconButton(
            icon: const Icon(Icons.security),
            onPressed: () => _showPrivacyScore(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildPrivacyScore(context, settings),
          const SizedBox(height: 24),
          _buildQuickToggle(context, ref, '隐藏照片', 'hide_photos', Icons.photo, settings),
          _buildQuickToggle(context, ref, '隐藏视频', 'hide_videos', Icons.videocam, settings),
          _buildQuickToggle(context, ref, '隐藏音频', 'hide_audio', Icons.mic, settings),
          _buildQuickToggle(context, ref, '隐藏笔记', 'hide_notes', Icons.note, settings),
          _buildQuickToggle(context, ref, '隐藏位置', 'hide_location', Icons.location_off, settings),
          const SizedBox(height: 24),
          _buildSecuritySection(context, ref, settings),
          const SizedBox(height: 24),
          _buildDataManagement(context),
        ],
      ),
    );
  }

  Widget _buildPrivacyScore(BuildContext context, Map<String, String> settings) {
    final score = _calculateScore(settings);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.blue, Colors.purple],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            '$score',
            style: const TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const Text(
            '隐私安全评分',
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: score / 100,
              minHeight: 8,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation(Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickToggle(BuildContext context, WidgetRef ref, String label, String key, IconData icon, Map<String, String> settings) {
    final isEnabled = settings[key] == 'true';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: isEnabled ? Colors.red : Colors.grey),
        title: Text(label),
        trailing: Switch(
          value: isEnabled,
          onChanged: (value) {
            ref.read(privacySettingsProvider.notifier).updateSetting(key, value.toString());
          },
        ),
      ),
    );
  }

  Widget _buildSecuritySection(BuildContext context, WidgetRef ref, Map<String, String> settings) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('安全设置', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.lock),
            title: const Text('自动锁定'),
            subtitle: const Text('离开应用时自动锁定'),
            trailing: Switch(
              value: settings['auto_lock'] == 'true',
              onChanged: (value) {
                ref.read(privacySettingsProvider.notifier).updateSetting('auto_lock', value.toString());
              },
            ),
          ),
          ListTile(
            leading: const Icon(Icons.fingerprint),
            title: const Text('生物识别'),
            subtitle: const Text('使用指纹或面容解锁'),
            trailing: Switch(
              value: settings['biometric_enabled'] == 'true',
              onChanged: (value) {
                ref.read(privacySettingsProvider.notifier).updateSetting('biometric_enabled', value.toString());
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataManagement(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('数据管理', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.download),
            title: const Text('导出数据'),
            subtitle: const Text('下载所有个人数据'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: const Text('删除所有数据', style: TextStyle(color: Colors.red)),
            subtitle: const Text('永久删除账户和数据'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _confirmDelete(context),
          ),
        ],
      ),
    );
  }

  void _showPrivacyScore(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('隐私安全评分'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('💡 建议：'),
            SizedBox(height: 8),
            Text('• 启用生物识别以提高安全性'),
            Text('• 开启自动锁定功能'),
            Text('• 定期审查隐藏的内容'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('知道了'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('此操作不可撤销，所有数据将被永久删除。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('数据删除功能开发中...')),
              );
            },
            child: const Text('确认删除'),
          ),
        ],
      ),
    );
  }

  int _calculateScore(Map<String, String> settings) {
    int score = 60;
    if (settings['biometric_enabled'] == 'true') score += 10;
    if (settings['auto_lock'] == 'true') score += 10;
    if (settings['hide_photos'] == 'true') score += 5;
    if (settings['hide_videos'] == 'true') score += 5;
    if (settings['hide_location'] == 'true') score += 10;
    return score;
  }
}