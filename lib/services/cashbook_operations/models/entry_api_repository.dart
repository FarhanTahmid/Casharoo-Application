import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';

import '../data/entry.dart';
import '../models/filters.dart';
import '../data/category.dart';
import '../data/payment_method.dart';

import 'package:casharoo/helpers/backend_config.dart';
import 'package:casharoo/services/auth/auth.dart';
import 'package:casharoo/api_exception.dart';
import 'package:casharoo/helpers/helpers.dart';

import 'api_repository.dart';

class EntryApiRepository implements EntryRepository {
  // ---------- Public API ----------

  @override
  Future<(List<Entry>, double, double, double)> listEntries({
    required String cashbookId,
    required EntryFilters filters,
  }) async {
    try {
      final qp = <String, String>{};

      // Map filters to query params expected by your DRF
      if (filters.search != null && filters.search!.trim().isNotEmpty) {
        qp['search'] = filters.search!.trim();
      }
      if (filters.type != null) {
        qp['type'] = filters.type == EntryType.cashIn ? 'cash_in' : 'cash_out';
      }
      if (filters.dateRange != null) {
        qp['date_from'] = _isoDate(filters.dateRange!.start);
        qp['date_to'] = _isoDate(filters.dateRange!.end);
      }
      if (filters.category != null && filters.category!.trim().isNotEmpty) {
        qp['category'] = filters.category!;
      }
      if (filters.paymentMode != null &&
          filters.paymentMode!.trim().isNotEmpty) {
        qp['payment_mode'] = filters.paymentMode!;
      }

      final uri = BackendConfig.endpoint(_entriesPath(cashbookId, qp: qp));
      final response = await AuthService.authenticatedRequest('GET', uri)
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () => throw ApiException.timeout('list entries'),
          );

      if (response.statusCode == 200) {
        final payload = jsonDecode(response.body);

        // Support paginated {results: [...], total_in, total_out, net} OR plain list
        final List<dynamic> raw = payload is Map && payload['results'] is List
            ? payload['results'] as List
            : (payload is List ? payload : <dynamic>[]);

        final entries = raw.map<Entry>(_parseEntry).toList();

        // Totals: prefer server values; otherwise compute locally
        final double totalIn =
            _toDoubleOrNull(payload is Map ? payload['total_in'] : null) ??
            entries
                .where((e) => e.type == EntryType.cashIn)
                .fold(0.0, (s, e) => s + e.amount);
        final double totalOut =
            _toDoubleOrNull(payload is Map ? payload['total_out'] : null) ??
            entries
                .where((e) => e.type == EntryType.cashOut)
                .fold(0.0, (s, e) => s + e.amount);
        final double net =
            _toDoubleOrNull(payload is Map ? payload['net'] : null) ??
            (totalIn - totalOut);

        return (entries, totalIn, totalOut, net);
      } else {
        final msg = HelperFunctions.extractDjangoError(response.body);
        throw ApiException(
          message: msg ?? 'Failed to list entries. Please try again.',
          statusCode: response.statusCode,
          type: _getExceptionType(response.statusCode),
        );
      }
    } on SocketException {
      throw ApiException.network('list entries');
    } on TimeoutException {
      throw ApiException.timeout('list entries');
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        message: 'Failed to list entries: $e',
        type: ApiExceptionType.unknown,
      );
    }
  }

  @override
  Future<Entry> createEntry(Entry entry) async {
    try {
      final uri = BackendConfig.endpoint(_entriesPath(entry.cashbookId));
      final response =
          await AuthService.authenticatedRequest(
            'POST',
            uri,
            body: _entryToPayload(entry),
          ).timeout(
            const Duration(seconds: 30),
            onTimeout: () => throw ApiException.timeout('create entry'),
          );
      debugPrint("Response: ${jsonDecode(response.body)}");
      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Some backends return envelope {data: {...}}
        final obj = (data is Map && data['data'] != null) ? data['data'] : data;
        return _parseEntry(obj);
      } else {
        final msg = HelperFunctions.extractDjangoError(response.body);
        throw ApiException(
          message: msg ?? 'Failed to create entry. Please try again.',
          statusCode: response.statusCode,
          type: _getExceptionType(response.statusCode),
        );
      }
    } on SocketException {
      throw ApiException.network('create entry');
    } on TimeoutException {
      throw ApiException.timeout('create entry');
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        message: 'Failed to create entry: $e',
        type: ApiExceptionType.unknown,
      );
    }
  }

  @override
  Future<void> updateEntry(Entry entry) async {
    try {
      final uri = BackendConfig.endpoint(
        _entryDetailPath(entry.cashbookId, entry.id),
      );
      final response =
          await AuthService.authenticatedRequest(
            'PATCH',
            uri,
            body: _entryToPayload(entry, partial: true),
          ).timeout(
            const Duration(seconds: 30),
            onTimeout: () => throw ApiException.timeout('update entry'),
          );

      if (response.statusCode != 200) {
        final msg = HelperFunctions.extractDjangoError(response.body);
        throw ApiException(
          message: msg ?? 'Failed to update entry.',
          statusCode: response.statusCode,
          type: _getExceptionType(response.statusCode),
        );
      }
    } on SocketException {
      throw ApiException.network('update entry');
    } on TimeoutException {
      throw ApiException.timeout('update entry');
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        message: 'Failed to update entry: $e',
        type: ApiExceptionType.unknown,
      );
    }
  }

  @override
  Future<void> deleteEntry(String entryId) async {
    // If your API needs cashbookId for delete, call the bulk endpoint with one id instead.
    // Otherwise you can expose a top-level /entries/{id}/ route in DRF. We implement both:
    try {
      // Try a generic top-level delete first (if you have it)
      final tryTopLevel = BackendConfig.endpoint(
        '/cashbooks/entries/$entryId/',
      );
      final res = await AuthService.authenticatedRequest('DELETE', tryTopLevel)
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () => throw ApiException.timeout('delete entry'),
          );

      if (res.statusCode == 204 || res.statusCode == 200) return;

      // If backend doesn’t expose top-level, return a clear error to switch the caller to bulk delete with cashbookId.
      final msg = HelperFunctions.extractDjangoError(res.body);
      throw ApiException(
        message: msg ?? 'Delete entry failed. Use bulk delete with cashbookId.',
        statusCode: res.statusCode,
        type: _getExceptionType(res.statusCode),
      );
    } on SocketException {
      throw ApiException.network('delete entry');
    } on TimeoutException {
      throw ApiException.timeout('delete entry');
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        message: 'Failed to delete entry: $e',
        type: ApiExceptionType.unknown,
      );
    }
  }

  @override
  Future<void> deleteEntriesBulk({
    required String cashbookId,
    required List<String> entryIds,
  }) async {
    if (entryIds.isEmpty) {
      throw ApiException(
        message: 'No entries selected for deletion.',
        type: ApiExceptionType.validation,
      );
    }
    if (entryIds.length > 200) {
      throw ApiException(
        message: 'Cannot delete more than 200 entries at once.',
        type: ApiExceptionType.validation,
      );
    }

    try {
      final uri = BackendConfig.endpoint(_entriesBulkDeletePath(cashbookId));
      // You used DELETE with body for cashbooks bulk delete, keep same convention here.
      final response =
          await AuthService.authenticatedRequest(
            'DELETE',
            uri,
            body: {'ids': entryIds},
          ).timeout(
            const Duration(seconds: 30),
            onTimeout: () => throw ApiException.timeout('bulk delete entries'),
          );

      if (response.statusCode != 200) {
        final msg = HelperFunctions.extractDjangoError(response.body);
        throw ApiException(
          message: msg ?? 'Failed to delete entries. Please try again.',
          statusCode: response.statusCode,
          type: _getExceptionType(response.statusCode),
        );
      }
    } on SocketException {
      throw ApiException.network('bulk delete entries');
    } on TimeoutException {
      throw ApiException.timeout('bulk delete entries');
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        message: 'Failed to bulk delete entries: $e',
        type: ApiExceptionType.unknown,
      );
    }
  }

  // ---------- Categories ----------

  @override
  Future<List<Category>> listCategories(String cashbookId) async {
    try {
      final uri = BackendConfig.endpoint(_categoriesPath(cashbookId));
      final response = await AuthService.authenticatedRequest('GET', uri)
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () => throw ApiException.timeout('list categories'),
          );

      if (response.statusCode == 200) {
        final payload = jsonDecode(response.body);
        final List<dynamic> raw = payload is Map && payload['results'] is List
            ? payload['results'] as List
            : (payload is List ? payload : <dynamic>[]);

        return raw
            .map<Category>(
              (j) => Category(
                id: j['id'].toString(),
                name: (j['name'] ?? j['title'] ?? '').toString(),
              ),
            )
            .toList();
      } else {
        final msg = HelperFunctions.extractDjangoError(response.body);
        throw ApiException(
          message: msg ?? 'Failed to fetch categories.',
          statusCode: response.statusCode,
          type: _getExceptionType(response.statusCode),
        );
      }
    } on SocketException {
      throw ApiException.network('list categories');
    } on TimeoutException {
      throw ApiException.timeout('list categories');
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        message: 'Failed to list categories: $e',
        type: ApiExceptionType.unknown,
      );
    }
  }

  @override
  Future<Category> createCategory(String cashbookId, String name) async {
    if (name.trim().isEmpty) {
      throw ApiException(
        message: 'Category name is required.',
        type: ApiExceptionType.validation,
      );
    }

    try {
      final uri = BackendConfig.endpoint(_categoriesPath(cashbookId));
      final response =
          await AuthService.authenticatedRequest(
            'POST',
            uri,
            body: {'name': name.trim()},
          ).timeout(
            const Duration(seconds: 30),
            onTimeout: () => throw ApiException.timeout('create category'),
          );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final obj = (data is Map && data['data'] != null) ? data['data'] : data;
        return Category(
          id: obj['id'].toString(),
          name: (obj['name'] ?? obj['title'] ?? '').toString(),
        );
      } else {
        final msg = HelperFunctions.extractDjangoError(response.body);
        throw ApiException(
          message: msg ?? 'Failed to create category.',
          statusCode: response.statusCode,
          type: _getExceptionType(response.statusCode),
        );
      }
    } on SocketException {
      throw ApiException.network('create category');
    } on TimeoutException {
      throw ApiException.timeout('create category');
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        message: 'Failed to create category: $e',
        type: ApiExceptionType.unknown,
      );
    }
  }

  // ---------- Payment Methods ----------

  @override
  Future<List<PaymentMethod>> listPaymentMethods(String cashbookId) async {
    try {
      final uri = BackendConfig.endpoint(_paymentMethodsPath(cashbookId));
      final response = await AuthService.authenticatedRequest('GET', uri)
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () => throw ApiException.timeout('list payment methods'),
          );

      if (response.statusCode == 200) {
        final payload = jsonDecode(response.body);
        final List<dynamic> raw = payload is Map && payload['results'] is List
            ? payload['results'] as List
            : (payload is List ? payload : <dynamic>[]);

        return raw
            .map<PaymentMethod>(
              (j) => PaymentMethod(
                id: j['id'].toString(),
                name: (j['name'] ?? j['title'] ?? '').toString(),
              ),
            )
            .toList();
      } else {
        final msg = HelperFunctions.extractDjangoError(response.body);
        throw ApiException(
          message: msg ?? 'Failed to fetch payment methods.',
          statusCode: response.statusCode,
          type: _getExceptionType(response.statusCode),
        );
      }
    } on SocketException {
      throw ApiException.network('list payment methods');
    } on TimeoutException {
      throw ApiException.timeout('list payment methods');
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        message: 'Failed to list payment methods: $e',
        type: ApiExceptionType.unknown,
      );
    }
  }

  @override
  Future<PaymentMethod> createPaymentMethod(
    String cashbookId,
    String name,
  ) async {
    if (name.trim().isEmpty) {
      throw ApiException(
        message: 'Payment method name is required.',
        type: ApiExceptionType.validation,
      );
    }

    try {
      final uri = BackendConfig.endpoint(_paymentMethodsPath(cashbookId));
      final response =
          await AuthService.authenticatedRequest(
            'POST',
            uri,
            body: {'name': name.trim()},
          ).timeout(
            const Duration(seconds: 30),
            onTimeout: () =>
                throw ApiException.timeout('create payment method'),
          );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final obj = (data is Map && data['data'] != null) ? data['data'] : data;
        return PaymentMethod(
          id: obj['id'].toString(),
          name: (obj['name'] ?? obj['title'] ?? '').toString(),
        );
      } else {
        final msg = HelperFunctions.extractDjangoError(response.body);
        throw ApiException(
          message: msg ?? 'Failed to create payment method.',
          statusCode: response.statusCode,
          type: _getExceptionType(response.statusCode),
        );
      }
    } on SocketException {
      throw ApiException.network('create payment method');
    } on TimeoutException {
      throw ApiException.timeout('create payment method');
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        message: 'Failed to create payment method: $e',
        type: ApiExceptionType.unknown,
      );
    }
  }

  // ---------- Optional: Summary (for balance carousel) ----------

  Future<({double totalIn, double totalOut, double net})> summary(
    String cashbookId, {
    EntryFilters? filters,
  }) async {
    try {
      final qp = <String, String>{};
      if (filters?.dateRange != null) {
        qp['date_from'] = _isoDate(filters!.dateRange!.start);
        qp['date_to'] = _isoDate(filters.dateRange!.end);
      }

      final uri = BackendConfig.endpoint(_statsSummaryPath(cashbookId, qp: qp));
      final response = await AuthService.authenticatedRequest('GET', uri)
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () => throw ApiException.timeout('fetch summary'),
          );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final totalIn = _toDoubleOrZero(data['total_in']);
        final totalOut = _toDoubleOrZero(data['total_out']);
        final net = _toDoubleOrZero(data['net']);
        return (totalIn: totalIn, totalOut: totalOut, net: net);
      } else {
        final msg = HelperFunctions.extractDjangoError(response.body);
        throw ApiException(
          message: msg ?? 'Failed to fetch summary.',
          statusCode: response.statusCode,
          type: _getExceptionType(response.statusCode),
        );
      }
    } on SocketException {
      throw ApiException.network('fetch summary');
    } on TimeoutException {
      throw ApiException.timeout('fetch summary');
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        message: 'Failed to fetch summary: $e',
        type: ApiExceptionType.unknown,
      );
    }
  }

  // ---------- Helpers ----------

  // Routes (follow your working CashbookUtils prefix)
  String _base(String cashbookId) => '/cashbooks/cashbooks/$cashbookId';
  String _entriesPath(String cashbookId, {Map<String, String>? qp}) =>
      _withQuery('${_base(cashbookId)}/entries/', qp);
  String _entryDetailPath(String cashbookId, String entryId) =>
      '${_base(cashbookId)}/entries/$entryId/';
  String _entriesBulkDeletePath(String cashbookId) =>
      '${_base(cashbookId)}/entries/bulk-delete/';

  String _categoriesPath(String cashbookId) =>
      '${_base(cashbookId)}/categories/';
  String _paymentMethodsPath(String cashbookId) =>
      '${_base(cashbookId)}/payment-methods/';
  String _statsSummaryPath(String cashbookId, {Map<String, String>? qp}) =>
      _withQuery('${_base(cashbookId)}/stats/summary/', qp);

  String _withQuery(String path, Map<String, String>? qp) {
    if (qp == null || qp.isEmpty) return path;
    final q = qp.entries
        .map(
          (e) =>
              '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value)}',
        )
        .join('&');
    return '$path?$q';
  }

  String _isoDate(DateTime d) =>
      DateTime(d.year, d.month, d.day).toIso8601String().substring(0, 10);

  ApiExceptionType _getExceptionType(int statusCode) {
    switch (statusCode) {
      case 400:
        return ApiExceptionType.validation;
      case 401:
        return ApiExceptionType.authentication;
      case 403:
        return ApiExceptionType.permission;
      case 404:
        return ApiExceptionType.notFound;
      case 409:
        return ApiExceptionType.conflict;
      case 500:
      case 502:
      case 503:
        return ApiExceptionType.server;
      default:
        return ApiExceptionType.unknown;
    }
  }

  double _toDoubleOrZero(dynamic v) {
    if (v is num) return v.toDouble();
    if (v == null) return 0.0;
    return double.tryParse(v.toString()) ?? 0.0;
  }

  double? _toDoubleOrNull(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }

  /// Parse one entry JSON object from DRF.
  Entry _parseEntry(dynamic j) {
    final m = (j as Map<String, dynamic>);
    final type = (m['type'] == 'in' || m['type'] == 'cash_in')
        ? EntryType.cashIn
        : EntryType.cashOut;

    DateTime _parseDt(dynamic x, {bool dateOnly = false}) {
      if (x == null) return DateTime.now();
      final s = x.toString();
      try {
        final d = DateTime.parse(s);
        if (dateOnly) return DateTime(d.year, d.month, d.day);
        return d;
      } catch (_) {
        // Fallback if backend sends date-only without 'T'
        if (dateOnly && RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(s)) {
          final parts = s.split('-').map((e) => int.parse(e)).toList();
          return DateTime(parts[0], parts[1], parts[2]);
        }
        return DateTime.now();
      }
    }

    return Entry(
      id: m['id'].toString(),
      cashbookId:
          m['cashbook_id']?.toString() ?? m['cashbook']?.toString() ?? '',
      date: _parseDt(m['date'], dateOnly: true),
      timestamp: _parseDt(m['timestamp']),
      updatedAt: _parseDt(m['updated_at']),
      type: type,
      amount: _toDoubleOrZero(m['amount']),
      title: m['title']?.toString(),
      remark: m['remark']?.toString(),
      createdBy: m['created_by']?.toString(),
      categoryName: (m['category_name'] ?? m['category'] ?? 'Miscellaneous')
          .toString(),
      paymentModeName: (m['payment_mode_name'] ?? m['payment_method'] ?? 'Cash')
          .toString(),
      runningBalance: _toDoubleOrZero(m['running_balance']),
    );
  }

  Map<String, dynamic> _entryToPayload(Entry e, {bool partial = false}) {
    // Keep keys aligned with your DRF serializers.
    final map = <String, dynamic>{
      'cashbook_id': e.cashbookId,
      'entry_date': _isoDate(e.date),
      'timestamp': e.timestamp.toIso8601String(),
      'type': e.type == EntryType.cashIn ? 'cash_in' : 'cash_out',
      'amount': e.amount,
      'remark': e.remark,
      'title': e.title,
      'category_name': e.categoryName,
      'payment_mode_name': e.paymentModeName,
    };

    if (partial) {
      // Remove nulls to avoid PATCHing empty fields
      map.removeWhere((_, v) => v == null);
    }
    return map;
  }
}
