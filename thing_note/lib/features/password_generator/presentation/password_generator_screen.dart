import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:thing_note/features/password_generator/data/password_repository.dart';
import 'package:thing_note/features/password_generator/domain/password_generator.dart';

final currentPasswordProvider = StateProvider<GeneratedPassword?>((ref) => null);

final passwordHistoryProvider = FutureProvider<List<GeneratedPassword>>((ref) async {
  final repository = ref.watch(passwordGeneratorRepositoryProvider);
  return await repository.getRecentPasswords();
});

class PasswordGeneratorScreen extends ConsumerStatefulWidget {
  const PasswordGeneratorScreen({super.key});

  @override
  ConsumerState<PasswordGeneratorScreen> createState() => _PasswordGeneratorScreenState();
}

class _PasswordGeneratorScreenState extends ConsumerState<PasswordGeneratorScreen> {
  int _length = 16;
  bool _includeUppercase = true;
  bool _includeLowercase = true;
  bool _includeNumbers = true;
  bool _includeSymbols = true;

  @override
  void initState() {
    super.initState();
    _generatePassword();
  }

  void _generatePassword() {
    final options = PasswordGeneratorOptions(
      length: _length,
      includeUppercase: _includeUppercase,
      includeLowercase: _includeLowercase,
      includeNumbers: _includeNumbers,
      includeSymbols: _includeSymbols,
    );
    final password = PasswordGenerator.generate(options);
    ref.read(currentPasswordProvider.notifier).state = password;
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('密码已复制到剪贴板'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _savePassword(GeneratedPassword password) async {
    final repository = ref.read(passwordGeneratorRepositoryProvider);
    await repository.savePassword(password);
    ref.invalidate(passwordHistoryProvider);
  }

  @override
  Widget build(BuildContext context) {
    final currentPassword = ref.watch(currentPasswordProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('密码生成器'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => _showHistoryDialog(context),
            tooltip: '历史记录',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildPasswordDisplay(context, currentPassword),
            const SizedBox(height: 24),
            _buildStrengthIndicator(context, currentPassword),
            const SizedBox(height: 24),
            _buildOptionsCard(context),
            const SizedBox(height: 24),
            _buildActionButtons(context, currentPassword),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordDisplay(BuildContext context, GeneratedPassword? password) {
    return Card(
      elevation: 4,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.primary.withOpacity(0.1),
              Theme.of(context).colorScheme.secondary.withOpacity(0.1),
            ],
          ),
        ),
        child: Column(
          children: [
            Text(
              '生成的密码',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: SelectableText(
                password?.password ?? '点击生成按钮创建密码',
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildActionButton(
                  icon: Icons.refresh,
                  label: '重新生成',
                  onPressed: _generatePassword,
                ),
                const SizedBox(width: 12),
                _buildActionButton(
                  icon: Icons.copy,
                  label: '复制',
                  onPressed: password != null
                      ? () => _copyToClipboard(password.password)
                      : null,
                ),
                const SizedBox(width: 12),
                _buildActionButton(
                  icon: Icons.save,
                  label: '保存',
                  onPressed: password != null
                      ? () => _savePassword(password)
                      : null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    VoidCallback? onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }

  Widget _buildStrengthIndicator(BuildContext context, GeneratedPassword? password) {
    final score = password?.strengthScore ?? 0;
    final color = GeneratedPassword.getStrengthColor(score);
    final label = password?.strengthLabel ?? '未知';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '密码强度',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: password?.strengthProgress ?? 0,
                minHeight: 12,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '安全评分: $score/100',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (password != null)
                  Text(
                    '${password.length}位 · ${_getCharTypes(password)}种字符',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getCharTypes(GeneratedPassword password) {
    int count = 2; // lowercase + numbers by default
    if (password.hasUppercase) count++;
    if (password.hasSymbols) count++;
    return count.toString();
  }

  Widget _buildOptionsCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '密码选项',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            // Length slider
            Row(
              children: [
                const Text('密码长度'),
                const Spacer(),
                Text(
                  '$_length 位',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            Slider(
              value: _length.toDouble(),
              min: 8,
              max: 64,
              divisions: 56,
              label: '$_length',
              onChanged: (value) {
                setState(() {
                  _length = value.round();
                });
                _generatePassword();
              },
            ),
            const Divider(),
            // Character options
            SwitchListTile(
              title: const Text('大写字母 (A-Z)'),
              subtitle: const Text('增强密码复杂性'),
              value: _includeUppercase,
              onChanged: (value) {
                setState(() => _includeUppercase = value);
                _generatePassword();
              },
            ),
            SwitchListTile(
              title: const Text('小写字母 (a-z)'),
              subtitle: const Text('基础字符集'),
              value: _includeLowercase,
              onChanged: (value) {
                setState(() => _includeLowercase = value);
                _generatePassword();
              },
            ),
            SwitchListTile(
              title: const Text('数字 (0-9)'),
              subtitle: const Text('增加数字字符'),
              value: _includeNumbers,
              onChanged: (value) {
                setState(() => _includeNumbers = value);
                _generatePassword();
              },
            ),
            SwitchListTile(
              title: const Text('特殊符号'),
              subtitle: const Text('最大程度增强密码强度'),
              value: _includeSymbols,
              onChanged: (value) {
                setState(() => _includeSymbols = value);
                _generatePassword();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, GeneratedPassword? password) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _generatePassword,
            icon: const Icon(Icons.refresh),
            label: const Text('生成新密码'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.all(16),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: password != null
                ? () => _copyToClipboard(password.password)
                : null,
            icon: const Icon(Icons.copy),
            label: const Text('复制到剪贴板'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.all(16),
            ),
          ),
        ),
      ],
    );
  }

  void _showHistoryDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            final historyAsync = ref.watch(passwordHistoryProvider);

            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '密码历史',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        TextButton(
                          onPressed: () async {
                            final repository = ref.read(passwordGeneratorRepositoryProvider);
                            await repository.clearHistory();
                            ref.invalidate(passwordHistoryProvider);
                          },
                          child: const Text('清空'),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: historyAsync.when(
                      data: (history) {
                        if (history.isEmpty) {
                          return const Center(
                            child: Text('暂无历史记录'),
                          );
                        }
                        return ListView.separated(
                          controller: scrollController,
                          itemCount: history.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final password = history[index];
                            return ListTile(
                              title: Text(
                                password.password,
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                _formatDate(password.createdAt),
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.copy),
                                onPressed: () => _copyToClipboard(password.password),
                              ),
                            );
                          },
                        );
                      },
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (e, _) => Center(child: Text('加载失败: $e')),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _formatDate(String isoTime) {
    try {
      final date = DateTime.parse(isoTime);
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return isoTime;
    }
  }
}
