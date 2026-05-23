import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/smart_dashboard/data/smart_dashboard_repository.dart';
import 'package:thing_note/features/smart_dashboard/domain/smart_dashboard.dart';

final smartDashboardRepositoryProvider = Provider((ref) => SmartDashboardRepository(ref));

final allConfigsProvider = FutureProvider<List<SmartDashboardConfig>>((ref) async {
  final repo = ref.read(smartDashboardRepositoryProvider);
  return repo.getAllConfigs();
});

final activeConfigProvider = FutureProvider<SmartDashboardConfig?>((ref) async {
  final repo = ref.read(smartDashboardRepositoryProvider);
  return repo.getActiveConfig();
});