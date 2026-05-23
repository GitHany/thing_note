import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/reading_session.dart';
import '../data/reading_tracker_repository.dart';

final readingProvider = StateNotifierProvider<ReadingNotifier, ReadingState>((ref) {
  return ReadingNotifier(ref.watch(readingTrackerRepositoryProvider));
});

class ReadingState {
  final List<ReadingSession> sessions;
  final bool isLoading;
  final String? error;

  ReadingState({
    this.sessions = const [],
    this.isLoading = false,
    this.error,
  });

  ReadingState copyWith({
    List<ReadingSession>? sessions,
    bool? isLoading,
    String? error,
  }) {
    return ReadingState(
      sessions: sessions ?? this.sessions,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class ReadingNotifier extends StateNotifier<ReadingState> {
  final ReadingTrackerRepository _repository;

  ReadingNotifier(this._repository) : super(ReadingState()) {
    loadSessions();
  }

  Future<void> loadSessions() async {
    state = state.copyWith(isLoading: true);
    try {
      final sessions = await _repository.getAllSessions();
      state = state.copyWith(sessions: sessions, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<void> addSession(ReadingSession session) async {
    try {
      await _repository.insertSession(session);
      await loadSessions();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> deleteSession(int id) async {
    try {
      await _repository.deleteSession(id);
      await loadSessions();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}

final readingStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final repo = ref.watch(readingTrackerRepositoryProvider);
  return await repo.getReadingStats();
});

final readingByBookProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final repo = ref.watch(readingTrackerRepositoryProvider);
  return await repo.getReadingByBook();
});

class ReadingTrackerScreen extends ConsumerStatefulWidget {
  const ReadingTrackerScreen({super.key});

  @override
  ConsumerState<ReadingTrackerScreen> createState() => _ReadingTrackerScreenState();
}

class _ReadingTrackerScreenState extends ConsumerState<ReadingTrackerScreen> {
  final _titleController = TextEditingController();
  final _authorController = TextEditingController();
  final _pagesController = TextEditingController();
  final _durationController = TextEditingController();
  final _noteController = TextEditingController();
  final String _readingType = 'book';

  @override
  Widget build(BuildContext context) {
    final readingState = ref.watch(readingProvider);
    final statsAsync = ref.watch(readingStatsProvider);
    final booksAsync = ref.watch(readingByBookProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reading Tracker'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: readingState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => ref.read(readingProvider.notifier).loadSessions(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Stats Card
                    statsAsync.when(
                      data: (stats) => _buildStatsCard(stats),
                      loading: () => const Card(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                      ),
                      error: (e, _) => Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text('Error: $e'),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Book List
                    booksAsync.when(
                      data: (books) => books.isEmpty 
                          ? const SizedBox.shrink()
                          : _buildBookList(books),
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (e, _) => Text('Error: $e'),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Add Session Form
                    _buildAddSessionForm(),
                    
                    const SizedBox(height: 16),
                    
                    // Recent Sessions
                    Text(
                      'Recent Sessions',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    if (readingState.sessions.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Text('No reading sessions yet'),
                        ),
                      )
                    else
                      ...readingState.sessions.take(10).map((s) => _buildSessionItem(s)),
                  ],
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddSessionDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildStatsCard(Map<String, dynamic> stats) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem('Sessions', '${stats['total_sessions'] ?? 0}'),
            _buildStatItem('Minutes', '${stats['total_minutes'] ?? 0}'),
            _buildStatItem('Pages', '${stats['total_pages'] ?? 0}'),
            _buildStatItem('Avg', '${(stats['avg_duration'] as num?)?.toInt() ?? 0}m'),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(color: Colors.grey[600], fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildBookList(List<Map<String, dynamic>> books) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Books',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        ...books.map((book) => ListTile(
          leading: const Icon(Icons.book),
          title: Text(book['book_title'] as String),
          subtitle: Text(
            '${book['total_pages']} pages - ${book['sessions']} sessions',
          ),
          trailing: Text('${book['total_minutes']} min'),
        )),
      ],
    );
  }

  Widget _buildAddSessionForm() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Log Reading Session',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Book Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _authorController,
              decoration: const InputDecoration(
                labelText: 'Author (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _pagesController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Pages Read',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _durationController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Minutes',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _noteController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Note (optional)',
                border: OutlineInputBorder(),
                hintText: 'Add your reading notes here...',
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _logSession,
                child: const Text('Log Session'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionItem(ReadingSession session) {
    return Dismissible(
      key: Key('session_${session.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) {
        if (session.id != null) {
          ref.read(readingProvider.notifier).deleteSession(session.id!);
        }
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          leading: const Icon(Icons.auto_stories),
          title: Text(session.bookTitle),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${session.pagesRead} pages - ${session.durationMinutes} min',
              ),
              if (session.note != null && session.note!.isNotEmpty)
                Text(
                  session.note!,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
          trailing: Text(_formatDate(session.sessionDate)),
          isThreeLine: session.note != null && session.note!.isNotEmpty,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}';
  }

  void _logSession() {
    if (_titleController.text.isEmpty) return;
    
    final session = ReadingSession(
      bookTitle: _titleController.text,
      bookAuthor: _authorController.text.isNotEmpty ? _authorController.text : null,
      pagesRead: int.tryParse(_pagesController.text) ?? 0,
      durationMinutes: int.tryParse(_durationController.text) ?? 0,
      sessionDate: DateTime.now(),
      readingType: _readingType,
      note: _noteController.text.isNotEmpty ? _noteController.text : null,
    );
    
    ref.read(readingProvider.notifier).addSession(session);
    
    _titleController.clear();
    _authorController.clear();
    _pagesController.clear();
    _durationController.clear();
    _noteController.clear();
  }

  void _showAddSessionDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: _buildAddSessionForm(),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    _pagesController.dispose();
    _durationController.dispose();
    _noteController.dispose();
    super.dispose();
  }
}
