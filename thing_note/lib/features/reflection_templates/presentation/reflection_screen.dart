import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/core/database/database_provider.dart';
import 'package:thing_note/features/reflection_templates/data/reflection_provider.dart';
import 'package:thing_note/features/reflection_templates/domain/reflection_models.dart';

class ReflectionScreen extends ConsumerStatefulWidget {
  const ReflectionScreen({super.key});

  @override
  ConsumerState<ReflectionScreen> createState() => _ReflectionScreenState();
}

class _ReflectionScreenState extends ConsumerState<ReflectionScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Map<String, TextEditingController> _controllers = {};
  int? _selectedTemplateId;
  final Map<String, dynamic> _answers = {};
  int _moodLevel = 3;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _controllers.forEach((_, controller) => controller.dispose());
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final templatesAsync = ref.watch(reflectionTemplatesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('定期回顾'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '今日回顾'),
            Tab(text: '历史记录'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Reflection Tab
          templatesAsync.when(
            data: (templates) => _buildReflectionForm(templates),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
          ),
          // History Tab
          _buildHistoryTab(),
        ],
      ),
    );
  }

  Widget _buildReflectionForm(List<ReflectionTemplate> templates) {
    final dailyTemplates = templates.where((t) => t.type == 'daily').toList();
    
    if (dailyTemplates.isEmpty) {
      return const Center(child: Text('没有可用的模板'));
    }

    // Auto-select first daily template
    _selectedTemplateId ??= dailyTemplates.first.id;
    final selectedTemplate = dailyTemplates.firstWhere(
      (t) => t.id == _selectedTemplateId,
      orElse: () => dailyTemplates.first,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Template Selector
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    selectedTemplate.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getTypeLabel(selectedTemplate.type),
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Questions
          ...selectedTemplate.questions.map((q) => _buildQuestionWidget(q)),
          
          const SizedBox(height: 16),
          
          // Mood Selector
          _buildMoodSelector(),
          
          const SizedBox(height: 16),
          
          // Overall Note
          _buildOverallNote(),
          
          const SizedBox(height: 24),
          
          // Save Button
          Center(
            child: FilledButton.icon(
              onPressed: () => _saveReflection(selectedTemplate),
              icon: const Icon(Icons.save),
              label: const Text('保存回顾'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionWidget(ReflectionQuestion question) {
    _controllers.putIfAbsent(
      question.id,
      () => TextEditingController(text: _answers[question.id]?.toString() ?? ''),
    );

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
                    question.question,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                if (!question.isRequired)
                  const Text(
                    '选填',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
              ],
            ),
            if (question.hint != null) ...[
              const SizedBox(height: 4),
              Text(
                question.hint!,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
            const SizedBox(height: 12),
            if (question.type == 'rating')
              _buildRatingInput(question.id)
            else if (question.type == 'choice' && question.options != null)
              _buildChoiceInput(question.id, question.options!)
            else
              TextField(
                controller: _controllers[question.id],
                decoration: const InputDecoration(
                  hintText: '输入你的回答...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                onChanged: (value) => _answers[question.id] = value,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingInput(String questionId) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: List.generate(5, (i) {
        final rating = i + 1;
        return GestureDetector(
          onTap: () {
            setState(() {
              _answers[questionId] = rating;
            });
          },
          child: Icon(
            rating <= (_answers[questionId] as int? ?? 0)
                ? Icons.star
                : Icons.star_border,
            size: 36,
            color: Colors.amber,
          ),
        );
      }),
    );
  }

  Widget _buildChoiceInput(String questionId, List<String> options) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((option) {
        final isSelected = _answers[questionId] == option;
        return ChoiceChip(
          label: Text(option),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              _answers[questionId] = selected ? option : null;
            });
          },
        );
      }).toList(),
    );
  }

  Widget _buildMoodSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '今日心情',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(5, (i) {
                final level = i + 1;
                return GestureDetector(
                  onTap: () => setState(() => _moodLevel = level),
                  child: Column(
                    children: [
                      Icon(
                        _getMoodIcon(level),
                        size: 32,
                        color: level == _moodLevel
                            ? _getMoodColor(level)
                            : Colors.grey,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getMoodLabel(level),
                        style: TextStyle(
                          fontSize: 12,
                          color: level == _moodLevel
                              ? _getMoodColor(level)
                              : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverallNote() {
    _controllers.putIfAbsent('overall', () => TextEditingController());
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '总体备注',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _controllers['overall'],
              decoration: const InputDecoration(
                hintText: '写下今天回顾的总体感受...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  IconData _getMoodIcon(int level) {
    switch (level) {
      case 1: return Icons.sentiment_very_dissatisfied;
      case 2: return Icons.sentiment_dissatisfied;
      case 3: return Icons.sentiment_neutral;
      case 4: return Icons.sentiment_satisfied;
      case 5: return Icons.sentiment_very_satisfied;
      default: return Icons.sentiment_neutral;
    }
  }

  Color _getMoodColor(int level) {
    switch (level) {
      case 1: return Colors.red;
      case 2: return Colors.orange;
      case 3: return Colors.yellow.shade700;
      case 4: return Colors.lightGreen;
      case 5: return Colors.green;
      default: return Colors.grey;
    }
  }

  String _getMoodLabel(int level) {
    switch (level) {
      case 1: return '很差';
      case 2: return '较差';
      case 3: return '一般';
      case 4: return '不错';
      case 5: return '很棒';
      default: return '';
    }
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case 'daily': return '每日回顾';
      case 'weekly': return '每周回顾';
      case 'monthly': return '月度回顾';
      case 'quarterly': return '季度回顾';
      default: return type;
    }
  }

  Future<void> _saveReflection(ReflectionTemplate template) async {
    final db = await ref.read(databaseProvider.future);
    final today = DateTime.now().toIso8601String().substring(0, 10);
    
    final entry = ReflectionEntry(
      templateId: template.id!,
      templateName: template.name,
      type: template.type,
      date: today,
      answers: _answers,
      moodLevel: _moodLevel,
      overallNote: _controllers['overall']?.text,
    );
    
    await db.insert('reflection_entries', {
      'template_id': entry.templateId,
      'template_name': entry.templateName,
      'type': entry.type,
      'date': entry.date,
      'answers': jsonEncode(entry.answers),
      'overall_note': entry.overallNote,
      'mood_level': entry.moodLevel,
      'created_at': DateTime.now().toIso8601String(),
    });
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('回顾已保存')),
      );
      ref.invalidate(recentReflectionEntriesProvider);
    }
  }

  Widget _buildHistoryTab() {
    final entriesAsync = ref.watch(recentReflectionEntriesProvider);
    
    return entriesAsync.when(
      data: (entries) {
        if (entries.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('暂无历史回顾记录', style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: entries.length,
          itemBuilder: (context, index) {
            final entry = entries[index];
            final date = DateTime.parse(entry.date);
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  child: Text('${entry.moodLevel ?? 3}'),
                ),
                title: Text(entry.templateName),
                subtitle: Text(
                  '${date.year}/${date.month}/${date.day}',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showEntryDetail(entry),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }

  void _showEntryDetail(ReflectionEntry entry) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) {
          final date = DateTime.parse(entry.date);
          return Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      entry.templateName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${date.year}/${date.month}/${date.day}',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
                const Divider(),
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    children: [
                      if (entry.moodLevel != null)
                        _buildDetailRow(
                          '心情',
                          '${_getMoodLabel(entry.moodLevel!)} (${entry.moodLevel}/5)',
                        ),
                      if (entry.overallNote != null && entry.overallNote!.isNotEmpty)
                        _buildDetailRow('备注', entry.overallNote!),
                      if (entry.answers.isNotEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            '回答详情',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ...entry.answers.entries.map((e) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Text('${e.key}: ${e.value}'),
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(color: Colors.grey),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}