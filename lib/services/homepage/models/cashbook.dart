import 'package:flutter/material.dart';

enum CashbookSort { lastUpdated, nameAZ, netHighToLow, netLowToHigh, lastCreated }

class Cashbook {
  final String id;
  final String name;
  final String description;
  final double netBalance; // positive = green, negative = red
  final DateTime createdAt;
  final DateTime updatedAt;

  Cashbook({
    required this.id,
    required this.name,
    required this.description,
    required this.netBalance,
    required this.createdAt,
    required this.updatedAt,
  });

  // Helper for demo formatting
  String get friendlyUpdated =>
      'Updated on ${_monthDayYear(updatedAt)}';

  static String _monthDayYear(DateTime d) {
    // Simple cross-platform formatter
    const months = [
      'Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'
    ];
    return '${months[d.month - 1]} ${d.day.toString().padLeft(2,'0')} ${d.year}';
  }

  Color balanceColor(Color positive, Color negative) =>
      netBalance >= 0 ? positive : negative;
}
