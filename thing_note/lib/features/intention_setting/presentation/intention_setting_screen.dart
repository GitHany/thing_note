import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/intention_setting/data/intention_setting_provider.dart';
import 'package:thing_note/features/intention_setting/domain/intention_setting.dart';

class IntentionSettingScreen extends ConsumerStatefulWidget {
  const IntentionSettingScreen({super.key});

  @override
  ConsumerState<IntentionSettingScreen> createState() => _IntentionSettingScreenState();
}

class _IntentionSettingScreenState extends ConsumerState<IntentionSettingScreen> {
  final _intentionController = TextEditingController();
  final _affirmationController = TextEditingController();
  List<String> _focusAreas = [];
  int _energyLevel = 3;

  @override
  void dispose() {
    _intentionController.dispose();
    _affirmationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final intentionAsync = ref.watch(todayIntentionProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('意图设定'),
      ),
      body: intentionAsync.when(
        data: (intention) {
          if (intention != null && _intentionController.text.isEmpty) {
            _loadIntention(intention);
          }
          return _buildForm();
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  void _loadIntention(Intention intention) {
    _intentionController.text = intention.intention;
    _affirmationController.text = intention.affirmation ?? '';
    _focusAreas = List.from(intention.focusAreas);
    _energyLevel = intention.energyLevel;
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Center(
            child: Column(
              children: [
                Icon(Icons.auto_awesome, size: 64, color: Colors.purple.shade300),
                const SizedBox(height: 8),
                Text(
                  '设定今日意图',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  '清晰的目标是成功的一半',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Intention
          _buildSection(
            '今日意图',
            '我想要...',
            TextField(
              controller: _intentionController,
              decoration: const InputDecoration(
                hintText: '例如：专注完成重要任务',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ),
          const SizedBox(height: 16),

          // Affirmation
          _buildSection(
            '自我肯定',
            '我相信...',
            TextField(
              controller: _affirmationController,
              decoration: const InputDecoration(
                hintText: '例如：我有能力完成目标',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Focus Areas
          _buildSection(
            '聚焦领域',
            '今天重点关注什么？',
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildFocusChip('工作', Icons.work),
                _buildFocusChip('学习', Icons.school),
                _buildFocusChip('健康', Icons.fitness_center),
                _buildFocusChip('人际', Icons.people),
                _buildFocusChip('创意', Icons.lightbulb),
                _buildFocusChip('休息', Icons.self_improvement),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Energy Level
          _buildSection(
            '能量状态',
            '你现在的能量如何？',
            Row(
              children: [
                const Text('低'),
                Expanded(
                  child: Slider(
                    value: _energyLevel.toDouble(),
                    min: 1,
                    max: 5,
                    divisions: 4,
                    onChanged: (value) => setState(() => _energyLevel = value.toInt()),
                  ),
                ),
                const Text('高'),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Templates
          Text(
            '使用模板',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 100,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: defaultIntentionTemplates.map((template) {
                return GestureDetector(
                  onTap: () => _applyTemplate(template),
                  child: Container(
                    width: 120,
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.purple.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          template.category,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          template.intentions.first,
                          style: const TextStyle(fontSize: 10),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 24),

          // Save Button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: _saveIntention,
              icon: const Icon(Icons.check),
              label: const Text('设定意图'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, String subtitle, Widget content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(subtitle, style: TextStyle(color: Colors.grey.shade600)),
        const SizedBox(height: 8),
        content,
      ],
    );
  }

  Widget _buildFocusChip(String label, IconData icon) {
    final isSelected = _focusAreas.contains(label);
    return FilterChip(
      avatar: Icon(icon, size: 16),
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          if (selected) {
            _focusAreas.add(label);
          } else {
            _focusAreas.remove(label);
          }
        });
      },
    );
  }

  void _applyTemplate(IntentionTemplate template) {
    setState(() {
      _intentionController.text = template.intentions.first;
      if (template.affirmations.isNotEmpty) {
        _affirmationController.text = template.affirmations.first;
      }
    });
  }

  void _saveIntention() {
    if (_intentionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入今日意图')),
      );
      return;
    }

    final intention = Intention(
      date: DateTime.now(),
      intention: _intentionController.text,
      affirmation: _affirmationController.text.isEmpty ? null : _affirmationController.text,
      focusAreas: _focusAreas,
      energyLevel: _energyLevel,
      createdAt: DateTime.now(),
    );

    ref.read(saveIntentionProvider).save(intention);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('意图已设定，祝你今天顺利！')),
    );
  }
}