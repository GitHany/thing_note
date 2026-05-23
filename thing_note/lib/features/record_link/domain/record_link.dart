class RecordLink {
  final int? id;
  final int recordIdA;
  final int recordIdB;
  final DateTime createdAt;

  const RecordLink({
    this.id,
    required this.recordIdA,
    required this.recordIdB,
    required this.createdAt,
  });

  RecordLink copyWith({
    int? id,
    int? recordIdA,
    int? recordIdB,
    DateTime? createdAt,
  }) {
    return RecordLink(
      id: id ?? this.id,
      recordIdA: recordIdA ?? this.recordIdA,
      recordIdB: recordIdB ?? this.recordIdB,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Returns the other record ID given one side of the link
  int getOther(int recordId) {
    return recordId == recordIdA ? recordIdB : recordIdA;
  }
}