import 'dart:convert';
import 'dart:math';
import 'package:casharoo/helpers/backend_config.dart';
import 'package:casharoo/services/auth/auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../models/cashbook.dart';

/// Replace with your networking layer. This file keeps the UI clean.
class CashbookUtils {
  Future<List<Cashbook>> fetchCashbooks() async {
    try {
      final Uri uri = BackendConfig.endpoint('/cashbooks/cashbooks/');
      final response = await AuthService.authenticatedRequest('GET', uri);

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        // Handle paginated response
        if (responseData is Map && responseData.containsKey('results')) {
          final List<dynamic> data = responseData['results'];
          return data.map((json) => Cashbook.fromJson(json)).toList();
        }
        // Handle direct list
        else if (responseData is List) {
          return responseData.map((json) => Cashbook.fromJson(json)).toList();
        } else {
          throw Exception('Unexpected response format');
        }
      } else {
        throw Exception('Failed to fetch cashbooks: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to fetch cashbooks: $e');
    }
  }

  List<Cashbook> sort(List<Cashbook> data, CashbookSort s) {
    final list = [...data];
    switch (s) {
      case CashbookSort.lastUpdated:
        list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        break;
      case CashbookSort.nameAZ:
        list.sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );
        break;
      case CashbookSort.netHighToLow:
        list.sort((a, b) => b.netBalance.compareTo(a.netBalance));
        break;
      case CashbookSort.netLowToHigh:
        list.sort((a, b) => a.netBalance.compareTo(b.netBalance));
        break;
      case CashbookSort.lastCreated:
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
    }
    return list;
  }

  Future<Cashbook> createCashbook(String name, String? description) async {
    try {
      final Uri uri = BackendConfig.endpoint('/cashbooks/cashbooks/');
      final response = await AuthService.authenticatedRequest(
        'POST',
        uri,
        body: {'book_name': name, 'description': description},
      );
      if (response.statusCode == 201) {
        return Cashbook.fromJson(jsonDecode(response.body));
      } else {
        throw Exception(
          'Failed to create cashbook: ${response.statusCode}-${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Failed to create cashbook: $e');
    }
  }

  Future<void> deleteCashbook(String id) async {
    try {
      final Uri uri = BackendConfig.endpoint('/cashbooks/cashbooks/$id/');
      final response = await AuthService.authenticatedRequest('DELETE', uri);
      if (response.statusCode != 204 && response.statusCode != 200) {
        throw Exception('Failed to delete cashbook: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to delete cashbook: $e');
    }
  }

  Future<void> updateCashbook(
    Cashbook cb, [
    String? name,
    String? description,
  ]) async {
    final Uri uri = BackendConfig.endpoint('/cashbooks/cashbooks/${cb.id}/');
    
    // Build body dynamically - only include fields that are provided
    final Map<String, dynamic> body = {};
    if (name != null) body['book_name'] = name;
    if (description != null) body['description'] = description;
    
    // If nothing to update, return early
    if (body.isEmpty) {
      throw Exception('No fields provided to update');
    }
    
    final response = await AuthService.authenticatedRequest(
      'PATCH',  // ← Use PATCH for partial updates, not PUT
      uri,
      body: body,
    );
    
    if (response.statusCode != 200) {
      throw Exception('Failed to update cashbook: ${response.statusCode}');
    }
  }

  Future<void> bulkDeleteCashbooks(List<String> list) async {
    final Uri uri = BackendConfig.endpoint('/cashbooks/cashbooks/bulk-delete/');
    final response = await AuthService.authenticatedRequest(
      'DELETE',  // ← Use PATCH for partial updates, not PUT
      uri,
      body: {
        "ids":list
      },
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to delete cashbooks: ${response.statusCode}');
    }
  }
}
