/// Data import source types
enum ImportSourceType {
  json,
  csv,
  thingNoteBackup,
  generic,
}

class ImportConfig {
  final ImportSourceType sourceType;
  final String filePath;
  final bool importPhotos;
  final bool importAudio;
  final bool importLocation;
  final bool createMissingTags;
  final bool createMissingThingNames;
  final bool preserveIds;
  final String? thingNameMapping; // JSON string for field mapping

  ImportConfig({
    required this.sourceType,
    required this.filePath,
    this.importPhotos = true,
    this.importAudio = true,
    this.importLocation = true,
    this.createMissingTags = true,
    this.createMissingThingNames = true,
    this.preserveIds = false,
    this.thingNameMapping,
  });
}

class ImportResult {
  final int totalRecords;
  final int successCount;
  final int failedCount;
  final List<String> errors;
  final List<int> importedRecordIds;
  final Duration duration;

  ImportResult({
    this.totalRecords = 0,
    this.successCount = 0,
    this.failedCount = 0,
    this.errors = const [],
    this.importedRecordIds = const [],
    required this.duration,
  });

  double get successRate => totalRecords > 0 ? successCount / totalRecords : 0;
}

class ImportPreview {
  final int recordCount;
  final int photoCount;
  final int audioCount;
  final int videoCount;
  final int documentCount;
  final List<String> tagsToCreate;
  final List<String> thingNamesToCreate;
  final String? dateRange;

  ImportPreview({
    this.recordCount = 0,
    this.photoCount = 0,
    this.audioCount = 0,
    this.videoCount = 0,
    this.documentCount = 0,
    this.tagsToCreate = const [],
    this.thingNamesToCreate = const [],
    this.dateRange,
  });
}

class ImportMapping {
  final String sourceField;
  final String targetField;
  final String? transform; // e.g., "date", "duration", "json"

  ImportMapping({
    required this.sourceField,
    required this.targetField,
    this.transform,
  });
}

class ImportTemplate {
  final int? id;
  final String name;
  final ImportSourceType sourceType;
  final List<ImportMapping> mappings;
  final bool hasHeader;
  final String delimiter;

  ImportTemplate({
    this.id,
    required this.name,
    required this.sourceType,
    this.mappings = const [],
    this.hasHeader = true,
    this.delimiter = ',',
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'source_type': sourceType.name,
      'mappings': mappings.map((m) => {
        'source_field': m.sourceField,
        'target_field': m.targetField,
        'transform': m.transform,
      }).toList(),
      'has_header': hasHeader ? 1 : 0,
      'delimiter': delimiter,
    };
  }

  factory ImportTemplate.fromMap(Map<String, dynamic> map) {
    final mappingsRaw = map['mappings'];
    List<ImportMapping> mappings = [];
    if (mappingsRaw is List) {
      mappings = mappingsRaw.map((m) {
        final mapItem = m as Map<String, dynamic>;
        return ImportMapping(
          sourceField: mapItem['source_field'] as String,
          targetField: mapItem['target_field'] as String,
          transform: mapItem['transform'] as String?,
        );
      }).toList();
    }

    return ImportTemplate(
      id: map['id'] as int?,
      name: map['name'] as String,
      sourceType: ImportSourceType.values.firstWhere(
        (t) => t.name == map['source_type'],
        orElse: () => ImportSourceType.generic,
      ),
      mappings: mappings,
      hasHeader: (map['has_header'] as int?) == 1,
      delimiter: map['delimiter'] as String? ?? ',',
    );
  }
}