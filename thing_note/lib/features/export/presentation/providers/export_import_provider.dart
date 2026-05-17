import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/record/domain/episode_record.dart';
import 'package:thing_note/features/export/data/zip_exporter.dart';

class ExportImportState {
  final double progress;
  final bool isExporting;
  final bool isImporting;
  final String statusMessage;
  final String? error;

  const ExportImportState({
    this.progress = 0.0,
    this.isExporting = false,
    this.isImporting = false,
    this.statusMessage = '',
    this.error,
  });

  ExportImportState copyWith({
    double? progress,
    bool? isExporting,
    bool? isImporting,
    String? statusMessage,
    String? error,
  }) {
    return ExportImportState(
      progress: progress ?? this.progress,
      isExporting: isExporting ?? this.isExporting,
      isImporting: isImporting ?? this.isImporting,
      statusMessage: statusMessage ?? this.statusMessage,
      error: error,
    );
  }
}

class ExportImportNotifier extends StateNotifier<ExportImportState> {
  ExportImportNotifier() : super(const ExportImportState());

  Future<File?> exportRecords({
    required List<EpisodeRecord> records,
    required List<String> thingNames,
  }) async {
    if (state.isExporting || state.isImporting) return null;

    state = state.copyWith(
      isExporting: true,
      progress: 0.0,
      statusMessage: '正在准备导出...',
      error: null,
    );

    try {
      final zipFile = await ZipExporter.exportRecords(
        records: records,
        thingNames: thingNames,
        onProgress: (current, total) {
          state = state.copyWith(
            progress: current / total,
            statusMessage: '正在导出: $current / $total',
          );
        },
      );

      state = state.copyWith(
        isExporting: false,
        progress: 1.0,
        statusMessage: '导出完成',
      );

      return zipFile;
    } catch (e) {
      state = state.copyWith(
        isExporting: false,
        error: e.toString(),
        statusMessage: '导出失败',
      );
      return null;
    }
  }

  void reset() {
    state = const ExportImportState();
  }
}

final exportImportNotifierProvider =
    StateNotifierProvider<ExportImportNotifier, ExportImportState>((ref) {
  return ExportImportNotifier();
});
