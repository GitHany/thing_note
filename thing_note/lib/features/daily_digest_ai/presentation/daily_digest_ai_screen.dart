import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/daily_digest_ai_service.dart';
import '../domain/daily_digest_ai.dart';

final dailyDigestAIProvider = Provider((ref) => ref.watch(dailyDigestAIServiceProvider));

class DailyDigestAIScreen extends ConsumerStatefulWidget {
  const DailyDigestAIScreen({super.key});

  @override
  ConsumerState<DailyDigestAIScreen> createState() => _DailyDigestAIScreenState();
}

class _DailyDigestAIScreenState extends ConsumerState<DailyDigestAIScreen> {
  String _selectedDate = DateTime.now().toIso8601String().split('T')[0];
  DailyDigestAI? _currentDigest;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadDigest();
  }

  Future<void> _loadDigest() async {
    setState(() => _isLoading = true);
    try {
      final service = ref.read(dailyDigestAIProvider);
      final digest = await service.getDailyDigest(_selectedDate);
      setState(() => _currentDigest = digest);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _generateDigest() async {
    setState(() => _isLoading = true);
    try {
      final service = ref.read(dailyDigestAIProvider);
      final digest = await service.generateDailyDigest(_selectedDate);
      setState(() => _currentDigest = digest);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('智能每日摘要'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _generateDigest,
            tooltip: '重新生成摘要',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _currentDigest == null
              ? _buildEmptyState()
              : _buildDigestContent(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isLoading ? null : _generateDigest,
        icon: const Icon(Icons.auto_awesome),
        label: const Text('生成摘要'),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.summarize_outlined,
            size: 80,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            '暂无摘要',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            '点击下方按钮生成今日摘要',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _generateDigest,
            icon: const Icon(Icons.auto_awesome),
            label: const Text('生成摘要'),
          ),
        ],
      ),
    );
  }

  Widget _buildDigestContent() {
    final digest = _currentDigest!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 日期选择器
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      digest.date,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: DateTime.parse(_selectedDate),
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) {
                        setState(() {
                          _selectedDate = date.toIso8601String().split('T')[0];
                        });
                        _loadDigest();
                      }
                    },
                    child: const Text('选择日期'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 统计卡片
          Row(
            children: [
              Expanded(child: _buildStatCard('📝', '记录数', '${digest.recordCount}')),
              const SizedBox(width: 8),
              Expanded(child: _buildStatCard('⏱️', '总时长', '${digest.totalMinutes}分钟')),
              if (digest.streakDays != null) ...[
                const SizedBox(width: 8),
                Expanded(child: _buildStatCard('🔥', '连续', '${digest.streakDays}天')),
              ],
            ],
          ),
          const SizedBox(height: 16),

          // 摘要内容
          _buildSection('📋 摘要', digest.summary),
          
          // 高亮
          if (digest.highlights.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildSection('✨ 今日亮点', digest.highlights.join('\n')),
          ],

          // 模式识别
          if (digest.patterns.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildSection('🔍 行为模式', digest.patterns.join('\n')),
          ],

          // 建议
          if (digest.suggestions.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildSection('💡 智能建议', digest.suggestions.join('\n')),
          ],

          // 洞察
          if (digest.insight != null && digest.insight!.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildSection('🧠 AI 洞察', digest.insight!),
          ],

          // 周对比
          if (digest.weeklyComparison != null) ...[
            const SizedBox(height: 16),
            _buildSection('📊 周对比', digest.weeklyComparison!),
          ],

          // 顶部活动
          if (digest.topThingName != null) ...[
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                leading: const Icon(Icons.star, color: Colors.amber),
                title: const Text('最常做的事情'),
                subtitle: Text(digest.topThingName!),
              ),
            ),
          ],

          // 顶部标签
          if (digest.topTags.isNotEmpty) ...[
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('🏷️ 常用标签', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: digest.topTags.map((tag) => Chip(label: Text(tag))).toList(),
                    ),
                  ],
                ),
              ),
            ),
          ],

          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildStatCard(String emoji, String label, String value) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            Text(content, style: const TextStyle(height: 1.5)),
          ],
        ),
      ),
    );
  }
}