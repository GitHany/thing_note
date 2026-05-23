class DataExport {
  final String format; // 'json', 'csv', 'pdf', 'excel'
  final DateTime startDate;
  final DateTime endDate;
  final List<String> includeTypes; // 'records', 'goals', 'habits', etc.
  final bool includeMedia;
  final String? filePath;

  DataExport({
    required this.format,
    required this.startDate,
    required this.endDate,
    this.includeTypes = const [],
    this.includeMedia = true,
    this.filePath,
  });

  Map<String, dynamic> toMap() {
    return {
      'format': format,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'include_types': includeTypes.join(','),
      'include_media': includeMedia ? 1 : 0,
      'file_path': filePath,
    };
  }
}

class ExportResult {
  final bool success;
  final String? filePath;
  final String? errorMessage;
  final int recordCount;
  final int fileSizeBytes;

  ExportResult({
    required this.success,
    this.filePath,
    this.errorMessage,
    this.recordCount = 0,
    this.fileSizeBytes = 0,
  });
}