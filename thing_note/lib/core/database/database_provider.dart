import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

final databaseProvider = FutureProvider<Database>((ref) async {
  final dbPath = await getDatabasesPath();
  final path = join(dbPath, 'thing_note.db');

  return openDatabase(
    path,
    version: 11,
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
          annotations TEXT,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          has_reminder INTEGER NOT NULL DEFAULT 0,
          latitude REAL,
          longitude REAL,
          address TEXT,
          video_paths TEXT NOT NULL DEFAULT '[]',
          document_paths TEXT NOT NULL DEFAULT '[]'
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

      await db.execute('''
        CREATE TABLE reminders (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          record_id INTEGER NOT NULL,
          remind_at TEXT NOT NULL,
          is_triggered INTEGER NOT NULL DEFAULT 0,
          calendar_event_id TEXT,
          created_at TEXT NOT NULL,
          FOREIGN KEY (record_id) REFERENCES episode_records(id) ON DELETE CASCADE
        )
      ''');
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
        } catch (e) {
          print('Schema upgrade v1->v2 failed: $e');
        }
      }

      if (oldVersion < 3) {
        try {
          await db.execute(
              'ALTER TABLE episode_records ADD COLUMN photo_paths TEXT NOT NULL DEFAULT \'[]\'');
        } catch (e) {
          print('Schema upgrade v2->v3 failed: $e');
        }
      }

      if (oldVersion < 4) {
        try {
          await db.execute(
              'ALTER TABLE episode_records ADD COLUMN audio_paths TEXT NOT NULL DEFAULT \'[]\'');
        } catch (_) {}

        try {
          await db.execute(
              'ALTER TABLE episode_records ADD COLUMN audio_durations_sec TEXT NOT NULL DEFAULT \'[]\'');
        } catch (e) {
          print('Schema upgrade v3->v4 audio_durations_sec failed: $e');
        }

        try {
          final rows = await db.query('episode_records',
              columns: ['id', 'audio_path', 'audio_duration_sec']);

          for (final row in rows) {
            final id = row['id'];
            final audioPath = row['audio_path'] as String?;
            final audioDurationSec = row['audio_duration_sec'] as int?;

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
        } catch (e) {
          print('Schema upgrade v3->v4 audio migration failed: $e');
        }

        try {
          await db.execute(
              'ALTER TABLE episode_records DROP COLUMN audio_path');
        } catch (e) {
          print('Schema upgrade v3->v4 DROP audio_path failed: $e');
        }

        try {
          await db.execute(
              'ALTER TABLE episode_records DROP COLUMN audio_duration_sec');
        } catch (e) {
          print('Schema upgrade v3->v4 DROP audio_duration_sec failed: $e');
        }
      }

      if (oldVersion < 5) {
        try {
          await db.execute(
              'ALTER TABLE episode_records ADD COLUMN annotations TEXT');
        } catch (e) {
          print('Schema upgrade v4->v5 failed: $e');
        }
      }

      if (oldVersion < 6) {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS reminders (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            record_id INTEGER NOT NULL,
            remind_at TEXT NOT NULL,
            is_triggered INTEGER NOT NULL DEFAULT 0,
            created_at TEXT NOT NULL,
            FOREIGN KEY (record_id) REFERENCES episode_records(id) ON DELETE CASCADE
          )
        ''');
      }

      if (oldVersion < 7) {
        try {
          await db.execute(
              'ALTER TABLE reminders ADD COLUMN calendar_event_id TEXT');
        } catch (e) {
          print('Schema upgrade v6->v7 failed: $e');
        }
      }

      if (oldVersion < 8) {
        try {
          await db.execute(
              'ALTER TABLE episode_records ADD COLUMN has_reminder INTEGER NOT NULL DEFAULT 0');
        } catch (e) {
          print('Schema upgrade v7->v8 has_reminder failed: $e');
        }
        try {
          await db.execute('DROP TABLE IF EXISTS reminders');
        } catch (e) {
          print('Schema upgrade v7->v8 DROP reminders failed: $e');
        }
      }

      if (oldVersion < 9) {
        try {
          await db.execute(
              'ALTER TABLE episode_records ADD COLUMN latitude REAL');
        } catch (e) {
          print('Schema upgrade v8->v9 latitude failed: $e');
        }
        try {
          await db.execute(
              'ALTER TABLE episode_records ADD COLUMN longitude REAL');
        } catch (e) {
          print('Schema upgrade v8->v9 longitude failed: $e');
        }
        try {
          await db.execute(
              'ALTER TABLE episode_records ADD COLUMN address TEXT');
        } catch (e) {
          print('Schema upgrade v8->v9 address failed: $e');
        }
      }

      if (oldVersion < 10) {
        try {
          await db.execute(
              'ALTER TABLE episode_records ADD COLUMN video_paths TEXT NOT NULL DEFAULT \'[]\'');
        } catch (e) {
          print('Schema upgrade v9->v10 failed: $e');
        }
      }

      if (oldVersion < 11) {
        try {
          await db.execute(
              'ALTER TABLE episode_records ADD COLUMN document_paths TEXT NOT NULL DEFAULT \'[]\'');
        } catch (e) {
          print('Schema upgrade v10->v11 failed: $e');
        }
      }
    },
  );
});
