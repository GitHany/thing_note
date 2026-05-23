import 'package:thing_note/features/record/domain/episode_record.dart';

enum BatchOperationType {
  changeTime,
  changeThingName,
  addTags,
  removeTags,
  changeFavorite,
  delete,
}

class BatchOperation {
  final BatchOperationType type;
  final List<int> recordIds;
  final Map<String, dynamic> parameters;

  const BatchOperation({
    required this.type,
    required this.recordIds,
    required this.parameters,
  });

  String get description {
    switch (type) {
      case BatchOperationType.changeTime:
        final offset = parameters['offset_minutes'] as int? ?? 0;
        return offset > 0 ? 'Delayed by $offset minutes' : 'Advanced by ${offset.abs()} minutes';
      case BatchOperationType.changeThingName:
        return 'Changed thing name';
      case BatchOperationType.addTags:
        return 'Added tags';
      case BatchOperationType.removeTags:
        return 'Removed tags';
      case BatchOperationType.changeFavorite:
        final isFavorite = parameters['is_favorite'] as bool? ?? false;
        return isFavorite ? 'Marked as favorite' : 'Unmarked as favorite';
      case BatchOperationType.delete:
        return 'Deleted records';
    }
  }
}

class BatchOperationService {
  Future<List<EpisodeRecord>> applyOperation(
    List<EpisodeRecord> records,
    BatchOperation operation,
  ) async {
    switch (operation.type) {
      case BatchOperationType.changeTime:
        return _changeTime(records, operation);
      case BatchOperationType.changeThingName:
        return _changeThingName(records, operation);
      case BatchOperationType.addTags:
        return _addTags(records, operation);
      case BatchOperationType.removeTags:
        return _removeTags(records, operation);
      case BatchOperationType.changeFavorite:
        return _changeFavorite(records, operation);
      case BatchOperationType.delete:
        // 删除操作需要特殊处理
        return records;
    }
  }

  List<EpisodeRecord> _changeTime(List<EpisodeRecord> records, BatchOperation op) {
    final offsetMinutes = op.parameters['offset_minutes'] as int? ?? 0;
    return records.map((r) {
      return r.copyWith(
        occurredAt: r.occurredAt.add(Duration(minutes: offsetMinutes)),
        updatedAt: DateTime.now(),
      );
    }).toList();
  }

  List<EpisodeRecord> _changeThingName(List<EpisodeRecord> records, BatchOperation op) {
    final thingNameId = op.parameters['thing_name_id'] as int?;
    return records.map((r) {
      return r.copyWith(
        thingNameId: thingNameId,
        updatedAt: DateTime.now(),
      );
    }).toList();
  }

  List<EpisodeRecord> _addTags(List<EpisodeRecord> records, BatchOperation op) {
    // 标签操作需要与标签系统集成
    // 这里只是占位，实际实现需要与 TagRepository 交互
    return records;
  }

  List<EpisodeRecord> _removeTags(List<EpisodeRecord> records, BatchOperation op) {
    return records;
  }

  List<EpisodeRecord> _changeFavorite(List<EpisodeRecord> records, BatchOperation op) {
    final isFavorite = op.parameters['is_favorite'] as bool? ?? false;
    return records.map((r) {
      return r.copyWith(
        isFavorite: isFavorite,
        updatedAt: DateTime.now(),
      );
    }).toList();
  }
}