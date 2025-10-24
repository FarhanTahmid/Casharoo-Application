import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:casharoo/helpers/backend_config.dart';
import 'package:casharoo/services/auth/auth.dart';

import '../models/cashbook.dart';
import 'package:casharoo/helpers/helpers.dart';
import 'package:casharoo/api_exception.dart';

/// Replace with your networking layer. This file keeps the UI clean.
class CashbookUtils {
  
  /// Fetch all cashbooks with comprehensive error handling
  Future<List<Cashbook>> fetchCashbooks() async {
    try {
      final Uri uri = BackendConfig.endpoint('/cashbooks/cashbooks/');
      final response = await AuthService.authenticatedRequest('GET', uri)
          .timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw ApiException.timeout('fetch cashbooks'),
      );

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
          throw ApiException(
            message: 'Unexpected response format from server.',
            type: ApiExceptionType.unknown,
          );
        }
      } else {
        // Extract Django error message
        final errorMsg = HelperFunctions.extractDjangoError(response.body);
        throw ApiException(
          message: errorMsg ?? 'Failed to fetch cashbooks. Please try again.',
          statusCode: response.statusCode,
          type: _getExceptionType(response.statusCode),
        );
      }
    } on SocketException {
      throw ApiException.network('fetch cashbooks');
    } on TimeoutException {
      throw ApiException.timeout('fetch cashbooks');
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        message: 'Failed to fetch cashbooks: ${e.toString()}',
        type: ApiExceptionType.unknown,
      );
    }
  }

  /// Sort cashbooks locally
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

  /// Create a new cashbook with validation and error handling
  Future<Cashbook> createCashbook(String name, String? description) async {
    // Client-side validation
    if (name.trim().isEmpty) {
      throw ApiException(
        message: 'Cashbook name is required.',
        type: ApiExceptionType.validation,
      );
    }

    if (name.length > 100) {
      throw ApiException(
        message: 'Cashbook name must not exceed 100 characters.',
        type: ApiExceptionType.validation,
      );
    }

    try {
      final Uri uri = BackendConfig.endpoint('/cashbooks/cashbooks/');
      final response = await AuthService.authenticatedRequest(
        'POST',
        uri,
        body: {'book_name': name.trim(), 'description': description?.trim()},
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw ApiException.timeout('create cashbook'),
      );

      if (response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        
        // Check if response has 'data' field (from enhanced backend)
        final cashbookData = responseData is Map && responseData.containsKey('data')
            ? responseData['data']
            : responseData;
        
        return Cashbook.fromJson(cashbookData);
      } else {
        // Extract Django error message
        final errorMsg = HelperFunctions.extractDjangoError(response.body);
        throw ApiException(
          message: errorMsg ?? 'Failed to create cashbook. Please try again.',
          statusCode: response.statusCode,
          type: _getExceptionType(response.statusCode),
        );
      }
    } on SocketException {
      throw ApiException.network('create cashbook');
    } on TimeoutException {
      throw ApiException.timeout('create cashbook');
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        message: 'Failed to create cashbook: ${e.toString()}',
        type: ApiExceptionType.unknown,
      );
    }
  }

  /// Delete a cashbook with error handling
  Future<void> deleteCashbook(String id) async {
    try {
      final Uri uri = BackendConfig.endpoint('/cashbooks/cashbooks/$id/');
      final response = await AuthService.authenticatedRequest('DELETE', uri)
          .timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw ApiException.timeout('delete cashbook'),
      );

      if (response.statusCode != 204 && response.statusCode != 200) {
        // Extract Django error message
        final errorMsg = HelperFunctions.extractDjangoError(response.body);
        throw ApiException(
          message: errorMsg ?? 'Failed to delete cashbook. Please try again.',
          statusCode: response.statusCode,
          type: _getExceptionType(response.statusCode),
        );
      }
    } on SocketException {
      throw ApiException.network('delete cashbook');
    } on TimeoutException {
      throw ApiException.timeout('delete cashbook');
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        message: 'Failed to delete cashbook: ${e.toString()}',
        type: ApiExceptionType.unknown,
      );
    }
  }

  /// Update a cashbook with validation and error handling
  Future<void> updateCashbook(
    Cashbook cb, [
    String? name,
    String? description,
  ]) async {
    // Build body dynamically - only include fields that are provided
    final Map<String, dynamic> body = {};
    
    if (name != null) {
      final trimmedName = name.trim();
      if (trimmedName.isEmpty) {
        throw ApiException(
          message: 'Cashbook name cannot be empty.',
          type: ApiExceptionType.validation,
        );
      }
      if (trimmedName.length > 100) {
        throw ApiException(
          message: 'Cashbook name must not exceed 100 characters.',
          type: ApiExceptionType.validation,
        );
      }
      body['book_name'] = trimmedName;
    }
    
    if (description != null) {
      body['description'] = description.trim();
    }

    // If nothing to update, throw validation error
    if (body.isEmpty) {
      throw ApiException(
        message: 'No fields provided to update.',
        type: ApiExceptionType.validation,
      );
    }

    try {
      final Uri uri = BackendConfig.endpoint('/cashbooks/cashbooks/${cb.id}/');
      final response = await AuthService.authenticatedRequest(
        'PATCH',
        uri,
        body: body,
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw ApiException.timeout('update cashbook'),
      );

      if (response.statusCode != 200) {
        // Extract Django error message
        final errorMsg = HelperFunctions.extractDjangoError(response.body);
        throw ApiException(
          message: errorMsg ?? 'Failed to update cashbook. Please try again.',
          statusCode: response.statusCode,
          type: _getExceptionType(response.statusCode),
        );
      }
    } on SocketException {
      throw ApiException.network('update cashbook');
    } on TimeoutException {
      throw ApiException.timeout('update cashbook');
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        message: 'Failed to update cashbook: ${e.toString()}',
        type: ApiExceptionType.unknown,
      );
    }
  }

  /// Bulk delete cashbooks with validation and error handling
  Future<void> bulkDeleteCashbooks(List<String> list) async {
    // Client-side validation
    if (list.isEmpty) {
      throw ApiException(
        message: 'No cashbooks selected for deletion.',
        type: ApiExceptionType.validation,
      );
    }

    if (list.length > 50) {
      throw ApiException(
        message: 'Cannot delete more than 50 cashbooks at once.',
        type: ApiExceptionType.validation,
      );
    }

    try {
      final Uri uri =
          BackendConfig.endpoint('/cashbooks/cashbooks/bulk-delete/');
      final response = await AuthService.authenticatedRequest(
        'DELETE',
        uri,
        body: {"ids": list},
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw ApiException.timeout('delete cashbooks'),
      );

      if (response.statusCode != 200) {
        // Extract Django error message
        final errorMsg = HelperFunctions.extractDjangoError(response.body);
        throw ApiException(
          message: errorMsg ?? 'Failed to delete cashbooks. Please try again.',
          statusCode: response.statusCode,
          type: _getExceptionType(response.statusCode),
        );
      }
    } on SocketException {
      throw ApiException.network('delete cashbooks');
    } on TimeoutException {
      throw ApiException.timeout('delete cashbooks');
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        message: 'Failed to delete cashbooks: ${e.toString()}',
        type: ApiExceptionType.unknown,
      );
    }
  }

  /// Helper method to determine exception type from status code
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
}