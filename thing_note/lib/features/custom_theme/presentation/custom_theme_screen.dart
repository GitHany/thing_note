import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/custom_theme/data/custom_theme_repository.dart';
import 'package:thing_note/features/custom_theme/domain/custom_theme.dart';

final customThemeRepoProvider = Provider((ref) => CustomThemeRepository(ref));

class CustomThemeScreen extends ConsumerStatefulWidget {
  const CustomThemeScreen({super.key});

  @override
  ConsumerState<CustomThemeScreen> createState() => _CustomThemeScreenState();
}

class _CustomThemeScreenState extends ConsumerState<CustomThemeScreen> {
  List<CustomTheme> _themes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadThemes();
  }

  Future<void> _loadThemes() async {
    setState(() => _isLoading = true);
    final repo = ref.read(customThemeRepoProvider);
    _themes = await repo.getAllThemes();
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('自定义主题'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddDialog,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _themes.isEmpty
              ? _buildEmptyState()
              : _buildThemeList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.palette, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('暂无自定义主题', style: TextStyle(fontSize: 18)),
          const SizedBox(height: 8),
          const Text('创建你的专属配色方案'),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _showAddDialog,
            icon: const Icon(Icons.add),
            label: const Text('创建主题'),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _themes.length,
      itemBuilder: (context, index) {
        final theme = _themes[index];
        return _ThemeCard(
          theme: theme,
          onApply: () => _applyTheme(theme),
          onDelete: () => _deleteTheme(theme.id!),
        );
      },
    );
  }

  void _showAddDialog() {
    final nameController = TextEditingController();
    final primaryColorController = TextEditingController(text: '#2196F3');
    bool isDark = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('创建主题'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: '主题名称'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: primaryColorController,
                  decoration: const InputDecoration(labelText: '主色 (HEX)'),
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('深色模式'),
                  value: isDark,
                  onChanged: (v) => setDialogState(() => isDark = v),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () async {
                if (nameController.text.trim().isEmpty) return;
                final repo = ref.read(customThemeRepoProvider);
                await repo.insertTheme(CustomTheme(
                  name: nameController.text.trim(),
                  primaryColor: primaryColorController.text.trim(),
                  isDarkMode: isDark,
                  createdAt: DateTime.now(),
                ));
                if (!ctx.mounted) return;
                Navigator.pop(ctx);
                _loadThemes();
              },
              child: const Text('创建'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _applyTheme(CustomTheme theme) async {
    final repo = ref.read(customThemeRepoProvider);
    await repo.setActiveTheme(theme.id!);
    _loadThemes();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('已应用主题: ${theme.name}')),
      );
    }
  }

  Future<void> _deleteTheme(int id) async {
    final repo = ref.read(customThemeRepoProvider);
    await repo.deleteTheme(id);
    _loadThemes();
  }
}

class _ThemeCard extends StatelessWidget {
  final CustomTheme theme;
  final VoidCallback onApply;
  final VoidCallback onDelete;

  const _ThemeCard({
    required this.theme,
    required this.onApply,
    required this.onDelete,
  });

  Color _parseColor(String hex) {
    return Color(int.parse(hex.replaceFirst('#', '0xFF')));
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = _parseColor(theme.primaryColor);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onApply,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: primaryColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          theme.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          theme.isDarkMode ? '深色模式' : '浅色模式',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  if (theme.isActive)
                    const Chip(
                      label: Text('应用中'),
                      backgroundColor: Colors.green,
                    ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: onDelete,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}