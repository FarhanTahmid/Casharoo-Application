import 'dart:math';
import '../models/cashbook.dart';

/// Replace with your networking layer. This file keeps the UI clean.
class CashbookUtils {
  Future<List<Cashbook>> fetchCashbooks() async {
    // TODO: Call your API; here’s demo data
    await Future.delayed(const Duration(milliseconds: 300));
    final now = DateTime.now();
    final rnd = Random(7);
    return List.generate(8, (i) {
      final bal = (rnd.nextInt(120000) - 40000).toDouble();
      final created = now.subtract(Duration(days: 160 + i * 8));
      final updated = now.subtract(Duration(days: rnd.nextInt(90)));
      return Cashbook(
        id: 'c_$i',
        name: [
          'AC EMI',
          'July 2025',
          'Eid Ul Adha Bonus',
          'Savings',
          'June 2025',
          'May 2025',
          'April 2025',
          'Household'
        ][i],
        description: 'Sample desc for item #$i',
        netBalance: bal,
        createdAt: created,
        updatedAt: updated,
      );
    });
  }

  List<Cashbook> sort(List<Cashbook> data, CashbookSort s) {
    final list = [...data];
    switch (s) {
      case CashbookSort.lastUpdated:
        list.sort((a,b)=> b.updatedAt.compareTo(a.updatedAt));
        break;
      case CashbookSort.nameAZ:
        list.sort((a,b)=> a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        break;
      case CashbookSort.netHighToLow:
        list.sort((a,b)=> b.netBalance.compareTo(a.netBalance));
        break;
      case CashbookSort.netLowToHigh:
        list.sort((a,b)=> a.netBalance.compareTo(b.netBalance));
        break;
      case CashbookSort.lastCreated:
        list.sort((a,b)=> b.createdAt.compareTo(a.createdAt));
        break;
    }
    return list;
  }

  Future<void> createCashbook(Cashbook cb) async {
    // TODO: POST to API
    await Future.delayed(const Duration(milliseconds: 200));
  }

  Future<void> deleteCashbook(String id) async {
    // TODO: DELETE API
    await Future.delayed(const Duration(milliseconds: 200));
  }
}
