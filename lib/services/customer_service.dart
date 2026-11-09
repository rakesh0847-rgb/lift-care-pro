import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Offline customer storage, separated by company code on this device.
class CustomerService {
  CustomerService._();

  static final CustomerService instance = CustomerService._();

  String _key(String companyCode) =>
      'liftcare_customers_${companyCode.trim().toUpperCase()}';

  Future<List<Map<String, dynamic>>> getCustomers(String companyCode) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key(companyCode));
    if (raw == null || raw.isEmpty) return [];

    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      final result = decoded
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
      result.sort((a, b) => (b['updatedAt'] ?? '')
          .toString()
          .compareTo((a['updatedAt'] ?? '').toString()));
      return result;
    } catch (_) {
      throw Exception(
        'Customer data could not be read. Create a backup before changing stored data.',
      );
    }
  }

  Future<void> saveCustomer({
    required String companyCode,
    required Map<String, dynamic> customer,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final customers = await getCustomers(companyCode);
    final now = DateTime.now().toIso8601String();
    final id = (customer['id'] ?? '').toString();
    final index = customers.indexWhere((item) => item['id'] == id);

    if (index >= 0) {
      customers[index] = {
        ...customers[index],
        ...customer,
        'updatedAt': now,
      };
    } else {
      customers.add({
        ...customer,
        'id': DateTime.now().microsecondsSinceEpoch.toString(),
        'companyCode': companyCode,
        'createdAt': now,
        'updatedAt': now,
      });
    }

    await prefs.setString(_key(companyCode), jsonEncode(customers));
  }

  Future<void> deleteCustomer({
    required String companyCode,
    required String customerId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final customers = await getCustomers(companyCode);
    customers.removeWhere((item) => item['id'] == customerId);
    await prefs.setString(_key(companyCode), jsonEncode(customers));
  }
}
