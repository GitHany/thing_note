import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:thing_note/features/record/presentation/providers/record_provider.dart';
import 'package:thing_note/features/record/domain/episode_record.dart';

// Quick Record Floating State Provider
final quickRecordFloatingEnabledProvider = StateProvider<bool>((ref) => true);
final quickRecordExpandedProvider = StateProvider<bool>((ref) => false);

class QuickRecordFloatingScreen extends ConsumerStatefulWidget {
  const QuickRecordFloatingScreen({super.key});

  @override
  ConsumerState<QuickRecordFloatingScreen> createState() => _QuickRecordFloatingScreenState();
}

class _QuickRecordFloatingScreenState extends ConsumerState<QuickRecordFloatingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;
  bool _isExpanded = false;
  final List<_QuickAction> _quickActions = [
    _QuickAction(Icons.note_add, '文字', Colors.blue, '/record/new'),
    _QuickAction(Icons.mic, '语音', Colors.red, '/voice-recorder'),
    _QuickAction(Icons.camera_alt, '拍照', Colors.green, '/quick-photo-capture'),
    _QuickAction(Icons.calendar_today, '日程', Colors.orange, '/planner'),
    _QuickAction(Icons.search, '搜索', Colors.purple, '/search'),
    _QuickAction(Icons.bookmark, '收藏', Colors.amber, '/record-favorites'),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _rotationAnimation = Tween<double>(begin: 0.0, end: 0.125).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('悬浮快速记录'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _showSettings(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('快速操作'),
            const SizedBox(height: 12),
            _buildQuickActionsGrid(),
            const SizedBox(height: 24),
            _buildSectionTitle('最近记录'),
            const SizedBox(height: 12),
            _buildRecentRecords(),
            const SizedBox(height: 24),
            _buildSectionTitle('快捷方式设置'),
            const SizedBox(height: 12),
            _buildQuickActionsConfig(),
          ],
        ),
      ),
      floatingActionButton: _buildFloatingButton(),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
    );
  }

  Widget _buildQuickActionsGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _quickActions.length,
      itemBuilder: (context, index) {
        final action = _quickActions[index];
        return _buildQuickActionCard(action);
      },
    );
  }

  Widget _buildQuickActionCard(_QuickAction action) {
    return InkWell(
      onTap: () => context.push(action.route),
      borderRadius: BorderRadius.circular(16),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                action.color.withOpacity(0.8),
                action.color,
              ],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(action.icon, size: 32, color: Colors.white),
              const SizedBox(height: 8),
              Text(
                action.label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentRecords() {
    final recordsAsync = ref.watch(recordListProvider);

    return recordsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('加载失败: $err')),
      data: (records) {
        if (records.isEmpty) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Center(
                child: Text('暂无记录'),
              ),
            ),
          );
        }
        final recentRecords = records.take(5).toList();
        return Column(
          children: recentRecords.map((record) {
            return _buildRecentRecordCard(record);
          }).toList(),
        );
      },
    );
  }

  Widget _buildRecentRecordCard(EpisodeRecord record) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _getRecordIcon(record),
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        title: Text(
          record.note.isNotEmpty ? record.note : '无内容记录',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          _formatDate(record.occurredAt),
          style: TextStyle(color: Theme.of(context).colorScheme.outline),
        ),
        trailing: record.isFavorite
            ? const Icon(Icons.star, color: Colors.amber)
            : null,
        onTap: () => context.push('/record/${record.id}'),
      ),
    );
  }

  Widget _buildQuickActionsConfig() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SwitchListTile(
              title: const Text('启用悬浮按钮'),
              subtitle: const Text('在屏幕边缘显示悬浮快速记录按钮'),
              value: ref.watch(quickRecordFloatingEnabledProvider),
              onChanged: (value) {
                ref.read(quickRecordFloatingEnabledProvider.notifier).state = value;
              },
            ),
            const Divider(),
            SwitchListTile(
              title: const Text('语音快捷键'),
              subtitle: const Text('长按快捷方式触发语音输入'),
              value: true,
              onChanged: (value) {},
            ),
            const Divider(),
            SwitchListTile(
              title: const Text('位置自动记录'),
              subtitle: const Text('自动记录当前位置'),
              value: true,
              onChanged: (value) {},
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingButton() {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: RotationTransition(
        turns: _rotationAnimation,
        child: FloatingActionButton(
          onPressed: _toggleExpanded,
          backgroundColor: Theme.of(context).colorScheme.primary,
          child: Icon(_isExpanded ? Icons.close : Icons.add),
        ),
      ),
    );
  }

  IconData _getRecordIcon(EpisodeRecord record) {
    if (record.hasVideos) return Icons.videocam;
    if (record.hasPhotos) return Icons.photo;
    if (record.hasAudio) return Icons.mic;
    if (record.note.isNotEmpty) return Icons.note;
    return Icons.event;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) {
      return '今天 ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays == 1) {
      return '昨天 ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else {
      return '${date.month}/${date.day} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    }
  }

  void _showSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                '快速记录设置',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 24),
              const _SettingsSection(title: '快捷操作', children: [
                _SettingsItem(
                  icon: Icons.speed,
                  title: '快速模式',
                  subtitle: '单次点击完成记录',
                ),
                _SettingsItem(
                  icon: Icons.flash_on,
                  title: '极速模式',
                  subtitle: '连续快速记录',
                ),
                _SettingsItem(
                  icon: Icons.keyboard,
                  title: '快捷键',
                  subtitle: '配置键盘快捷键',
                ),
              ]),
              const SizedBox(height: 16),
              const _SettingsSection(title: '自动化', children: [
                _SettingsItem(
                  icon: Icons.location_on,
                  title: '位置自动记录',
                  subtitle: '自动获取GPS坐标',
                ),
                _SettingsItem(
                  icon: Icons.access_time,
                  title: '时间戳自动',
                  subtitle: '自动使用当前时间',
                ),
                _SettingsItem(
                  icon: Icons.mic,
                  title: '语音转文字',
                  subtitle: '自动将语音转为文字',
                ),
              ]),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('保存设置'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickAction {
  final IconData icon;
  final String label;
  final Color color;
  final String route;

  _QuickAction(this.icon, this.label, this.color, this.route);
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }
}

class _SettingsItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _SettingsItem({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {},
    );
  }
}
