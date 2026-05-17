import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

final databaseProvider = FutureProvider<Database>((ref) async {
  final dbPath = await getDatabasesPath();
  final path = join(dbPath, 'thing_note.db');

  return openDatabase(
    path,
    version: 4,
    onCreate: (db, version) async {
      await db.execute('''
        CREATE TABLE episode_records (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          occurred_at TEXT NOT NULL,
          duration_sec INTEGER NOT NULL DEFAULT 0,
          note TEXT NOT NULL DEFAULT '',
          photo_paths TEXT NOT NULL DEFAULT '[]',
          audio_paths TEXT NOT NULL DEFAULT '[]',
          audio_durations_sec TEXT NOT NULL DEFAULT '[]',
          thing_name_id INTEGER,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL
        )
      ''');

      await db.execute('''
        CREATE TABLE thing_names (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          remark TEXT,
          created_at TEXT NOT NULL
        )
      ''');

      await db.insert('thing_names', {
        'name': '默认',
        'remark': '未选择事件名称的记录将归类到此处',
        'created_at': DateTime.now().toIso8601String(),
      });
    },
    onUpgrade: (db, oldVersion, newVersion) async {
      if (oldVersion < 2) {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS thing_names (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            remark TEXT,
            created_at TEXT NOT NULL
          )
        ''');

        await db.insert('thing_names', {
          'name': '默认',
          'remark': '未选择事件名称的记录将归类到此处',
          'created_at': DateTime.now().toIso8601String(),
        });

        try {
          await db.execute(
              'ALTER TABLE episode_records ADD COLUMN thing_name_id INTEGER');
        } catch (_) {}
      }

      if (oldVersion < 3) {
        try {
          await db.execute(
              'ALTER TABLE episode_records ADD COLUMN photo_paths TEXT NOT NULL DEFAULT \'[]\'');
        } catch (_) {}
      }

      if (oldVersion < 4) {
        try {
          await db.execute(
              'ALTER TABLE episode_records ADD COLUMN audio_paths TEXT NOT NULL DEFAULT \'[]\'');
        } catch (_) {}

        try {
          await db.execute(
              'ALTER TABLE episode_records ADD COLUMN audio_durations_sec TEXT NOT NULL DEFAULT \'[]\'');
        } catch (_) {}

        try {
          final rows = await db.query('episode_records',
              columns: ['id', 'audio_path', 'audio_duration_sec']);

          for (final row in rows) {
            final id = row['id'];
            final audioPath = row['audio_path'];
            final audioDurationSec = row['audio_duration_sec'];

            final audioPaths =
                audioPath != null ? '["$audioPath"]' : '[]';
            final audioDurationsSec =
                audioDurationSec != null ? '[$audioDurationSec]' : '[]';

            await db.update(
              'episode_records',
              {
                'audio_paths': audioPaths,
                'audio_durations_sec': audioDurationsSec,
              },
              where: 'id = ?',
              whereArgs: [id],
            );
          }
        } catch (_) {}

        try {
          await db.execute(
              'ALTER TABLE episode_records DROP COLUMN audio_path');
        } catch (_) {}

        try {
          await db.execute(
              'ALTER TABLE episode_records DROP COLUMN audio_duration_sec');
        } catch (_) {}
      }
    },
  );
});
