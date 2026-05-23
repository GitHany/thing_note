import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/reading_list/data/reading_repository.dart';
import 'package:thing_note/features/reading_list/domain/reading_item.dart';

class ReadingListScreen extends ConsumerStatefulWidget {
  const ReadingListScreen({super.key});

  @override
  ConsumerState<ReadingListScreen> createState() => _ReadingListScreenState();
}

class _ReadingListScreenState extends ConsumerState<ReadingListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('阅读清单'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '书籍', icon: Icon(Icons.book)),
            Tab(text: '文章', icon: Icon(Icons.article)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildBooksTab(),
          _buildArticlesTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_tabController.index == 0) {
            _showAddBookDialog(context);
          } else {
            _showAddArticleDialog(context);
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBooksTab() {
    final booksAsync = ref.watch(booksProvider);

    return booksAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('错误: $e')),
      data: (books) {
        if (books.isEmpty) {
          return _buildEmptyState('书籍', Icons.book, () => _showAddBookDialog(context));
        }

        final reading = books.where((b) => b.status == 'reading').toList();
        final finished = books.where((b) => b.status == 'finished').toList();

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (reading.isNotEmpty) ...[
              _buildSectionHeader('阅读中 (${reading.length})'),
              ...reading.map((b) => _BookCard(book: b)),
              const SizedBox(height: 16),
            ],
            if (finished.isNotEmpty) ...[
              _buildSectionHeader('已完成 (${finished.length})'),
              ...finished.map((b) => _BookCard(book: b)),
            ],
          ],
        );
      },
    );
  }

  Widget _buildArticlesTab() {
    final articlesAsync = ref.watch(articlesProvider);

    return articlesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('错误: $e')),
      data: (articles) {
        if (articles.isEmpty) {
          return _buildEmptyState('文章', Icons.article, () => _showAddArticleDialog(context));
        }

        final unread = articles.where((a) => a.status == 'unread').toList();
        final reading = articles.where((a) => a.status == 'reading').toList();
        final done = articles.where((a) => a.status == 'done').toList();

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (unread.isNotEmpty) ...[
              _buildSectionHeader('未读 (${unread.length})'),
              ...unread.map((a) => _ArticleCard(article: a)),
              const SizedBox(height: 16),
            ],
            if (reading.isNotEmpty) ...[
              _buildSectionHeader('阅读中 (${reading.length})'),
              ...reading.map((a) => _ArticleCard(article: a)),
              const SizedBox(height: 16),
            ],
            if (done.isNotEmpty) ...[
              _buildSectionHeader('已完成 (${done.length})'),
              ...done.map((a) => _ArticleCard(article: a)),
            ],
          ],
        );
      },
    );
  }

  Widget _buildEmptyState(String type, IconData icon, VoidCallback onAdd) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text('暂无$type', style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: Text('添加$type'),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey),
      ),
    );
  }

  void _showAddBookDialog(BuildContext context) {
    final titleController = TextEditingController();
    final authorController = TextEditingController();
    final pagesController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('添加书籍'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: '书名'),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: authorController,
              decoration: const InputDecoration(labelText: '作者（可选）'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: pagesController,
              decoration: const InputDecoration(labelText: '总页数（可选）'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              if (titleController.text.trim().isNotEmpty) {
                final book = Book(
                  title: titleController.text.trim(),
                  author: authorController.text.trim().isEmpty ? null : authorController.text.trim(),
                  totalPages: int.tryParse(pagesController.text),
                  startedAt: DateTime.now().toIso8601String().substring(0, 10),
                  createdAt: DateTime.now(),
                );
                ref.read(booksProvider.notifier).addBook(book);
                Navigator.pop(context);
              }
            },
            child: const Text('添加'),
          ),
        ],
      ),
    );
  }

  void _showAddArticleDialog(BuildContext context) {
    final titleController = TextEditingController();
    final urlController = TextEditingController();
    final sourceController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('添加文章'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: '标题'),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: urlController,
              decoration: const InputDecoration(labelText: '链接（可选）'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: sourceController,
              decoration: const InputDecoration(labelText: '来源（可选）'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              if (titleController.text.trim().isNotEmpty) {
                final article = Article(
                  title: titleController.text.trim(),
                  url: urlController.text.trim().isEmpty ? null : urlController.text.trim(),
                  source: sourceController.text.trim().isEmpty ? null : sourceController.text.trim(),
                  createdAt: DateTime.now(),
                );
                ref.read(articlesProvider.notifier).addArticle(article);
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

class _BookCard extends ConsumerWidget {
  final Book book;

  const _BookCard({required this.book});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showProgressDialog(context, ref),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.book, color: Colors.blue),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(book.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        if (book.author != null)
                          Text(book.author!, style: const TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'delete') {
                        ref.read(booksProvider.notifier).deleteBook(book.id!);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'delete', child: Text('删除')),
                    ],
                  ),
                ],
              ),
              if (book.totalPages != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: book.progressPercent / 100,
                          minHeight: 8,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('${book.progressPercent.toStringAsFixed(0)}%', style: const TextStyle(color: Colors.grey)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '第 ${book.currentPage} / ${book.totalPages} 页',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showProgressDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController(text: book.currentPage.toString());
    final pages = book.totalPages ?? 0;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('更新进度'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('当前页数: $pages 页'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(labelText: '当前看到第几页'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              final page = int.tryParse(controller.text);
              if (page != null) {
                ref.read(booksProvider.notifier).updateProgress(book.id!, page);
              }
              Navigator.pop(context);
            },
            child: const Text('更新'),
          ),
        ],
      ),
    );
  }
}

class _ArticleCard extends ConsumerWidget {
  final Article article;

  const _ArticleCard({required this.article});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(
          _getStatusIcon(article.status),
          color: _getStatusColor(article.status),
        ),
        title: Text(article.title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (article.source != null) Text(article.source!, style: const TextStyle(fontSize: 12)),
            Text(_getStatusText(article.status), style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'reading') {
              ref.read(articlesProvider.notifier).updateArticle(article.copyWith(status: 'reading'));
            } else if (value == 'done') {
              ref.read(articlesProvider.notifier).updateArticle(article.copyWith(status: 'done'));
            } else if (value == 'delete') {
              ref.read(articlesProvider.notifier).deleteArticle(article.id!);
            }
          },
          itemBuilder: (context) => [
            if (article.status != 'reading')
              const PopupMenuItem(value: 'reading', child: Text('标记阅读中')),
            if (article.status != 'done')
              const PopupMenuItem(value: 'done', child: Text('标记已完成')),
            const PopupMenuItem(value: 'delete', child: Text('删除')),
          ],
        ),
      ),
    );
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'reading': return Icons.auto_stories;
      case 'done': return Icons.check_circle;
      default: return Icons.article;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'reading': return Colors.blue;
      case 'done': return Colors.green;
      default: return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'reading': return '阅读中';
      case 'done': return '已完成';
      default: return '未读';
    }
  }
}