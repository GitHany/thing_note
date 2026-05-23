import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class PrivacyFolderScreen extends ConsumerStatefulWidget {
  const PrivacyFolderScreen({super.key});

  @override
  ConsumerState<PrivacyFolderScreen> createState() => _PrivacyFolderScreenState();
}

class _PrivacyFolderScreenState extends ConsumerState<PrivacyFolderScreen> {
  bool _isUnlocked = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('隐私文件夹'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(_isUnlocked ? Icons.lock : Icons.lock_open),
            onPressed: () {
              setState(() {
                _isUnlocked = !_isUnlocked;
              });
            },
          ),
        ],
      ),
      body: _isUnlocked ? _buildUnlockedView() : _buildLockedView(),
      floatingActionButton: _isUnlocked
          ? FloatingActionButton(
              onPressed: () => _showCreateFolderDialog(context),
              child: const Icon(Icons.create_new_folder),
            )
          : null,
    );
  }

  Widget _buildLockedView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.folder_special, size: 80, color: Colors.grey),
          const SizedBox(height: 24),
          const Text(
            '隐私文件夹已锁定',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            '解锁后可以访问私密内容',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showUnlockDialog(context),
            icon: const Icon(Icons.lock_open),
            label: const Text('解锁'),
          ),
        ],
      ),
    );
  }

  Widget _buildUnlockedView() {
    final folders = [
      {'name': '工作秘密', 'icon': '💼', 'color': '#2196F3', 'count': 12},
      {'name': '个人日记', 'icon': '📓', 'color': '#9C27B0', 'count': 45},
      {'name': '财务记录', 'icon': '💰', 'color': '#4CAF50', 'count': 8},
      {'name': '医疗信息', 'icon': '🏥', 'color': '#FF5722', 'count': 5},
    ];

    return ListView(
      children: [
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            '我的私密文件夹',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        ...folders.map((folder) => _buildFolderCard(folder)),
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildFolderCard(Map<String, dynamic> folder) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Color(int.parse((folder['color'] as String).replaceFirst('#', '0xFF'))).withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              folder['icon'] as String,
              style: const TextStyle(fontSize: 24),
            ),
          ),
        ),
        title: Text(folder['name'] as String),
        subtitle: Text('${folder['count']} 条记录'),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'open', child: Text('打开')),
            const PopupMenuItem(value: 'edit', child: Text('编辑')),
            const PopupMenuItem(value: 'delete', child: Text('删除')),
          ],
        ),
        onTap: () => _openFolder(folder),
      ),
    );
  }

  void _showUnlockDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('解锁隐私文件夹'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const TextField(
              obscureText: true,
              decoration: InputDecoration(
                labelText: '密码',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('使用指纹解锁'),
                Switch(
                  value: true,
                  onChanged: (value) {},
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _isUnlocked = true;
              });
            },
            child: const Text('解锁'),
          ),
        ],
      ),
    );
  }

  void _showCreateFolderDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('创建私密文件夹'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const TextField(
              decoration: InputDecoration(
                labelText: '文件夹名称',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            const TextField(
              obscureText: true,
              decoration: InputDecoration(
                labelText: '设置密码',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            const Text('选择图标：'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: ['💼', '📓', '💰', '🏥', '📝', '🔐', '🎯', '💡']
                  .map((icon) => GestureDetector(
                        onTap: () {},
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(icon, style: const TextStyle(fontSize: 24)),
                        ),
                      ))
                  .toList(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('文件夹创建成功')),
              );
            },
            child: const Text('创建'),
          ),
        ],
      ),
    );
  }

  void _openFolder(Map<String, dynamic> folder) {
    // Navigate to folder contents
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('打开文件夹: ${folder['name']}')),
    );
  }
}