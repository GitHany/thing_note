import 'package:flutter_riverpod/flutter_riverpod.dart';
// ignore_for_file: avoid_print
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

final databaseProvider = FutureProvider<Database>((ref) async {
  final dbPath = await getDatabasesPath();
  final path = join(dbPath, 'thing_note.db');

  try {
    return openDatabase(
      path,
      version: 45,
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

        // NOTE: SQLite < 3.35.0 does not support DROP COLUMN.
        // The old audio_path and audio_duration_sec columns will remain
        // in the table but are no longer used (data was migrated above).
        // This is harmless — unused columns don't affect correctness.
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

      // v0.0.27 new tables
      if (oldVersion < 27) {
        // record_versions table for tracking record changes
        await db.execute('''
          CREATE TABLE IF NOT EXISTS record_versions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            record_id INTEGER NOT NULL,
            note TEXT,
            photo_paths TEXT,
            audio_paths TEXT,
            video_paths TEXT,
            thing_name_id INTEGER,
            duration_sec INTEGER DEFAULT 0,
            annotations_json TEXT,
            latitude REAL,
            longitude REAL,
            address TEXT,
            change_type TEXT NOT NULL DEFAULT 'updated',
            change_detail TEXT,
            version_at TEXT NOT NULL,
            created_at TEXT NOT NULL
          )
        ''');

        // record_tags table for batch tag operations
        await db.execute('''
          CREATE TABLE IF NOT EXISTS record_tags (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            record_id INTEGER NOT NULL,
            tag_name TEXT NOT NULL,
            added_at TEXT NOT NULL
          )
        ''');

        // batch_tag_operations table
        await db.execute('''
          CREATE TABLE IF NOT EXISTS batch_tag_operations (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            operation_type TEXT NOT NULL,
            record_ids TEXT NOT NULL,
            tags TEXT NOT NULL,
            performed_at TEXT NOT NULL
          )
        ''');

        // enhanced_reminders table
        await db.execute('''
          CREATE TABLE IF NOT EXISTS enhanced_reminders (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            record_id INTEGER NOT NULL,
            remind_at TEXT NOT NULL,
            reminder_type TEXT NOT NULL DEFAULT 'once',
            custom_repeat_days TEXT,
            snooze_minutes INTEGER DEFAULT 5,
            snooze_count INTEGER DEFAULT 0,
            sound_uri TEXT,
            vibration_pattern TEXT,
            is_enabled INTEGER NOT NULL DEFAULT 1,
            is_triggered INTEGER NOT NULL DEFAULT 0,
            triggered_at TEXT,
            created_at TEXT NOT NULL
          )
        ''');

        // voice_memos table
        await db.execute('''
          CREATE TABLE IF NOT EXISTS voice_memos (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            record_id INTEGER,
            title TEXT NOT NULL,
            file_path TEXT NOT NULL,
            duration_sec INTEGER DEFAULT 0,
            transcription TEXT,
            keywords TEXT,
            transcript_language TEXT,
            is_favorite INTEGER NOT NULL DEFAULT 0,
            created_at TEXT NOT NULL
          )
        ''');

        // smart_locations table
        await db.execute('''
          CREATE TABLE IF NOT EXISTS smart_locations (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            alias TEXT,
            latitude REAL NOT NULL,
            longitude REAL NOT NULL,
            address TEXT,
            icon TEXT DEFAULT '📍',
            color TEXT DEFAULT '#607D8B',
            category TEXT,
            visit_count INTEGER DEFAULT 0,
            total_duration_sec INTEGER DEFAULT 0,
            last_visited_at TEXT,
            is_favorite INTEGER NOT NULL DEFAULT 0,
            tags TEXT,
            created_at TEXT NOT NULL
          )
        ''');

        // location_check_ins table
        await db.execute('''
          CREATE TABLE IF NOT EXISTS location_check_ins (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            location_id INTEGER NOT NULL,
            check_in_at TEXT NOT NULL,
            check_out_at TEXT,
            note TEXT,
            photo_path TEXT
          )
        ''');

        // export_templates table
        await db.execute('''
          CREATE TABLE IF NOT EXISTS export_templates (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            format TEXT NOT NULL,
            include_photos INTEGER DEFAULT 0,
            include_audio INTEGER DEFAULT 0,
            include_location INTEGER DEFAULT 1,
            include_tags INTEGER DEFAULT 1,
            created_at TEXT NOT NULL
          )
        ''');

        // merge_history table
        await db.execute('''
          CREATE TABLE IF NOT EXISTS merge_history (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            target_record_id INTEGER NOT NULL,
            source_record_ids TEXT NOT NULL,
            photos_count INTEGER DEFAULT 0,
            audio_count INTEGER DEFAULT 0,
            video_count INTEGER DEFAULT 0,
            documents_count INTEGER DEFAULT 0,
            merged_at TEXT NOT NULL
          )
        ''');

        // import_templates table
        await db.execute('''
          CREATE TABLE IF NOT EXISTS import_templates (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            source_type TEXT NOT NULL,
            mappings TEXT,
            has_header INTEGER DEFAULT 1,
            delimiter TEXT DEFAULT ','
          )
        ''');

        // enhanced_backups table
        await db.execute('''
          CREATE TABLE IF NOT EXISTS enhanced_backups (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            file_path TEXT NOT NULL,
            backup_type TEXT DEFAULT 'full',
            file_size_bytes INTEGER DEFAULT 0,
            record_count INTEGER DEFAULT 0,
            media_count INTEGER DEFAULT 0,
            created_at TEXT NOT NULL,
            is_compressed INTEGER DEFAULT 0,
            is_encrypted INTEGER DEFAULT 0,
            checksum TEXT
          )
        ''');

        // backup_schedules table
        await db.execute('''
          CREATE TABLE IF NOT EXISTS backup_schedules (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            frequency TEXT DEFAULT 'daily',
            time_of_day TEXT,
            day_of_week TEXT,
            day_of_month TEXT,
            is_enabled INTEGER DEFAULT 1,
            last_run_at TEXT,
            max_backups INTEGER DEFAULT 10
          )
        ''');

        // search_history table
        await db.execute('''
          CREATE TABLE IF NOT EXISTS search_history (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            query TEXT NOT NULL,
            searched_at TEXT NOT NULL,
            result_count INTEGER DEFAULT 0
          )
        ''');

        // saved_searches table
        await db.execute('''
          CREATE TABLE IF NOT EXISTS saved_searches (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            query TEXT NOT NULL,
            filter TEXT,
            use_count INTEGER DEFAULT 0,
            created_at TEXT NOT NULL
          )
        ''');

        // enhanced_record_links table
        await db.execute('''
          CREATE TABLE IF NOT EXISTS enhanced_record_links (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            source_record_id INTEGER NOT NULL,
            target_record_id INTEGER NOT NULL,
            link_type TEXT DEFAULT 'related',
            note TEXT,
            created_at TEXT NOT NULL
          )
        ''');

        // Create indexes for better performance
        await db.execute('CREATE INDEX IF NOT EXISTS idx_record_versions_record_id ON record_versions(record_id)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_record_tags_record_id ON record_tags(record_id)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_enhanced_reminders_record_id ON enhanced_reminders(record_id)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_enhanced_reminders_remind_at ON enhanced_reminders(remind_at)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_smart_locations_visit_count ON smart_locations(visit_count)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_enhanced_record_links_source ON enhanced_record_links(source_record_id)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_enhanced_record_links_target ON enhanced_record_links(target_record_id)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_search_history_searched_at ON search_history(searched_at)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_saved_searches_use_count ON saved_searches(use_count)');
      }

      // v0.0.28 new tables
      if (oldVersion < 28) {
        // smart_reminders_v2 table
        await db.execute('''
          CREATE TABLE IF NOT EXISTS smart_reminders_v2 (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            record_id INTEGER,
            title TEXT NOT NULL,
            remind_at TEXT NOT NULL,
            repeat_type TEXT DEFAULT 'once',
            repeat_interval INTEGER DEFAULT 0,
            snooze_minutes INTEGER DEFAULT 5,
            sound_uri TEXT,
            vibration INTEGER DEFAULT 1,
            advance_minutes INTEGER DEFAULT 15,
            is_enabled INTEGER DEFAULT 1,
            triggered_count INTEGER DEFAULT 0,
            created_at TEXT NOT NULL
          )
        ''');

        // incremental_backup_metadata table
        await db.execute('''
          CREATE TABLE IF NOT EXISTS incremental_backup_metadata (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            backup_type TEXT NOT NULL,
            base_backup_id INTEGER,
            file_path TEXT NOT NULL,
            file_size INTEGER DEFAULT 0,
            record_count INTEGER DEFAULT 0,
            start_time TEXT NOT NULL,
            end_time TEXT,
            checksum TEXT,
            is_complete INTEGER DEFAULT 0
          )
        ''');

        // templates table
        await db.execute('''
          CREATE TABLE IF NOT EXISTS templates (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            category TEXT NOT NULL,
            description TEXT,
            default_thing_name TEXT,
            default_tags TEXT,
            default_duration INTEGER DEFAULT 0,
            use_count INTEGER DEFAULT 0,
            is_favorite INTEGER DEFAULT 0,
            created_at TEXT NOT NULL
          )
        ''');

        // template_categories table
        await db.execute('''
          CREATE TABLE IF NOT EXISTS template_categories (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            icon TEXT,
            color TEXT,
            sort_order INTEGER DEFAULT 0
          )
        ''');

        // chart_configs table
        await db.execute('''
          CREATE TABLE IF NOT EXISTS chart_configs (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            chart_type TEXT NOT NULL,
            title TEXT NOT NULL,
            data_source TEXT NOT NULL,
            config_json TEXT,
            created_at TEXT NOT NULL
          )
        ''');

        // batch_tag_history table
        await db.execute('''
          CREATE TABLE IF NOT EXISTS batch_tag_history (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            operation_type TEXT NOT NULL,
            tag_action TEXT NOT NULL,
            record_count INTEGER DEFAULT 0,
            performed_at TEXT NOT NULL
          )
        ''');

        // voice_search_history table
        await db.execute('''
          CREATE TABLE IF NOT EXISTS voice_search_history (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            query_text TEXT NOT NULL,
            result_count INTEGER DEFAULT 0,
            searched_at TEXT NOT NULL
          )
        ''');

        // recovery_logs table
        await db.execute('''
          CREATE TABLE IF NOT EXISTS recovery_logs (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            backup_file TEXT NOT NULL,
            records_restored INTEGER DEFAULT 0,
            status TEXT NOT NULL,
            log TEXT,
            recovered_at TEXT NOT NULL
          )
        ''');

        // privacy_folders table
        await db.execute('''
          CREATE TABLE IF NOT EXISTS privacy_folders (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            password_hash TEXT NOT NULL,
            icon TEXT DEFAULT '🔐',
            color TEXT DEFAULT '#607D8B',
            created_at TEXT NOT NULL
          )
        ''');

        // folder_contents table
        await db.execute('''
          CREATE TABLE IF NOT EXISTS folder_contents (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            folder_id INTEGER NOT NULL,
            record_id INTEGER,
            note TEXT,
            added_at TEXT NOT NULL,
            FOREIGN KEY (folder_id) REFERENCES privacy_folders(id) ON DELETE CASCADE
          )
        ''');

        // quick_action_configs table
        await db.execute('''
          CREATE TABLE IF NOT EXISTS quick_action_configs (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            action_type TEXT NOT NULL,
            action_name TEXT NOT NULL,
            icon TEXT,
            color TEXT,
            sort_order INTEGER DEFAULT 0,
            is_enabled INTEGER DEFAULT 1
          )
        ''');

        // notifications table
        await db.execute('''
          CREATE TABLE IF NOT EXISTS notifications (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            body TEXT,
            type TEXT NOT NULL,
            is_read INTEGER DEFAULT 0,
            created_at TEXT NOT NULL
          )
        ''');

        // dashboard_pages table
        await db.execute('''
          CREATE TABLE IF NOT EXISTS dashboard_pages (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            is_default INTEGER DEFAULT 0,
            created_at TEXT NOT NULL
          )
        ''');

        // dashboard_widgets table
        await db.execute('''
          CREATE TABLE IF NOT EXISTS dashboard_widgets (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            page_id INTEGER NOT NULL,
            widget_type TEXT NOT NULL,
            title TEXT NOT NULL,
            config_json TEXT,
            position_x INTEGER DEFAULT 0,
            position_y INTEGER DEFAULT 0,
            width INTEGER DEFAULT 1,
            height INTEGER DEFAULT 1,
            FOREIGN KEY (page_id) REFERENCES dashboard_pages(id) ON DELETE CASCADE
          )
        ''');

        // export_configs table
        await db.execute('''
          CREATE TABLE IF NOT EXISTS export_configs (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            format TEXT NOT NULL,
            fields TEXT,
            filters TEXT,
            use_count INTEGER DEFAULT 0,
            created_at TEXT NOT NULL
          )
        ''');

        // export_history table
        await db.execute('''
          CREATE TABLE IF NOT EXISTS export_history (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            format TEXT NOT NULL,
            record_count INTEGER DEFAULT 0,
            file_path TEXT,
            created_at TEXT NOT NULL
          )
        ''');

        // Create indexes for v0.0.28 tables
        await db.execute('CREATE INDEX IF NOT EXISTS idx_smart_reminders_remind_at ON smart_reminders_v2(remind_at)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_incremental_backup_created_at ON incremental_backup_metadata(start_time)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_templates_category ON templates(category)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_privacy_folders_created_at ON privacy_folders(created_at)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_dashboard_widgets_page_id ON dashboard_widgets(page_id)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_export_history_created_at ON export_history(created_at)');
      }

      // v0.0.29 new tables
      if (oldVersion < 29) {
        // user_levels table
        await db.execute('''
          CREATE TABLE IF NOT EXISTS user_levels (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            level INTEGER NOT NULL UNIQUE,
            xp_required INTEGER NOT NULL,
            title TEXT NOT NULL,
            badge_icon TEXT,
            created_at TEXT NOT NULL
          )
        ''');

        // xp_transactions table
        await db.execute('''
          CREATE TABLE IF NOT EXISTS xp_transactions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            amount INTEGER NOT NULL,
            source TEXT NOT NULL,
            source_id INTEGER,
            description TEXT,
            created_at TEXT NOT NULL
          )
        ''');

        // level_rewards table
        await db.execute('''
          CREATE TABLE IF NOT EXISTS level_rewards (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            level INTEGER NOT NULL,
            reward_type TEXT NOT NULL,
            reward_config TEXT,
            is_claimed INTEGER DEFAULT 0,
            created_at TEXT NOT NULL
          )
        ''');

        // daily_quests table
        await db.execute('''
          CREATE TABLE IF NOT EXISTS daily_quests (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            quest_type TEXT NOT NULL,
            title TEXT NOT NULL,
            description TEXT,
            xp_reward INTEGER NOT NULL,
            target_count INTEGER DEFAULT 1,
            current_count INTEGER DEFAULT 0,
            is_completed INTEGER DEFAULT 0,
            date TEXT NOT NULL,
            created_at TEXT NOT NULL
          )
        ''');

        // smart_place_clusters table
        await db.execute('''
          CREATE TABLE IF NOT EXISTS smart_place_clusters (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            cluster_name TEXT NOT NULL,
            cluster_type TEXT NOT NULL,
            center_latitude REAL,
            center_longitude REAL,
            icon TEXT,
            color TEXT,
            visit_count INTEGER DEFAULT 0,
            avg_duration_minutes INTEGER DEFAULT 0,
            created_at TEXT NOT NULL
          )
        ''');

        // place_visit_history table
        await db.execute('''
          CREATE TABLE IF NOT EXISTS place_visit_history (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            cluster_id INTEGER NOT NULL,
            latitude REAL NOT NULL,
            longitude REAL NOT NULL,
            arrived_at TEXT NOT NULL,
            left_at TEXT,
            duration_minutes INTEGER,
            FOREIGN KEY (cluster_id) REFERENCES smart_place_clusters(id) ON DELETE CASCADE
          )
        ''');

        // scene_modes table
        await db.execute('''
          CREATE TABLE IF NOT EXISTS scene_modes (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            icon TEXT,
            color TEXT,
            notification_mode TEXT DEFAULT 'all',
            default_reminder_offset INTEGER,
            theme_mode TEXT,
            is_active INTEGER DEFAULT 0,
            created_at TEXT NOT NULL
          )
        ''');

        // scene_switch_history table
        await db.execute('''
          CREATE TABLE IF NOT EXISTS scene_switch_history (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            scene_id INTEGER NOT NULL,
            switched_at TEXT NOT NULL,
            trigger_type TEXT,
            FOREIGN KEY (scene_id) REFERENCES scene_modes(id) ON DELETE CASCADE
          )
        ''');

        // generated_passwords table
        await db.execute('''
          CREATE TABLE IF NOT EXISTS generated_passwords (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            password TEXT NOT NULL,
            strength_score INTEGER NOT NULL,
            length INTEGER NOT NULL,
            has_uppercase INTEGER DEFAULT 0,
            has_numbers INTEGER DEFAULT 0,
            has_symbols INTEGER DEFAULT 0,
            created_at TEXT NOT NULL
          )
        ''');

        // reminder_suggestions table
        await db.execute('''
          CREATE TABLE IF NOT EXISTS reminder_suggestions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            reminder_id INTEGER,
            suggested_time TEXT,
            suggested_repeat TEXT,
            confidence_score REAL DEFAULT 0,
            reason TEXT,
            is_accepted INTEGER DEFAULT 0,
            created_at TEXT NOT NULL
          )
        ''');

        // trips table
        await db.execute('''
          CREATE TABLE IF NOT EXISTS trips (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            destination TEXT,
            start_date TEXT NOT NULL,
            end_date TEXT,
            participants INTEGER DEFAULT 1,
            budget REAL,
            cover_image_path TEXT,
            status TEXT NOT NULL DEFAULT 'planning',
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''');

        // trip_itineraries table
        await db.execute('''
          CREATE TABLE IF NOT EXISTS trip_itineraries (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            trip_id INTEGER NOT NULL,
            title TEXT NOT NULL,
            date TEXT NOT NULL,
            start_time TEXT,
            end_time TEXT,
            location TEXT,
            latitude REAL,
            longitude REAL,
            note TEXT,
            order_index INTEGER DEFAULT 0,
            FOREIGN KEY (trip_id) REFERENCES trips(id) ON DELETE CASCADE
          )
        ''');

        // trip_bookings table
        await db.execute('''
          CREATE TABLE IF NOT EXISTS trip_bookings (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            trip_id INTEGER NOT NULL,
            booking_type TEXT NOT NULL,
            title TEXT NOT NULL,
            provider TEXT,
            amount REAL,
            currency TEXT DEFAULT 'CNY',
            booking_date TEXT,
            status TEXT DEFAULT 'pending',
            confirmation_code TEXT,
            note TEXT,
            FOREIGN KEY (trip_id) REFERENCES trips(id) ON DELETE CASCADE
          )
        ''');

        // trip_expenses table
        await db.execute('''
          CREATE TABLE IF NOT EXISTS trip_expenses (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            trip_id INTEGER NOT NULL,
            category TEXT NOT NULL,
            amount REAL NOT NULL,
            currency TEXT DEFAULT 'CNY',
            paid_by INTEGER,
            split_type TEXT DEFAULT 'equal',
            note TEXT,
            date TEXT NOT NULL,
            FOREIGN KEY (trip_id) REFERENCES trips(id) ON DELETE CASCADE
          )
        ''');

        // monthly_reviews table
        await db.execute('''
          CREATE TABLE IF NOT EXISTS monthly_reviews (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            year INTEGER NOT NULL,
            month INTEGER NOT NULL,
            highlights TEXT,
            improvements TEXT,
            reflection TEXT,
            next_month_goals TEXT,
            achievements TEXT,
            overall_score REAL,
            created_at TEXT NOT NULL
          )
        ''');

        // monthly_goals table
        await db.execute('''
          CREATE TABLE IF NOT EXISTS monthly_goals (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            month INTEGER NOT NULL,
            year INTEGER NOT NULL,
            title TEXT NOT NULL,
            description TEXT,
            target_value REAL,
            current_value REAL DEFAULT 0,
            is_completed INTEGER DEFAULT 0,
            created_at TEXT NOT NULL
          )
        ''');

        // Create indexes for v0.0.29 tables
        await db.execute('CREATE INDEX IF NOT EXISTS idx_xp_transactions_created_at ON xp_transactions(created_at)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_place_clusters_visit_count ON smart_place_clusters(visit_count)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_scene_modes_is_active ON scene_modes(is_active)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_trips_date ON trips(start_date)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_monthly_reviews_year_month ON monthly_reviews(year, month)');
      }

      // v0.0.30 new tables
      if (oldVersion < 30) {
        // exercise_records table
        await db.execute('''
          CREATE TABLE IF NOT EXISTS exercise_records (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            exercise_type TEXT NOT NULL,
            duration_minutes INTEGER NOT NULL,
            calories_burned INTEGER DEFAULT 0,
            distance_km REAL DEFAULT 0,
            avg_pace REAL,
            avg_heart_rate INTEGER,
            gps_track TEXT,
            occurred_at TEXT NOT NULL,
            linked_record_id INTEGER,
            note TEXT,
            created_at TEXT NOT NULL
          )
        ''');

        // exercise_types table
        await db.execute('''
          CREATE TABLE IF NOT EXISTS exercise_types (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            icon TEXT,
            color TEXT,
            calories_per_minute REAL DEFAULT 5.0,
            created_at TEXT NOT NULL
          )
        ''');

        // nutrition_records table
        await db.execute('''
          CREATE TABLE IF NOT EXISTS nutrition_records (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            meal_type TEXT NOT NULL,
            food_name TEXT NOT NULL,
            portion_size TEXT,
            calories INTEGER DEFAULT 0,
            protein REAL DEFAULT 0,
            carbs REAL DEFAULT 0,
            fat REAL DEFAULT 0,
            recorded_at TEXT NOT NULL,
            created_at TEXT NOT NULL
          )
        ''');

        // food_items table
        await db.execute('''
          CREATE TABLE IF NOT EXISTS food_items (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            category TEXT,
            calories_per_100g REAL DEFAULT 0,
            protein_per_100g REAL DEFAULT 0,
            carbs_per_100g REAL DEFAULT 0,
            fat_per_100g REAL DEFAULT 0,
            created_at TEXT NOT NULL
          )
        ''');

        // mood_journals table
        await db.execute('''
          CREATE TABLE IF NOT EXISTS mood_journals (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            date TEXT NOT NULL,
            mood_level INTEGER NOT NULL,
            gratitude_items TEXT,
            detailed_note TEXT,
            triggers TEXT,
            linked_record_id INTEGER,
            created_at TEXT NOT NULL
          )
        ''');

        // note_sync_queue table
        await db.execute('''
          CREATE TABLE IF NOT EXISTS note_sync_queue (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            note_id INTEGER NOT NULL,
            action TEXT NOT NULL,
            payload TEXT,
            status TEXT NOT NULL DEFAULT 'pending',
            retry_count INTEGER DEFAULT 0,
            created_at TEXT NOT NULL
          )
        ''');

        // note_sync_history table
        await db.execute('''
          CREATE TABLE IF NOT EXISTS note_sync_history (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            note_id INTEGER NOT NULL,
            action TEXT NOT NULL,
            synced_at TEXT NOT NULL,
            status TEXT NOT NULL
          )
        ''');

        // quick_commands table
        await db.execute('''
          CREATE TABLE IF NOT EXISTS quick_commands (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            alias TEXT,
            command_type TEXT NOT NULL,
            action_config TEXT NOT NULL,
            category TEXT,
            use_count INTEGER DEFAULT 0,
            is_enabled INTEGER DEFAULT 1,
            created_at TEXT NOT NULL
          )
        ''');

        // smart_suggestions table
        await db.execute('''
          CREATE TABLE IF NOT EXISTS smart_suggestions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            suggestion_type TEXT NOT NULL,
            title TEXT NOT NULL,
            description TEXT,
            action_data TEXT,
            confidence_score REAL DEFAULT 0,
            is_accepted INTEGER DEFAULT 0,
            accepted_at TEXT,
            created_at TEXT NOT NULL
          )
        ''');

        // suggestion_history table
        await db.execute('''
          CREATE TABLE IF NOT EXISTS suggestion_history (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            suggestion_id INTEGER NOT NULL,
            accepted INTEGER DEFAULT 0,
            feedback TEXT,
            created_at TEXT NOT NULL
          )
        ''');

        // mood_matrix_data table
        await db.execute('''
          CREATE TABLE IF NOT EXISTS mood_matrix_data (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            activity_name TEXT NOT NULL,
            energy_level INTEGER NOT NULL,
            mood_impact_score REAL DEFAULT 0,
            sample_count INTEGER DEFAULT 0,
            last_updated TEXT,
            created_at TEXT NOT NULL
          )
        ''');

        // habit_tournaments table
        await db.execute('''
          CREATE TABLE IF NOT EXISTS habit_tournaments (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            description TEXT,
            target_habit TEXT NOT NULL,
            start_date TEXT NOT NULL,
            end_date TEXT,
            max_participants INTEGER DEFAULT 50,
            reward TEXT,
            status TEXT DEFAULT 'active',
            created_at TEXT NOT NULL
          )
        ''');

        // tournament_participants table
        await db.execute('''
          CREATE TABLE IF NOT EXISTS tournament_participants (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            tournament_id INTEGER NOT NULL,
            participant_name TEXT NOT NULL,
            current_streak INTEGER DEFAULT 0,
            total_score INTEGER DEFAULT 0,
            rank INTEGER DEFAULT 0,
            is_active INTEGER DEFAULT 1,
            joined_at TEXT NOT NULL,
            FOREIGN KEY (tournament_id) REFERENCES habit_tournaments(id) ON DELETE CASCADE
          )
        ''');

        // goal_trees table
        await db.execute('''
          CREATE TABLE IF NOT EXISTS goal_trees (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            description TEXT,
            root_goal_id INTEGER,
            created_at TEXT NOT NULL
          )
        ''');

        // goal_nodes table
        await db.execute('''
          CREATE TABLE IF NOT EXISTS goal_nodes (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            tree_id INTEGER NOT NULL,
            goal_id INTEGER NOT NULL,
            parent_node_id INTEGER,
            level INTEGER DEFAULT 0,
            sort_order INTEGER DEFAULT 0,
            FOREIGN KEY (tree_id) REFERENCES goal_trees(id) ON DELETE CASCADE
          )
        ''');

        // reminder_patterns table
        await db.execute('''
          CREATE TABLE IF NOT EXISTS reminder_patterns (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            pattern_type TEXT NOT NULL,
            trigger_time TEXT,
            trigger_days TEXT,
            success_rate REAL DEFAULT 0,
            total_triggers INTEGER DEFAULT 0,
            last_triggered TEXT,
            created_at TEXT NOT NULL
          )
        ''');

        // privacy_settings table
        await db.execute('''
          CREATE TABLE IF NOT EXISTS privacy_settings (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            setting_key TEXT NOT NULL UNIQUE,
            setting_value TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''');

        // daily_digests table
        await db.execute('''
          CREATE TABLE IF NOT EXISTS daily_digests (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            date TEXT NOT NULL UNIQUE,
            record_count INTEGER DEFAULT 0,
            habit_completion_rate REAL DEFAULT 0,
            goal_progress_summary TEXT,
            health_summary TEXT,
            highlights TEXT,
            suggestions TEXT,
            created_at TEXT NOT NULL
          )
        ''');

        // Create indexes for v0.0.30 tables
        await db.execute('CREATE INDEX IF NOT EXISTS idx_exercise_records_occurred_at ON exercise_records(occurred_at)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_nutrition_records_recorded_at ON nutrition_records(recorded_at)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_mood_journals_date ON mood_journals(date)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_quick_commands_use_count ON quick_commands(use_count)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_smart_suggestions_confidence ON smart_suggestions(confidence_score)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_mood_matrix_energy_level ON mood_matrix_data(energy_level)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_tournament_participants_rank ON tournament_participants(rank)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_reminder_patterns_success_rate ON reminder_patterns(success_rate)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_privacy_settings_key ON privacy_settings(setting_key)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_daily_digests_date ON daily_digests(date)');
      }

      // v0.0.31 new tables - trip_planner, monthly_review, quick_commands, smart_suggestions
      if (oldVersion < 31) {
        // trip_planner tables (already defined in v0.0.29, verify existence)
        await db.execute('''
          CREATE TABLE IF NOT EXISTS trips (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            destination TEXT,
            start_date TEXT NOT NULL,
            end_date TEXT,
            participants INTEGER DEFAULT 1,
            budget REAL,
            cover_image_path TEXT,
            status TEXT NOT NULL DEFAULT 'planning',
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE IF NOT EXISTS trip_itineraries (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            trip_id INTEGER NOT NULL,
            title TEXT NOT NULL,
            date TEXT NOT NULL,
            start_time TEXT,
            end_time TEXT,
            location TEXT,
            latitude REAL,
            longitude REAL,
            note TEXT,
            order_index INTEGER DEFAULT 0,
            FOREIGN KEY (trip_id) REFERENCES trips(id) ON DELETE CASCADE
          )
        ''');

        await db.execute('''
          CREATE TABLE IF NOT EXISTS trip_bookings (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            trip_id INTEGER NOT NULL,
            booking_type TEXT NOT NULL,
            title TEXT NOT NULL,
            provider TEXT,
            amount REAL,
            currency TEXT DEFAULT 'CNY',
            booking_date TEXT,
            status TEXT DEFAULT 'pending',
            confirmation_code TEXT,
            note TEXT,
            FOREIGN KEY (trip_id) REFERENCES trips(id) ON DELETE CASCADE
          )
        ''');

        await db.execute('''
          CREATE TABLE IF NOT EXISTS trip_expenses (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            trip_id INTEGER NOT NULL,
            category TEXT NOT NULL,
            amount REAL NOT NULL,
            currency TEXT DEFAULT 'CNY',
            paid_by INTEGER,
            split_type TEXT DEFAULT 'equal',
            note TEXT,
            date TEXT NOT NULL,
            FOREIGN KEY (trip_id) REFERENCES trips(id) ON DELETE CASCADE
          )
        ''');

        // quick_commands table
        await db.execute('''
          CREATE TABLE IF NOT EXISTS quick_commands (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            alias TEXT,
            command_type TEXT NOT NULL,
            action_config TEXT NOT NULL,
            category TEXT,
            use_count INTEGER DEFAULT 0,
            is_enabled INTEGER DEFAULT 1,
            created_at TEXT NOT NULL
          )
        ''');

        // Create indexes for v0.0.31 tables
        await db.execute('CREATE INDEX IF NOT EXISTS idx_trips_date ON trips(start_date)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_trip_itineraries_trip_id ON trip_itineraries(trip_id)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_trip_bookings_trip_id ON trip_bookings(trip_id)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_trip_expenses_trip_id ON trip_expenses(trip_id)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_quick_commands_use_count ON quick_commands(use_count)');
      }

      // v0.0.32 新增功能表
      if (oldVersion < 32) {
        // mood_thermometer_records 表
        await db.execute('''
          CREATE TABLE IF NOT EXISTS mood_thermometer_records (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            mood_level INTEGER NOT NULL,
            category TEXT,
            trigger TEXT,
            note TEXT,
            recorded_at TEXT NOT NULL,
            tags TEXT,
            linked_record_id INTEGER
          )
        ''');

        // habit_watermark_config 表
        await db.execute('''
          CREATE TABLE IF NOT EXISTS habit_watermark_config (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            enabled INTEGER DEFAULT 1,
            position TEXT DEFAULT 'topLeft',
            style TEXT DEFAULT 'badge',
            habit_ids TEXT,
            show_streak INTEGER DEFAULT 1,
            show_icon INTEGER DEFAULT 1,
            opacity REAL DEFAULT 0.8
          )
        ''');

        // record_habit_links 表
        await db.execute('''
          CREATE TABLE IF NOT EXISTS record_habit_links (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            record_id INTEGER NOT NULL,
            habit_id INTEGER NOT NULL,
            linked_at TEXT NOT NULL
          )
        ''');

        // template_usage_history 表
        await db.execute('''
          CREATE TABLE IF NOT EXISTS template_usage_history (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            template_id INTEGER NOT NULL,
            template_name TEXT NOT NULL,
            used_at TEXT NOT NULL,
            context TEXT
          )
        ''');

        // classification_rules 表
        await db.execute('''
          CREATE TABLE IF NOT EXISTS classification_rules (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            pattern TEXT NOT NULL,
            assigned_thing_name TEXT,
            assigned_tags TEXT,
            is_enabled INTEGER DEFAULT 1,
            match_count INTEGER DEFAULT 0
          )
        ''');

        // classification_history 表
        await db.execute('''
          CREATE TABLE IF NOT EXISTS classification_history (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            record_id INTEGER NOT NULL,
            suggested_thing_name TEXT,
            suggested_tags TEXT,
            confidence REAL DEFAULT 0,
            applied_at TEXT NOT NULL
          )
        ''');

        // digest_history 表
        await db.execute('''
          CREATE TABLE IF NOT EXISTS digest_history (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            frequency TEXT NOT NULL,
            period_start TEXT NOT NULL,
            period_end TEXT NOT NULL,
            total_records INTEGER DEFAULT 0,
            total_minutes INTEGER DEFAULT 0,
            active_days INTEGER DEFAULT 0,
            top_tags TEXT,
            top_things TEXT,
            average_mood REAL,
            ai_insight TEXT,
            highlights_json TEXT,
            generated_at TEXT NOT NULL
          )
        ''');

        // digest_config 表
        await db.execute('''
          CREATE TABLE IF NOT EXISTS digest_config (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            enabled INTEGER DEFAULT 1,
            frequency TEXT DEFAULT 'daily',
            default_time TEXT DEFAULT 'evening',
            content_types TEXT,
            auto_send INTEGER DEFAULT 0,
            notification_channel TEXT
          )
        ''');

        // reminder_schedules 表
        await db.execute('''
          CREATE TABLE IF NOT EXISTS reminder_schedules (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            scheduled_time TEXT NOT NULL,
            type TEXT DEFAULT 'oneTime',
            is_enabled INTEGER DEFAULT 1,
            linked_record_id INTEGER,
            priority TEXT DEFAULT 'normal',
            created_at TEXT NOT NULL
          )
        ''');

        // record_snapshots 表
        await db.execute('''
          CREATE TABLE IF NOT EXISTS record_snapshots (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            record_id INTEGER NOT NULL,
            snapshot_data TEXT NOT NULL,
            note TEXT,
            created_at TEXT NOT NULL,
            expires_at TEXT
          )
        ''');

        // habit_check_ins 表
        await db.execute('''
          CREATE TABLE IF NOT EXISTS habit_check_ins (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            habit_id INTEGER NOT NULL,
            check_date TEXT NOT NULL,
            check_time TEXT NOT NULL,
            streak INTEGER DEFAULT 0
          )
        ''');

        // 创建索引
        await db.execute('CREATE INDEX IF NOT EXISTS idx_mood_thermometer_date ON mood_thermometer_records(recorded_at)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_classification_rules_enabled ON classification_rules(is_enabled)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_reminder_schedules_time ON reminder_schedules(scheduled_time)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_record_snapshots_record ON record_snapshots(record_id)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_habit_check_ins ON habit_check_ins(habit_id, check_date)');
      }

      // v0.0.33 new features
      if (oldVersion < 33) {
        // flow_states table - Flow State Tracker
        await db.execute('''
          CREATE TABLE IF NOT EXISTS flow_states (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            started_at TEXT NOT NULL,
            ended_at TEXT,
            duration_minutes INTEGER DEFAULT 0,
            focus_rating INTEGER DEFAULT 0,
            distraction_count INTEGER DEFAULT 0,
            linked_record_id INTEGER,
            note TEXT,
            created_at TEXT NOT NULL
          )
        ''');

        // reading_sessions table - Reading Session Tracker
        await db.execute('''
          CREATE TABLE IF NOT EXISTS reading_sessions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            book_title TEXT NOT NULL,
            book_author TEXT,
            start_page INTEGER DEFAULT 0,
            end_page INTEGER DEFAULT 0,
            pages_read INTEGER DEFAULT 0,
            duration_minutes INTEGER DEFAULT 0,
            session_date TEXT NOT NULL,
            reading_type TEXT DEFAULT 'book',
            note TEXT,
            linked_record_id INTEGER,
            created_at TEXT NOT NULL
          )
        ''');

        // creative_projects table - Creative Projects
        await db.execute('''
          CREATE TABLE IF NOT EXISTS creative_projects (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            project_name TEXT NOT NULL,
            project_type TEXT NOT NULL,
            description TEXT,
            status TEXT DEFAULT 'active',
            progress_percent INTEGER DEFAULT 0,
            started_at TEXT,
            target_completion TEXT,
            completed_at TEXT,
            tags TEXT,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''');

        // creative_sessions table
        await db.execute('''
          CREATE TABLE IF NOT EXISTS creative_sessions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            project_id INTEGER NOT NULL,
            session_type TEXT NOT NULL,
            duration_minutes INTEGER DEFAULT 0,
            output_summary TEXT,
            creativity_rating INTEGER DEFAULT 0,
            session_date TEXT NOT NULL,
            linked_record_id INTEGER,
            note TEXT,
            created_at TEXT NOT NULL,
            FOREIGN KEY (project_id) REFERENCES creative_projects(id) ON DELETE CASCADE
          )
        ''');

        // social_interactions table - Social Interactions Logger
        await db.execute('''
          CREATE TABLE IF NOT EXISTS social_interactions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            person_name TEXT NOT NULL,
            interaction_type TEXT NOT NULL,
            duration_minutes INTEGER DEFAULT 0,
            quality_rating INTEGER DEFAULT 0,
            location TEXT,
            interaction_date TEXT NOT NULL,
            topics_discussed TEXT,
            follow_up_needed INTEGER DEFAULT 0,
            linked_record_id INTEGER,
            note TEXT,
            created_at TEXT NOT NULL
          )
        ''');

        // daily_productivity_scores table - Productivity Score
        await db.execute('''
          CREATE TABLE IF NOT EXISTS daily_productivity_scores (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            date TEXT NOT NULL UNIQUE,
            focus_score INTEGER DEFAULT 0,
            energy_score INTEGER DEFAULT 0,
            output_score INTEGER DEFAULT 0,
            overall_score REAL DEFAULT 0,
            completed_tasks INTEGER DEFAULT 0,
            planned_tasks INTEGER DEFAULT 0,
            deep_work_minutes INTEGER DEFAULT 0,
            interruption_count INTEGER DEFAULT 0,
            mood_at_start INTEGER,
            mood_at_end INTEGER,
            notes TEXT,
            created_at TEXT NOT NULL
          )
        ''');

        // idle_time_records table - Idle Time Detector
        await db.execute('''
          CREATE TABLE IF NOT EXISTS idle_time_records (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            started_at TEXT NOT NULL,
            ended_at TEXT,
            duration_minutes INTEGER DEFAULT 0,
            idle_type TEXT DEFAULT 'unplanned',
            reason TEXT,
            is_productive INTEGER DEFAULT 0,
            linked_record_id INTEGER,
            created_at TEXT NOT NULL
          )
        ''');

        // weather_correlations table - Weather Correlation
        await db.execute('''
          CREATE TABLE IF NOT EXISTS weather_correlations (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            date TEXT NOT NULL,
            temperature REAL,
            humidity REAL,
            weather_condition TEXT,
            pressure REAL,
            productivity_score REAL DEFAULT 0,
            mood_score INTEGER DEFAULT 0,
            energy_level INTEGER DEFAULT 0,
            note TEXT,
            created_at TEXT NOT NULL
          )
        ''');

        // energy_patterns table - Energy Patterns
        await db.execute('''
          CREATE TABLE IF NOT EXISTS energy_patterns (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            hour_of_day INTEGER NOT NULL,
            day_of_week INTEGER,
            energy_level INTEGER NOT NULL,
            activity_type TEXT,
            productivity_impact REAL DEFAULT 0,
            sample_count INTEGER DEFAULT 0,
            last_recorded TEXT,
            created_at TEXT NOT NULL
          )
        ''');

        // goal_momentum table - Goal Momentum
        await db.execute('''
          CREATE TABLE IF NOT EXISTS goal_momentum (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            goal_id INTEGER NOT NULL,
            momentum_score REAL DEFAULT 0,
            streak_days INTEGER DEFAULT 0,
            weekly_progress REAL DEFAULT 0,
            monthly_progress REAL DEFAULT 0,
            predicted_completion TEXT,
            risk_factors TEXT,
            acceleration_score REAL DEFAULT 0,
            last_updated TEXT NOT NULL,
            created_at TEXT NOT NULL,
            FOREIGN KEY (goal_id) REFERENCES goals(id) ON DELETE CASCADE
          )
        ''');

        // micro_goals table - Micro Goals
        await db.execute('''
          CREATE TABLE IF NOT EXISTS micro_goals (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            description TEXT,
            estimated_minutes INTEGER DEFAULT 5,
            actual_minutes INTEGER,
            priority INTEGER DEFAULT 1,
            status TEXT DEFAULT 'pending',
            completed_at TEXT,
            parent_goal_id INTEGER,
            category TEXT,
            linked_record_id INTEGER,
            created_at TEXT NOT NULL
          )
        ''');

        // stress_indicators table - Stress Detection
        await db.execute('''
          CREATE TABLE IF NOT EXISTS stress_indicators (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            recorded_at TEXT NOT NULL,
            stress_level INTEGER NOT NULL,
            trigger_type TEXT,
            triggers TEXT,
            physical_symptoms TEXT,
            coping_strategies TEXT,
            effectiveness_rating INTEGER,
            mood_score INTEGER DEFAULT 0,
            energy_level INTEGER DEFAULT 0,
            linked_record_id INTEGER,
            note TEXT,
            created_at TEXT NOT NULL
          )
        ''');

        // relationships table - Relationship Tracker
        await db.execute('''
          CREATE TABLE IF NOT EXISTS relationships (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            person_name TEXT NOT NULL,
            relationship_type TEXT,
            contact_frequency INTEGER DEFAULT 0,
            last_contact_date TEXT,
            closeness_level INTEGER DEFAULT 0,
            shared_interests TEXT,
            notes TEXT,
            photo_url TEXT,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''');

        // relationship_interactions table
        await db.execute('''
          CREATE TABLE IF NOT EXISTS relationship_interactions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            relationship_id INTEGER NOT NULL,
            interaction_type TEXT NOT NULL,
            quality_rating INTEGER DEFAULT 0,
            duration_minutes INTEGER DEFAULT 0,
            interaction_date TEXT NOT NULL,
            topics TEXT,
            emotional_impact INTEGER DEFAULT 0,
            follow_up_planned INTEGER DEFAULT 0,
            linked_record_id INTEGER,
            note TEXT,
            created_at TEXT NOT NULL,
            FOREIGN KEY (relationship_id) REFERENCES relationships(id) ON DELETE CASCADE
          )
        ''');

        // mood_predictions table - Mood Prediction
        await db.execute('''
          CREATE TABLE IF NOT EXISTS mood_predictions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            predicted_date TEXT NOT NULL,
            predicted_mood_level INTEGER NOT NULL,
            confidence_score REAL DEFAULT 0,
            factors TEXT,
            prediction_based_on TEXT,
            actual_mood_level INTEGER,
            prediction_accuracy REAL,
            created_at TEXT NOT NULL
          )
        ''');

        // Create indexes for v0.0.33 tables
        await db.execute('CREATE INDEX IF NOT EXISTS idx_flow_states_date ON flow_states(started_at)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_reading_sessions_date ON reading_sessions(session_date)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_creative_projects_status ON creative_projects(status)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_social_interactions_date ON social_interactions(interaction_date)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_productivity_scores_date ON daily_productivity_scores(date)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_idle_time_date ON idle_time_records(started_at)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_weather_correlations_date ON weather_correlations(date)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_energy_patterns_hour ON energy_patterns(hour_of_day)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_goal_momentum_goal ON goal_momentum(goal_id)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_micro_goals_status ON micro_goals(status)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_stress_indicators_date ON stress_indicators(recorded_at)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_relationships_last_contact ON relationships(last_contact_date)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_relationship_interactions_date ON relationship_interactions(interaction_date)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_mood_predictions_date ON mood_predictions(predicted_date)');
      }

      // v0.0.34 new features
      if (oldVersion < 34) {
        // daily_reflections table - Daily Reflection
        await db.execute('''
          CREATE TABLE IF NOT EXISTS daily_reflections (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            date TEXT NOT NULL UNIQUE,
            achievements TEXT,
            gratitude_items TEXT,
            tomorrow_plans TEXT,
            mood_rating INTEGER DEFAULT 3,
            overall_note TEXT,
            linked_record_ids TEXT,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''');

        // reflection_entries table - Reflection Entries
        await db.execute('''
          CREATE TABLE IF NOT EXISTS reflection_entries (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            reflection_id INTEGER NOT NULL,
            entry_type TEXT NOT NULL,
            content TEXT NOT NULL,
            category TEXT,
            created_at TEXT NOT NULL,
            FOREIGN KEY (reflection_id) REFERENCES daily_reflections(id) ON DELETE CASCADE
          )
        ''');

        // habit_bricks table - Habit Bricks
        await db.execute('''
          CREATE TABLE IF NOT EXISTS habit_bricks (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            habit_name TEXT NOT NULL,
            parent_habit_id INTEGER,
            target_bricks_per_day INTEGER DEFAULT 1,
            brick_unit TEXT DEFAULT 'task',
            description TEXT,
            is_active INTEGER DEFAULT 1,
            created_at TEXT NOT NULL
          )
        ''');

        // brick_progress table - Brick Progress
        await db.execute('''
          CREATE TABLE IF NOT EXISTS brick_progress (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            brick_id INTEGER NOT NULL,
            record_date TEXT NOT NULL,
            completed_bricks INTEGER DEFAULT 0,
            total_bricks INTEGER DEFAULT 1,
            note TEXT,
            created_at TEXT NOT NULL,
            FOREIGN KEY (brick_id) REFERENCES habit_bricks(id) ON DELETE CASCADE
          )
        ''');

        // quick_review_cards table - Quick Review Cards
        await db.execute('''
          CREATE TABLE IF NOT EXISTS quick_review_cards (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            front TEXT NOT NULL,
            back TEXT NOT NULL,
            category TEXT,
            source TEXT,
            linked_record_id INTEGER,
            ease_factor REAL DEFAULT 2.5,
            interval_days INTEGER DEFAULT 1,
            next_review_at TEXT,
            review_count INTEGER DEFAULT 0,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''');

        // card_reviews table - Card Reviews
        await db.execute('''
          CREATE TABLE IF NOT EXISTS card_reviews (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            card_id INTEGER NOT NULL,
            reviewed_at TEXT NOT NULL,
            quality INTEGER NOT NULL DEFAULT 0,
            ease_factor REAL DEFAULT 2.5,
            interval_days INTEGER DEFAULT 1,
            FOREIGN KEY (card_id) REFERENCES quick_review_cards(id) ON DELETE CASCADE
          )
        ''');

        // knowledge_base table - Personal Knowledge Base
        await db.execute('''
          CREATE TABLE IF NOT EXISTS knowledge_base (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            content TEXT NOT NULL,
            summary TEXT,
            source TEXT,
            linked_record_id INTEGER,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''');

        // knowledge_tags table - Knowledge Tags
        await db.execute('''
          CREATE TABLE IF NOT EXISTS knowledge_tags (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            knowledge_id INTEGER NOT NULL,
            tag TEXT NOT NULL,
            FOREIGN KEY (knowledge_id) REFERENCES knowledge_base(id) ON DELETE CASCADE
          )
        ''');

        // skill_logs table - Skill Development Log
        await db.execute('''
          CREATE TABLE IF NOT EXISTS skill_logs (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            skill_name TEXT NOT NULL,
            description TEXT,
            current_level TEXT DEFAULT 'beginner',
            target_level TEXT,
            total_hours INTEGER DEFAULT 0,
            milestone TEXT,
            is_active INTEGER DEFAULT 1,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''');

        // skill_sessions table - Skill Sessions
        await db.execute('''
          CREATE TABLE IF NOT EXISTS skill_sessions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            skill_id INTEGER NOT NULL,
            duration_minutes INTEGER NOT NULL,
            practice_type TEXT,
            output_summary TEXT,
            rating INTEGER DEFAULT 3,
            session_date TEXT NOT NULL,
            linked_record_id INTEGER,
            note TEXT,
            created_at TEXT NOT NULL,
            FOREIGN KEY (skill_id) REFERENCES skill_logs(id) ON DELETE CASCADE
          )
        ''');

        // energy_records table - Energy Management
        await db.execute('''
          CREATE TABLE IF NOT EXISTS energy_records (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            recorded_at TEXT NOT NULL,
            energy_level INTEGER NOT NULL,
            trigger TEXT,
            activity TEXT,
            note TEXT,
            created_at TEXT NOT NULL
          )
        ''');

        // focus_zones table - Focus Zones
        await db.execute('''
          CREATE TABLE IF NOT EXISTS focus_zones (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            focus_duration_minutes INTEGER DEFAULT 25,
            break_duration_minutes INTEGER DEFAULT 5,
            long_break_duration INTEGER DEFAULT 15,
            color TEXT DEFAULT '#2196F3',
            is_active INTEGER DEFAULT 1,
            created_at TEXT NOT NULL
          )
        ''');

        // daily_wins table - Daily Wins
        await db.execute('''
          CREATE TABLE IF NOT EXISTS daily_wins (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            win_date TEXT NOT NULL,
            title TEXT NOT NULL,
            description TEXT,
            category TEXT,
            points INTEGER DEFAULT 10,
            created_at TEXT NOT NULL
          )
        ''');

        // location_routines table - Location-Based Routines
        await db.execute('''
          CREATE TABLE IF NOT EXISTS location_routines (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            location_name TEXT NOT NULL,
            location_type TEXT,
            routines TEXT NOT NULL DEFAULT '',
            is_auto_detect INTEGER DEFAULT 0,
            latitude REAL,
            longitude REAL,
            radius_meters REAL DEFAULT 100,
            created_at TEXT NOT NULL
          )
        ''');

        // media_gallery table - Media Gallery
        await db.execute('''
          CREATE TABLE IF NOT EXISTS media_gallery (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            file_path TEXT NOT NULL,
            file_type TEXT NOT NULL,
            thumbnail_path TEXT,
            file_size INTEGER DEFAULT 0,
            width INTEGER,
            height INTEGER,
            linked_record_id INTEGER,
            album_id INTEGER,
            created_at TEXT NOT NULL
          )
        ''');

        // weekly_planner_items table - Weekly Planner
        await db.execute('''
          CREATE TABLE IF NOT EXISTS weekly_planner_items (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            description TEXT,
            day_of_week INTEGER NOT NULL,
            start_time TEXT,
            duration_minutes INTEGER DEFAULT 60,
            priority TEXT DEFAULT 'normal',
            status TEXT DEFAULT 'pending',
            linked_record_id INTEGER,
            created_at TEXT NOT NULL
          )
        ''');

        // quick_export_configs table - Quick Export
        await db.execute('''
          CREATE TABLE IF NOT EXISTS quick_export_configs (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            format TEXT NOT NULL,
            fields TEXT,
            filters TEXT,
            use_count INTEGER DEFAULT 0,
            created_at TEXT NOT NULL
          )
        ''');

// v0.0.35 new features
        if (oldVersion < 35) {
          // deep_work_sessions table
          await db.execute('''
            CREATE TABLE IF NOT EXISTS deep_work_sessions (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              started_at TEXT NOT NULL,
              ended_at TEXT,
              duration_minutes INTEGER DEFAULT 0,
              focus_score INTEGER DEFAULT 0,
              distraction_count INTEGER DEFAULT 0,
              linked_record_id INTEGER,
              note TEXT,
              created_at TEXT NOT NULL
            )
          ''');

          // learning_progress table
          await db.execute('''
            CREATE TABLE IF NOT EXISTS learning_progress (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              subject TEXT NOT NULL,
              description TEXT,
              total_hours INTEGER DEFAULT 0,
              target_hours INTEGER DEFAULT 100,
              proficiency_level REAL DEFAULT 0,
              status TEXT DEFAULT 'active',
              last_studied TEXT,
              next_milestone TEXT,
              created_at TEXT NOT NULL,
              updated_at TEXT NOT NULL
            )
          ''');

          // learning_sessions table
          await db.execute('''
            CREATE TABLE IF NOT EXISTS learning_sessions (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              subject TEXT NOT NULL,
              topic TEXT,
              duration_minutes INTEGER DEFAULT 0,
              proficiency_level REAL DEFAULT 0,
              notes TEXT,
              resource TEXT,
              completed_at TEXT,
              session_date TEXT NOT NULL,
              created_at TEXT NOT NULL
            )
          ''');

          // quick_capture_config table
          await db.execute('''
            CREATE TABLE IF NOT EXISTS quick_capture_config (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              mode TEXT DEFAULT 'standard',
              default_duration INTEGER DEFAULT 0,
              quick_tags TEXT,
              auto_location INTEGER DEFAULT 1,
              auto_time INTEGER DEFAULT 1,
              sound_enabled INTEGER DEFAULT 1,
              rapid_interval INTEGER DEFAULT 30
            )
          ''');

          // quick_captures table
          await db.execute('''
            CREATE TABLE IF NOT EXISTS quick_captures (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              type TEXT NOT NULL,
              content TEXT NOT NULL,
              media_path TEXT,
              thing_name TEXT,
              tags TEXT,
              captured_at TEXT NOT NULL,
              is_converted INTEGER DEFAULT 0,
              linked_record_id TEXT
            )
          ''');

          // smart_notification_config table
          await db.execute('''
            CREATE TABLE IF NOT EXISTS smart_notification_config (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              enabled INTEGER DEFAULT 1,
              quiet_hours_start INTEGER DEFAULT 22,
              quiet_hours_end INTEGER DEFAULT 8,
              smart_timing INTEGER DEFAULT 1,
              batch_notifications INTEGER DEFAULT 1,
              max_daily INTEGER DEFAULT 10,
              disabled_categories TEXT
            )
          ''');

          // smart_notifications table
          await db.execute('''
            CREATE TABLE IF NOT EXISTS smart_notifications (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              title TEXT NOT NULL,
              body TEXT,
              category TEXT DEFAULT 'general',
              scheduled_time TEXT NOT NULL,
              sent_time TEXT,
              opened_at TEXT,
              status TEXT DEFAULT 'pending',
              priority INTEGER DEFAULT 1,
              action_route TEXT,
              action_data TEXT,
              created_at TEXT NOT NULL
            )
          ''');

          // archive_config table
          await db.execute('''
            CREATE TABLE IF NOT EXISTS archive_config (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              auto_archive_enabled INTEGER DEFAULT 0,
              auto_archive_days INTEGER DEFAULT 365,
              exclude_categories TEXT,
              batch_size INTEGER DEFAULT 100,
              compress_media INTEGER DEFAULT 1,
              compression_quality INTEGER DEFAULT 70
            )
          ''');

          // archive_jobs table
          await db.execute('''
            CREATE TABLE IF NOT EXISTS archive_jobs (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT NOT NULL,
              type TEXT NOT NULL,
              created_at TEXT NOT NULL,
              completed_at TEXT,
              records_affected INTEGER DEFAULT 0,
              storage_freed INTEGER DEFAULT 0,
              status TEXT DEFAULT 'pending',
              error TEXT
            )
          ''');

          // review_schedules table
          await db.execute('''
            CREATE TABLE IF NOT EXISTS review_schedules (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT NOT NULL,
              type TEXT NOT NULL,
              frequency TEXT NOT NULL,
              next_review TEXT NOT NULL,
              last_review TEXT,
              config TEXT
            )
          ''');

          // review_history table
          await db.execute('''
            CREATE TABLE IF NOT EXISTS review_history (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              schedule_type TEXT NOT NULL,
              summary TEXT,
              completed_items INTEGER DEFAULT 0,
              pending_items INTEGER DEFAULT 0,
              notes TEXT,
              reviewed_at TEXT NOT NULL
            )
          ''');

          // goal_dependencies table
          await db.execute('''
            CREATE TABLE IF NOT EXISTS goal_dependencies (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              goal_id INTEGER NOT NULL,
              depends_on_goal_id INTEGER NOT NULL,
              note TEXT,
              created_at TEXT NOT NULL
            )
          ''');

          // Create indexes for new tables
          await db.execute('CREATE INDEX IF NOT EXISTS idx_deep_work_date ON deep_work_sessions(started_at)');
          await db.execute('CREATE INDEX IF NOT EXISTS idx_learning_progress_subject ON learning_progress(subject)');
          await db.execute('CREATE INDEX IF NOT EXISTS idx_learning_sessions_date ON learning_sessions(session_date)');
          await db.execute('CREATE INDEX IF NOT EXISTS idx_smart_notifications_time ON smart_notifications(scheduled_time)');
          await db.execute('CREATE INDEX IF NOT EXISTS idx_archive_jobs_date ON archive_jobs(created_at)');
          await db.execute('CREATE INDEX IF NOT EXISTS idx_review_schedules_next ON review_schedules(next_review)');
          await db.execute('CREATE INDEX IF NOT EXISTS idx_goal_dependencies_goal ON goal_dependencies(goal_id)');
        }
      }

      // v0.0.36 new features
      if (oldVersion < 36) {
        // okr_objectives table - Personal OKR
        await db.execute('''
          CREATE TABLE IF NOT EXISTS okr_objectives (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            description TEXT,
            quarter INTEGER NOT NULL,
            year INTEGER NOT NULL,
            progress REAL DEFAULT 0,
            status TEXT DEFAULT 'active',
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''');

        // okr_key_results table
        await db.execute('''
          CREATE TABLE IF NOT EXISTS okr_key_results (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            objective_id INTEGER NOT NULL,
            title TEXT NOT NULL,
            metric TEXT,
            target_value REAL DEFAULT 100,
            current_value REAL DEFAULT 0,
            unit TEXT DEFAULT '',
            sort_order INTEGER DEFAULT 0,
            created_at TEXT NOT NULL,
            FOREIGN KEY (objective_id) REFERENCES okr_objectives(id) ON DELETE CASCADE
          )
        ''');

        // energy_curves table
        await db.execute('''
          CREATE TABLE IF NOT EXISTS energy_curves (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            date TEXT NOT NULL UNIQUE,
            hour_6_8 INTEGER DEFAULT 0,
            hour_8_10 INTEGER DEFAULT 0,
            hour_10_12 INTEGER DEFAULT 0,
            hour_12_14 INTEGER DEFAULT 0,
            hour_14_16 INTEGER DEFAULT 0,
            hour_16_18 INTEGER DEFAULT 0,
            hour_18_20 INTEGER DEFAULT 0,
            hour_20_22 INTEGER DEFAULT 0,
            note TEXT,
            created_at TEXT NOT NULL
          )
        ''');

        // habit_stacks table
        await db.execute('''
          CREATE TABLE IF NOT EXISTS habit_stacks (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            description TEXT,
            color INTEGER DEFAULT 0xFF2196F3,
            is_active INTEGER DEFAULT 1,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''');

        // stack_links table
        await db.execute('''
          CREATE TABLE IF NOT EXISTS stack_links (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            stack_id INTEGER NOT NULL,
            habit_id INTEGER NOT NULL,
            order_index INTEGER DEFAULT 0,
            trigger_text TEXT,
            created_at TEXT NOT NULL,
            FOREIGN KEY (stack_id) REFERENCES habit_stacks(id) ON DELETE CASCADE
          )
        ''');

        // mini_tasks table
        await db.execute('''
          CREATE TABLE IF NOT EXISTS mini_tasks (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            description TEXT,
            parent_task_id INTEGER,
            priority INTEGER DEFAULT 2,
            estimated_minutes INTEGER DEFAULT 15,
            actual_minutes INTEGER DEFAULT 0,
            is_completed INTEGER DEFAULT 0,
            due_date TEXT,
            completed_at TEXT,
            status TEXT DEFAULT 'pending',
            sort_order INTEGER DEFAULT 0,
            created_at TEXT NOT NULL
          )
        ''');

        // task_groups table
        await db.execute('''
          CREATE TABLE IF NOT EXISTS task_groups (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            description TEXT,
            color INTEGER DEFAULT 0xFF2196F3,
            progress REAL DEFAULT 0,
            created_at TEXT NOT NULL
          )
        ''');

        // weekly_focuses table
        await db.execute('''
          CREATE TABLE IF NOT EXISTS weekly_focuses (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            week_number INTEGER NOT NULL,
            year INTEGER NOT NULL,
            title TEXT NOT NULL,
            description TEXT,
            theme TEXT,
            color INTEGER DEFAULT 0xFF2196F3,
            status TEXT DEFAULT 'planning',
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''');

        // weekly_goals table
        await db.execute('''
          CREATE TABLE IF NOT EXISTS weekly_goals (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            focus_id INTEGER NOT NULL,
            title TEXT NOT NULL,
            progress INTEGER DEFAULT 0,
            is_completed INTEGER DEFAULT 0,
            sort_order INTEGER DEFAULT 0,
            created_at TEXT NOT NULL,
            FOREIGN KEY (focus_id) REFERENCES weekly_focuses(id) ON DELETE CASCADE
          )
        ''');

        // gratitude_entries table
        await db.execute('''
          CREATE TABLE IF NOT EXISTS gratitude_entries (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            date TEXT NOT NULL UNIQUE,
            content TEXT NOT NULL,
            mood TEXT,
            mood_level INTEGER,
            gratitude_items TEXT,
            note TEXT,
            created_at TEXT NOT NULL
          )
        ''');

        // skills table
        await db.execute('''
          CREATE TABLE IF NOT EXISTS skills (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            description TEXT,
            category TEXT DEFAULT 'other',
            color INTEGER DEFAULT 0xFF2196F3,
            current_level INTEGER DEFAULT 1,
            target_level INTEGER DEFAULT 10,
            total_hours INTEGER DEFAULT 0,
            status TEXT DEFAULT 'learning',
            started_at TEXT,
            last_practiced_at TEXT,
            created_at TEXT NOT NULL
          )
        ''');

        // skill_milestones table
        await db.execute('''
          CREATE TABLE IF NOT EXISTS skill_milestones (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            skill_id INTEGER NOT NULL,
            title TEXT NOT NULL,
            description TEXT,
            target_hours INTEGER DEFAULT 10,
            current_hours INTEGER DEFAULT 0,
            is_completed INTEGER DEFAULT 0,
            completed_at TEXT,
            created_at TEXT NOT NULL,
            FOREIGN KEY (skill_id) REFERENCES skills(id) ON DELETE CASCADE
          )
        ''');

        // reflection_templates table
        await db.execute('''
          CREATE TABLE IF NOT EXISTS reflection_templates (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            type TEXT NOT NULL,
            questions TEXT,
            is_default INTEGER DEFAULT 0,
            created_at TEXT NOT NULL
          )
        ''');

        // reflection_entries table (enhanced)
        await db.execute('''
          CREATE TABLE IF NOT EXISTS reflection_entries (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            template_id INTEGER NOT NULL,
            template_name TEXT NOT NULL,
            type TEXT NOT NULL,
            date TEXT NOT NULL,
            answers TEXT,
            overall_note TEXT,
            mood_level INTEGER,
            created_at TEXT NOT NULL
          )
        ''');

        // focus_playlists table
        await db.execute('''
          CREATE TABLE IF NOT EXISTS focus_playlists (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            description TEXT,
            category TEXT DEFAULT 'focus',
            color INTEGER DEFAULT 0xFF2196F3,
            track_count INTEGER DEFAULT 0,
            cover_url TEXT,
            is_default INTEGER DEFAULT 0,
            created_at TEXT NOT NULL
          )
        ''');

        // focus_tracks table
        await db.execute('''
          CREATE TABLE IF NOT EXISTS focus_tracks (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            artist TEXT,
            file_path TEXT,
            url TEXT,
            duration_seconds INTEGER DEFAULT 0,
            category TEXT DEFAULT 'ambient',
            play_count INTEGER DEFAULT 0,
            is_favorite INTEGER DEFAULT 0,
            created_at TEXT NOT NULL
          )
        ''');

        // focus_playlist_tracks table
        await db.execute('''
          CREATE TABLE IF NOT EXISTS focus_playlist_tracks (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            track_id INTEGER NOT NULL,
            playlist_id INTEGER NOT NULL,
            added_at TEXT NOT NULL,
            FOREIGN KEY (track_id) REFERENCES focus_tracks(id) ON DELETE CASCADE,
            FOREIGN KEY (playlist_id) REFERENCES focus_playlists(id) ON DELETE CASCADE
          )
        ''');

        // Create indexes for v0.0.36 tables
        await db.execute('CREATE INDEX IF NOT EXISTS idx_okr_objectives_quarter ON okr_objectives(quarter, year)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_okr_key_results_objective ON okr_key_results(objective_id)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_energy_curves_date ON energy_curves(date)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_habit_stacks_active ON habit_stacks(is_active)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_stack_links_order ON stack_links(stack_id, order_index)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_mini_tasks_status ON mini_tasks(status, is_completed)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_weekly_focuses_current ON weekly_focuses(year, week_number)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_weekly_goals_focus ON weekly_goals(focus_id)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_gratitude_entries_date ON gratitude_entries(date)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_skills_category ON skills(category)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_skill_milestones_skill ON skill_milestones(skill_id)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_reflection_templates_type ON reflection_templates(type)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_reflection_entries_date ON reflection_entries(date)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_focus_playlists_category ON focus_playlists(category)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_focus_tracks_category ON focus_tracks(category)');
      }

      // ============ v0.0.37 Upgrade ============
      if (oldVersion < 37) {
        // water_intake_records - Water Intake Tracker
        await db.execute('''
          CREATE TABLE IF NOT EXISTS water_intake_records (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            date TEXT NOT NULL,
            glasses INTEGER DEFAULT 0,
            total_ml INTEGER DEFAULT 0,
            goal_ml INTEGER DEFAULT 2000,
            reminder_enabled INTEGER DEFAULT 1,
            note TEXT,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''');

        // mini_habits - Mini Habits (2-min or less)
        await db.execute('''
          CREATE TABLE IF NOT EXISTS mini_habits (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            description TEXT,
            duration_seconds INTEGER DEFAULT 120,
            icon TEXT,
            color INTEGER DEFAULT 0xFF2196F3,
            frequency TEXT DEFAULT 'daily',
            streak_days INTEGER DEFAULT 0,
            best_streak INTEGER DEFAULT 0,
            total_completions INTEGER DEFAULT 0,
            is_active INTEGER DEFAULT 1,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''');

        // mini_habit_logs
        await db.execute('''
          CREATE TABLE IF NOT EXISTS mini_habit_logs (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            habit_id INTEGER NOT NULL,
            completed_at TEXT NOT NULL,
            duration_actual INTEGER DEFAULT 0,
            note TEXT,
            FOREIGN KEY (habit_id) REFERENCES mini_habits(id) ON DELETE CASCADE
          )
        ''');

        // daily_mottos - Daily Quote/Motto
        await db.execute('''
          CREATE TABLE IF NOT EXISTS daily_mottos (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            date TEXT NOT NULL UNIQUE,
            quote TEXT,
            author TEXT,
            source TEXT,
            reflection TEXT,
            mood_after INTEGER,
            is_favorite INTEGER DEFAULT 0,
            created_at TEXT NOT NULL
          )
        ''');

        // habit_heatmap_data
        await db.execute('''
          CREATE TABLE IF NOT EXISTS habit_heatmap_data (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            habit_id INTEGER NOT NULL,
            date TEXT NOT NULL,
            completion_level INTEGER DEFAULT 0,
            created_at TEXT NOT NULL,
            FOREIGN KEY (habit_id) REFERENCES mini_habits(id) ON DELETE CASCADE
          )
        ''');

        // daily_intentions - Daily Intention
        await db.execute('''
          CREATE TABLE IF NOT EXISTS daily_intentions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            date TEXT NOT NULL UNIQUE,
            intention TEXT NOT NULL,
            category TEXT,
            color INTEGER DEFAULT 0xFF2196F3,
            is_completed INTEGER DEFAULT 0,
            completed_at TEXT,
            note TEXT,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''');

        // break_sessions - Break Timer
        await db.execute('''
          CREATE TABLE IF NOT EXISTS break_sessions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            started_at TEXT NOT NULL,
            ended_at TEXT,
            duration_minutes INTEGER DEFAULT 0,
            break_type TEXT DEFAULT 'short',
            activity TEXT,
            mood_before INTEGER,
            mood_after INTEGER,
            is_micro_break INTEGER DEFAULT 1,
            note TEXT,
            created_at TEXT NOT NULL
          )
        ''');

        // break_suggestions
        await db.execute('''
          CREATE TABLE IF NOT EXISTS break_suggestions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            description TEXT,
            duration_minutes INTEGER DEFAULT 5,
            category TEXT DEFAULT 'relax',
            icon TEXT,
            energy_impact INTEGER DEFAULT 0,
            created_at TEXT NOT NULL
          )
        ''');

        // mood_colors - Mood Colors
        await db.execute('''
          CREATE TABLE IF NOT EXISTS mood_colors (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            date TEXT NOT NULL UNIQUE,
            color_hex TEXT NOT NULL,
            mood_level INTEGER DEFAULT 3,
            primary_emotion TEXT,
            intensity REAL DEFAULT 1.0,
            note TEXT,
            linked_record_ids TEXT,
            created_at TEXT NOT NULL
          )
        ''');

        // voice_journal_entries
        await db.execute('''
          CREATE TABLE IF NOT EXISTS voice_journal_entries (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            date TEXT NOT NULL,
            file_path TEXT NOT NULL,
            duration_seconds INTEGER DEFAULT 0,
            transcript TEXT,
            mood TEXT,
            tags TEXT,
            is_transcribed INTEGER DEFAULT 0,
            is_favorite INTEGER DEFAULT 0,
            created_at TEXT NOT NULL
          )
        ''');

        // pomodoro_sessions
        await db.execute('''
          CREATE TABLE IF NOT EXISTS pomodoro_sessions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            started_at TEXT NOT NULL,
            ended_at TEXT,
            focus_minutes INTEGER DEFAULT 25,
            break_minutes INTEGER DEFAULT 5,
            rounds_completed INTEGER DEFAULT 1,
            total_sessions INTEGER DEFAULT 1,
            session_type TEXT DEFAULT 'focus',
            is_completed INTEGER DEFAULT 1,
            linked_record_id INTEGER,
            note TEXT,
            created_at TEXT NOT NULL
          )
        ''');

        // pomodoro_stats
        await db.execute('''
          CREATE TABLE IF NOT EXISTS pomodoro_stats (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            date TEXT NOT NULL UNIQUE,
            total_sessions INTEGER DEFAULT 0,
            total_focus_minutes INTEGER DEFAULT 0,
            completed_rounds INTEGER DEFAULT 0,
            longest_streak INTEGER DEFAULT 0,
            productivity_score INTEGER DEFAULT 0,
            mood_score INTEGER DEFAULT 0,
            note TEXT,
            created_at TEXT NOT NULL
          )
        ''');

        // daily_stats_snapshot
        await db.execute('''
          CREATE TABLE IF NOT EXISTS daily_stats_snapshot (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            date TEXT NOT NULL UNIQUE,
            records_count INTEGER DEFAULT 0,
            total_duration_minutes INTEGER DEFAULT 0,
            habits_completed INTEGER DEFAULT 0,
            habits_total INTEGER DEFAULT 0,
            goals_completed INTEGER DEFAULT 0,
            mood_score INTEGER,
            energy_score INTEGER,
            top_thing_names TEXT,
            top_tags TEXT,
            notes TEXT,
            created_at TEXT NOT NULL
          )
        ''');

        // quick_flash_cards
        await db.execute('''
          CREATE TABLE IF NOT EXISTS quick_flash_cards (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            front TEXT NOT NULL,
            back TEXT NOT NULL,
            category TEXT,
            source TEXT,
            difficulty INTEGER DEFAULT 2,
            last_reviewed TEXT,
            next_review TEXT,
            ease_factor REAL DEFAULT 2.5,
            interval_days INTEGER DEFAULT 1,
            review_count INTEGER DEFAULT 0,
            is_favorite INTEGER DEFAULT 0,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''');

        // flash_card_reviews (enhanced)
        await db.execute('''
          CREATE TABLE IF NOT EXISTS flash_card_reviews (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            card_id INTEGER NOT NULL,
            reviewed_at TEXT NOT NULL,
            quality INTEGER NOT NULL DEFAULT 0,
            ease_factor REAL DEFAULT 2.5,
            interval_days INTEGER DEFAULT 1,
            FOREIGN KEY (card_id) REFERENCES quick_flash_cards(id) ON DELETE CASCADE
          )
        ''');

        // monthly_milestones
        await db.execute('''
          CREATE TABLE IF NOT EXISTS monthly_milestones (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            year INTEGER NOT NULL,
            month INTEGER NOT NULL,
            milestone_title TEXT NOT NULL,
            description TEXT,
            target_type TEXT,
            target_value REAL,
            current_value REAL DEFAULT 0,
            category TEXT,
            is_completed INTEGER DEFAULT 0,
            completed_at TEXT,
            color INTEGER DEFAULT 0xFF2196F3,
            created_at TEXT NOT NULL
          )
        ''');

        // milestone_progress
        await db.execute('''
          CREATE TABLE IF NOT EXISTS milestone_progress (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            milestone_id INTEGER NOT NULL,
            date TEXT NOT NULL,
            progress REAL DEFAULT 0,
            note TEXT,
            created_at TEXT NOT NULL,
            FOREIGN KEY (milestone_id) REFERENCES monthly_milestones(id) ON DELETE CASCADE
          )
        ''');

        // habit_streak_fire - Habit Streak Fire
        await db.execute('''
          CREATE TABLE IF NOT EXISTS habit_streak_fire (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            habit_id INTEGER NOT NULL,
            current_streak INTEGER DEFAULT 0,
            best_streak INTEGER DEFAULT 0,
            streak_start_date TEXT,
            fire_level INTEGER DEFAULT 0,
            total_fires INTEGER DEFAULT 0,
            flame_color TEXT DEFAULT '#FF6B35',
            is_on_fire INTEGER DEFAULT 0,
            updated_at TEXT NOT NULL,
            FOREIGN KEY (habit_id) REFERENCES mini_habits(id) ON DELETE CASCADE
          )
        ''');

        // Create indexes for v0.0.37
        await db.execute('CREATE INDEX IF NOT EXISTS idx_water_intake_date ON water_intake_records(date)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_mini_habits_active ON mini_habits(is_active)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_mini_habit_logs_habit ON mini_habit_logs(habit_id)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_daily_mottos_date ON daily_mottos(date)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_habit_heatmap_date ON habit_heatmap_data(date)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_daily_intentions_date ON daily_intentions(date)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_break_sessions_date ON break_sessions(started_at)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_mood_colors_date ON mood_colors(date)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_voice_journal_date ON voice_journal_entries(date)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_pomodoro_sessions_date ON pomodoro_sessions(started_at)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_pomodoro_stats_date ON pomodoro_stats(date)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_daily_stats_date ON daily_stats_snapshot(date)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_quick_flash_cards_category ON quick_flash_cards(category)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_monthly_milestones_date ON monthly_milestones(year, month)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_habit_streak_fire_habit ON habit_streak_fire(habit_id)');
      }

      // v0.0.36 新功能数据库表 (v0.0.38 实际版本)
      if (oldVersion < 38) {
        // morning_checkins 表 - 晨间签到
        await db.execute('''
          CREATE TABLE IF NOT EXISTS morning_checkins (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            date TEXT NOT NULL UNIQUE,
            energy_level INTEGER DEFAULT 3,
            mood_level INTEGER DEFAULT 3,
            intention TEXT,
            focus_area TEXT,
            priorities TEXT,
            gratitude_note TEXT,
            created_at TEXT NOT NULL
          )
        ''');

        // pomodoro_tasks 表 - 番茄任务
        await db.execute('''
          CREATE TABLE IF NOT EXISTS pomodoro_tasks (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            description TEXT,
            estimated_pomodoros INTEGER DEFAULT 1,
            completed_pomodoros INTEGER DEFAULT 0,
            status TEXT DEFAULT 'pending',
            priority TEXT DEFAULT 'medium',
            due_date TEXT,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''');

        // pomodoro_sessions table already created in v0.0.37

        // weekly_wins 表 - 每周成就
        await db.execute('''
          CREATE TABLE IF NOT EXISTS weekly_wins (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            week_number INTEGER NOT NULL,
            year INTEGER NOT NULL,
            title TEXT NOT NULL,
            description TEXT,
            category TEXT,
            achieved_at TEXT,
            created_at TEXT NOT NULL
          )
        ''');

        // weekly_summaries 表
        await db.execute('''
          CREATE TABLE IF NOT EXISTS weekly_summaries (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            week_number INTEGER NOT NULL,
            year INTEGER NOT NULL,
            total_wins INTEGER DEFAULT 0,
            categories TEXT,
            reflection TEXT,
            created_at TEXT NOT NULL
          )
        ''');

        // interrupts 表 - 中断追踪
        await db.execute('''
          CREATE TABLE IF NOT EXISTS interrupts (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            type TEXT NOT NULL,
            started_at TEXT NOT NULL,
            ended_at TEXT,
            duration_seconds INTEGER DEFAULT 0,
            source TEXT,
            is_productive INTEGER DEFAULT 0,
            note TEXT,
            linked_task_id INTEGER,
            created_at TEXT NOT NULL
          )
        ''');

        // grateful_notes 表 - 感恩日志
        await db.execute('''
          CREATE TABLE IF NOT EXISTS grateful_notes (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            date TEXT NOT NULL,
            content TEXT NOT NULL,
            category TEXT,
            mood_level INTEGER DEFAULT 3,
            created_at TEXT NOT NULL
          )
        ''');

        // intentions 表 - 意图设定
        await db.execute('''
          CREATE TABLE IF NOT EXISTS intentions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            date TEXT NOT NULL UNIQUE,
            intention TEXT NOT NULL,
            affirmation TEXT,
            focus_areas TEXT,
            energy_level INTEGER DEFAULT 3,
            created_at TEXT NOT NULL
          )
        ''');

        // energy_peaks 表 - 能量峰值
        await db.execute('''
          CREATE TABLE IF NOT EXISTS energy_peaks (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            date TEXT NOT NULL,
            hour INTEGER NOT NULL,
            energy_level INTEGER NOT NULL,
            activity TEXT,
            note TEXT,
            created_at TEXT NOT NULL
          )
        ''');

        // mood_activity_mappings 表 - 情绪活动匹配
        await db.execute('''
          CREATE TABLE IF NOT EXISTS mood_activity_mappings (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            activity TEXT NOT NULL,
            avg_mood REAL DEFAULT 0,
            sample_count INTEGER DEFAULT 0,
            last_updated TEXT NOT NULL
          )
        ''');

        // daily_progress_items 表 - 每日进度
        await db.execute('''
          CREATE TABLE IF NOT EXISTS daily_progress_items (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            is_completed INTEGER DEFAULT 0,
            target_value INTEGER,
            current_value INTEGER DEFAULT 0,
            unit TEXT,
            category TEXT,
            date TEXT NOT NULL,
            created_at TEXT NOT NULL
          )
        ''');

        // habit_chains 表 - 习惯堆叠
        await db.execute('''
          CREATE TABLE IF NOT EXISTS habit_chains (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            items TEXT,
            last_completed TEXT,
            streak INTEGER DEFAULT 0,
            created_at TEXT NOT NULL
          )
        ''');

        // focus_music_configs 表 - 专注音乐
        await db.execute('''
          CREATE TABLE IF NOT EXISTS focus_music_configs (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            category TEXT,
            url TEXT,
            is_looping INTEGER DEFAULT 1,
            volume INTEGER DEFAULT 70,
            created_at TEXT NOT NULL
          )
        ''');

        // weekly_plans 表 - 周计划
        await db.execute('''
          CREATE TABLE IF NOT EXISTS weekly_plans (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            year INTEGER NOT NULL,
            week_number INTEGER NOT NULL,
            days TEXT,
            created_at TEXT NOT NULL
          )
        ''');

        // weekly_plan_items 表
        await db.execute('''
          CREATE TABLE IF NOT EXISTS weekly_plan_items (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            plan_id INTEGER NOT NULL,
            day_of_week INTEGER NOT NULL,
            content TEXT NOT NULL,
            is_completed INTEGER DEFAULT 0,
            priority INTEGER,
            created_at TEXT NOT NULL,
            FOREIGN KEY (plan_id) REFERENCES weekly_plans(id) ON DELETE CASCADE
          )
        ''');
      }

      // ============ v0.0.38 Patch: Add Missing Tables ============
      // Add missing tables for features that were added but tables weren't created
      if (oldVersion >= 1) {
        // habits table
        await db.execute('''
          CREATE TABLE IF NOT EXISTS habits (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            description TEXT,
            frequency TEXT DEFAULT 'daily',
            icon TEXT,
            color INTEGER DEFAULT 0xFF2196F3,
            target_days TEXT,
            reminder_time TEXT,
            current_streak INTEGER DEFAULT 0,
            best_streak INTEGER DEFAULT 0,
            last_completed_at TEXT,
            is_active INTEGER DEFAULT 1,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''');

        // habit_logs table
        await db.execute('''
          CREATE TABLE IF NOT EXISTS habit_logs (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            habit_id INTEGER NOT NULL,
            completed_at TEXT NOT NULL,
            note TEXT,
            FOREIGN KEY (habit_id) REFERENCES habits(id) ON DELETE CASCADE
          )
        ''');

        // goals table
        await db.execute('''
          CREATE TABLE IF NOT EXISTS goals (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            description TEXT,
            target_date TEXT,
            priority TEXT DEFAULT 'medium',
            status TEXT DEFAULT 'active',
            current_progress INTEGER DEFAULT 0,
            target_progress INTEGER DEFAULT 100,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''');

        // mood_entries table
        await db.execute('''
          CREATE TABLE IF NOT EXISTS mood_entries (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            mood INTEGER NOT NULL,
            timestamp TEXT NOT NULL,
            note TEXT,
            activities TEXT,
            created_at TEXT NOT NULL
          )
        ''');

        // projects table
        await db.execute('''
          CREATE TABLE IF NOT EXISTS projects (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            description TEXT,
            status TEXT DEFAULT 'active',
            color INTEGER DEFAULT 0xFF2196F3,
            start_date TEXT,
            end_date TEXT,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''');

        // Create indexes for missing tables
        await db.execute('CREATE INDEX IF NOT EXISTS idx_habits_active ON habits(is_active)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_habit_logs_habit ON habit_logs(habit_id)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_habit_logs_date ON habit_logs(completed_at)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_goals_status ON goals(status)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_mood_entries_date ON mood_entries(timestamp)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_projects_status ON projects(status)');
      }

      // v0.0.39 new features
      if (oldVersion < 39) {
        // daily_digest_ai table
        await db.execute('''
          CREATE TABLE IF NOT EXISTS daily_digest_ai (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            date TEXT NOT NULL UNIQUE,
            summary TEXT NOT NULL DEFAULT '',
            highlights TEXT,
            patterns TEXT,
            insight TEXT,
            record_count INTEGER DEFAULT 0,
            total_minutes INTEGER DEFAULT 0,
            mood_average REAL,
            top_thing_name TEXT,
            top_tags TEXT,
            suggestions TEXT,
            weekly_comparison TEXT,
            streak_days INTEGER,
            created_at TEXT NOT NULL
          )
        ''');

        // daily_digest_ai_config table
        await db.execute('''
          CREATE TABLE IF NOT EXISTS daily_digest_ai_config (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            enabled INTEGER DEFAULT 1,
            generate_time TEXT DEFAULT 'evening',
            include_highlights INTEGER DEFAULT 1,
            include_patterns INTEGER DEFAULT 1,
            include_suggestions INTEGER DEFAULT 1,
            include_comparison INTEGER DEFAULT 1,
            auto_save INTEGER DEFAULT 1
          )
        ''');

        // weekly_digest_ai table
        await db.execute('''
          CREATE TABLE IF NOT EXISTS weekly_digest_ai (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            week_number INTEGER NOT NULL,
            year INTEGER NOT NULL,
            summary TEXT NOT NULL DEFAULT '',
            highlights TEXT,
            activity_breakdown TEXT,
            average_mood REAL,
            total_records INTEGER DEFAULT 0,
            total_minutes INTEGER DEFAULT 0,
            patterns TEXT,
            insight TEXT,
            created_at TEXT NOT NULL
          )
        ''');

        // time_block_predictions table
        await db.execute('''
          CREATE TABLE IF NOT EXISTS time_block_predictions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            hour_start INTEGER NOT NULL,
            hour_end INTEGER NOT NULL,
            activity_type TEXT NOT NULL,
            thing_name TEXT,
            confidence_score REAL DEFAULT 0,
            total_occurrences INTEGER DEFAULT 0,
            avg_duration_minutes INTEGER DEFAULT 0,
            explanation TEXT,
            last_used TEXT,
            created_at TEXT NOT NULL
          )
        ''');

        // prediction_configs table
        await db.execute('''
          CREATE TABLE IF NOT EXISTS prediction_configs (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            enabled INTEGER DEFAULT 1,
            min_sample_size INTEGER DEFAULT 5,
            include_weekends INTEGER DEFAULT 1,
            prediction_days_ahead INTEGER DEFAULT 7,
            auto_schedule INTEGER DEFAULT 0
          )
        ''');

        // tag_merge_suggestions table
        await db.execute('''
          CREATE TABLE IF NOT EXISTS tag_merge_suggestions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            source_tag TEXT NOT NULL,
            target_tag TEXT NOT NULL,
            similarity_score REAL DEFAULT 0,
            shared_record_count INTEGER DEFAULT 0,
            usage_overlap_percent INTEGER,
            reason TEXT,
            is_auto_suggested INTEGER DEFAULT 1,
            is_accepted INTEGER DEFAULT 0,
            created_at TEXT NOT NULL
          )
        ''');

        // tag_groups table
        await db.execute('''
          CREATE TABLE IF NOT EXISTS tag_groups (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            group_name TEXT NOT NULL,
            tags TEXT,
            color TEXT,
            icon TEXT,
            created_at TEXT NOT NULL
          )
        ''');

        // tag_aliases table
        await db.execute('''
          CREATE TABLE IF NOT EXISTS tag_aliases (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            main_tag TEXT NOT NULL,
            aliases TEXT,
            created_at TEXT NOT NULL
          )
        ''');

        // record_quality_scores table
        await db.execute('''
          CREATE TABLE IF NOT EXISTS record_quality_scores (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            record_id INTEGER NOT NULL,
            total_score INTEGER DEFAULT 0,
            completeness_score INTEGER DEFAULT 0,
            detail_score INTEGER DEFAULT 0,
            consistency_score INTEGER DEFAULT 0,
            timeliness_score INTEGER DEFAULT 0,
            suggestions TEXT,
            evaluated_at TEXT NOT NULL
          )
        ''');

        // quality_benchmarks table
        await db.execute('''
          CREATE TABLE IF NOT EXISTS quality_benchmarks (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            period TEXT NOT NULL,
            average_score REAL NOT NULL,
            total_records INTEGER DEFAULT 0,
            calculated_at TEXT NOT NULL
          )
        ''');

        // link_discoveries table
        await db.execute('''
          CREATE TABLE IF NOT EXISTS link_discoveries (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            target_record_id INTEGER NOT NULL,
            linked_records TEXT,
            discovered_at TEXT NOT NULL
          )
        ''');

        // backlink_suggestions table
        await db.execute('''
          CREATE TABLE IF NOT EXISTS backlink_suggestions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            source_record_id INTEGER NOT NULL,
            target_record_id INTEGER NOT NULL,
            reason TEXT NOT NULL,
            relevance_score REAL DEFAULT 0,
            is_ignored INTEGER DEFAULT 0,
            created_at TEXT NOT NULL
          )
        ''');

        // link_networks table
        await db.execute('''
          CREATE TABLE IF NOT EXISTS link_networks (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            central_record_id INTEGER NOT NULL,
            nodes TEXT,
            edges TEXT,
            generated_at TEXT NOT NULL
          )
        ''');

        // recovery_tasks table
        await db.execute('''
          CREATE TABLE IF NOT EXISTS recovery_tasks (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            task_type TEXT NOT NULL,
            status TEXT DEFAULT 'scanning',
            found_items INTEGER DEFAULT 0,
            recovered_items INTEGER DEFAULT 0,
            error_message TEXT,
            started_at TEXT NOT NULL,
            completed_at TEXT
          )
        ''');

        // recoverable_items table
        await db.execute('''
          CREATE TABLE IF NOT EXISTS recoverable_items (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            original_id INTEGER NOT NULL,
            item_type TEXT NOT NULL,
            title TEXT NOT NULL,
            preview TEXT,
            deleted_at TEXT,
            source TEXT,
            recoverability REAL DEFAULT 0
          )
        ''');

        // backup_metadata table
        await db.execute('''
          CREATE TABLE IF NOT EXISTS backup_metadata (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            file_path TEXT NOT NULL,
            created_at TEXT NOT NULL,
            size_bytes INTEGER DEFAULT 0,
            record_count INTEGER DEFAULT 0,
            checksum TEXT,
            is_valid INTEGER DEFAULT 1,
            error_message TEXT
          )
        ''');

        // recognized_patterns table
        await db.execute('''
          CREATE TABLE IF NOT EXISTS recognized_patterns (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            pattern_type TEXT NOT NULL,
            name TEXT NOT NULL,
            description TEXT NOT NULL,
            confidence_score REAL DEFAULT 0,
            occurrences INTEGER DEFAULT 0,
            data TEXT,
            implications TEXT,
            last_detected TEXT NOT NULL,
            created_at TEXT NOT NULL
          )
        ''');

        // pattern_rules table
        await db.execute('''
          CREATE TABLE IF NOT EXISTS pattern_rules (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            pattern_type TEXT NOT NULL,
            condition TEXT NOT NULL,
            action TEXT NOT NULL,
            is_enabled INTEGER DEFAULT 1,
            trigger_count INTEGER DEFAULT 0,
            created_at TEXT NOT NULL
          )
        ''');

        // pattern_insights table
        await db.execute('''
          CREATE TABLE IF NOT EXISTS pattern_insights (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            category TEXT NOT NULL,
            title TEXT NOT NULL,
            content TEXT NOT NULL,
            importance_score REAL DEFAULT 0.5,
            action_items TEXT,
            is_read INTEGER DEFAULT 0,
            generated_at TEXT NOT NULL
          )
        ''');

        // reminder_optimizations table
        await db.execute('''
          CREATE TABLE IF NOT EXISTS reminder_optimizations (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            reminder_id INTEGER NOT NULL,
            suggested_time TEXT NOT NULL,
            suggested_repeat TEXT,
            success_rate_improvement REAL DEFAULT 0,
            reason TEXT,
            is_accepted INTEGER DEFAULT 0,
            created_at TEXT NOT NULL
          )
        ''');

        // optimization_strategies table
        await db.execute('''
          CREATE TABLE IF NOT EXISTS optimization_strategies (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            strategy_name TEXT NOT NULL,
            description TEXT NOT NULL,
            parameters TEXT,
            expected_improvement REAL DEFAULT 0,
            applied_count INTEGER DEFAULT 0,
            is_active INTEGER DEFAULT 1
          )
        ''');

        // reminder_analytics table
        await db.execute('''
          CREATE TABLE IF NOT EXISTS reminder_analytics (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            reminder_id INTEGER NOT NULL,
            total_triggers INTEGER DEFAULT 0,
            successful_triggers INTEGER DEFAULT 0,
            success_rate REAL DEFAULT 0,
            snooze_count INTEGER DEFAULT 0,
            avg_snooze_delay REAL DEFAULT 0,
            best_time TEXT,
            best_day TEXT,
            calculated_at TEXT NOT NULL
          )
        ''');

        // daily_inspirations table
        await db.execute('''
          CREATE TABLE IF NOT EXISTS daily_inspirations (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            date TEXT NOT NULL,
            content TEXT NOT NULL,
            category TEXT DEFAULT 'tip',
            related_actions TEXT,
            is_viewed INTEGER DEFAULT 0,
            created_at TEXT NOT NULL
          )
        ''');

        // inspiration_templates table
        await db.execute('''
          CREATE TABLE IF NOT EXISTS inspiration_templates (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            category TEXT NOT NULL,
            template TEXT NOT NULL,
            variables TEXT,
            usage_count INTEGER DEFAULT 0,
            rating REAL DEFAULT 0
          )
        ''');

        // challenges table
        await db.execute('''
          CREATE TABLE IF NOT EXISTS challenges (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            description TEXT,
            duration_days INTEGER NOT NULL,
            difficulty TEXT DEFAULT 'medium',
            xp_reward INTEGER DEFAULT 10,
            current_progress INTEGER DEFAULT 0,
            is_completed INTEGER DEFAULT 0,
            started_at TEXT NOT NULL,
            completed_at TEXT
          )
        ''');

        // privacy_metrics table
        await db.execute('''
          CREATE TABLE IF NOT EXISTS privacy_metrics (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            metric_type TEXT NOT NULL,
            name TEXT NOT NULL,
            value REAL DEFAULT 0,
            status TEXT DEFAULT 'safe',
            recommendations TEXT,
            calculated_at TEXT NOT NULL
          )
        ''');

        // data_exposure_items table
        await db.execute('''
          CREATE TABLE IF NOT EXISTS data_exposure_items (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            data_type TEXT NOT NULL,
            description TEXT NOT NULL,
            exposure_level TEXT DEFAULT 'private',
            shared_with TEXT,
            is_intentional INTEGER DEFAULT 1,
            last_access TEXT NOT NULL
          )
        ''');

        // privacy_reports table
        await db.execute('''
          CREATE TABLE IF NOT EXISTS privacy_reports (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            period TEXT NOT NULL,
            total_records INTEGER DEFAULT 0,
            exposed_records INTEGER DEFAULT 0,
            exposure_rate REAL DEFAULT 0,
            overall_score TEXT,
            generated_at TEXT NOT NULL
          )
        ''');

        // energy_activity_maps table
        await db.execute('''
          CREATE TABLE IF NOT EXISTS energy_activity_maps (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            activity_type TEXT NOT NULL,
            thing_name TEXT,
            optimal_energy_level INTEGER DEFAULT 3,
            productivity_score REAL DEFAULT 0,
            sample_count INTEGER DEFAULT 0,
            best_time_range TEXT,
            tips TEXT,
            last_updated TEXT NOT NULL
          )
        ''');

        // energy_levels table
        await db.execute('''
          CREATE TABLE IF NOT EXISTS energy_levels (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            level INTEGER NOT NULL,
            label TEXT NOT NULL,
            description TEXT,
            recommended_activities TEXT,
            avoid_activities TEXT
          )
        ''');

        // activity_schedules table
        await db.execute('''
          CREATE TABLE IF NOT EXISTS activity_schedules (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            date TEXT NOT NULL,
            activities TEXT,
            predicted_energy_level REAL DEFAULT 0,
            generated_at TEXT NOT NULL
          )
        ''');

        // Create indexes for v0.0.39 tables
        await db.execute('CREATE INDEX IF NOT EXISTS idx_daily_digest_date ON daily_digest_ai(date)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_weekly_digest_period ON weekly_digest_ai(week_number, year)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_time_predictions_confidence ON time_block_predictions(confidence_score)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_tag_merge_similarity ON tag_merge_suggestions(similarity_score)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_quality_scores_record ON record_quality_scores(record_id)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_link_discoveries_target ON link_discoveries(target_record_id)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_recovery_tasks_status ON recovery_tasks(status)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_patterns_confidence ON recognized_patterns(confidence_score)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_inspirations_date ON daily_inspirations(date)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_privacy_metrics_type ON privacy_metrics(metric_type)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_energy_maps_activity ON energy_activity_maps(activity_type)');
      }

      // v0.0.40 new features
      if (oldVersion < 40) {
        // recurring_tasks table
        await db.execute('''
          CREATE TABLE IF NOT EXISTS recurring_tasks (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            description TEXT,
            repeat_type TEXT NOT NULL DEFAULT 'daily',
            repeat_interval INTEGER DEFAULT 1,
            custom_days TEXT,
            priority INTEGER DEFAULT 2,
            category TEXT,
            estimated_minutes INTEGER DEFAULT 30,
            completed_count INTEGER DEFAULT 0,
            skipped_count INTEGER DEFAULT 0,
            current_streak INTEGER DEFAULT 0,
            best_streak INTEGER DEFAULT 0,
            last_completed_at TEXT,
            next_due_at TEXT,
            is_active INTEGER DEFAULT 1,
            linked_goal_id INTEGER,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''');

        // achievement_badges table
        await db.execute('''
          CREATE TABLE IF NOT EXISTS achievement_badges (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            badge_id TEXT NOT NULL UNIQUE,
            badge_name TEXT NOT NULL,
            badge_type TEXT NOT NULL,
            description TEXT,
            icon TEXT,
            color TEXT,
            requirement_type TEXT,
            requirement_value INTEGER,
            current_progress INTEGER DEFAULT 0,
            is_unlocked INTEGER DEFAULT 0,
            unlocked_at TEXT,
            xp_reward INTEGER DEFAULT 0,
            created_at TEXT NOT NULL
          )
        ''');

        // smart_summaries table
        await db.execute('''
          CREATE TABLE IF NOT EXISTS smart_summaries (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            summary_type TEXT NOT NULL DEFAULT 'daily',
            period_start TEXT NOT NULL,
            period_end TEXT NOT NULL,
            title TEXT,
            content TEXT NOT NULL,
            highlights TEXT,
            insights TEXT,
            record_count INTEGER DEFAULT 0,
            top_things TEXT,
            top_tags TEXT,
            mood_average REAL,
            energy_average REAL,
            is_read INTEGER DEFAULT 0,
            created_at TEXT NOT NULL
          )
        ''');

        // knowledge_entries table
        await db.execute('''
          CREATE TABLE IF NOT EXISTS knowledge_entries (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            content TEXT NOT NULL,
            category TEXT,
            tags TEXT,
            source TEXT,
            use_count INTEGER DEFAULT 0,
            is_favorite INTEGER DEFAULT 0,
            linked_record_ids TEXT,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''');

        // deep_stats_cache table
        await db.execute('''
          CREATE TABLE IF NOT EXISTS deep_stats_cache (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            stats_type TEXT NOT NULL,
            period TEXT NOT NULL,
            period_start TEXT NOT NULL,
            period_end TEXT NOT NULL,
            data_json TEXT NOT NULL,
            computed_at TEXT NOT NULL,
            is_stale INTEGER DEFAULT 0
          )
        ''');

        // quick_recall_entries table
        await db.execute('''
          CREATE TABLE IF NOT EXISTS quick_recall_entries (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            record_id INTEGER NOT NULL,
            recall_type TEXT DEFAULT 'recent',
            importance_score INTEGER DEFAULT 0,
            is_starred INTEGER DEFAULT 0,
            viewed_at TEXT,
            created_at TEXT NOT NULL
          )
        ''');

        // priority_matrix_tasks table
        await db.execute('''
          CREATE TABLE IF NOT EXISTS priority_matrix_tasks (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            description TEXT,
            quadrant TEXT NOT NULL,
            urgency_score INTEGER DEFAULT 0,
            importance_score INTEGER DEFAULT 0,
            estimated_minutes INTEGER DEFAULT 30,
            due_date TEXT,
            status TEXT DEFAULT 'pending',
            linked_record_id INTEGER,
            sort_order INTEGER DEFAULT 0,
            created_at TEXT NOT NULL
          )
        ''');

        // emotion_tags table
        await db.execute('''
          CREATE TABLE IF NOT EXISTS emotion_tags (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            tag_name TEXT NOT NULL,
            tag_type TEXT NOT NULL,
            intensity REAL DEFAULT 1.0,
            emotion_category TEXT,
            occurrence_count INTEGER DEFAULT 0,
            last_used_at TEXT,
            created_at TEXT NOT NULL
          )
        ''');

        // health_metrics table
        await db.execute('''
          CREATE TABLE IF NOT EXISTS health_metrics (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            metric_type TEXT NOT NULL,
            value REAL NOT NULL,
            unit TEXT,
            source TEXT,
            recorded_at TEXT NOT NULL,
            linked_record_ids TEXT,
            note TEXT,
            created_at TEXT NOT NULL
          )
        ''');

        // habit_challenge_participants table
        await db.execute('''
          CREATE TABLE IF NOT EXISTS habit_challenge_participants (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            challenge_id INTEGER NOT NULL,
            habit_title TEXT NOT NULL,
            target_days INTEGER NOT NULL,
            completed_days INTEGER DEFAULT 0,
            start_date TEXT NOT NULL,
            end_date TEXT,
            status TEXT DEFAULT 'active',
            reward_earned INTEGER DEFAULT 0,
            joined_at TEXT NOT NULL
          )
        ''');

        // backup_verification_logs table
        await db.execute('''
          CREATE TABLE IF NOT EXISTS backup_verification_logs (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            backup_id INTEGER NOT NULL,
            verification_status TEXT NOT NULL,
            file_size_bytes INTEGER,
            checksum_verified INTEGER DEFAULT 0,
            data_integrity_score REAL DEFAULT 0,
            issues_found TEXT,
            verified_at TEXT NOT NULL
          )
        ''');

        // focus_training_sessions table
        await db.execute('''
          CREATE TABLE IF NOT EXISTS focus_training_sessions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            training_type TEXT NOT NULL,
            duration_minutes INTEGER NOT NULL,
            score REAL DEFAULT 0,
            difficulty_level INTEGER DEFAULT 1,
            accuracy_rate REAL DEFAULT 0,
            improvement_percent REAL DEFAULT 0,
            completed_at TEXT NOT NULL,
            created_at TEXT NOT NULL
          )
        ''');

        // time_travel_snapshots table
        await db.execute('''
          CREATE TABLE IF NOT EXISTS time_travel_snapshots (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            snapshot_date TEXT NOT NULL,
            snapshot_type TEXT NOT NULL,
            record_count INTEGER DEFAULT 0,
            mood_score INTEGER,
            energy_score INTEGER,
            top_activities TEXT,
            highlights TEXT,
            snapshot_data TEXT NOT NULL,
            created_at TEXT NOT NULL
          )
        ''');

        // Create indexes for v0.0.40 tables
        await db.execute('CREATE INDEX IF NOT EXISTS idx_recurring_tasks_type ON recurring_tasks(repeat_type)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_recurring_tasks_active ON recurring_tasks(is_active)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_achievement_badges_type ON achievement_badges(badge_type)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_achievement_badges_unlocked ON achievement_badges(is_unlocked)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_smart_summaries_type ON smart_summaries(summary_type)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_smart_summaries_period ON smart_summaries(period_start, period_end)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_knowledge_entries_category ON knowledge_entries(category)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_deep_stats_cache_type ON deep_stats_cache(stats_type)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_quick_recall_starred ON quick_recall_entries(is_starred)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_priority_matrix_quadrant ON priority_matrix_tasks(quadrant)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_emotion_tags_category ON emotion_tags(emotion_category)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_health_metrics_type ON health_metrics(metric_type)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_health_metrics_recorded_at ON health_metrics(recorded_at)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_habit_challenge_participants_challenge ON habit_challenge_participants(challenge_id)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_backup_verification_logs_backup ON backup_verification_logs(backup_id)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_focus_training_sessions_type ON focus_training_sessions(training_type)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_time_travel_snapshots_date ON time_travel_snapshots(snapshot_date)');
      }

      // Add missing tables for features that reference them
      if (oldVersion >= 1) {
        // celebrations table
        await db.execute('''
          CREATE TABLE IF NOT EXISTS celebrations (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            description TEXT,
            celebration_type TEXT,
            achieved_at TEXT NOT NULL,
            badge_id TEXT,
            shared INTEGER DEFAULT 0,
            created_at TEXT NOT NULL
          )
        ''');

        // daily_rituals table
        await db.execute('''
          CREATE TABLE IF NOT EXISTS daily_rituals (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            description TEXT,
            time_of_day TEXT NOT NULL,
            icon TEXT,
            order_index INTEGER DEFAULT 0,
            is_active INTEGER DEFAULT 1,
            created_at TEXT NOT NULL
          )
        ''');

        // ritual_completions table
        await db.execute('''
          CREATE TABLE IF NOT EXISTS ritual_completions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            ritual_id INTEGER NOT NULL,
            completed_at TEXT NOT NULL,
            notes TEXT,
            mood_before INTEGER,
            mood_after INTEGER,
            FOREIGN KEY (ritual_id) REFERENCES daily_rituals(id) ON DELETE CASCADE
          )
        ''');

        // daily_scores table
        await db.execute('''
          CREATE TABLE IF NOT EXISTS daily_scores (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            date TEXT NOT NULL UNIQUE,
            productivity_score REAL DEFAULT 0,
            health_score REAL DEFAULT 0,
            mood_score REAL DEFAULT 0,
            social_score REAL DEFAULT 0,
            overall_score REAL DEFAULT 0,
            achievements TEXT,
            note TEXT,
            created_at TEXT NOT NULL
          )
        ''');

        // focus_music_sessions table
        await db.execute('''
          CREATE TABLE IF NOT EXISTS focus_music_sessions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            scene_type TEXT NOT NULL,
            playlist_name TEXT,
            started_at TEXT NOT NULL,
            ended_at TEXT,
            duration_minutes INTEGER DEFAULT 0
          )
        ''');

        // data_integrity_issues table
        await db.execute('''
          CREATE TABLE IF NOT EXISTS data_integrity_issues (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            issue_type TEXT NOT NULL,
            severity TEXT NOT NULL,
            description TEXT NOT NULL,
            record_id TEXT,
            file_path TEXT,
            detected_at TEXT NOT NULL,
            is_resolved INTEGER DEFAULT 0
          )
        ''');

        // cross_feature_insights table
        await db.execute('''
          CREATE TABLE IF NOT EXISTS cross_feature_insights (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            insight_type TEXT NOT NULL,
            title TEXT NOT NULL,
            description TEXT NOT NULL,
            confidence REAL DEFAULT 0,
            data TEXT,
            generated_at TEXT NOT NULL
          )
        ''');

        // sleep_records table
        await db.execute('''
          CREATE TABLE IF NOT EXISTS sleep_records (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            date TEXT NOT NULL UNIQUE,
            duration_minutes INTEGER DEFAULT 0,
            quality INTEGER DEFAULT 3,
            note TEXT,
            created_at TEXT NOT NULL
          )
        ''');

        // daily_routines table
        await db.execute('''
          CREATE TABLE IF NOT EXISTS daily_routines (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            time_slot TEXT NOT NULL,
            duration_minutes INTEGER DEFAULT 30,
            category TEXT,
            is_active INTEGER DEFAULT 1,
            created_at TEXT NOT NULL
          )
        ''');

        // routine_completions table
        await db.execute('''
          CREATE TABLE IF NOT EXISTS routine_completions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            routine_id INTEGER NOT NULL,
            completed_date TEXT NOT NULL,
            completed_at TEXT NOT NULL,
            note TEXT,
            FOREIGN KEY (routine_id) REFERENCES daily_routines(id) ON DELETE CASCADE
          )
        ''');

        // Create indexes for missing tables
        await db.execute('CREATE INDEX IF NOT EXISTS idx_celebrations_achieved_at ON celebrations(achieved_at)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_celebrations_type ON celebrations(celebration_type)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_daily_rituals_order ON daily_rituals(order_index)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_ritual_completions_ritual ON ritual_completions(ritual_id)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_ritual_completions_date ON ritual_completions(completed_at)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_daily_scores_date ON daily_scores(date)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_focus_music_sessions_date ON focus_music_sessions(started_at)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_data_integrity_severity ON data_integrity_issues(severity)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_cross_feature_type ON cross_feature_insights(insight_type)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_sleep_records_date ON sleep_records(date)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_daily_routines_active ON daily_routines(is_active)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_routine_completions_routine ON routine_completions(routine_id)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_routine_completions_date ON routine_completions(completed_date)');
      }

      // v0.0.38 new features
      if (oldVersion < 41) {
        // link_discoveries table - Smart Link Discovery
        await db.execute('''
          CREATE TABLE IF NOT EXISTS link_discoveries (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            record_id_a INTEGER NOT NULL,
            record_id_b INTEGER NOT NULL,
            link_type TEXT NOT NULL,
            confidence_score REAL DEFAULT 0,
            is_accepted INTEGER DEFAULT 0,
            created_at TEXT NOT NULL
          )
        ''');

        // time_fragments table - Time Fragment
        await db.execute('''
          CREATE TABLE IF NOT EXISTS time_fragments (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            content TEXT NOT NULL,
            fragment_type TEXT NOT NULL,
            duration_seconds INTEGER DEFAULT 30,
            audio_path TEXT,
            media_paths TEXT,
            is_converted INTEGER DEFAULT 0,
            linked_record_id INTEGER,
            captured_at TEXT NOT NULL,
            created_at TEXT NOT NULL
          )
        ''');

        // emotion_trail_data table - Emotion Trail
        await db.execute('''
          CREATE TABLE IF NOT EXISTS emotion_trail_data (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            date TEXT NOT NULL,
            emotion_level INTEGER NOT NULL,
            triggers TEXT,
            events TEXT,
            peak_moment TEXT,
            low_moment TEXT,
            note TEXT,
            created_at TEXT NOT NULL
          )
        ''');

        // relationship_graphs table - Relationship Graph
        await db.execute('''
          CREATE TABLE IF NOT EXISTS relationship_graphs (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            person_name TEXT NOT NULL,
            person_type TEXT,
            interaction_count INTEGER DEFAULT 0,
            last_interaction_date TEXT,
            closeness_score REAL DEFAULT 0,
            shared_tags TEXT,
            shared_locations TEXT,
            group_id INTEGER,
            photo_url TEXT,
            note TEXT,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''');

        // location_storylines table - Location Storyline
        await db.execute('''
          CREATE TABLE IF NOT EXISTS location_storylines (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            location_name TEXT NOT NULL,
            latitude REAL,
            longitude REAL,
            visit_count INTEGER DEFAULT 0,
            first_visit_date TEXT,
            last_visit_date TEXT,
            cover_photo_path TEXT,
            story_summary TEXT,
            highlights TEXT,
            created_at TEXT NOT NULL
          )
        ''');

        // tag_recommendation_history table - Smart Tag V2
        await db.execute('''
          CREATE TABLE IF NOT EXISTS tag_recommendation_history (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            record_id INTEGER NOT NULL,
            recommended_tags TEXT,
            selected_tags TEXT,
            confidence_scores TEXT,
            model_version TEXT,
            recommended_at TEXT NOT NULL
          )
        ''');

        // data_quality_scores table - Data Quality Score
        await db.execute('''
          CREATE TABLE IF NOT EXISTS data_quality_scores (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            date TEXT NOT NULL UNIQUE,
            completeness_score REAL DEFAULT 0,
            continuity_score REAL DEFAULT 0,
            depth_score REAL DEFAULT 0,
            relevance_score REAL DEFAULT 0,
            overall_score REAL DEFAULT 0,
            suggestions TEXT,
            created_at TEXT NOT NULL
          )
        ''');

        // milestone_events table - Milestone Review
        await db.execute('''
          CREATE TABLE IF NOT EXISTS milestone_events (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            milestone_type TEXT NOT NULL,
            milestone_value INTEGER NOT NULL,
            record_id INTEGER,
            achieved_at TEXT NOT NULL,
            certificate_path TEXT,
            shared INTEGER DEFAULT 0
          )
        ''');

        // time_allocations table - Time Allocation
        await db.execute('''
          CREATE TABLE IF NOT EXISTS time_allocations (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            date TEXT NOT NULL,
            category TEXT NOT NULL,
            total_minutes INTEGER DEFAULT 0,
            record_count INTEGER DEFAULT 0,
            percentage REAL DEFAULT 0,
            efficiency_score REAL DEFAULT 0,
            created_at TEXT NOT NULL
          )
        ''');

        // template_learning_models table - Template Learning
        await db.execute('''
          CREATE TABLE IF NOT EXISTS template_learning_models (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            model_type TEXT NOT NULL,
            model_data TEXT NOT NULL,
            accuracy_score REAL DEFAULT 0,
            sample_count INTEGER DEFAULT 0,
            last_updated TEXT NOT NULL,
            created_at TEXT NOT NULL
          )
        ''');

        // quick_annotations table - Quick Annotation
        await db.execute('''
          CREATE TABLE IF NOT EXISTS quick_annotations (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            record_id INTEGER NOT NULL,
            annotation_type TEXT NOT NULL,
            annotation_value TEXT,
            created_at TEXT NOT NULL
          )
        ''');

        // reminder_optimizations table - Reminder Optimizer
        await db.execute('''
          CREATE TABLE IF NOT EXISTS reminder_optimizations (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            reminder_id INTEGER,
            optimal_time TEXT,
            optimal_frequency TEXT,
            success_rate REAL DEFAULT 0,
            based_on_samples INTEGER DEFAULT 0,
            optimized_at TEXT NOT NULL
          )
        ''');

        // record_influence_links table - Record Influence
        await db.execute('''
          CREATE TABLE IF NOT EXISTS record_influence_links (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            source_record_id INTEGER NOT NULL,
            target_record_id INTEGER NOT NULL,
            influence_type TEXT NOT NULL,
            influence_strength REAL DEFAULT 0,
            created_at TEXT NOT NULL
          )
        ''');

        // search_enhancements table - Smart Search Enhanced
        await db.execute('''
          CREATE TABLE IF NOT EXISTS search_enhancements (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            query TEXT NOT NULL,
            semantic_expansion TEXT,
            result_count INTEGER DEFAULT 0,
            clicked_record_id INTEGER,
            search_time TEXT NOT NULL
          )
        ''');

        // record_favorite_groups table - Record Favorites
        await db.execute('''
          CREATE TABLE IF NOT EXISTS record_favorite_groups (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            description TEXT,
            icon TEXT,
            color TEXT,
            sort_order INTEGER DEFAULT 0,
            auto_rules TEXT,
            created_at TEXT NOT NULL
          )
        ''');

// Create indexes for v0.0.38 tables
        await db.execute('CREATE INDEX IF NOT EXISTS idx_link_discoveries_confidence ON link_discoveries(confidence_score)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_time_fragments_converted ON time_fragments(is_converted)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_emotion_trail_date ON emotion_trail_data(date)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_relationship_graphs_closeness ON relationship_graphs(closeness_score)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_location_storylines_visits ON location_storylines(visit_count)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_data_quality_date ON data_quality_scores(date)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_milestone_achieved ON milestone_events(achieved_at)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_time_allocations_date ON time_allocations(date)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_quick_annotations_record ON quick_annotations(record_id)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_record_influence_source ON record_influence_links(source_record_id)');
      }

      // v0.0.42 new features (v0.0.39 in features, but 42 in database for versioning alignment)
      if (oldVersion < 42) {
        // smart_micro_captures table - Smart Micro Capture
        await db.execute('''
          CREATE TABLE IF NOT EXISTS smart_micro_captures (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            content TEXT NOT NULL,
            capture_type TEXT DEFAULT 'quick',
            duration_sec INTEGER DEFAULT 0,
            suggested_tags TEXT,
            suggested_category TEXT,
            is_converted INTEGER DEFAULT 0,
            converted_record_id INTEGER,
            created_at TEXT NOT NULL
          )
        ''');

        // emotion_energy_logs table - Emotion Energy Timeline
        await db.execute('''
          CREATE TABLE IF NOT EXISTS emotion_energy_logs (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            log_date TEXT NOT NULL,
            work_score INTEGER DEFAULT 50,
            life_score INTEGER DEFAULT 50,
            health_score INTEGER DEFAULT 50,
            relationship_score INTEGER DEFAULT 50,
            creativity_score INTEGER DEFAULT 50,
            overall_score REAL DEFAULT 50,
            triggers TEXT,
            note TEXT,
            created_at TEXT NOT NULL
          )
        ''');

        // habit_analysis table - Habit Success Rate
        await db.execute('''
          CREATE TABLE IF NOT EXISTS habit_analysis (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            habit_id INTEGER NOT NULL,
            analysis_type TEXT NOT NULL,
            success_rate REAL DEFAULT 0,
            best_time TEXT,
            failure_pattern TEXT,
            prediction_days INTEGER DEFAULT 0,
            created_at TEXT NOT NULL
          )
        ''');

        // record_associations table - Cross Record Association
        await db.execute('''
          CREATE TABLE IF NOT EXISTS record_associations (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            source_record_id INTEGER NOT NULL,
            target_record_id INTEGER NOT NULL,
            association_type TEXT DEFAULT 'auto',
            strength_score REAL DEFAULT 0,
            association_basis TEXT,
            created_at TEXT NOT NULL
          )
        ''');

        // smart_summaries table (enhanced)
        await db.execute('''
          CREATE TABLE IF NOT EXISTS smart_summaries (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            summary_date TEXT NOT NULL,
            summary_type TEXT DEFAULT 'daily',
            highlights TEXT,
            patterns TEXT,
            productivity_score REAL DEFAULT 0,
            mood_average REAL DEFAULT 50,
            insights TEXT,
            record_count INTEGER DEFAULT 0,
            total_minutes INTEGER DEFAULT 0,
            created_at TEXT NOT NULL
          )
        ''');

        // growth_pathways table - Growth Pathway
        await db.execute('''
          CREATE TABLE IF NOT EXISTS growth_pathways (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            pathway_name TEXT NOT NULL,
            category TEXT NOT NULL,
            start_date TEXT,
            current_progress REAL DEFAULT 0,
            milestones TEXT,
            velocity_score REAL DEFAULT 0,
            created_at TEXT NOT NULL
          )
        ''');

        // search_enhancements table (enhanced)
        await db.execute('''
          CREATE TABLE IF NOT EXISTS search_enhancements (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            query TEXT NOT NULL,
            corrected_query TEXT,
            result_count INTEGER DEFAULT 0,
            search_type TEXT DEFAULT 'standard',
            created_at TEXT NOT NULL
          )
        ''');

        // quick_notes table - Quick Note Overlay
        await db.execute('''
          CREATE TABLE IF NOT EXISTS quick_notes (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            record_id INTEGER NOT NULL,
            note_content TEXT,
            note_type TEXT DEFAULT 'emoji',
            created_at TEXT NOT NULL
          )
        ''');

        // data_health_metrics table - Data Health Dashboard
        await db.execute('''
          CREATE TABLE IF NOT EXISTS data_health_metrics (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            metric_type TEXT NOT NULL,
            metric_value REAL DEFAULT 0,
            issues_count INTEGER DEFAULT 0,
            health_score REAL DEFAULT 100,
            created_at TEXT NOT NULL
          )
        ''');

        // reminder_optimizations table (enhanced)
        await db.execute('''
          CREATE TABLE IF NOT EXISTS reminder_optimizations (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            reminder_id INTEGER,
            original_time TEXT,
            optimized_time TEXT,
            response_rate REAL DEFAULT 0,
            optimization_reason TEXT,
            applied_at TEXT,
            created_at TEXT NOT NULL
          )
        ''');

        // place_timelines table - Place Memory Timeline
        await db.execute('''
          CREATE TABLE IF NOT EXISTS place_timelines (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            place_name TEXT NOT NULL,
            visit_date TEXT NOT NULL,
            visit_records TEXT,
            memory_content TEXT,
            emotion_score INTEGER DEFAULT 50,
            photo_paths TEXT,
            created_at TEXT NOT NULL
          )
        ''');

        // record_impact_links table - Record Impact Tracker
        await db.execute('''
          CREATE TABLE IF NOT EXISTS record_impact_links (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            source_record_id INTEGER NOT NULL,
            target_record_id INTEGER,
            action_type TEXT NOT NULL,
            impact_score REAL DEFAULT 0,
            created_at TEXT NOT NULL
          )
        ''');

        // dashboard_configs table - Multi Dashboard Builder
        await db.execute('''
          CREATE TABLE IF NOT EXISTS dashboard_configs (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            config_name TEXT NOT NULL,
            layout_json TEXT,
            chart_types TEXT,
            data_sources TEXT,
            is_default INTEGER DEFAULT 0,
            created_at TEXT NOT NULL
          )
        ''');

        // template_recommendations table - Intelligent Template Recommendation
        await db.execute('''
          CREATE TABLE IF NOT EXISTS template_recommendations (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            template_name TEXT NOT NULL,
            recommendation_reason TEXT,
            confidence_score REAL DEFAULT 0,
            usage_context TEXT,
            suggested_tags TEXT,
            use_count INTEGER DEFAULT 0,
            created_at TEXT NOT NULL
          )
        ''');

        // Create indexes for v0.0.42 tables
        await db.execute('CREATE INDEX IF NOT EXISTS idx_smart_micro_captures_converted ON smart_micro_captures(is_converted)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_emotion_energy_date ON emotion_energy_logs(log_date)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_habit_analysis_habit ON habit_analysis(habit_id)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_record_associations_source ON record_associations(source_record_id)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_record_associations_target ON record_associations(target_record_id)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_smart_summaries_date ON smart_summaries(summary_date)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_growth_pathways_category ON growth_pathways(category)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_quick_notes_record ON quick_notes(record_id)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_data_health_type ON data_health_metrics(metric_type)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_reminder_optimizations_response ON reminder_optimizations(response_rate)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_place_timelines_place ON place_timelines(place_name)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_place_timelines_date ON place_timelines(visit_date)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_record_impact_source ON record_impact_links(source_record_id)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_dashboard_configs_default ON dashboard_configs(is_default)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_template_recommendations_confidence ON template_recommendations(confidence_score)');
      }

      // v0.0.39 new features - smart habit scheduling, cross device sync, mood music, etc.
      if (oldVersion < 39) {
        // smart_habit_schedules table - Smart Habit Scheduling
        await db.execute('''
          CREATE TABLE IF NOT EXISTS smart_habit_schedules (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            habit_id INTEGER NOT NULL,
            scheduled_hour INTEGER,
            scheduled_minute INTEGER,
            priority INTEGER DEFAULT 1,
            energy_level_needed INTEGER,
            is_enabled INTEGER DEFAULT 1,
            last_executed TEXT,
            success_count INTEGER DEFAULT 0,
            created_at TEXT NOT NULL
          )
        ''');

        // device_sync_state table - Cross Device Sync
        await db.execute('''
          CREATE TABLE IF NOT EXISTS device_sync_state (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            device_id TEXT NOT NULL UNIQUE,
            last_sync_time TEXT NOT NULL,
            sync_version INTEGER DEFAULT 0,
            pending_changes INTEGER DEFAULT 0,
            status TEXT DEFAULT 'active'
          )
        ''');

        // mood_music_playlists table - Mood Music Recommendation
        await db.execute('''
          CREATE TABLE IF NOT EXISTS mood_music_playlists (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            mood_type TEXT NOT NULL,
            playlist_name TEXT NOT NULL,
            track_uris TEXT,
            use_count INTEGER DEFAULT 0,
            created_at TEXT NOT NULL
          )
        ''');

        // focus_breathing_sessions table - Focus Breathing
        await db.execute('''
          CREATE TABLE IF NOT EXISTS breathing_sessions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            session_type TEXT NOT NULL,
            duration_seconds INTEGER DEFAULT 0,
            completed INTEGER DEFAULT 0,
            started_at TEXT NOT NULL,
            ended_at TEXT
          )
        ''');

        // weekly_goals_v2 table - Weekly Goal Reset
        await db.execute('''
          CREATE TABLE IF NOT EXISTS weekly_goals (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            week_start TEXT NOT NULL,
            goal_title TEXT NOT NULL,
            target_value REAL,
            current_value REAL DEFAULT 0,
            is_completed INTEGER DEFAULT 0,
            is_reset INTEGER DEFAULT 0,
            created_at TEXT NOT NULL
          )
        ''');

        // habit_chains table - Habit Chaining
        await db.execute('''
          CREATE TABLE IF NOT EXISTS habit_chains (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            chain_name TEXT NOT NULL,
            habit_ids TEXT NOT NULL,
            chain_type TEXT DEFAULT 'time',
            completion_count INTEGER DEFAULT 0,
            success_rate REAL DEFAULT 0,
            created_at TEXT NOT NULL
          )
        ''');

        // energy_mood_correlations table - Energy Mood Correlation
        await db.execute('''
          CREATE TABLE IF NOT EXISTS energy_mood_correlations (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            date TEXT NOT NULL,
            energy_level INTEGER,
            mood_level INTEGER,
            activity_type TEXT,
            correlation_score REAL DEFAULT 0,
            created_at TEXT NOT NULL
          )
        ''');

        // notification_timing_rules table - Smart Notification Timing
        await db.execute('''
          CREATE TABLE IF NOT EXISTS notification_timing_rules (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            notification_type TEXT NOT NULL,
            optimal_hour INTEGER,
            optimal_minute INTEGER,
            day_of_week TEXT,
            response_rate REAL DEFAULT 0,
            sample_count INTEGER DEFAULT 0,
            last_updated TEXT
          )
        ''');

        // focus_achievements table - Focus Sharing
        await db.execute('''
          CREATE TABLE IF NOT EXISTS focus_achievements (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            achievement_type TEXT NOT NULL,
            title TEXT NOT NULL,
            description TEXT,
            target_minutes INTEGER,
            badge_icon TEXT,
            is_unlocked INTEGER DEFAULT 0,
            unlocked_at TEXT,
            share_count INTEGER DEFAULT 0,
            created_at TEXT NOT NULL
          )
        ''');

        // daily_challenges table - Daily Achievements
        await db.execute('''
          CREATE TABLE IF NOT EXISTS daily_challenges (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            challenge_date TEXT NOT NULL UNIQUE,
            challenge_type TEXT NOT NULL,
            title TEXT NOT NULL,
            description TEXT,
            target_value INTEGER,
            current_value INTEGER DEFAULT 0,
            xp_reward INTEGER DEFAULT 10,
            is_completed INTEGER DEFAULT 0,
            created_at TEXT NOT NULL
          )
        ''');

        // weekly_insights table - Weekly Insights Card
        await db.execute('''
          CREATE TABLE IF NOT EXISTS weekly_insights (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            week_start TEXT NOT NULL,
            week_end TEXT NOT NULL,
            record_count INTEGER DEFAULT 0,
            habit_completion_rate REAL DEFAULT 0,
            average_energy REAL,
            average_mood REAL,
            highlights_json TEXT,
            suggestions TEXT,
            created_at TEXT NOT NULL
          )
        ''');

        // Create indexes for v0.0.39 tables
        await db.execute('CREATE INDEX IF NOT EXISTS idx_smart_habit_schedules_habit ON smart_habit_schedules(habit_id)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_device_sync_last_time ON device_sync_state(last_sync_time)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_location_routines_enabled ON location_routines(is_enabled)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_energy_mood_date ON energy_mood_correlations(date)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_notification_timing_type ON notification_timing_rules(notification_type)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_daily_challenges_date ON daily_challenges(challenge_date)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_weekly_insights_week ON weekly_insights(week_start)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_breathing_sessions_date ON breathing_sessions(started_at)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_habit_chains_completion ON habit_chains(completion_count)');
      }

      // ============ v0.0.44 Upgrade - thing_note v0.0.40 ============
      if (oldVersion < 44) {
        // smart_note_links table - Smart Note Linking
        await db.execute('''
          CREATE TABLE IF NOT EXISTS smart_note_links (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            source_note_id INTEGER NOT NULL,
            target_record_id INTEGER NOT NULL,
            link_type TEXT DEFAULT 'auto',
            strength_score REAL DEFAULT 0,
            link_basis TEXT,
            created_at TEXT NOT NULL
          )
        ''');

        // focus_session_analytics table - Focus Session Analytics
        await db.execute('''
          CREATE TABLE IF NOT EXISTS focus_session_analytics (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            session_id INTEGER NOT NULL,
            analysis_type TEXT NOT NULL,
            distraction_pattern TEXT,
            efficiency_score REAL DEFAULT 0,
            best_focus_period TEXT,
            suggestions TEXT,
            created_at TEXT NOT NULL
          )
        ''');

        // habit_templates table - Habit Template Marketplace
        await db.execute('''
          CREATE TABLE IF NOT EXISTS habit_templates (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            template_name TEXT NOT NULL,
            category TEXT NOT NULL,
            description TEXT,
            habit_config TEXT,
            use_count INTEGER DEFAULT 0,
            rating REAL DEFAULT 0,
            is_published INTEGER DEFAULT 0,
            created_at TEXT NOT NULL
          )
        ''');

        // daily_quotes table - Daily Quote
        await db.execute('''
          CREATE TABLE IF NOT EXISTS daily_quotes (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            quote_text TEXT NOT NULL,
            author TEXT,
            category TEXT DEFAULT 'inspiration',
            action_suggestion TEXT,
            is_favorite INTEGER DEFAULT 0,
            created_at TEXT NOT NULL
          )
        ''');

        // activity_correlations table - Activity Correlation Engine
        await db.execute('''
          CREATE TABLE IF NOT EXISTS activity_correlations (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            activity_name TEXT NOT NULL,
            result_metric TEXT NOT NULL,
            correlation_score REAL DEFAULT 0,
            sample_count INTEGER DEFAULT 0,
            confidence_level REAL DEFAULT 0,
            last_updated TEXT NOT NULL,
            created_at TEXT NOT NULL
          )
        ''');

        // goal_milestones table - Goal Milestone Alerts
        await db.execute('''
          CREATE TABLE IF NOT EXISTS goal_milestones (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            goal_id INTEGER NOT NULL,
            milestone_type TEXT NOT NULL,
            milestone_value REAL NOT NULL,
            achieved_at TEXT,
            is_celebrated INTEGER DEFAULT 0,
            celebration_note TEXT,
            created_at TEXT NOT NULL
          )
        ''');

        // smart_search_configs table - Smart Search Filters
        await db.execute('''
          CREATE TABLE IF NOT EXISTS smart_search_configs (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            config_key TEXT NOT NULL UNIQUE,
            config_value TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''');

        // daily_progress_snapshots table - Daily Progress Snapshot
        await db.execute('''
          CREATE TABLE IF NOT EXISTS daily_progress_snapshots (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            snapshot_date TEXT NOT NULL UNIQUE,
            completed_items INTEGER DEFAULT 0,
            total_items INTEGER DEFAULT 0,
            progress_percent REAL DEFAULT 0,
            highlights TEXT,
            week_comparison TEXT,
            created_at TEXT NOT NULL
          )
        ''');

        // mood_patterns table - Mood Pattern Detection
        await db.execute('''
          CREATE TABLE IF NOT EXISTS mood_patterns (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            pattern_type TEXT NOT NULL,
            pattern_data TEXT,
            trigger_factors TEXT,
            confidence_score REAL DEFAULT 0,
            first_detected TEXT,
            last_occurred TEXT,
            occurrence_count INTEGER DEFAULT 0,
            created_at TEXT NOT NULL
          )
        ''');

        // quick_access_items table - Quick Access Bar
        await db.execute('''
          CREATE TABLE IF NOT EXISTS quick_access_items (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            item_type TEXT NOT NULL,
            item_name TEXT NOT NULL,
            icon TEXT,
            action_config TEXT,
            sort_order INTEGER DEFAULT 0,
            use_count INTEGER DEFAULT 0,
            is_enabled INTEGER DEFAULT 1,
            created_at TEXT NOT NULL
          )
        ''');

        // record_versions table - Record Version History
        await db.execute('''
          CREATE TABLE IF NOT EXISTS record_versions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            record_id INTEGER NOT NULL,
            version_number INTEGER DEFAULT 1,
            version_data TEXT NOT NULL,
            change_summary TEXT,
            created_at TEXT NOT NULL
          )
        ''');

        // weekly_themes table - Weekly Theme Suggestions
        await db.execute('''
          CREATE TABLE IF NOT EXISTS weekly_themes (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            theme_name TEXT NOT NULL,
            color_scheme TEXT,
            background_image TEXT,
            start_date TEXT NOT NULL,
            end_date TEXT,
            is_active INTEGER DEFAULT 0,
            created_at TEXT NOT NULL
          )
        ''');

        // Create indexes for v0.0.44 tables
        await db.execute('CREATE INDEX IF NOT EXISTS idx_smart_note_links_source ON smart_note_links(source_note_id)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_smart_note_links_target ON smart_note_links(target_record_id)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_focus_analytics_session ON focus_session_analytics(session_id)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_habit_templates_category ON habit_templates(category)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_daily_quotes_category ON daily_quotes(category)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_activity_correlations_activity ON activity_correlations(activity_name)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_goal_milestones_goal ON goal_milestones(goal_id)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_daily_snapshots_date ON daily_progress_snapshots(snapshot_date)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_mood_patterns_type ON mood_patterns(pattern_type)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_quick_access_sort ON quick_access_items(sort_order)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_record_versions_record ON record_versions(record_id)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_weekly_themes_active ON weekly_themes(is_active)');
      }

      // ============ v0.0.45 Upgrade - thing_note v0.0.41 ============
      if (oldVersion < 45) {
        // vision_boards table - Daily Vision Board
        await db.execute('''
          CREATE TABLE IF NOT EXISTS vision_boards (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            board_name TEXT NOT NULL,
            description TEXT,
            image_path TEXT,
            goal_type TEXT,
            target_date TEXT,
            is_active INTEGER DEFAULT 1,
            created_at TEXT NOT NULL
          )
        ''');

        // vision_board_items table
        await db.execute('''
          CREATE TABLE IF NOT EXISTS vision_board_items (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            board_id INTEGER NOT NULL,
            item_type TEXT NOT NULL,
            content TEXT NOT NULL,
            image_path TEXT,
            position_x INTEGER DEFAULT 0,
            position_y INTEGER DEFAULT 0,
            sort_order INTEGER DEFAULT 0,
            created_at TEXT NOT NULL,
            FOREIGN KEY (board_id) REFERENCES vision_boards(id) ON DELETE CASCADE
          )
        ''');

        // skill_progress table - Skill Development Tracker
        await db.execute('''
          CREATE TABLE IF NOT EXISTS skill_progress (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            skill_name TEXT NOT NULL,
            category TEXT,
            current_level TEXT DEFAULT 'beginner',
            target_level TEXT,
            total_hours REAL DEFAULT 0,
            certification_name TEXT,
            certification_date TEXT,
            provider TEXT,
            is_active INTEGER DEFAULT 1,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''');

        // skill_sessions_v2 table
        await db.execute('''
          CREATE TABLE IF NOT EXISTS skill_sessions_v2 (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            skill_id INTEGER NOT NULL,
            duration_minutes INTEGER NOT NULL,
            practice_type TEXT,
            notes TEXT,
            rating INTEGER DEFAULT 3,
            session_date TEXT NOT NULL,
            linked_record_id INTEGER,
            created_at TEXT NOT NULL,
            FOREIGN KEY (skill_id) REFERENCES skill_progress(id) ON DELETE CASCADE
          )
        ''');

        // break_reminders table - Break Reminder System
        await db.execute('''
          CREATE TABLE IF NOT EXISTS break_reminders (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            focus_session_id INTEGER,
            break_type TEXT DEFAULT 'short',
            duration_minutes INTEGER DEFAULT 5,
            suggested_activity TEXT,
            completed INTEGER DEFAULT 0,
            started_at TEXT NOT NULL,
            ended_at TEXT,
            created_at TEXT NOT NULL
          )
        ''');

        // moment_captures table - Moment Capture
        await db.execute('''
          CREATE TABLE IF NOT EXISTS moment_captures (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            content TEXT NOT NULL,
            capture_type TEXT DEFAULT 'thought',
            mood_level INTEGER,
            tags TEXT,
            media_paths TEXT,
            is_converted INTEGER DEFAULT 0,
            linked_record_id INTEGER,
            captured_at TEXT NOT NULL,
            created_at TEXT NOT NULL
          )
        ''');

        // habit_layers table - Habit Layering/Stacking
        await db.execute('''
          CREATE TABLE IF NOT EXISTS habit_layers (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            chain_name TEXT NOT NULL,
            description TEXT,
            base_habit_id INTEGER NOT NULL,
            layered_habit_name TEXT NOT NULL,
            completion_trigger TEXT DEFAULT 'after',
            current_streak INTEGER DEFAULT 0,
            best_streak INTEGER DEFAULT 0,
            is_active INTEGER DEFAULT 1,
            created_at TEXT NOT NULL
          )
        ''');

        // weather_logs table - Weather Auto-Log
        await db.execute('''
          CREATE TABLE IF NOT EXISTS weather_logs (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            recorded_at TEXT NOT NULL,
            temperature REAL,
            humidity REAL,
            weather_condition TEXT,
            aqi INTEGER,
            location_name TEXT,
            latitude REAL,
            longitude REAL,
            note TEXT,
            created_at TEXT NOT NULL
          )
        ''');

        // weekly_focus_challenges table - Weekly Focus Mode
        await db.execute('''
          CREATE TABLE IF NOT EXISTS weekly_focus_challenges (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            week_start TEXT NOT NULL,
            challenge_title TEXT NOT NULL,
            theme TEXT,
            focus_area TEXT,
            target_hours REAL DEFAULT 0,
            achieved_hours REAL DEFAULT 0,
            target_sessions INTEGER DEFAULT 0,
            achieved_sessions INTEGER DEFAULT 0,
            status TEXT DEFAULT 'active',
            completion_note TEXT,
            created_at TEXT NOT NULL
          )
        ''');

        // quick_stats_widget_configs table - Quick Stats Widget
        await db.execute('''
          CREATE TABLE IF NOT EXISTS quick_stats_widget_configs (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            widget_name TEXT NOT NULL,
            stat_types TEXT NOT NULL,
            layout_style TEXT DEFAULT 'compact',
            refresh_interval INTEGER DEFAULT 60,
            is_enabled INTEGER DEFAULT 1,
            created_at TEXT NOT NULL
          )
        ''');

        // export_formats table - Data Export Formats
        await db.execute('''
          CREATE TABLE IF NOT EXISTS export_formats (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            format_type TEXT NOT NULL,
            format_name TEXT NOT NULL,
            file_extension TEXT NOT NULL,
            config_json TEXT,
            use_count INTEGER DEFAULT 0,
            is_favorite INTEGER DEFAULT 0,
            created_at TEXT NOT NULL
          )
        ''');

        // link_previews table - Link Preview Auto-fetch
        await db.execute('''
          CREATE TABLE IF NOT EXISTS link_previews (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            url TEXT NOT NULL,
            title TEXT,
            description TEXT,
            image_url TEXT,
            site_name TEXT,
            fetched_at TEXT,
            created_at TEXT NOT NULL
          )
        ''');

        // focus_music_playlists table - Focus Music Player
        await db.execute('''
          CREATE TABLE IF NOT EXISTS focus_music_playlists (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            playlist_name TEXT NOT NULL,
            music_style TEXT,
            track_list TEXT,
            track_count INTEGER DEFAULT 0,
            is_active INTEGER DEFAULT 0,
            use_count INTEGER DEFAULT 0,
            created_at TEXT NOT NULL
          )
        ''');

        // celebration_events table - Achievement Celebrations
        await db.execute('''
          CREATE TABLE IF NOT EXISTS celebration_events (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            event_type TEXT NOT NULL,
            title TEXT NOT NULL,
            description TEXT,
            celebration_style TEXT DEFAULT 'confetti',
            triggered_by TEXT,
            trigger_id INTEGER,
            triggered_at TEXT NOT NULL,
            is_displayed INTEGER DEFAULT 1,
            created_at TEXT NOT NULL
          )
        ''');

        // quick_mood_checkins table - Quick Mood Check-in
        await db.execute('''
          CREATE TABLE IF NOT EXISTS quick_mood_checkins (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            mood_level INTEGER NOT NULL,
            mood_category TEXT,
            quick_note TEXT,
            energy_level INTEGER,
            checkin_time TEXT NOT NULL,
            linked_record_id INTEGER,
            created_at TEXT NOT NULL
          )
        ''');

        // Create indexes for v0.0.45 tables
        await db.execute('CREATE INDEX IF NOT EXISTS idx_vision_boards_active ON vision_boards(is_active)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_vision_board_items_board ON vision_board_items(board_id)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_skill_progress_category ON skill_progress(category)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_skill_sessions_v2_date ON skill_sessions_v2(session_date)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_break_reminders_session ON break_reminders(focus_session_id)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_moment_captures_converted ON moment_captures(is_converted)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_habit_layers_active ON habit_layers(is_active)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_weather_logs_date ON weather_logs(recorded_at)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_weekly_focus_status ON weekly_focus_challenges(status)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_export_formats_type ON export_formats(format_type)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_link_previews_url ON link_previews(url)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_celebration_events_triggered ON celebration_events(triggered_at)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_quick_mood_date ON quick_mood_checkins(checkin_time)');
      }
    },
  );
  } catch (e) {
    print('Database open failed, attempting recovery: $e');
    try {
      await deleteDatabase(path);
      return openDatabase(
        path,
        version: 45,
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
        onUpgrade: (db, oldVersion, newVersion) async {},
      );
    } catch (e2) {
      print('Database recovery failed: $e2');
      rethrow;
    }
  }
});
