import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/enhanced_voice/domain/voice_memo.dart';
import 'package:thing_note/features/enhanced_voice/data/voice_memo_repository.dart';
import 'package:thing_note/core/database/database_provider.dart';

final voiceMemoRepositoryProvider = FutureProvider<VoiceMemoRepository>((ref) async {
  final db = await ref.watch(databaseProvider.future);
  return VoiceMemoRepository(db);
});

final allVoiceMemosProvider = FutureProvider<List<VoiceMemo>>((ref) async {
  final repo = await ref.watch(voiceMemoRepositoryProvider.future);
  return repo.getAllMemos();
});

final favoriteVoiceMemosProvider = FutureProvider<List<VoiceMemo>>((ref) async {
  final repo = await ref.watch(voiceMemoRepositoryProvider.future);
  return repo.getFavoriteMemos();
});

final voiceMemosForRecordProvider = FutureProvider.family<List<VoiceMemo>, int>((ref, recordId) async {
  final repo = await ref.watch(voiceMemoRepositoryProvider.future);
  return repo.getMemosForRecord(recordId);
});

final voiceMemoSearchProvider = FutureProvider.family<List<VoiceMemo>, String>((ref, query) async {
  final repo = await ref.watch(voiceMemoRepositoryProvider.future);
  return repo.searchByTranscription(query);
});

class VoiceMemoNotifier extends StateNotifier<AsyncValue<List<VoiceMemo>>> {
  VoiceMemoNotifier() : super(const AsyncValue.data([]));

  Future<void> loadMemos() async {
    state = const AsyncValue.data([]);
  }

  Future<void> createMemo(VoiceMemo memo) async {
    // Placeholder
  }

  Future<void> updateMemo(VoiceMemo memo) async {
    // Placeholder
  }

  Future<void> deleteMemo(int id) async {
    // Placeholder
  }

  Future<void> toggleFavorite(int id) async {
    // Placeholder
  }
}

final voiceMemoNotifierProvider = StateNotifierProvider<VoiceMemoNotifier, AsyncValue<List<VoiceMemo>>>((ref) {
  return VoiceMemoNotifier();
});

/// Voice memo stats provider
final voiceMemoStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final repo = await ref.watch(voiceMemoRepositoryProvider.future);
  final totalDuration = await repo.getTotalDuration();
  final count = await repo.getMemoCount();
  return {
    'totalDuration': totalDuration,
    'count': count,
    'formattedDuration': _formatDuration(totalDuration),
  };
});

String _formatDuration(int seconds) {
  final hours = seconds ~/ 3600;
  final minutes = (seconds % 3600) ~/ 60;
  if (hours > 0) {
    return '${hours}h ${minutes}m';
  }
  return '${minutes}m';
}