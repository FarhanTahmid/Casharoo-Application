import '../data/entry.dart';
import '../models/filters.dart';
import '../data/category.dart';
import '../data/payment_method.dart';

abstract class EntryRepository {
  Future<(List<Entry> entries, double totalIn, double totalOut, double net)>
      listEntries({
    required String cashbookId,
    required EntryFilters filters,
  });

  Future<void> deleteEntriesBulk({
    required String cashbookId,
    required List<String> entryIds,
  });

  Future<Entry> createEntry(Entry entry);
  Future<void> deleteEntry(String entryId);
  Future<void> updateEntry(Entry entry);

  // Suggestions & CRUD shells for popups (plug your endpoints)
  Future<List<Category>> listCategories(String cashbookId);
  Future<Category> createCategory(String cashbookId, String name);

  Future<List<PaymentMethod>> listPaymentMethods(String cashbookId);
  Future<PaymentMethod> createPaymentMethod(String cashbookId, String name);
}
