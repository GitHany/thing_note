import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:thing_note/features/record/presentation/record_list_screen.dart';
import 'package:thing_note/features/record/presentation/record_form_screen.dart';
import 'package:thing_note/features/record/presentation/record_detail_screen.dart';
import 'package:thing_note/features/settings/presentation/settings_screen.dart';
import 'package:thing_note/features/thing_name/presentation/thing_name_manage_screen.dart';
import 'package:thing_note/features/thing_name/presentation/thing_name_detail_screen.dart';
import 'package:thing_note/features/export/presentation/backup_list_screen.dart';
import 'package:thing_note/features/tag/presentation/tag_list_screen.dart';
import 'package:thing_note/features/tag/presentation/tag_edit_screen.dart';
import 'package:thing_note/features/statistics/presentation/statistics_screen.dart';
import 'package:thing_note/features/timeline/presentation/timeline_screen.dart';
import 'package:thing_note/features/search/presentation/search_results_screen.dart';
import 'package:thing_note/features/calendar/presentation/calendar_screen.dart';
import 'package:thing_note/features/sync/presentation/sync_settings_screen.dart';
import 'package:thing_note/features/smart_reminder/presentation/smart_reminder_screen.dart';
import 'package:thing_note/features/chart/presentation/chart_screen.dart';
import 'package:thing_note/features/batch/presentation/batch_operation_screen.dart';
import 'package:thing_note/features/analytics/presentation/usage_insights_screen.dart';
import 'package:thing_note/features/backup/presentation/enhanced_backup_screen.dart';
import 'package:thing_note/features/goal/presentation/goals_screen.dart';
import 'package:thing_note/features/mood/presentation/mood_screen.dart';
import 'package:thing_note/features/habit/presentation/habit_screen.dart';
import 'package:thing_note/features/project/presentation/project_screen.dart';
import 'package:thing_note/features/notification_center/presentation/notification_center_screen.dart';
import 'package:thing_note/features/importer/presentation/importer_screen.dart';
import 'package:thing_note/features/report/presentation/report_screen.dart';
import 'package:thing_note/features/custom_theme/domain/custom_theme_service.dart';
import 'package:thing_note/features/quick_note/presentation/quick_notes_screen.dart';
import 'package:thing_note/features/collection/presentation/collections_screen.dart';
import 'package:thing_note/features/reminder_prediction/presentation/reminder_prediction_screen.dart';
import 'package:thing_note/features/dashboard/presentation/dashboard_screen.dart';
import 'package:thing_note/features/voice_recorder/presentation/voice_recorder_screen.dart';
import 'package:thing_note/features/ai_assistant/presentation/ai_assistant_screen.dart';
import 'package:thing_note/features/auto_report/presentation/auto_report_screen.dart';
import 'package:thing_note/features/data_encryption/presentation/encryption_settings_screen.dart';
import 'package:thing_note/features/hotspot_analysis/presentation/hotspot_analysis_screen.dart';
import 'package:thing_note/features/file_manager/presentation/file_manager_screen.dart';
import 'package:thing_note/features/privacy_mode/presentation/privacy_mode_screen.dart';
import 'package:thing_note/features/satisfaction_survey/presentation/satisfaction_survey_screen.dart';
import 'package:thing_note/features/workflow_automation/presentation/workflow_automation_screen.dart';
import 'package:thing_note/features/media_compressor/presentation/media_compressor_screen.dart';
import 'package:thing_note/features/smart_sort/presentation/smart_sort_screen.dart';
import 'package:thing_note/features/data_health_check/presentation/data_health_check_screen.dart';
import 'package:thing_note/features/data_health_dashboard/presentation/data_health_dashboard_screen.dart';
import 'package:thing_note/features/keyboard_shortcuts/presentation/keyboard_shortcuts_screen.dart';
import 'package:thing_note/features/journal/presentation/journal_screen.dart';
import 'package:thing_note/features/geofence/presentation/geofence_screen.dart';
import 'package:thing_note/features/flashcard/presentation/flashcard_screen.dart';
import 'package:thing_note/features/ocr/presentation/ocr_screen.dart';
import 'package:thing_note/features/timeline_enhanced/presentation/timeline_enhanced_screen.dart';
import 'package:thing_note/features/auto_summary/presentation/auto_summary_screen.dart';
import 'package:thing_note/features/tag_hierarchy/presentation/tag_hierarchy_screen.dart';
import 'package:thing_note/features/task_dependency/presentation/task_dependency_screen.dart';
import 'package:thing_note/features/place/presentation/place_screen.dart';
import 'package:thing_note/features/share_external/presentation/share_external_screen.dart';
import 'package:thing_note/features/time_block/presentation/time_block_screen.dart';
import 'package:thing_note/features/home_widget/presentation/home_widget_screen.dart';
import 'package:thing_note/features/voice_note/presentation/voice_note_screen.dart';
import 'package:thing_note/features/daily_planner/presentation/daily_planner_screen.dart';
import 'package:thing_note/features/focus_mode/presentation/focus_mode_screen.dart';
import 'package:thing_note/features/weekly_review/presentation/weekly_review_screen.dart';
import 'package:thing_note/features/budget_tracker/presentation/budget_tracker_screen.dart';
import 'package:thing_note/features/sleep_tracker/presentation/sleep_tracker_screen.dart';
import 'package:thing_note/features/reading_list/presentation/reading_list_screen.dart';
import 'package:thing_note/features/link_saver/presentation/link_saver_screen.dart';
import 'package:thing_note/features/recipe_manager/presentation/recipe_manager_screen.dart';
import 'package:thing_note/features/meeting_assistant/presentation/meeting_assistant_screen.dart';
import 'package:thing_note/features/mood_boost/presentation/mood_boost_screen.dart';
import 'package:thing_note/features/voice_tag/presentation/voice_tag_screen.dart';
import 'package:thing_note/features/custom_dashboard/presentation/custom_dashboard_screen.dart';
import 'package:thing_note/features/event_reminder/presentation/event_reminder_screen.dart';
import 'package:thing_note/features/data_archive/presentation/data_archive_screen.dart';
import 'package:thing_note/features/travel_log/presentation/travel_log_screen.dart';
import 'package:thing_note/features/pet_management/presentation/pet_management_screen.dart';
import 'package:thing_note/features/weight_tracker/presentation/weight_tracker_screen.dart';
import 'package:thing_note/features/study_timer/presentation/study_timer_screen.dart';
import 'package:thing_note/features/music_listening/presentation/music_listening_screen.dart';
import 'package:thing_note/features/water_intake/presentation/water_intake_screen.dart';
import 'package:thing_note/features/medication_reminder/presentation/medication_reminder_screen.dart';
import 'package:thing_note/features/password_manager/presentation/password_manager_screen.dart';
import 'package:thing_note/features/receipt_collection/presentation/receipt_collection_screen.dart';
import 'package:thing_note/features/gift_list/presentation/gift_list_screen.dart';
import 'package:thing_note/features/maintenance_log/presentation/maintenance_log_screen.dart';
import 'package:thing_note/features/plant_care/presentation/plant_care_screen.dart';
import 'package:thing_note/features/social_tracker/presentation/social_tracker_screen.dart';
import 'package:thing_note/features/mindful_moments/presentation/mindful_moments_screen.dart';
import 'package:thing_note/features/health_connect/presentation/health_connect_screen.dart';
import 'package:thing_note/features/collaborative_workspace/presentation/collaborative_workspace_screen.dart';
import 'package:thing_note/features/advanced_analytics/presentation/advanced_analytics_screen.dart';
import 'package:thing_note/features/smart_suggestions/presentation/smart_suggestions_screen.dart';
import 'package:thing_note/features/notification_hub/presentation/notification_hub_screen.dart';
import 'package:thing_note/features/document_scanner/presentation/document_scanner_screen.dart';
import 'package:thing_note/features/voice_commands/presentation/voice_commands_screen.dart';
import 'package:thing_note/features/custom_reports/presentation/custom_reports_screen.dart';
import 'package:thing_note/features/smart_scheduling/presentation/smart_scheduling_screen.dart';
import 'package:thing_note/features/project_management/presentation/project_management_screen.dart';
import 'package:thing_note/features/smart_geofence/presentation/smart_geofence_screen.dart';
import 'package:thing_note/features/automation_rules/presentation/automation_rules_screen.dart';
import 'package:thing_note/features/screen_time/presentation/screen_time_screen.dart';
import 'package:thing_note/features/expense_categories/presentation/expense_categories_screen.dart';
import 'package:thing_note/features/contact_manager/presentation/contact_manager_screen.dart';
import 'package:thing_note/features/vehicle_tracker/presentation/vehicle_tracker_screen.dart';
import 'package:thing_note/features/subscription_manager/presentation/subscription_manager_screen.dart';
import 'package:thing_note/features/investment_tracker/presentation/investment_tracker_screen.dart';
import 'package:thing_note/features/invoice_manager/presentation/invoice_manager_screen.dart';
import 'package:thing_note/features/warranty_tracker/presentation/warranty_tracker_screen.dart';
import 'package:thing_note/features/meal_planner/presentation/meal_planner_screen.dart';
import 'package:thing_note/features/clothing_inventory/presentation/clothing_inventory_screen.dart';
import 'package:thing_note/features/achievement/presentation/achievement_screen.dart';
import 'package:thing_note/features/energy_tracker/presentation/energy_tracker_screen.dart';
import 'package:thing_note/features/smart_calendar/presentation/smart_calendar_screen.dart';
import 'package:thing_note/features/quick_stats/presentation/quick_stats_screen.dart';
import 'package:thing_note/features/mood_calendar/presentation/mood_calendar_screen.dart';
import 'package:thing_note/features/habit_streak/presentation/habit_streak_screen.dart';
import 'package:thing_note/features/time_analysis/presentation/time_analysis_screen.dart';
import 'package:thing_note/features/location_history/presentation/location_history_screen.dart';
import 'package:thing_note/features/tag_cloud/presentation/tag_cloud_screen.dart';
import 'package:thing_note/features/daily_routine/presentation/daily_routine_screen.dart';
import 'package:thing_note/features/focus_timer/presentation/focus_timer_screen.dart';
import 'package:thing_note/features/mood_heatmap/presentation/mood_heatmap_screen.dart';
import 'package:thing_note/features/quick_search/presentation/quick_search_screen.dart';
import 'package:thing_note/features/reminder_analytics/presentation/reminder_analytics_screen.dart';
import 'package:thing_note/features/daily_score/presentation/daily_score_screen.dart';
import 'package:thing_note/features/smart_weekly_planner/presentation/smart_weekly_planner_screen.dart';
import 'package:thing_note/features/habit_challenge/presentation/habit_challenge_screen.dart';
import 'package:thing_note/features/mood_correlation/presentation/mood_correlation_screen.dart';
import 'package:thing_note/features/intelligent_reminder/presentation/intelligent_reminder_screen.dart';
import 'package:thing_note/features/quick_template/presentation/quick_template_screen.dart';
import 'package:thing_note/features/location_checkin/presentation/location_checkin_screen.dart';
import 'package:thing_note/features/idea_capture/presentation/idea_capture_screen.dart';
import 'package:thing_note/features/goal_review/presentation/goal_review_screen.dart';
import 'package:thing_note/features/custom_gesture/presentation/custom_gesture_screen.dart';
import 'package:thing_note/features/custom_theme/presentation/custom_theme_screen.dart';
import 'package:thing_note/features/cloud_sync/presentation/cloud_sync_screen.dart';
import 'package:thing_note/features/smart_dashboard/presentation/smart_dashboard_screen.dart';
import 'package:thing_note/features/data_export/presentation/data_export_screen.dart';
import 'package:thing_note/features/smart_template/presentation/smart_template_screen.dart';
import 'package:thing_note/features/smart_reminder_v2/presentation/smart_reminder_v2_screen.dart';
import 'package:thing_note/features/incremental_backup/presentation/incremental_backup_screen.dart';
import 'package:thing_note/features/template_market/presentation/template_market_screen.dart';
import 'package:thing_note/features/data_visualization/presentation/data_visualization_screen.dart';
import 'package:thing_note/features/batch_tag_v2/presentation/batch_tag_v2_screen.dart';
import 'package:thing_note/features/voice_search/presentation/voice_search_screen.dart';
import 'package:thing_note/features/data_recovery_wizard/presentation/data_recovery_wizard_screen.dart';
import 'package:thing_note/features/privacy_folder/presentation/privacy_folder_screen.dart';
import 'package:thing_note/features/quick_actions/presentation/quick_actions_screen.dart';
import 'package:thing_note/features/calendar_enhanced/presentation/calendar_enhanced_screen.dart';
import 'package:thing_note/features/notification_manager/presentation/notification_manager_screen.dart';
import 'package:thing_note/features/custom_widget_dashboard/presentation/custom_widget_dashboard_screen.dart';
import 'package:thing_note/features/data_export_hub/presentation/data_export_hub_screen.dart';
import 'package:thing_note/features/level_system/presentation/level_system_screen.dart';
import 'package:thing_note/features/password_generator/presentation/password_generator_screen.dart';
import 'package:thing_note/features/scene_mode/presentation/scene_mode_screen.dart';
import 'package:thing_note/features/smart_place_cluster/presentation/smart_place_cluster_screen.dart';
import 'package:thing_note/features/trip_planner/presentation/trip_planner_screen.dart';
import 'package:thing_note/features/monthly_review/presentation/monthly_review_screen.dart';
import 'package:thing_note/features/quick_commands/presentation/quick_commands_screen.dart';
import 'package:thing_note/features/habit_tournament/presentation/habit_tournament_screen.dart';
import 'package:thing_note/features/habit_tournament/presentation/goal_tree_screen.dart';
import 'package:thing_note/features/habit_tournament/presentation/reminder_patterns_screen.dart';
import 'package:thing_note/features/habit_tournament/presentation/privacy_settings_screen.dart';
import 'package:thing_note/features/habit_tournament/presentation/mood_journal_screen.dart';
import 'package:thing_note/features/smart_template_v2/presentation/smart_template_v2_screen.dart';
import 'package:thing_note/features/mood_thermometer/presentation/mood_thermometer_screen.dart';
import 'package:thing_note/features/habit_watermark/presentation/habit_watermark_widgets.dart';
import 'package:thing_note/features/time_insight_report/presentation/time_insight_report_screen.dart';
import 'package:thing_note/features/smart_classifier/presentation/smart_classifier_screen.dart';
import 'package:thing_note/features/location_story/presentation/location_story_screen.dart';
import 'package:thing_note/features/scheduled_digest/presentation/scheduled_digest_screen.dart';
import 'package:thing_note/features/record_snapshot/presentation/record_snapshot_screen.dart';
import 'package:thing_note/features/flow_state/presentation/flow_state_screen.dart';
import 'package:thing_note/features/reading_tracker/presentation/reading_tracker_screen.dart';
import 'package:thing_note/features/creative_tracker/presentation/creative_tracker_screen.dart';
import 'package:thing_note/features/social_logger/presentation/social_logger_screen.dart';
import 'package:thing_note/features/productivity_score/presentation/productivity_score_screen.dart';
import 'package:thing_note/features/idle_detector/presentation/idle_detector_screen.dart';
import 'package:thing_note/features/weather_correlation/presentation/weather_correlation_screen.dart';
import 'package:thing_note/features/energy_patterns/presentation/energy_patterns_screen.dart';
import 'package:thing_note/features/goal_momentum/presentation/momentum_screen.dart';
import 'package:thing_note/features/micro_goals/presentation/micro_goals_screen.dart';
import 'package:thing_note/features/stress_detector/presentation/stress_detector_screen.dart';
import 'package:thing_note/features/relationship_tracker/presentation/relationship_tracker_screen.dart';
import 'package:thing_note/features/mood_prediction/presentation/mood_prediction_screen.dart';
import 'package:thing_note/features/daily_reflection/presentation/daily_reflection_screen.dart';
import 'package:thing_note/features/habit_bricks/presentation/habit_bricks_screen.dart';
import 'package:thing_note/features/quick_review/presentation/quick_review_screen.dart';
import 'package:thing_note/features/knowledge_base/presentation/knowledge_base_screen.dart';
import 'package:thing_note/features/skill_log/presentation/skill_log_screen.dart';
import 'package:thing_note/features/energy_management/presentation/energy_management_screen.dart';
import 'package:thing_note/features/focus_zones/presentation/focus_zones_screen.dart';
import 'package:thing_note/features/mini_goals/presentation/mini_goals_screen.dart';
import 'package:thing_note/features/daily_wins/presentation/daily_wins_screen.dart';
import 'package:thing_note/features/location_routines/presentation/location_routines_screen.dart';
import 'package:thing_note/features/quick_export/presentation/quick_export_screen.dart';
import 'package:thing_note/features/media_gallery/presentation/media_gallery_screen.dart';
import 'package:thing_note/features/deep_work/presentation/deep_work_screen.dart';
import 'package:thing_note/features/learning_progress/presentation/learning_progress_screen.dart';
import 'package:thing_note/features/personal_okr/presentation/okr_screen.dart';
import 'package:thing_note/features/energy_curve/presentation/energy_curve_screen.dart';
import 'package:thing_note/features/habit_stacking/presentation/habit_stack_screen.dart';
import 'package:thing_note/features/mini_tasks/presentation/mini_tasks_screen.dart';
import 'package:thing_note/features/weekly_focus/presentation/weekly_focus_screen.dart';
import 'package:thing_note/features/gratitude_practice/presentation/gratitude_screen.dart';
import 'package:thing_note/features/skill_tracker/presentation/skill_tracker_screen.dart';
import 'package:thing_note/features/reflection_templates/presentation/reflection_screen.dart';
import 'package:thing_note/features/focus_music/presentation/focus_music_screen.dart';
import 'package:thing_note/features/time_audit/presentation/time_audit_screen.dart';
import 'package:thing_note/features/daily_rituals/presentation/daily_rituals_screen.dart';
import 'package:thing_note/features/pomodoro_tracker/presentation/pomodoro_tracker_screen.dart';
import 'package:thing_note/features/personal_milestones/presentation/personal_milestones_screen.dart';
import 'package:thing_note/features/focus_journal/presentation/focus_journal_screen.dart';
import 'package:thing_note/features/goal_dependencies/presentation/goal_dependencies_screen.dart';
import 'package:thing_note/features/smart_tag_clustering/presentation/smart_tag_clustering_screen.dart';
import 'package:thing_note/features/quick_capture/presentation/quick_capture_screen.dart';
import 'package:thing_note/features/cross_feature_insights/presentation/cross_feature_insights_screen.dart';
import 'package:thing_note/features/periodic_review/presentation/periodic_review_screen.dart';
import 'package:thing_note/features/data_integrity/presentation/data_integrity_screen.dart';
import 'package:thing_note/features/smart_notifications/presentation/smart_notifications_screen.dart';
import 'package:thing_note/features/batch_archive/presentation/batch_archive_screen.dart';
import 'package:thing_note/features/export_templates/presentation/export_templates_screen.dart';
import 'package:thing_note/features/recurring_tasks/presentation/recurring_tasks_screen.dart';
import 'package:thing_note/features/achievement_badges/presentation/achievement_badges_screen.dart';
import 'package:thing_note/features/smart_summary_assistant/presentation/smart_summary_screen.dart';
import 'package:thing_note/features/deep_stats_panel/presentation/deep_stats_panel_screen.dart';
import 'package:thing_note/features/quick_recall/presentation/quick_recall_screen.dart';
import 'package:thing_note/features/priority_matrix/presentation/priority_matrix_screen.dart';
import 'package:thing_note/features/emotion_tag_cloud/presentation/emotion_tag_cloud_screen.dart';
import 'package:thing_note/features/health_dashboard/presentation/health_dashboard_screen.dart';
import 'package:thing_note/features/habit_challenges/presentation/habit_challenges_screen.dart';
import 'package:thing_note/features/smart_backup_verify/presentation/smart_backup_verify_screen.dart';
import 'package:thing_note/features/focus_training/presentation/focus_training_screen.dart';
import 'package:thing_note/features/time_travel/presentation/time_travel_screen.dart';
import 'package:thing_note/features/okr_tracker/presentation/okr_tracker_screen.dart';
import 'package:thing_note/features/morning_checkin/presentation/morning_checkin_screen.dart';
import 'package:thing_note/features/pomodoro_task/presentation/pomodoro_task_screen.dart';
import 'package:thing_note/features/weekly_wins/presentation/weekly_wins_screen.dart';
import 'package:thing_note/features/interrupt_tracker/presentation/interrupt_tracker_screen.dart';
import 'package:thing_note/features/grateful_notes/presentation/grateful_notes_screen.dart';
import 'package:thing_note/features/intention_setting/presentation/intention_setting_screen.dart';
import 'package:thing_note/features/energy_peak/presentation/energy_peak_screen.dart';
import 'package:thing_note/features/mood_activity_matcher/presentation/mood_activity_matcher_screen.dart';
import 'package:thing_note/features/daily_progress/presentation/daily_progress_screen.dart';
import 'package:thing_note/features/weekly_planning/presentation/weekly_planning_screen.dart';
import 'package:thing_note/features/folder_management/presentation/folder_management_screen.dart';
import 'package:thing_note/features/smart_link_discovery/presentation/smart_link_discovery_screen.dart';
import 'package:thing_note/features/time_fragment/presentation/time_fragment_screen.dart';
import 'package:thing_note/features/emotion_trail/presentation/emotion_trail_screen.dart';
import 'package:thing_note/features/relationship_graph/presentation/relationship_graph_screen.dart';
import 'package:thing_note/features/location_storyline/presentation/location_storyline_screen.dart';
import 'package:thing_note/features/smart_tag_v2/presentation/smart_tag_v2_screen.dart';
import 'package:thing_note/features/data_quality_score/presentation/data_quality_score_screen.dart';
import 'package:thing_note/features/milestone_review/presentation/milestone_review_screen.dart';
import 'package:thing_note/features/time_allocation/presentation/time_allocation_screen.dart';
import 'package:thing_note/features/template_learning/presentation/template_learning_screen.dart';
import 'package:thing_note/features/quick_annotation/presentation/quick_annotation_screen.dart';
import 'package:thing_note/features/reminder_optimizer/presentation/reminder_optimizer_screen.dart';
import 'package:thing_note/features/record_influence/presentation/record_influence_screen.dart';
import 'package:thing_note/features/smart_search_enhanced/presentation/smart_search_enhanced_screen.dart';
import 'package:thing_note/features/quick_record_floating/presentation/quick_record_floating_screen.dart';
import 'package:thing_note/features/multi_stat_card/presentation/multi_stat_card_screen.dart';
import 'package:thing_note/features/smart_search_suggestion/presentation/smart_search_suggestion_screen.dart';
import 'package:thing_note/features/quick_photo_capture/presentation/quick_photo_capture_screen.dart';
import 'package:thing_note/features/smart_reminder_scheduler/presentation/smart_reminder_scheduler_screen.dart';
import 'package:thing_note/features/record_favorites/presentation/record_favorites_screen.dart';
import 'package:thing_note/features/smart_habit_scheduling/presentation/smart_habit_scheduling_screen.dart';
import 'package:thing_note/features/cross_device_sync/presentation/cross_device_sync_screen.dart';
import 'package:thing_note/features/mood_music_recommendation/presentation/mood_music_screen.dart';
import 'package:thing_note/features/daily_briefing_widget/presentation/daily_briefing_widget_screen.dart';
import 'package:thing_note/features/focus_breathing/presentation/focus_breathing_screen.dart';
import 'package:thing_note/features/weekly_goal_reset/presentation/weekly_goal_reset_screen.dart';
import 'package:thing_note/features/habit_chaining/presentation/habit_chaining_screen.dart';
import 'package:thing_note/features/energy_mood_correlation/presentation/energy_mood_correlation_screen.dart';
import 'package:thing_note/features/smart_notification_timing/presentation/smart_notification_timing_screen.dart';
import 'package:thing_note/features/focus_sharing/presentation/focus_sharing_screen.dart';
import 'package:thing_note/features/daily_achievements/presentation/daily_achievements_screen.dart';
import 'package:thing_note/features/weekly_insights_card/presentation/weekly_insights_card_screen.dart';
import 'package:thing_note/features/smart_note_linking/presentation/smart_note_linking_screen.dart';
import 'package:thing_note/features/focus_session_analytics/presentation/focus_session_analytics_screen.dart';
import 'package:thing_note/features/habit_template_marketplace/presentation/habit_template_marketplace_screen.dart';
import 'package:thing_note/features/daily_quote/presentation/daily_quote_screen.dart';
import 'package:thing_note/features/habit_checkin_widget/presentation/habit_checkin_widget_screen.dart';
import 'package:thing_note/features/activity_correlation_engine/presentation/activity_correlation_engine_screen.dart';
import 'package:thing_note/features/goal_milestone_alerts/presentation/goal_milestone_alerts_screen.dart';
import 'package:thing_note/features/smart_search_filters/presentation/smart_search_filters_screen.dart';
import 'package:thing_note/features/daily_progress_snapshot/presentation/daily_progress_snapshot_screen.dart';
import 'package:thing_note/features/mood_pattern_detection/presentation/mood_pattern_detection_screen.dart';
import 'package:thing_note/features/quick_access_bar/presentation/quick_access_bar_screen.dart';
import 'package:thing_note/features/record_version_history/presentation/record_version_history_screen.dart';
import 'package:thing_note/features/weekly_theme_suggestions/presentation/weekly_theme_suggestions_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

