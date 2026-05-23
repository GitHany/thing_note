import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/smart_classifier/data/smart_classifier_service.dart';
import 'package:thing_note/features/smart_classifier/domain/smart_classifier_models.dart';

/// 智能分类助手屏幕
class SmartClassifierScreen extends ConsumerStatefulWidget {
  const SmartClassifierScreen({super.key});

  @override
  ConsumerState<SmartClassifierScreen> createState() => _SmartClassifierScreenState();
}

class _SmartClassifierScreenState extends ConsumerState<SmartClassifierScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<ClassificationRule> _rules = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final service = ref.read(smartClassifierServiceProvider);
      final rules = await service.getRules();

      setState(() {
        _rules = rules;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载失败: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('智能分类'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '规则'),
            Tab(text: '统计'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildRulesTab(),
                _buildStatsTab(),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddRuleDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildRulesTab() {
    if (_rules.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.rule,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              '暂无分类规则',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              '创建规则自动分类您的记录',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => _showAddRuleDialog(),
              icon: const Icon(Icons.add),
              label: const Text('添加规则'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _rules.length,
      itemBuilder: (context, index) {
        final rule = _rules[index];
        return _buildRuleCard(rule);
      },
    );
  }

  Widget _buildRuleCard(ClassificationRule rule) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    rule.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Switch(
                  value: rule.isEnabled,
                  onChanged: (value) async {
                    final service = ref.read(smartClassifierServiceProvider);
                    final updatedRule = ClassificationRule(
                      id: rule.id,
                      name: rule.name,
                      pattern: rule.pattern,
                      assignedThingName: rule.assignedThingName,
                      assignedTags: rule.assignedTags,
                      isEnabled: value,
                      matchCount: rule.matchCount,
                    );
                    await service.updateRule(rule.id!, updatedRule);
                    _loadData();
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '匹配: ${rule.pattern}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            const SizedBox(height: 8),
            if (rule.assignedThingName != null)
              Chip(
                avatar: const Icon(Icons.category, size: 16),
                label: Text(rule.assignedThingName!),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
            if (rule.assignedTags.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: rule.assignedTags.map((tag) {
                  return Chip(
                    label: Text(tag),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              '已匹配 ${rule.matchCount} 次',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 统计概览
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '分类统计',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatItem(
                          '活跃规则',
                          '${_rules.where((r) => r.isEnabled).length}',
                          Icons.rule,
                        ),
                      ),
                      Expanded(
                        child: _buildStatItem(
                          '总匹配',
                          '${_rules.fold(0, (sum, r) => sum + r.matchCount)}',
                          Icons.check_circle,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 预设规则模板
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '快速添加规则',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  _buildQuickRuleChip('工作相关', '工作|上班|会议'),
                  _buildQuickRuleChip('学习相关', '学习|读书|课程'),
                  _buildQuickRuleChip('运动相关', '运动|跑步|健身'),
                  _buildQuickRuleChip('餐饮相关', '吃饭|午餐|晚餐'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickRuleChip(String label, String pattern) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ActionChip(
        avatar: const Icon(Icons.add, size: 16),
        label: Text(label),
        onPressed: () => _addQuickRule(label, pattern),
      ),
    );
  }

  Future<void> _addQuickRule(String name, String pattern) async {
    try {
      final service = ref.read(smartClassifierServiceProvider);
      await service.addRule(ClassificationRule(
        name: name,
        pattern: pattern,
      ));
      _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已添加规则: $name')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('添加失败: $e')),
        );
      }
    }
  }

  void _showAddRuleDialog() {
    final nameController = TextEditingController();
    final patternController = TextEditingController();
    final thingNameController = TextEditingController();
    final tagsController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('添加规则'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: '规则名称',
                  hintText: '例如：工作记录',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: patternController,
                decoration: const InputDecoration(
                  labelText: '匹配模式',
                  hintText: '例如：工作|上班|会议',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: thingNameController,
                decoration: const InputDecoration(
                  labelText: '自动设置事情名称（可选）',
                  hintText: '例如：工作',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: tagsController,
                decoration: const InputDecoration(
                  labelText: '自动添加标签（用逗号分隔，可选）',
                  hintText: '例如：工作,重要',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () async {
              if (nameController.text.isEmpty || patternController.text.isEmpty) {
                return;
              }

              final tags = tagsController.text
                  .split(',')
                  .map((t) => t.trim())
                  .where((t) => t.isNotEmpty)
                  .toList();

              try {
                final service = ref.read(smartClassifierServiceProvider);
                await service.addRule(ClassificationRule(
                  name: nameController.text,
                  pattern: patternController.text,
                  assignedThingName: thingNameController.text.isEmpty
                      ? null
                      : thingNameController.text,
                  assignedTags: tags,
                ));
                if (mounted) {
                  Navigator.pop(context);
                  _loadData();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('规则已添加')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('添加失败: $e')),
                  );
                }
              }
            },
            child: const Text('添加'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}