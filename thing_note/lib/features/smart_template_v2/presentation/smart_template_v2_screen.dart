import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/smart_template_v2/data/smart_template_v2_service.dart';
import 'package:thing_note/features/smart_template_v2/domain/smart_template_v2_models.dart';

/// 智能模板 V2 屏幕
class SmartTemplateV2Screen extends ConsumerStatefulWidget {
  const SmartTemplateV2Screen({super.key});

  @override
  ConsumerState<SmartTemplateV2Screen> createState() => _SmartTemplateV2ScreenState();
}

class _SmartTemplateV2ScreenState extends ConsumerState<SmartTemplateV2Screen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<TemplateRecommendation> _recommendations = [];
  List<Map<String, dynamic>> _allTemplates = [];
  bool _isLoading = true;
  UsagePattern? _usagePattern;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final service = ref.read(smartTemplateServiceProvider);
      
      // 获取推荐
      final recommendations = await service.getRecommendations();
      final allTemplates = await service.getAllTemplates();
      final pattern = await service.analyzeUsagePattern();

      setState(() {
        _recommendations = recommendations;
        _allTemplates = allTemplates;
        _usagePattern = pattern;
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
        title: const Text('智能模板'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '推荐'),
            Tab(text: '模板库'),
            Tab(text: '使用分析'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildRecommendationsTab(),
                _buildTemplateLibraryTab(),
                _buildUsageAnalysisTab(),
              ],
            ),
    );
  }

  /// 推荐标签页
  Widget _buildRecommendationsTab() {
    if (_recommendations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.auto_awesome,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              '暂无推荐',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              '使用更多模板后，我们会为您推荐常用模板',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _recommendations.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.lightbulb,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '基于您的使用习惯',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '我们分析了您的记录模式，为您推荐以下模板',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final recommendation = _recommendations[index - 1];
        return _buildRecommendationCard(recommendation);
      },
    );
  }

  Widget _buildRecommendationCard(TemplateRecommendation recommendation) {
    final confidencePercent = (recommendation.confidence * 100).toInt();
    final confidenceColor = recommendation.confidence > 0.7
        ? Colors.green
        : recommendation.confidence > 0.5
            ? Colors.orange
            : Colors.grey;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _useTemplate(recommendation),
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          recommendation.templateName,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          recommendation.reason,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: confidenceColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$confidencePercent%',
                      style: TextStyle(
                        color: confidenceColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: recommendation.suggestedTags.map((tag) {
                  return Chip(
                    label: Text(tag),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.history,
                    size: 14,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '已使用 ${recommendation.useCount} 次',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const Spacer(),
                  FilledButton.tonal(
                    onPressed: () => _useTemplate(recommendation),
                    child: const Text('使用'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _useTemplate(TemplateRecommendation recommendation) {
    // 记录使用
    final service = ref.read(smartTemplateServiceProvider);
    service.recordTemplateUsage(TemplateUsage(
      templateId: recommendation.templateId,
      templateName: recommendation.templateName,
      usedAt: DateTime.now(),
    ));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('已选择模板: ${recommendation.templateName}'),
        action: SnackBarAction(
          label: '查看',
          onPressed: () {
            // TODO: 跳转到模板详情
          },
        ),
      ),
    );

    // 刷新数据
    _loadData();
  }

  /// 模板库标签页
  Widget _buildTemplateLibraryTab() {
    if (_allTemplates.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.folder_open,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              '暂无模板',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              '创建您的第一个模板吧',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      );
    }

    // 按类别分组
    final categorizedTemplates = <String, List<Map<String, dynamic>>>{};
    for (final template in _allTemplates) {
      final category = template['category'] as String? ?? '默认';
      categorizedTemplates.putIfAbsent(category, () => []);
      categorizedTemplates[category]!.add(template);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: categorizedTemplates.length,
      itemBuilder: (context, index) {
        final category = categorizedTemplates.keys.elementAt(index);
        final templates = categorizedTemplates[category]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                category,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            ...templates.map((t) => _buildTemplateItem(t)),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  Widget _buildTemplateItem(Map<String, dynamic> template) {
    final name = template['name'] as String;
    final useCount = template['use_count'] as int? ?? 0;
    final isFavorite = (template['is_favorite'] as int?) == 1;
    final defaultTagsStr = template['default_tags'] as String?;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Icon(
            isFavorite ? Icons.star : Icons.description,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
        ),
        title: Text(name),
        subtitle: Text('已使用 $useCount 次'),
        trailing: defaultTagsStr != null && defaultTagsStr.isNotEmpty
            ? Chip(
                label: Text(
                  defaultTagsStr.split(',').first,
                  style: const TextStyle(fontSize: 10),
                ),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              )
            : null,
        onTap: () => _showTemplateDetails(template),
      ),
    );
  }

  void _showTemplateDetails(Map<String, dynamic> template) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              template['name'] as String,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Text('使用次数: ${template['use_count'] ?? 0}'),
            if (template['description'] != null)
              Text('描述: ${template['description']}'),
            if (template['default_thing_name'] != null)
              Text('默认事情: ${template['default_thing_name']}'),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('关闭'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: () {
                    Navigator.pop(context);
                    // 使用模板
                  },
                  child: const Text('使用'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 使用分析标签页
  Widget _buildUsageAnalysisTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 使用模式卡片
          if (_usagePattern != null) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.insights,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '使用模式分析',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                    const Divider(),
                    _buildPatternRow(
                      '最活跃时段',
                      _getTimeOfDayLabel(_usagePattern!.timeOfDay),
                      Icons.schedule,
                    ),
                    _buildPatternRow(
                      '最活跃日期',
                      _getDayOfWeekLabel(_usagePattern!.dayOfWeek),
                      Icons.calendar_today,
                    ),
                    _buildPatternRow(
                      '日均记录',
                      '${_usagePattern!.avgRecordCount} 条',
                      Icons.analytics,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // 统计数据
          _buildStatsSection(),
          const SizedBox(height: 16),

          // 使用历史
          _buildRecentUsageSection(),
        ],
      ),
    );
  }

  Widget _buildPatternRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.outline),
          const SizedBox(width: 12),
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              value,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getTimeOfDayLabel(String timeOfDay) {
    const labels = {
      'morning': '🌅 早晨 (6:00-12:00)',
      'afternoon': '☀️ 下午 (12:00-18:00)',
      'evening': '🌆 傍晚 (18:00-22:00)',
      'night': '🌙 夜间 (22:00-6:00)',
    };
    return labels[timeOfDay] ?? timeOfDay;
  }

  String _getDayOfWeekLabel(String dayOfWeek) {
    const labels = {
      'weekday': '📅 工作日',
      'weekend': '🎉 周末',
      '周一': '周一',
      '周二': '周二',
      '周三': '周三',
      '周四': '周四',
      '周五': '周五',
      '周六': '周六',
      '周日': '周日',
    };
    return labels[dayOfWeek] ?? dayOfWeek;
  }

  Widget _buildStatsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '模板统计',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    '总模板',
                    '${_allTemplates.length}',
                    Icons.folder,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    '总使用',
                    '${_allTemplates.fold(0, (sum, t) => sum + ((t['use_count'] as int?) ?? 0))}',
                    Icons.history,
                  ),
                ),
              ],
            ),
          ],
        ),
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

  Widget _buildRecentUsageSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.history,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  '最近使用',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 8),
            FutureBuilder<List<TemplateUsage>>(
              future: ref.read(smartTemplateServiceProvider).getUsageHistory(limit: 5),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final usages = snapshot.data!;
                if (usages.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('暂无使用记录'),
                  );
                }

                return Column(
                  children: usages.map((usage) {
                    return ListTile(
                      dense: true,
                      leading: const Icon(Icons.check_circle_outline),
                      title: Text(usage.templateName),
                      subtitle: Text(_formatDateTime(usage.usedAt)),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 1) return '刚刚';
    if (diff.inMinutes < 60) return '${diff.inMinutes} 分钟前';
    if (diff.inHours < 24) return '${diff.inHours} 小时前';
    if (diff.inDays < 7) return '${diff.inDays} 天前';

    return '${dateTime.month}/${dateTime.day}';
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}