CustomTransitionPage<void> _buildPageWithTransition({
  required LocalKey key,
  required Widget child,
  bool slideFromRight = true,
}) {
  return CustomTransitionPage<void>(
    key: key,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      if (!slideFromRight) return child;
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(1, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: Curves.easeInOut,
        )),
        child: child,
      );
    },
    transitionDuration: const Duration(milliseconds: 300),
    reverseTransitionDuration: const Duration(milliseconds: 300),
  );
}

final goRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const RecordListScreen(),
          slideFromRight: false,
        ),
      ),
      GoRoute(
        path: '/record/new',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const RecordFormScreen(),
        ),
      ),
      GoRoute(
        path: '/record/:id',
        pageBuilder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
          return _buildPageWithTransition(
            key: state.pageKey,
            child: RecordDetailScreen(recordId: id),
          );
        },
      ),
      GoRoute(
        path: '/record/:id/edit',
        pageBuilder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return _buildPageWithTransition(
            key: state.pageKey,
            child: RecordFormScreen(recordId: id),
          );
        },
      ),
      GoRoute(
        path: '/folder/:id',
        pageBuilder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return _buildPageWithTransition(
            key: state.pageKey,
            child: FolderDetailScreen(folderId: id),
          );
        },
      ),
      GoRoute(
        path: '/settings',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const SettingsScreen(),
        ),
      ),
      GoRoute(
        path: '/settings/backups',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const BackupListScreen(),
        ),
      ),
      GoRoute(
        path: '/settings/thing-names',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const ThingNameManageScreen(),
        ),
      ),
      GoRoute(
        path: '/settings/thing-names/:id',
        pageBuilder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
          return _buildPageWithTransition(
            key: state.pageKey,
            child: ThingNameDetailScreen(thingNameId: id),
          );
        },
      ),
      GoRoute(
        path: '/settings/tags',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const TagListScreen(),
        ),
      ),
      GoRoute(
        path: '/settings/tags/new',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const TagEditScreen(),
        ),
      ),
      GoRoute(
        path: '/settings/tags/:id',
        pageBuilder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
          return _buildPageWithTransition(
            key: state.pageKey,
            child: TagEditScreen(tagId: id),
          );
        },
      ),
      GoRoute(
        path: '/statistics',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const StatisticsScreen(),
        ),
      ),
      GoRoute(
        path: '/timeline',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const TimelineScreen(),
        ),
      ),
      GoRoute(
        path: '/search',
        pageBuilder: (context, state) {
          final query = state.uri.queryParameters['query'];
          return _buildPageWithTransition(
            key: state.pageKey,
            child: SearchResultsScreen(initialQuery: query),
          );
        },
      ),
      GoRoute(
        path: '/calendar',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const CalendarScreen(),
        ),
      ),
      GoRoute(
        path: '/sync',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const SyncSettingsScreen(),
        ),
      ),
      GoRoute(
        path: '/smart-reminder',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const SmartReminderScreen(),
        ),
      ),
      GoRoute(
        path: '/charts',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const ChartScreen(),
        ),
      ),
      GoRoute(
        path: '/batch-operation',
        pageBuilder: (context, state) {
          final ids = (state.extra as List<Object?>?)?.cast<int>().toList();
          return _buildPageWithTransition(
            key: state.pageKey,
            child: BatchOperationScreen(selectedRecordIds: ids ?? []),
          );
        },
      ),
      GoRoute(
        path: '/usage-insights',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const UsageInsightsScreen(),
        ),
      ),
      GoRoute(
        path: '/enhanced-backup',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const EnhancedBackupScreen(),
        ),
      ),
      GoRoute(
        path: '/goals',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const GoalsScreen(),
        ),
      ),
      GoRoute(
        path: '/mood',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const MoodScreen(),
        ),
      ),
      GoRoute(
        path: '/habits',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const HabitScreen(),
        ),
      ),
      GoRoute(
        path: '/projects',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const ProjectScreen(),
        ),
      ),
      GoRoute(
        path: '/notifications',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const NotificationCenterScreen(),
        ),
      ),
      GoRoute(
        path: '/importer',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const ImporterScreen(),
        ),
      ),
      GoRoute(
        path: '/report',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const ReportScreen(),
        ),
      ),
      GoRoute(
        path: '/theme',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const ThemeSelectorScreen(),
        ),
      ),
      GoRoute(
        path: '/quick-notes',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const QuickNotesScreen(),
        ),
      ),
      GoRoute(
        path: '/collections',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const CollectionsScreen(),
        ),
      ),
      GoRoute(
        path: '/reminder-prediction',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const ReminderPredictionScreen(),
        ),
      ),
      GoRoute(
        path: '/dashboard',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const DashboardScreen(),
        ),
      ),
      GoRoute(
        path: '/voice-recorder',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const VoiceRecorderScreen(),
        ),
      ),
      GoRoute(
        path: '/ai-assistant',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const AiAssistantScreen(),
        ),
      ),
      GoRoute(
        path: '/auto-report',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const AutoReportScreen(),
        ),
      ),
      GoRoute(
        path: '/encryption',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const EncryptionSettingsScreen(),
        ),
      ),
      GoRoute(
        path: '/hotspot-analysis',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const HotspotAnalysisScreen(),
        ),
      ),
      GoRoute(
        path: '/file-manager',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const FileManagerScreen(),
        ),
      ),
      GoRoute(
        path: '/privacy-mode',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const PrivacyModeScreen(),
        ),
      ),
      GoRoute(
        path: '/satisfaction-survey',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const SatisfactionSurveyScreen(),
        ),
      ),
      GoRoute(
        path: '/workflow-automation',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const WorkflowAutomationScreen(),
        ),
      ),
      GoRoute(
        path: '/media-compressor',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const MediaCompressorScreen(),
        ),
      ),
      GoRoute(
        path: '/smart-sort',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const SmartSortScreen(),
        ),
      ),
      GoRoute(
        path: '/data-health-check',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const DataHealthCheckScreen(),
        ),
      ),
      GoRoute(
        path: '/keyboard-shortcuts',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const KeyboardShortcutsScreen(),
        ),
      ),
      GoRoute(
        path: '/journal',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const JournalScreen(),
        ),
      ),
      GoRoute(
        path: '/geofence',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const GeofenceScreen(),
        ),
      ),
      GoRoute(
        path: '/flashcard',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const FlashcardScreen(),
        ),
      ),
      GoRoute(
        path: '/ocr',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const OcrScreen(),
        ),
      ),
      GoRoute(
        path: '/timeline-enhanced',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const TimelineEnhancedScreen(),
        ),
      ),
      GoRoute(
        path: '/auto-summary',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const AutoSummaryScreen(),
        ),
      ),
      GoRoute(
        path: '/tag-hierarchy',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const TagHierarchyScreen(),
        ),
      ),
      GoRoute(
        path: '/task-dependency',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const TaskDependencyScreen(),
        ),
      ),
      GoRoute(
        path: '/places',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const PlaceScreen(),
        ),
      ),
      GoRoute(
        path: '/share-external',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const ShareExternalScreen(),
        ),
      ),
      GoRoute(
        path: '/time-block',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const TimeBlockScreen(),
        ),
      ),
      GoRoute(
        path: '/home-widget',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const HomeWidgetScreen(),
        ),
      ),
      GoRoute(
        path: '/voice-note',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const VoiceNoteScreen(),
        ),
      ),
      GoRoute(
        path: '/planner',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const DailyPlannerScreen(),
        ),
      ),
      GoRoute(
        path: '/focus-mode',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const FocusModeScreen(),
        ),
      ),
      GoRoute(
        path: '/weekly-review',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const WeeklyReviewScreen(),
        ),
      ),
      GoRoute(
        path: '/budget',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const BudgetTrackerScreen(),
        ),
      ),
      GoRoute(
        path: '/sleep',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const SleepTrackerScreen(),
        ),
      ),
      GoRoute(
        path: '/reading',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const ReadingListScreen(),
        ),
      ),
      GoRoute(
        path: '/links',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const LinkSaverScreen(),
        ),
      ),
      GoRoute(
        path: '/recipes',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const RecipeManagerScreen(),
        ),
      ),
      GoRoute(
        path: '/meetings',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const MeetingAssistantScreen(),
        ),
      ),
      GoRoute(
        path: '/mood-boost',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const MoodBoostScreen(),
        ),
      ),
      GoRoute(
        path: '/voice-tag',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const VoiceTagScreen(),
        ),
      ),
      GoRoute(
        path: '/custom-dashboard',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const CustomDashboardScreen(),
        ),
      ),
      GoRoute(
        path: '/event-reminder',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const EventReminderScreen(),
        ),
      ),
      GoRoute(
        path: '/archive-data',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const DataArchiveScreen(),
        ),
      ),
      GoRoute(
        path: '/travel-log',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const TravelLogScreen(),
        ),
      ),
      GoRoute(
        path: '/pet-management',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const PetManagementScreen(),
        ),
      ),
      GoRoute(
        path: '/weight-tracker',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const WeightTrackerScreen(),
        ),
      ),
      GoRoute(
        path: '/study-timer',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const StudyTimerScreen(),
        ),
      ),
      GoRoute(
        path: '/music-listening',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const MusicListeningScreen(),
        ),
      ),
      GoRoute(
        path: '/water-intake',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const WaterIntakeScreen(),
        ),
      ),
      GoRoute(
        path: '/medication-reminder',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const MedicationReminderScreen(),
        ),
      ),
      GoRoute(
        path: '/password-manager',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const PasswordManagerScreen(),
        ),
      ),
      GoRoute(
        path: '/receipt-collection',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const ReceiptCollectionScreen(),
        ),
      ),
      GoRoute(
        path: '/gift-list',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const GiftListScreen(),
        ),
      ),
      GoRoute(
        path: '/maintenance-log',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const MaintenanceLogScreen(),
        ),
      ),
      GoRoute(
        path: '/plant-care',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const PlantCareScreen(),
        ),
      ),
      GoRoute(
        path: '/social-tracker',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const SocialTrackerScreen(),
        ),
      ),
      GoRoute(
        path: '/screen-time',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const ScreenTimeScreen(),
        ),
      ),
      GoRoute(
        path: '/expense-categories',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const ExpenseCategoriesScreen(),
        ),
      ),
      GoRoute(
        path: '/contacts',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const ContactManagerScreen(),
        ),
      ),
      GoRoute(
        path: '/vehicles',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const VehicleTrackerScreen(),
        ),
      ),
      GoRoute(
        path: '/subscriptions',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const SubscriptionManagerScreen(),
        ),
      ),
      GoRoute(
        path: '/investments',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const InvestmentTrackerScreen(),
        ),
      ),
      GoRoute(
        path: '/invoices',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const InvoiceManagerScreen(),
        ),
      ),
      GoRoute(
        path: '/warranties',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const WarrantyTrackerScreen(),
        ),
      ),
      GoRoute(
        path: '/meal-planner',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const MealPlannerScreen(),
        ),
      ),
      GoRoute(
        path: '/clothing',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const ClothingInventoryScreen(),
        ),
      ),
      GoRoute(
        path: '/achievements',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const AchievementScreen(),
        ),
      ),
      GoRoute(
        path: '/energy',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const EnergyTrackerScreen(),
        ),
      ),
      GoRoute(
        path: '/mindful-moments',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const MindfulMomentsScreen(),
        ),
      ),
      GoRoute(
        path: '/health-connect',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const HealthConnectScreen(),
        ),
      ),
      GoRoute(
        path: '/collaborative-workspace',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const CollaborativeWorkspaceScreen(),
        ),
      ),
      GoRoute(
        path: '/advanced-analytics',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const AdvancedAnalyticsScreen(),
        ),
      ),
      GoRoute(
        path: '/smart-suggestions',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const SmartSuggestionsScreen(),
        ),
      ),
      GoRoute(
        path: '/notification-hub',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const NotificationHubScreen(),
        ),
      ),
      GoRoute(
        path: '/document-scanner',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const DocumentScannerScreen(),
        ),
      ),
      GoRoute(
        path: '/voice-commands',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const VoiceCommandsScreen(),
        ),
      ),
      GoRoute(
        path: '/custom-reports',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const CustomReportsScreen(),
        ),
      ),
      GoRoute(
        path: '/smart-scheduling',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const SmartSchedulingScreen(),
        ),
      ),
      GoRoute(
        path: '/project-management',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const ProjectManagementScreen(),
        ),
      ),
      GoRoute(
        path: '/smart-geofence',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const SmartGeofenceScreen(),
        ),
      ),
      GoRoute(
        path: '/automation-rules',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const AutomationRulesScreen(),
        ),
      ),
      GoRoute(
        path: '/smart-calendar',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const SmartCalendarScreen(),
        ),
      ),
      GoRoute(
        path: '/quick-stats',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const QuickStatsScreen(),
        ),
      ),
      GoRoute(
        path: '/mood-calendar',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const MoodCalendarScreen(),
        ),
      ),
      GoRoute(
        path: '/habit-streak',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const HabitStreakScreen(),
        ),
      ),
      GoRoute(
        path: '/time-analysis',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const TimeAnalysisScreen(),
        ),
      ),
      GoRoute(
        path: '/location-history',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const LocationHistoryScreen(),
        ),
      ),
      GoRoute(
        path: '/tag-cloud',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const TagCloudScreen(),
        ),
      ),
      GoRoute(
        path: '/daily-routine',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const DailyRoutineScreen(),
        ),
      ),
      GoRoute(
        path: '/focus-timer',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const FocusTimerScreen(),
        ),
      ),
      GoRoute(
        path: '/mood-heatmap',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const MoodHeatmapScreen(),
        ),
      ),
      GoRoute(
        path: '/quick-search',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const QuickSearchScreen(),
        ),
      ),
      GoRoute(
        path: '/reminder-analytics',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const ReminderAnalyticsScreen(),
        ),
      ),
      GoRoute(
        path: '/daily-score',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const DailyScoreScreen(),
        ),
      ),
      GoRoute(
        path: '/weekly-planner',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const SmartWeeklyPlannerScreen(),
        ),
      ),
      GoRoute(
        path: '/habit-challenge',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const HabitChallengeScreen(),
        ),
      ),
      GoRoute(
        path: '/mood-correlation',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const MoodCorrelationScreen(),
        ),
      ),
      GoRoute(
        path: '/intelligent-reminder',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const IntelligentReminderScreen(),
        ),
      ),
      GoRoute(
        path: '/quick-template',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const QuickTemplateScreen(),
        ),
      ),
      GoRoute(
        path: '/location-checkin',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const LocationCheckinScreen(),
        ),
      ),
      GoRoute(
        path: '/idea-capture',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const IdeaCaptureScreen(),
        ),
      ),
      GoRoute(
        path: '/goal-review',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const GoalReviewScreen(),
        ),
      ),
      GoRoute(
        path: '/custom-gesture',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const CustomGestureScreen(),
        ),
      ),
      GoRoute(
        path: '/custom-theme',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const CustomThemeScreen(),
        ),
      ),
      GoRoute(
        path: '/cloud-sync',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const CloudSyncScreen(),
        ),
      ),
      GoRoute(
        path: '/smart-dashboard',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const SmartDashboardScreen(),
        ),
      ),
      GoRoute(
        path: '/data-export',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const DataExportScreen(),
        ),
      ),
      GoRoute(
        path: '/smart-template',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const SmartTemplateScreen(),
        ),
      ),
      GoRoute(
        path: '/smart-reminder-v2',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const SmartReminderV2Screen(),
        ),
      ),
      GoRoute(
        path: '/incremental-backup',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const IncrementalBackupScreen(),
        ),
      ),
      GoRoute(
        path: '/template-market',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const TemplateMarketScreen(),
        ),
      ),
      GoRoute(
        path: '/data-visualization',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const DataVisualizationScreen(),
        ),
      ),
      GoRoute(
        path: '/batch-tag-v2',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const BatchTagV2Screen(),
        ),
      ),
      GoRoute(
        path: '/voice-search',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const VoiceSearchScreen(),
        ),
      ),
      GoRoute(
        path: '/data-recovery-wizard',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const DataRecoveryWizardScreen(),
        ),
      ),
      GoRoute(
        path: '/privacy-folder',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const PrivacyFolderScreen(),
        ),
      ),
      GoRoute(
        path: '/quick-actions',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const QuickActionsScreen(),
        ),
      ),
      GoRoute(
        path: '/calendar-enhanced',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const CalendarEnhancedScreen(),
        ),
      ),
      GoRoute(
        path: '/notification-manager',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const NotificationManagerScreen(),
        ),
      ),
      GoRoute(
        path: '/custom-widget-dashboard',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const CustomWidgetDashboardScreen(),
        ),
      ),
      GoRoute(
        path: '/data-export-hub',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const DataExportHubScreen(),
        ),
      ),
      GoRoute(
        path: '/level-system',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const LevelSystemScreen(),
        ),
      ),
      GoRoute(
        path: '/password-generator',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const PasswordGeneratorScreen(),
        ),
      ),
      GoRoute(
        path: '/scene-mode',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const SceneModeScreen(),
        ),
      ),
      GoRoute(
        path: '/smart-place-cluster',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const SmartPlaceClusterScreen(),
        ),
      ),
      GoRoute(
        path: '/trip-planner',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const TripPlannerScreen(),
        ),
      ),
      GoRoute(
        path: '/monthly-review',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const MonthlyReviewScreen(),
        ),
      ),
      GoRoute(
        path: '/quick-commands',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const QuickCommandsScreen(),
        ),
      ),
      GoRoute(
        path: '/habit-tournament',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const HabitTournamentScreen(),
        ),
      ),
      GoRoute(
        path: '/goal-tree',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const GoalTreeScreen(),
        ),
      ),
      GoRoute(
        path: '/reminder-patterns',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const ReminderPatternsScreen(),
        ),
      ),
      GoRoute(
        path: '/privacy-settings',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const PrivacySettingsScreen(),
        ),
      ),
      GoRoute(
        path: '/mood-journal',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const MoodJournalScreen(),
        ),
      ),
      GoRoute(
        path: '/smart-template-v2',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const SmartTemplateV2Screen(),
        ),
      ),
      GoRoute(
        path: '/mood-thermometer',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const MoodThermometerScreen(),
        ),
      ),
      GoRoute(
        path: '/habit-watermark',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const HabitWatermarkConfigEditor(),
        ),
      ),
      GoRoute(
        path: '/quick-record-floating',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const QuickRecordFloatingScreen(),
        ),
      ),
      GoRoute(
        path: '/time-insight-report',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const TimeInsightReportScreen(),
        ),
      ),
      GoRoute(
        path: '/smart-classifier',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const SmartClassifierScreen(),
        ),
      ),
      GoRoute(
        path: '/multi-stat-card',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const MultiStatCardScreen(),
        ),
      ),
      GoRoute(
        path: '/location-story',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const LocationStoryScreen(),
        ),
      ),
      GoRoute(
        path: '/scheduled-digest',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const ScheduledDigestScreen(),
        ),
      ),
      GoRoute(
        path: '/smart-search-suggestion',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const SmartSearchSuggestionScreen(),
        ),
      ),
      GoRoute(
        path: '/record-snapshot/:recordId',
        pageBuilder: (context, state) {
          final recordId = int.tryParse(state.pathParameters['recordId'] ?? '') ?? 0;
          return _buildPageWithTransition(
            key: state.pageKey,
            child: RecordSnapshotScreen(recordId: recordId),
          );
        },
      ),
      GoRoute(
        path: '/quick-photo-capture',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const QuickPhotoCaptureScreen(),
        ),
      ),
      GoRoute(
        path: '/smart-reminder-scheduler',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const SmartReminderSchedulerScreen(),
        ),
      ),
      GoRoute(
        path: '/flow-state',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const FlowStateScreen(),
        ),
      ),
      GoRoute(
        path: '/reading-tracker',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const ReadingTrackerScreen(),
        ),
      ),
      GoRoute(
        path: '/creative-tracker',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const CreativeTrackerScreen(),
        ),
      ),
      GoRoute(
        path: '/social-logger',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const SocialLoggerScreen(),
        ),
      ),
      GoRoute(
        path: '/productivity-score',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const ProductivityScoreScreen(),
        ),
      ),
      GoRoute(
        path: '/idle-detector',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const IdleDetectorScreen(),
        ),
      ),
      GoRoute(
        path: '/weather-correlation',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const WeatherCorrelationScreen(),
        ),
      ),
      GoRoute(
        path: '/energy-patterns',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const EnergyPatternsScreen(),
        ),
      ),
      GoRoute(
        path: '/goal-momentum',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const GoalMomentumScreen(),
        ),
      ),
      GoRoute(
        path: '/micro-goals',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const MicroGoalsScreen(),
        ),
      ),
      GoRoute(
        path: '/stress-detector',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const StressDetectorScreen(),
        ),
      ),
      GoRoute(
        path: '/relationship-tracker',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const RelationshipTrackerScreen(),
        ),
      ),
      GoRoute(
        path: '/mood-prediction',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const MoodPredictionScreen(),
        ),
      ),
      GoRoute(
        path: '/daily-reflection',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const DailyReflectionScreen(),
        ),
      ),
      GoRoute(
        path: '/habit-bricks',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const HabitBricksScreen(),
        ),
      ),
      GoRoute(
        path: '/quick-review',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const QuickReviewScreen(),
        ),
      ),
      GoRoute(
        path: '/knowledge-base',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const KnowledgeBaseScreen(),
        ),
      ),
      GoRoute(
        path: '/skill-log',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const SkillLogScreen(),
        ),
      ),
      GoRoute(
        path: '/energy-management',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const EnergyManagementScreen(),
        ),
      ),
      GoRoute(
        path: '/focus-zones',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const FocusZonesScreen(),
        ),
      ),
      GoRoute(
        path: '/mini-goals',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const MiniGoalsScreen(),
        ),
      ),
      GoRoute(
        path: '/daily-wins',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const DailyWinsScreen(),
        ),
      ),
      GoRoute(
        path: '/location-routines',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const LocationRoutinesScreen(),
        ),
      ),
      GoRoute(
        path: '/quick-export',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const QuickExportScreen(),
        ),
      ),
      GoRoute(
        path: '/media-gallery',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const MediaGalleryScreen(),
        ),
      ),
      GoRoute(
        path: '/deep-work',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const DeepWorkScreen(),
        ),
      ),
      GoRoute(
        path: '/learning-progress',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const LearningProgressScreen(),
        ),
      ),
      GoRoute(
        path: '/time-audit',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const TimeAuditScreen(),
        ),
      ),
      GoRoute(
        path: '/goal-dependencies',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const GoalDependenciesScreen(),
        ),
      ),
      GoRoute(
        path: '/smart-tag-clustering',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const SmartTagClusteringScreen(),
        ),
      ),
      GoRoute(
        path: '/quick-capture',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const QuickCaptureScreen(),
        ),
      ),
      GoRoute(
        path: '/cross-feature-insights',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const CrossFeatureInsightsScreen(),
        ),
      ),
      GoRoute(
        path: '/periodic-review',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const PeriodicReviewScreen(),
        ),
      ),
      GoRoute(
        path: '/data-integrity',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const DataIntegrityScreen(),
        ),
      ),
      GoRoute(
        path: '/smart-notifications',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const SmartNotificationsScreen(),
        ),
      ),
      GoRoute(
        path: '/batch-archive',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const BatchArchiveScreen(),
        ),
      ),
      GoRoute(
        path: '/export-templates',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const ExportTemplatesScreen(),
        ),
      ),
      GoRoute(
        path: '/personal-okr',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const OkrScreen(),
        ),
      ),
      GoRoute(
        path: '/energy-curve',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const EnergyCurveScreen(),
        ),
      ),
      GoRoute(
        path: '/habit-stacking',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const HabitStackScreen(),
        ),
      ),
      GoRoute(
        path: '/mini-tasks',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const MiniTasksScreen(),
        ),
      ),
      GoRoute(
        path: '/weekly-focus',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const WeeklyFocusScreen(),
        ),
      ),
      GoRoute(
        path: '/gratitude',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const GratitudeScreen(),
        ),
      ),
      GoRoute(
        path: '/skill-tracker',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const SkillTrackerScreen(),
        ),
      ),
      GoRoute(
        path: '/reflection-templates',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const ReflectionScreen(),
        ),
      ),
      GoRoute(
        path: '/focus-music',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const FocusMusicScreen(),
        ),
      ),
      GoRoute(
        path: '/daily-rituals',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const DailyRitualsScreen(),
        ),
      ),
      GoRoute(
        path: '/pomodoro',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const PomodoroTrackerScreen(),
        ),
      ),
      GoRoute(
        path: '/milestones',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const PersonalMilestonesScreen(),
        ),
      ),
      GoRoute(
        path: '/focus-journal',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const FocusJournalScreen(),
        ),
      ),
      GoRoute(
        path: '/morning-checkin',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const MorningCheckinScreen(),
        ),
      ),
      GoRoute(
        path: '/pomodoro-task',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const PomodoroTaskScreen(),
        ),
      ),
      GoRoute(
        path: '/weekly-wins',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const WeeklyWinsScreen(),
        ),
      ),
      GoRoute(
        path: '/interrupt-tracker',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const InterruptTrackerScreen(),
        ),
      ),
      GoRoute(
        path: '/grateful-notes',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const GratefulNotesScreen(),
        ),
      ),
      GoRoute(
        path: '/intention-setting',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const IntentionSettingScreen(),
        ),
      ),
      GoRoute(
        path: '/energy-peak',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const EnergyPeakScreen(),
        ),
      ),
      GoRoute(
        path: '/mood-activity-matcher',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const MoodActivityMatcherScreen(),
        ),
      ),
      GoRoute(
        path: '/daily-progress',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const DailyProgressScreen(),
        ),
      ),
      GoRoute(
        path: '/weekly-planning',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const WeeklyPlanningScreen(),
        ),
      ),
      GoRoute(
        path: '/recurring-tasks',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const RecurringTasksScreen(),
        ),
      ),
      GoRoute(
        path: '/achievement-badges',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const AchievementBadgesScreen(),
        ),
      ),
      GoRoute(
        path: '/smart-summary',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const SmartSummaryScreen(),
        ),
      ),
      GoRoute(
        path: '/deep-stats',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const DeepStatsPanel(),
        ),
      ),
      GoRoute(
        path: '/quick-recall',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const QuickRecallScreen(),
        ),
      ),
      GoRoute(
        path: '/priority-matrix',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const PriorityMatrixScreen(),
        ),
      ),
      GoRoute(
        path: '/emotion-cloud',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const EmotionTagCloudScreen(),
        ),
      ),
      GoRoute(
        path: '/health-dashboard',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const HealthDashboardScreen(),
        ),
      ),
      GoRoute(
        path: '/habit-challenges',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const HabitChallengesScreen(),
        ),
      ),
      GoRoute(
        path: '/backup-verify',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const SmartBackupVerifyScreen(),
        ),
      ),
      GoRoute(
        path: '/focus-training',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const FocusTrainingScreen(),
        ),
      ),
      GoRoute(
        path: '/time-travel',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const TimeTravelScreen(),
        ),
      ),
      GoRoute(
        path: '/okr-tracker',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const OkrTrackerScreen(),
        ),
      ),
      GoRoute(
        path: '/smart-link-discovery',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const SmartLinkDiscoveryScreen(),
        ),
      ),
      GoRoute(
        path: '/time-fragment',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const TimeFragmentScreen(),
        ),
      ),
      GoRoute(
        path: '/emotion-trail',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const EmotionTrailScreen(),
        ),
      ),
      GoRoute(
        path: '/relationship-graph',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const RelationshipGraphScreen(),
        ),
      ),
      GoRoute(
        path: '/location-storyline',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const LocationStorylineScreen(),
        ),
      ),
      GoRoute(
        path: '/smart-tag-v2',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const SmartTagV2Screen(),
        ),
      ),
      GoRoute(
        path: '/data-quality-score',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const DataQualityScoreScreen(),
        ),
      ),
      GoRoute(
        path: '/milestone-review',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const MilestoneReviewScreen(),
        ),
      ),
      GoRoute(
        path: '/time-allocation',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const TimeAllocationScreen(),
        ),
      ),
      GoRoute(
        path: '/template-learning',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const TemplateLearningScreen(),
        ),
      ),
      GoRoute(
        path: '/quick-annotation',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const QuickAnnotationScreen(),
        ),
      ),
      GoRoute(
        path: '/reminder-optimizer',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const ReminderOptimizerScreen(),
        ),
      ),
      GoRoute(
        path: '/record-influence',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const RecordInfluenceScreen(),
        ),
      ),
      GoRoute(
        path: '/smart-search-enhanced',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const SmartSearchEnhancedScreen(),
        ),
      ),
      GoRoute(
        path: '/record-favorites',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const RecordFavoritesScreen(),
        ),
      ),
      // v0.0.39 new features routes
      GoRoute(
        path: '/smart-habit-scheduling',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const SmartHabitSchedulingScreen(),
        ),
      ),
      GoRoute(
        path: '/cross-device-sync',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const CrossDeviceSyncScreen(),
        ),
      ),
      GoRoute(
        path: '/mood-music',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const MoodMusicScreen(),
        ),
      ),
      GoRoute(
        path: '/daily-briefing',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const DailyBriefingWidgetScreen(),
        ),
      ),
      GoRoute(
        path: '/focus-breathing',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const FocusBreathingScreen(),
        ),
      ),
      GoRoute(
        path: '/weekly-goal-reset',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const WeeklyGoalResetScreen(),
        ),
      ),
      GoRoute(
        path: '/location-routines',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const LocationRoutinesScreen(),
        ),
      ),
      GoRoute(
        path: '/habit-chaining',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const HabitChainingScreen(),
        ),
      ),
      GoRoute(
        path: '/energy-mood-correlation',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const EnergyMoodCorrelationScreen(),
        ),
      ),
      GoRoute(
        path: '/smart-notification-timing',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const SmartNotificationTimingScreen(),
        ),
      ),
      GoRoute(
        path: '/focus-sharing',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const FocusSharingScreen(),
        ),
      ),
      GoRoute(
        path: '/daily-achievements',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const DailyAchievementsScreen(),
        ),
      ),
      GoRoute(
        path: '/weekly-insights',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const WeeklyInsightsCardScreen(),
        ),
      ),
      GoRoute(
        path: '/data-health',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const DataHealthDashboardScreen(),
        ),
      ),
      // v0.0.40 new features routes
      GoRoute(
        path: '/smart-note-linking',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const SmartNoteLinkingScreen(),
        ),
      ),
      GoRoute(
        path: '/focus-analytics',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const FocusSessionAnalyticsScreen(),
        ),
      ),
      GoRoute(
        path: '/habit-template-market',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const HabitTemplateMarketplaceScreen(),
        ),
      ),
      GoRoute(
        path: '/daily-quote',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const DailyQuoteScreen(),
        ),
      ),
      GoRoute(
        path: '/habit-widget',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const HabitCheckinWidgetScreen(),
        ),
      ),
      GoRoute(
        path: '/activity-correlation',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const ActivityCorrelationEngineScreen(),
        ),
      ),
      GoRoute(
        path: '/goal-milestones',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const GoalMilestoneAlertsScreen(),
        ),
      ),
      GoRoute(
        path: '/smart-search',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const SmartSearchFiltersScreen(),
        ),
      ),
      GoRoute(
        path: '/daily-snapshot',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const DailyProgressSnapshotScreen(),
        ),
      ),
      GoRoute(
        path: '/mood-patterns',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const MoodPatternDetectionScreen(),
        ),
      ),
      GoRoute(
        path: '/quick-access',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const QuickAccessBarScreen(),
        ),
      ),
      GoRoute(
        path: '/record-history',
        pageBuilder: (context, state) {
          final recordId = int.tryParse(state.uri.queryParameters['recordId'] ?? '') ?? 0;
          return _buildPageWithTransition(
            key: state.pageKey,
            child: RecordVersionHistoryScreen(recordId: recordId),
          );
        },
      ),
      GoRoute(
        path: '/weekly-theme',
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const WeeklyThemeSuggestionsScreen(),
        ),
      ),
    ],
  );
});
