import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/grateful_notes/domain/grateful_notes.dart';

/// 今日感恩列表
final gratefulNotesProvider = FutureProvider<List<GratefulNote>>((ref) async {
  // TODO: 从数据库获取
  return [];
});

/// 感恩统计
final gratefulStatsProvider = FutureProvider<GratefulStats>((ref) async {
  // TODO: 计算统计
  return const GratefulStats();
});

/// 添加感恩
final addGratefulNoteProvider = Provider((ref) {
  return AddGratefulNotifier(ref);
});

class AddGratefulNotifier extends StateNotifier<bool> {
  final Ref ref;
  
  AddGratefulNotifier(this.ref) : super(false);
  
  Future<void> addNote(GratefulNote note) async {
    state = true;
    // TODO: 保存到数据库
    ref.invalidate(gratefulNotesProvider);
    state = false;
  }
}