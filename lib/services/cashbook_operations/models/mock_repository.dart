// lib/services/homepage/data/mock_entry_repository.dart
import 'dart:math';
import 'package:casharoo/services/cashbook_operations/data/entry.dart';
import '../models/filters.dart';
import '../data/category.dart';
import '../data/payment_method.dart';
import 'api_repository.dart';

class MockEntryRepository implements EntryRepository {
  final _rand = Random();

  final List<Entry> _entries = [];
  final List<Category> _cats = [
    Category(id: 'c1', name: 'Miscellaneous'),
    Category(id: 'c2', name: 'Office Transportation'),
  ];
  final List<PaymentMethod> _pms = [
    PaymentMethod(id: 'pm1', name: 'Cash'),
    PaymentMethod(id: 'pm2', name: 'Online'),
  ];

  MockEntryRepository() {
    // Seed 18 demo entries
    final String cashbookId = 'book-1';
    final now = DateTime.now();

    double running = 0;
    for (int i = 0; i < 18; i++) {
      final type = i.isEven ? EntryType.cashIn : EntryType.cashOut;
      final amount = (i + 1) * 150.0;

      // Simulate the user-picked date (date-only) and the creation timestamp
      final timestamp = now.subtract(Duration(days: i, minutes: i * 7));
      final date = DateTime(timestamp.year, timestamp.month, timestamp.day);
      final updatedAt = timestamp.add(const Duration(minutes: 3));

      running += type == EntryType.cashIn ? amount : -amount;

      _entries.add(
        Entry(
          id: 'e$i',
          cashbookId: cashbookId,
          date: date,
          timestamp: timestamp,
          updatedAt: updatedAt,
          type: type,
          amount: amount,
          title: type == EntryType.cashIn ? 'Income #$i' : 'Expense #$i',
          remark: type == EntryType.cashIn ? 'Received payment #$i' : 'Paid bill #$i',
          createdBy: 'You',
          categoryName: i.isEven ? 'Miscellaneous' : 'Office Transportation',
          paymentModeName: i.isEven ? 'Cash' : 'Online',
          runningBalance: running,
        ),
      );
    }

    // Shuffle a bit so it’s not perfectly alternating
    _entries.shuffle(_rand);
    // Sort newest first by timestamp (typical feed)
    _entries.sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  @override
  Future<(List<Entry>, double, double, double)> listEntries({
    required String cashbookId,
    required EntryFilters filters,
  }) async {
    await Future.delayed(const Duration(milliseconds: 250)); // simulate IO

    var list = _entries.where((e) => e.cashbookId == cashbookId).toList();

    // Quick filters
    if (filters.type != null) {
      list = list.where((e) => e.type == filters.type).toList();
    }
    if (filters.search != null && filters.search!.trim().isNotEmpty) {
      final q = filters.search!.toLowerCase();
      list = list.where((e) =>
        (e.title ?? '').toLowerCase().contains(q) ||
        (e.remark ?? '').toLowerCase().contains(q) ||
        e.categoryName.toLowerCase().contains(q) ||
        e.paymentModeName.toLowerCase().contains(q) ||
        (e.createdBy ?? '').toLowerCase().contains(q) ||
        e.amount.toString().contains(q)
      ).toList();
    }
    if (filters.dateRange != null) {
      final start = DateTime(filters.dateRange!.start.year, filters.dateRange!.start.month, filters.dateRange!.start.day);
      final end   = DateTime(filters.dateRange!.end.year, filters.dateRange!.end.month, filters.dateRange!.end.day, 23, 59, 59, 999);
      list = list.where((e) => !e.date.isBefore(start) && !e.date.isAfter(end)).toList();
    }

    // Totals
    final totalIn  = list.where((e)=>e.type==EntryType.cashIn).fold<double>(0,(s,e)=>s+e.amount);
    final totalOut = list.where((e)=>e.type==EntryType.cashOut).fold<double>(0,(s,e)=>s+e.amount);
    final net = totalIn - totalOut;

    // Sort newest first by timestamp for display
    list.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return (list, totalIn, totalOut, net);
  }

  @override
  Future<void> deleteEntriesBulk({
    required String cashbookId,
    required List<String> entryIds,
  }) async {
    _entries.removeWhere((e) => e.cashbookId == cashbookId && entryIds.contains(e.id));
    await Future.delayed(const Duration(milliseconds: 180));
  }

  @override
  Future<Entry> createEntry(Entry entry) async {
    _entries.insert(0, entry);
    await Future.delayed(const Duration(milliseconds: 120));
    return entry;
  }

  @override
  Future<void> deleteEntry(String entryId) async {
    _entries.removeWhere((e) => e.id == entryId);
    await Future.delayed(const Duration(milliseconds: 120));
  }

  @override
  Future<void> updateEntry(Entry entry) async {
    final i = _entries.indexWhere((e) => e.id == entry.id);
    if (i != -1) _entries[i] = entry;
    await Future.delayed(const Duration(milliseconds: 120));
  }

  // ---- Categories & Payment Modes (mock) ----

  @override
  Future<List<Category>> listCategories(String cashbookId) async {
    await Future.delayed(const Duration(milliseconds: 80));
    return List<Category>.from(_cats);
  }

  @override
  Future<Category> createCategory(String cashbookId, String name) async {
    final c = Category(id: 'c${_cats.length + 1}', name: name);
    _cats.add(c);
    await Future.delayed(const Duration(milliseconds: 100));
    return c;
  }

  @override
  Future<List<PaymentMethod>> listPaymentMethods(String cashbookId) async {
    await Future.delayed(const Duration(milliseconds: 80));
    return List<PaymentMethod>.from(_pms);
  }

  @override
  Future<PaymentMethod> createPaymentMethod(String cashbookId, String name) async {
    final p = PaymentMethod(id: 'p${_pms.length + 1}', name: name);
    _pms.add(p);
    await Future.delayed(const Duration(milliseconds: 100));
    return p;
  }
}