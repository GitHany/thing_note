import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class DataRecoveryWizardScreen extends ConsumerStatefulWidget {
  const DataRecoveryWizardScreen({super.key});

  @override
  ConsumerState<DataRecoveryWizardScreen> createState() => _DataRecoveryWizardScreenState();
}

class _DataRecoveryWizardScreenState extends ConsumerState<DataRecoveryWizardScreen> {
  int _currentStep = 0;
  String? _selectedBackup;
  bool _isRecovering = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('数据恢复向导'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Stepper(
        currentStep: _currentStep,
        onStepContinue: () {
          if (_currentStep < 2) {
            setState(() {
              _currentStep++;
            });
          } else {
            _startRecovery();
          }
        },
        onStepCancel: () {
          if (_currentStep > 0) {
            setState(() {
              _currentStep--;
            });
          }
        },
        steps: [
          Step(
            title: const Text('选择备份'),
            content: _buildSelectBackupStep(),
            isActive: _currentStep >= 0,
            state: _currentStep > 0 ? StepState.complete : StepState.indexed,
          ),
          Step(
            title: const Text('预览内容'),
            content: _buildPreviewStep(),
            isActive: _currentStep >= 1,
            state: _currentStep > 1 ? StepState.complete : StepState.indexed,
          ),
          Step(
            title: const Text('确认恢复'),
            content: _buildConfirmStep(),
            isActive: _currentStep >= 2,
            state: _currentStep > 2 ? StepState.complete : StepState.indexed,
          ),
        ],
      ),
    );
  }

  Widget _buildSelectBackupStep() {
    final backups = [
      {'name': '完整备份 2026-05-21', 'size': '2.1 GB', 'date': '05-21 10:30'},
      {'name': '增量备份 2026-05-20', 'size': '856 MB', 'date': '05-20 22:00'},
      {'name': '完整备份 2026-05-19', 'size': '1.8 GB', 'date': '05-19 08:00'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '选择要恢复的备份文件：',
          style: TextStyle(fontSize: 14),
        ),
        const SizedBox(height: 16),
        ...backups.map((backup) => Card(
          margin: const EdgeInsets.only(bottom: 8),
          color: _selectedBackup == backup['name']
              ? Theme.of(context).colorScheme.primaryContainer
              : null,
          child: ListTile(
            leading: Radio<String>(
              value: backup['name'] as String,
              groupValue: _selectedBackup,
              onChanged: (value) {
                setState(() {
                  _selectedBackup = value;
                });
              },
            ),
            title: Text(backup['name'] as String),
            subtitle: Text('${backup['size']} - ${backup['date']}'),
            trailing: IconButton(
              icon: const Icon(Icons.visibility),
              onPressed: () => _previewBackup(backup),
            ),
          ),
        )),
      ],
    );
  }

  Widget _buildPreviewStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '备份内容预览：',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPreviewItem(Icons.description, '记录数量', '1,234'),
                _buildPreviewItem(Icons.photo, '照片', '89'),
                _buildPreviewItem(Icons.mic, '音频', '12'),
                _buildPreviewItem(Icons.videocam, '视频', '5'),
                _buildPreviewItem(Icons.label, '标签', '156'),
                _buildPreviewItem(Icons.bookmark, '收藏', '45'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          '⚠️ 恢复将覆盖当前数据，建议先创建当前数据的备份。',
          style: TextStyle(color: Colors.orange),
        ),
      ],
    );
  }

  Widget _buildPreviewItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          Text(label),
          const Spacer(),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildConfirmStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '恢复设置',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('恢复前自动备份当前数据'),
                  subtitle: const Text('创建当前数据的完整备份'),
                  value: true,
                  onChanged: (value) {},
                ),
                SwitchListTile(
                  title: const Text('保留当前标签'),
                  subtitle: const Text('合并而非覆盖'),
                  value: true,
                  onChanged: (value) {},
                ),
                SwitchListTile(
                  title: const Text('恢复媒体文件'),
                  subtitle: const Text('照片、音频、视频'),
                  value: true,
                  onChanged: (value) {},
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (_isRecovering) ...[
          const LinearProgressIndicator(),
          const SizedBox(height: 8),
          const Text('正在恢复数据...'),
        ],
      ],
    );
  }

  void _previewBackup(Map<String, dynamic> backup) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('预览: ${backup['name']}'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('记录列表：'),
            SizedBox(height: 8),
            Text('• 团队会议 (05-21 10:00)'),
            Text('• 健身记录 (05-21 07:00)'),
            Text('• 学习Flutter (05-20 20:00)'),
            Text('• ...'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  void _startRecovery() async {
    setState(() {
      _isRecovering = true;
    });

    // Simulate recovery process
    await Future.delayed(const Duration(seconds: 3));

    if (mounted) {
      setState(() {
        _isRecovering = false;
      });
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('恢复成功'),
          content: const Text('数据已成功恢复到所选备份的状态。'),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                context.go('/');
              },
              child: const Text('完成'),
            ),
          ],
        ),
      );
    }
  }
}