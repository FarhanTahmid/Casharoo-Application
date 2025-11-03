import 'package:casharoo/services/cashbook_operations/data/entry.dart';
import 'package:flutter/material.dart';

class EntryFilters {
  DateTimeRange? dateRange;
  EntryType? type;
  String? member;
  String? category;
  String? paymentMode;
  String? search;

  EntryFilters({
    this.dateRange,
    this.type,
    this.member,
    this.category,
    this.paymentMode,
    this.search,
  });

  EntryFilters copyWith({
    DateTimeRange? dateRange,
    EntryType? type,
    String? member,
    String? category,
    String? paymentMode,
    String? search,
  }) {
    return EntryFilters(
      dateRange: dateRange ?? this.dateRange,
      type: type ?? this.type,
      member: member ?? this.member,
      category: category ?? this.category,
      paymentMode: paymentMode ?? this.paymentMode,
      search: search ?? this.search,
    );
  }

  bool get isEmpty =>
      dateRange == null &&
      type == null &&
      member == null &&
      category == null &&
      paymentMode == null &&
      (search == null || search!.isEmpty);
}
