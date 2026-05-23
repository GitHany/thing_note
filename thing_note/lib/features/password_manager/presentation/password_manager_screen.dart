import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/password_manager/data/password_repository.dart';
import 'package:thing_note/features/password_manager/domain/password_entry.dart';

class PasswordManagerScreen extends ConsumerStatefulWidget {
  const PasswordManagerScreen({super.key});

  @override
  ConsumerState<PasswordManagerScreen> createState() => _PasswordManagerScreenState();
}

class _PasswordManagerScreenState extends ConsumerState<PasswordManagerScreen> {
  final _masterPasswordController = TextEditingController();
  String? _masterPassword;
  bool _showPasswords = false;

  @override
  Widget build(BuildContext context) {
    final entriesAsync = ref.watch(passwordEntriesProvider);

    if (_masterPassword == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('密码管理')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                const Text('输入主密码解锁', style: TextStyle(fontSize: 18)),
                const SizedBox(height: 16),
                TextField(
                  controller: _masterPasswordController,
                  decoration: const InputDecoration(
                    labelText: '主密码',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    if (_masterPasswordController.text.isNotEmpty) {
                      setState(() {
                        _masterPassword = _masterPasswordController.text;
                      });
                    }
                  },
                  child: const Text('解锁'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('密码管理'),
        actions: [
          IconButton(
            icon: Icon(_showPasswords ? Icons.visibility_off : Icons.visibility),
            onPressed: () => setState(() => _showPasswords = !_showPasswords),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddPasswordDialog(context),
          ),
        ],
      ),
      body: entriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('错误: $e')),
        data: (entries) {
          if (entries.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.key, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('暂无密码记录', style: TextStyle(fontSize: 18)),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => _showAddPasswordDialog(context),
                    child: const Text('添加密码'),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: entries.length,
            itemBuilder: (context, index) => _PasswordEntryCard(
              entry: entries[index],
              showPassword: _showPasswords,
              masterPassword: _masterPassword!,
            ),
          );
        },
      ),
    );
  }

  void _showAddPasswordDialog(BuildContext context) {
    final titleController = TextEditingController();
    final usernameController = TextEditingController();
    final passwordController = TextEditingController();
    final urlController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('添加密码'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: '标题'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: usernameController,
                decoration: const InputDecoration(labelText: '用户名/邮箱'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                decoration: const InputDecoration(labelText: '密码'),
                obscureText: true,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: urlController,
                decoration: const InputDecoration(labelText: '网站（可选）'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              if (titleController.text.trim().isNotEmpty && passwordController.text.isNotEmpty) {
                final encrypted = PasswordEncryptionService.encrypt(
                  passwordController.text,
                  _masterPassword!,
                );
                final now = DateTime.now();
                final entry = PasswordEntry(
                  title: titleController.text.trim(),
                  username: usernameController.text.trim().isEmpty ? null : usernameController.text.trim(),
                  encryptedPassword: encrypted,
                  url: urlController.text.trim().isEmpty ? null : urlController.text.trim(),
                  createdAt: now,
                  updatedAt: now,
                );
                ref.read(passwordEntriesProvider.notifier).addPassword(entry);
                Navigator.pop(context);
              }
            },
            child: const Text('添加'),
          ),
        ],
      ),
    );
  }
}

class _PasswordEntryCard extends ConsumerWidget {
  final PasswordEntry entry;
  final bool showPassword;
  final String masterPassword;

  const _PasswordEntryCard({
    required this.entry,
    required this.showPassword,
    required this.masterPassword,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue.withOpacity(0.2),
          child: const Icon(Icons.key, color: Colors.blue),
        ),
        title: Text(entry.title),
        subtitle: Text(entry.username ?? '无用户名'),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.red),
          onPressed: () => ref.read(passwordEntriesProvider.notifier).deletePassword(entry.id!),
        ),
      ),
    );
  }
}