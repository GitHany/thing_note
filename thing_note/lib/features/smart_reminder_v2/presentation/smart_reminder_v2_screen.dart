import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class SmartReminderV2Screen extends ConsumerStatefulWidget {
  const SmartReminderV2Screen({super.key});

  @override
  ConsumerState<SmartReminderV2Screen> createState() => _SmartReminderV2ScreenState();
}

class _SmartReminderV2ScreenState extends ConsumerState<SmartReminderV2Screen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('智能提醒系统 V2'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              _showAddReminderDialog(context);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildReminderStats(),
          Expanded(
            child: _buildReminderList(),
          ),
        ],
      ),
    );
  }

  Widget _buildReminderStats() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(child: _buildStatCard('今日', '3', Icons.today)),
          const SizedBox(width: 8),
          Expanded(child: _buildStatCard('本周', '12', Icons.date_range)),
          const SizedBox(width: 8),
          Expanded(child: _buildStatCard('本月', '45', Icons.calendar_month)),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, size: 24),
            const SizedBox(height: 4),
            Text(title, style: const TextStyle(fontSize: 12)),
            Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildReminderList() {
    return ListView(
      children: [
        _buildSectionHeader('今日提醒'),
        _buildReminderItem('会议提醒', '10:00', true),
        _buildReminderItem('喝水提醒', '14:00', false),
        _buildReminderItem('运动提醒', '18:00', true),
        const SizedBox(height: 16),
        _buildSectionHeader('本周提醒'),
        _buildReminderItem('周报提交', '周五 17:00', true),
        _buildReminderItem('项目评审', '周四 14:00', false),
        _buildReminderItem('团队会议', '周二 10:00', true),
        const SizedBox(height: 16),
        _buildSectionHeader('本月提醒'),
        _buildReminderItem('月度总结', '月末', true),
        _buildReminderItem('设备维护', '15日', false),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildReminderItem(String title, String time, bool isEnabled) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: Icon(
          isEnabled ? Icons.notifications_active : Icons.notifications_off,
          color: isEnabled ? Theme.of(context).colorScheme.primary : Colors.grey,
        ),
        title: Text(title),
        subtitle: Text(time),
        trailing: Switch(
          value: isEnabled,
          onChanged: (value) {
            // Toggle reminder
          },
        ),
        onTap: () {
          _showEditReminderDialog(context, title, time);
        },
      ),
    );
  }

  void _showAddReminderDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('添加提醒'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: InputDecoration(
                labelText: '提醒标题',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                labelText: '提醒时间',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  void _showEditReminderDialog(BuildContext context, String title, String time) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('编辑 $title'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.access_time),
              title: const Text('提醒时间'),
              subtitle: Text(time),
              onTap: () {
                // Show time picker
              },
            ),
            ListTile(
              leading: const Icon(Icons.repeat),
              title: const Text('重复模式'),
              subtitle: const Text('仅一次'),
              onTap: () {
                // Show repeat options
              },
            ),
            ListTile(
              leading: const Icon(Icons.snooze),
              title: const Text('贪睡时间'),
              subtitle: const Text('5 分钟'),
              onTap: () {
                // Show snooze options
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }
}