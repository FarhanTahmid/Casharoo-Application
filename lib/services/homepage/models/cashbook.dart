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

  // Add this factory constructor
  factory Cashbook.fromJson(Map<String, dynamic> json) {
    return Cashbook(
      id: json['id'],
      name: json['book_name'],
      description: json['description'],
      netBalance: double.parse(json['balance'].toString()),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: json['last_edited_at'] != null
          ? DateTime.parse(json['last_edited_at'])
          : DateTime.parse(json['created_at']),
    );
  }

  // Optional: Add toJson for sending data
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'book_name': name,
      'description': description,
      'balance': netBalance,
      'created_at': createdAt.toIso8601String(),
      'last_edited_at': updatedAt.toIso8601String(),
    };
  }
}
