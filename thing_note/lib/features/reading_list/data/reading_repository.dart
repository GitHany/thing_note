import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/reading_list/domain/reading_item.dart';
import 'package:sqflite/sqflite.dart';
import 'package:thing_note/core/database/database_provider.dart';

final readingRepositoryProvider = Provider<ReadingRepository>((ref) {
  final dbAsync = ref.watch(databaseProvider);
  return ReadingRepository(dbAsync);
});

final booksProvider = StateNotifierProvider<BooksNotifier, AsyncValue<List<Book>>>((ref) {
  final repository = ref.watch(readingRepositoryProvider);
  return BooksNotifier(repository);
});

final articlesProvider = StateNotifierProvider<ArticlesNotifier, AsyncValue<List<Article>>>((ref) {
  final repository = ref.watch(readingRepositoryProvider);
  return ArticlesNotifier(repository);
});

class ReadingRepository {
  final AsyncValue<Database> _dbAsync;

  ReadingRepository(this._dbAsync);

  Future<Database> get _db async {
    final db = _dbAsync.value;
    if (db == null) throw Exception('Database not initialized');
    return db;
  }

  // Books
  Future<int> insertBook(Book book) async {
    final db = await _db;
    return db.insert('books', book.toMap());
  }

  Future<int> updateBook(Book book) async {
    final db = await _db;
    return db.update('books', book.toMap(), where: 'id = ?', whereArgs: [book.id]);
  }

  Future<int> deleteBook(int id) async {
    final db = await _db;
    return db.delete('books', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Book>> getAllBooks() async {
    final db = await _db;
    final maps = await db.query('books', orderBy: 'created_at DESC');
    return maps.map((m) => Book.fromMap(m)).toList();
  }

  Future<List<Book>> getBooksByStatus(String status) async {
    final db = await _db;
    final maps = await db.query(
      'books',
      where: 'status = ?',
      whereArgs: [status],
      orderBy: 'created_at DESC',
    );
    return maps.map((m) => Book.fromMap(m)).toList();
  }

  // Articles
  Future<int> insertArticle(Article article) async {
    final db = await _db;
    return db.insert('articles', article.toMap());
  }

  Future<int> updateArticle(Article article) async {
    final db = await _db;
    return db.update('articles', article.toMap(), where: 'id = ?', whereArgs: [article.id]);
  }

  Future<int> deleteArticle(int id) async {
    final db = await _db;
    return db.delete('articles', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Article>> getAllArticles() async {
    final db = await _db;
    final maps = await db.query('articles', orderBy: 'created_at DESC');
    return maps.map((m) => Article.fromMap(m)).toList();
  }

  Future<List<Article>> getArticlesByStatus(String status) async {
    final db = await _db;
    final maps = await db.query(
      'articles',
      where: 'status = ?',
      whereArgs: [status],
      orderBy: 'created_at DESC',
    );
    return maps.map((m) => Article.fromMap(m)).toList();
  }
}

class BooksNotifier extends StateNotifier<AsyncValue<List<Book>>> {
  final ReadingRepository _repository;

  BooksNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadBooks();
  }

  Future<void> loadBooks() async {
    state = const AsyncValue.loading();
    try {
      final books = await _repository.getAllBooks();
      state = AsyncValue.data(books);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addBook(Book book) async {
    try {
      await _repository.insertBook(book);
      await loadBooks();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateBook(Book book) async {
    try {
      await _repository.updateBook(book);
      await loadBooks();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteBook(int id) async {
    try {
      await _repository.deleteBook(id);
      await loadBooks();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateProgress(int id, int currentPage) async {
    final books = state.valueOrNull ?? [];
    final book = books.firstWhere((b) => b.id == id);
    final updated = book.copyWith(currentPage: currentPage);
    await updateBook(updated);
  }
}

class ArticlesNotifier extends StateNotifier<AsyncValue<List<Article>>> {
  final ReadingRepository _repository;

  ArticlesNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadArticles();
  }

  Future<void> loadArticles() async {
    state = const AsyncValue.loading();
    try {
      final articles = await _repository.getAllArticles();
      state = AsyncValue.data(articles);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addArticle(Article article) async {
    try {
      await _repository.insertArticle(article);
      await loadArticles();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateArticle(Article article) async {
    try {
      await _repository.updateArticle(article);
      await loadArticles();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteArticle(int id) async {
    try {
      await _repository.deleteArticle(id);
      await loadArticles();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}