enum EntryType { cashIn, cashOut }

class Entry {
  final String id;
  final String cashbookId;
  final DateTime date;
  final DateTime timestamp;
  final DateTime updatedAt;
  final EntryType type;
  final String? title;
  final double amount;
  final String? remark;
  final String? createdBy;
  final String categoryName;
  final String paymentModeName;
  final double runningBalance;

  Entry({
    required this.id,
    required this.cashbookId,
    required this.date,
    required this.timestamp,
    required this.updatedAt,
    required this.type,
    required this.amount,
    required this.categoryName,
    required this.paymentModeName,
    required this.runningBalance,
    this.remark,
    this.createdBy,
    this.title,

  });
}
