class InvoiceEntry {
  final int? id;
  final String title;
  final String? clientName;
  final String? clientEmail;
  final String? clientAddress;
  final double amount;
  final String status;
  final String? issueDate;
  final String? dueDate;
  final String? paidDate;
  final String? invoiceNumber;
  final String? note;
  final String createdAt;
  final String? updatedAt;

  InvoiceEntry({
    this.id,
    required this.title,
    this.clientName,
    this.clientEmail,
    this.clientAddress,
    required this.amount,
    this.status = 'pending',
    this.issueDate,
    this.dueDate,
    this.paidDate,
    this.invoiceNumber,
    this.note,
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'client_name': clientName,
      'client_email': clientEmail,
      'client_address': clientAddress,
      'amount': amount,
      'status': status,
      'issue_date': issueDate,
      'due_date': dueDate,
      'paid_date': paidDate,
      'invoice_number': invoiceNumber,
      'note': note,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  factory InvoiceEntry.fromMap(Map<String, dynamic> map) {
    return InvoiceEntry(
      id: map['id'] as int?,
      title: map['title'] as String,
      clientName: map['client_name'] as String?,
      clientEmail: map['client_email'] as String?,
      clientAddress: map['client_address'] as String?,
      amount: (map['amount'] as num).toDouble(),
      status: map['status'] as String? ?? 'pending',
      issueDate: map['issue_date'] as String?,
      dueDate: map['due_date'] as String?,
      paidDate: map['paid_date'] as String?,
      invoiceNumber: map['invoice_number'] as String?,
      note: map['note'] as String?,
      createdAt: map['created_at'] as String,
      updatedAt: map['updated_at'] as String?,
    );
  }

  InvoiceEntry copyWith({
    int? id, String? title, String? clientName, String? clientEmail, String? clientAddress,
    double? amount, String? status, String? issueDate, String? dueDate, String? paidDate,
    String? invoiceNumber, String? note, String? createdAt, String? updatedAt,
  }) {
    return InvoiceEntry(
      id: id ?? this.id,
      title: title ?? this.title,
      clientName: clientName ?? this.clientName,
      clientEmail: clientEmail ?? this.clientEmail,
      clientAddress: clientAddress ?? this.clientAddress,
      amount: amount ?? this.amount,
      status: status ?? this.status,
      issueDate: issueDate ?? this.issueDate,
      dueDate: dueDate ?? this.dueDate,
      paidDate: paidDate ?? this.paidDate,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static const List<String> statuses = [
    'draft', 'sent', 'paid', 'overdue', 'cancelled',
  ];

  static String getStatusLabel(String status) {
    const labels = {
      'draft': '草稿',
      'sent': '已发送',
      'paid': '已支付',
      'overdue': '已逾期',
      'cancelled': '已取消',
    };
    return labels[status] ?? status;
  }
}