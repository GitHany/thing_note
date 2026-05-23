import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/idea_capture/data/idea_capture_repository.dart';
import 'package:thing_note/features/idea_capture/domain/idea_capture.dart';

final ideaCaptureRepoProvider = Provider((ref) => IdeaCaptureRepository(ref));

class IdeaCaptureScreen extends ConsumerStatefulWidget {
  const IdeaCaptureScreen({super.key});

  @override
  ConsumerState<IdeaCaptureScreen> createState() => _IdeaCaptureScreenState();
}

class _IdeaCaptureScreenState extends ConsumerState<IdeaCaptureScreen> {
  List<IdeaCapture> _ideas = [];
  bool _isLoading = true;
  bool _showConverted = false;

  @override
  void initState() {
    super.initState();
    _loadIdeas();
  }

  Future<void> _loadIdeas() async {
    setState(() => _isLoading = true);
    final repo = ref.read(ideaCaptureRepoProvider);
    _ideas = _showConverted
        ? await repo.getAllIdeas()
        : await repo.getUnconvertedIdeas();
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('灵感捕捉'),
        actions: [
          IconButton(
            icon: Icon(_showConverted ? Icons.visibility_off : Icons.visibility),
            tooltip: _showConverted ? '隐藏已转换' : '显示全部',
            onPressed: () {
              setState(() => _showConverted = !_showConverted);
              _loadIdeas();
            },
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddDialog,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _ideas.isEmpty
              ? _buildEmptyState()
              : _buildIdeaList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.lightbulb_outline, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('还没有灵感', style: TextStyle(fontSize: 18)),
          const SizedBox(height: 8),
          const Text('捕捉你的灵感，稍后转化为记录'),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _showAddDialog,
            icon: const Icon(Icons.add),
            label: const Text('记录灵感'),
          ),
        ],
      ),
    );
  }

  Widget _buildIdeaList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _ideas.length,
      itemBuilder: (context, index) {
        final idea = _ideas[index];
        return _IdeaCard(
          idea: idea,
          onConvert: () => _showConvertDialog(idea),
          onDelete: () => _deleteIdea(idea.id!),
        );
      },
    );
  }

  void _showAddDialog() {
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    String category = '创意';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('记录灵感'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: '灵感标题'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: contentController,
                  decoration: const InputDecoration(labelText: '详细内容（可选）'),
                  maxLines: 4,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: category,
                  decoration: const InputDecoration(labelText: '分类'),
                  items: const [
                    DropdownMenuItem(value: '创意', child: Text('💡 创意')),
                    DropdownMenuItem(value: '工作', child: Text('💼 工作')),
                    DropdownMenuItem(value: '学习', child: Text('📚 学习')),
                    DropdownMenuItem(value: '生活', child: Text('🏠 生活')),
                    DropdownMenuItem(value: '其他', child: Text('📝 其他')),
                  ],
                  onChanged: (v) => setDialogState(() => category = v!),
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
                if (titleController.text.trim().isEmpty) return;
                final repo = ref.read(ideaCaptureRepoProvider);
                await repo.insertIdea(IdeaCapture(
                  title: titleController.text.trim(),
                  content: contentController.text.trim().isEmpty ? null : contentController.text.trim(),
                  category: category,
                  createdAt: DateTime.now(),
                ));
                if (!ctx.mounted) return;
                Navigator.pop(ctx);
                _loadIdeas();
              },
              child: const Text('保存'),
            ),
          ],
        ),
      ),
    );
  }

  void _showConvertDialog(IdeaCapture idea) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('转换灵感'),
        content: Text('将 "${idea.title}" 转换为记录？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () async {
              final repo = ref.read(ideaCaptureRepoProvider);
              // In production, would create actual record first
              await repo.markAsConverted(idea.id!, 'record', 0);
              if (!ctx.mounted) return;
              Navigator.pop(ctx);
              _loadIdeas();
            },
            child: const Text('转换'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteIdea(int id) async {
    final repo = ref.read(ideaCaptureRepoProvider);
    await repo.deleteIdea(id);
    _loadIdeas();
  }
}

class _IdeaCard extends StatelessWidget {
  final IdeaCapture idea;
  final VoidCallback onConvert;
  final VoidCallback onDelete;

  const _IdeaCard({
    required this.idea,
    required this.onConvert,
    required this.onDelete,
  });

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
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
                    idea.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (idea.isConverted)
                  const Chip(
                    label: Text('已转换'),
                    backgroundColor: Colors.green,
                  ),
              ],
            ),
            if (idea.content != null) ...[
              const SizedBox(height: 8),
              Text(idea.content!),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                if (idea.category != null)
                  Chip(
                    label: Text(idea.category!),
                    avatar: const Icon(Icons.label, size: 16),
                  ),
                const Spacer(),
                Text(
                  _formatDate(idea.createdAt),
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
            if (!idea.isConverted) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: onConvert,
                    icon: const Icon(Icons.transform, size: 16),
                    label: const Text('转换为记录'),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20),
                    onPressed: onDelete,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}