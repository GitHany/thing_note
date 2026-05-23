import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/voice_structured_note/data/voice_note_service.dart';
import 'package:thing_note/features/voice_structured_note/domain/voice_note_models.dart';

class VoiceStructuredNoteScreen extends ConsumerStatefulWidget {
  const VoiceStructuredNoteScreen({super.key});

  @override
  ConsumerState<VoiceStructuredNoteScreen> createState() => _VoiceStructuredNoteScreenState();
}

class _VoiceStructuredNoteScreenState extends ConsumerState<VoiceStructuredNoteScreen> {
  bool _isRecording = false;
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  TemplateType _selectedTemplate = TemplateType.note;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notesAsync = ref.watch(voiceStructuredNotesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('语音结构化笔记'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _showSearchDialog(context),
            tooltip: '搜索',
          ),
        ],
      ),
      body: Column(
        children: [
          // 模板选择
          Container(
            padding: const EdgeInsets.all(12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: TemplateType.values.map((template) {
                  final isSelected = template == _selectedTemplate;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(template.label),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _selectedTemplate = template);
                        }
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          // 录音区域
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: _isRecording ? Colors.red.withOpacity( 0.1) : Colors.grey.withOpacity( 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _isRecording ? Colors.red : Colors.grey,
                width: 2,
              ),
            ),
            child: Column(
              children: [
                GestureDetector(
                  onTap: _toggleRecording,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: _isRecording ? Colors.red : Colors.blue,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _isRecording ? Icons.stop : Icons.mic,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _isRecording ? '录音中...' : '点击开始录音',
                  style: TextStyle(
                    fontSize: 16,
                    color: _isRecording ? Colors.red : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          // 内容输入
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _contentController,
              decoration: const InputDecoration(
                hintText: '或直接输入笔记内容...',
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
            ),
          ),
          const SizedBox(height: 12),
          // 生成按钮
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _contentController.text.isNotEmpty ? _structureText : null,
                icon: const Icon(Icons.auto_fix_high),
                label: const Text('结构化处理'),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Divider(),
          // 笔记列表
          Expanded(
            child: notesAsync.when(
              data: (notes) {
                if (notes.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.note_outlined, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('暂无笔记'),
                        SizedBox(height: 8),
                        Text(
                          '开始录音或输入内容创建笔记',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: notes.length,
                  itemBuilder: (context, index) {
                    final note = notes[index];
                    return _NoteCard(
                      note: note,
                      onTap: () => _showNoteDetail(context, note),
                      onDelete: () async {
                        final service = ref.read(voiceStructuredNoteServiceProvider);
                        await service.deleteNote(note.id!);
                        ref.invalidate(voiceStructuredNotesProvider);
                      },
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
  }

  void _toggleRecording() {
    setState(() {
      _isRecording = !_isRecording;
    });

    if (_isRecording) {
      // 模拟开始录音
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted && _isRecording) {
          setState(() {
            _isRecording = false;
            _contentController.text = '这是一段示例的语音转文字内容。包含了一些待办事项：需要完成报告，应该开会讨论，明日计划继续跟进。';
          });
        }
      });
    }
  }

  void _structureText() async {
    if (_contentController.text.isEmpty) return;

    final service = ref.read(voiceStructuredNoteServiceProvider);
    final keywords = service.extractKeywords(_contentController.text);
    final structuredContent = service.structureText(_contentController.text, _selectedTemplate);

    final note = VoiceStructuredNote(
      title: '笔记 ${DateTime.now().hour}:${DateTime.now().minute}',
      rawText: _contentController.text,
      structuredContent: structuredContent,
      keywords: keywords,
      templateType: _selectedTemplate.value,
    );

    await service.createNote(note);
    ref.invalidate(voiceStructuredNotesProvider);

    setState(() {
      _contentController.clear();
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('笔记已创建')),
      );
    }
  }

  void _showSearchDialog(BuildContext context) {
    final searchController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('搜索笔记'),
        content: TextField(
          controller: searchController,
          decoration: const InputDecoration(
            hintText: '输入关键词...',
            prefixIcon: Icon(Icons.search),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () async {
              if (searchController.text.isNotEmpty) {
                final service = ref.read(voiceStructuredNoteServiceProvider);
                final results = await service.searchNotes(searchController.text);
                if (!mounted) return;
                Navigator.pop(context);
                _showSearchResults(context, results);
              }
            },
            child: const Text('搜索'),
          ),
        ],
      ),
    );
  }

  void _showSearchResults(BuildContext context, List<VoiceStructuredNote> results) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Text('搜索结果 (${results.length})', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: results.isEmpty
                  ? const Center(child: Text('未找到相关笔记'))
                  : ListView.builder(
                      controller: scrollController,
                      itemCount: results.length,
                      itemBuilder: (context, index) {
                        final note = results[index];
                        return ListTile(
                          leading: const Icon(Icons.note),
                          title: Text(note.title),
                          subtitle: Text(
                            note.rawText.length > 50 ? '${note.rawText.substring(0, 50)}...' : note.rawText,
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            _showNoteDetail(context, note);
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _showNoteDetail(BuildContext context, VoiceStructuredNote note) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _NoteDetailScreen(note: note),
      ),
    );
  }
}

/// 笔记卡片
class _NoteCard extends StatelessWidget {
  final VoiceStructuredNote note;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _NoteCard({
    required this.note,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final template = TemplateType.fromValue(note.templateType);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity( 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      template.label,
                      style: const TextStyle(fontSize: 12, color: Colors.blue),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (note.linkedRecordId != null)
                    const Icon(Icons.link, size: 16, color: Colors.grey),
                  const Spacer(),
                  PopupMenuButton(
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'create_record',
                        child: Row(
                          children: [
                            Icon(Icons.add),
                            SizedBox(width: 8),
                            Text('转为记录'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline, color: Colors.red),
                            SizedBox(width: 8),
                            Text('删除', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                    onSelected: (value) {
                      if (value == 'delete') {
                        onDelete();
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                note.title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                note.rawText.length > 100 ? '${note.rawText.substring(0, 100)}...' : note.rawText,
                style: TextStyle(color: Colors.grey[600]),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (note.keywords.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: note.keywords.take(5).map((keyword) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity( 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(keyword, style: const TextStyle(fontSize: 10)),
                  )).toList(),
                ),
              ],
              const SizedBox(height: 8),
              Text(
                _formatDate(note.createdAt),
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}

/// 笔记详情页面
class _NoteDetailScreen extends ConsumerWidget {
  final VoiceStructuredNote note;

  const _NoteDetailScreen({required this.note});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sections = note.sections;
    final template = TemplateType.fromValue(note.templateType);

    return Scaffold(
      appBar: AppBar(
        title: Text(note.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.create),
            onPressed: () => _showEditDialog(context, ref),
            tooltip: '编辑',
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () => _createRecord(context, ref),
            tooltip: '转为记录',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 元信息
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity( 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  _MetaChip(icon: Icons.category, label: template.label),
                  const SizedBox(width: 12),
                  if (note.keywords.isNotEmpty)
                    Expanded(
                      child: Wrap(
                        spacing: 4,
                        children: note.keywords.map((k) => _KeywordChip(keyword: k)).toList(),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // 原始文本
            if (sections.isEmpty) ...[
              const Text(
                '原始文本',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(note.rawText),
                ),
              ),
            ] else ...[
              // 结构化内容
              const Text(
                '结构化内容',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...sections.map((section) => _SectionCard(section: section)),
            ],
          ],
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController(text: note.rawText);
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('编辑笔记'),
        content: TextField(
          controller: controller,
          maxLines: 10,
          decoration: const InputDecoration(
            hintText: '输入笔记内容...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                final service = ref.read(voiceStructuredNoteServiceProvider);
                await service.updateNote(note.copyWith(
                  title: '笔记 ${DateTime.now().hour}:${DateTime.now().minute}',
                  rawText: controller.text,
                  structuredContent: service.structureText(controller.text, TemplateType.fromValue(note.templateType)),
                ));
                ref.invalidate(voiceStructuredNotesProvider);
                Navigator.pop(dialogContext);
                Navigator.pop(context);
              }
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  void _createRecord(BuildContext context, WidgetRef ref) async {
    final service = ref.read(voiceStructuredNoteServiceProvider);
    final recordId = await service.createRecordFromNote(note);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('已转为记录 (ID: $recordId)')),
      );
    }
  }
}

/// 扩展方法
extension on VoiceStructuredNote {
  VoiceStructuredNote copyWith({
    int? id,
    String? title,
    String? rawText,
    String? structuredContent,
    List<String>? keywords,
    String? templateType,
    int? linkedRecordId,
    DateTime? createdAt,
  }) {
    return VoiceStructuredNote(
      id: id ?? this.id,
      title: title ?? this.title,
      rawText: rawText ?? this.rawText,
      structuredContent: structuredContent ?? this.structuredContent,
      keywords: keywords ?? this.keywords,
      templateType: templateType ?? this.templateType,
      linkedRecordId: linkedRecordId ?? this.linkedRecordId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// 元信息芯片
class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetaChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }
}

/// 关键词芯片
class _KeywordChip extends StatelessWidget {
  final String keyword;

  const _KeywordChip({required this.keyword});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity( 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(keyword, style: const TextStyle(fontSize: 10, color: Colors.blue)),
    );
  }
}

/// 分段卡片
class _SectionCard extends StatelessWidget {
  final StructuredSection section;

  const _SectionCard({required this.section});

  @override
  Widget build(BuildContext context) {
    final isHeading = section.type == 'heading';
    final isTodo = section.type == 'todo';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: isHeading ? Colors.blue.withOpacity( 0.1) : null,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isTodo)
              const Icon(Icons.check_circle_outline, color: Colors.green, size: 20)
            else if (isHeading)
              const Icon(Icons.title, color: Colors.blue, size: 20)
            else
              const Icon(Icons.text_fields, color: Colors.grey, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                section.content,
                style: TextStyle(
                  fontWeight: isHeading ? FontWeight.bold : null,
                  fontSize: isHeading ? 16 : 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}