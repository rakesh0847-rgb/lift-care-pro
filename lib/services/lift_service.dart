
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LiftService {
  LiftService._();

  static final LiftService instance = LiftService._();

  String _key(String companyCode) =>
      'liftcare_lifts_${companyCode.trim().toUpperCase()}';

  Future<List<Map<String, dynamic>>> getLifts(
      String companyCode) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key(companyCode));

    if (raw == null || raw.isEmpty) return [];

    try {
      final list = jsonDecode(raw) as List<dynamic>;
      final result = list
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();

      result.sort((a, b) =>
          (b['updatedAt'] ?? '').toString().compareTo(
              (a['updatedAt'] ?? '').toString()));

      return result;
    } catch (_) {
      throw Exception('Lift data could not be read.');
    }
  }

  Future<void> saveLift({
    required String companyCode,
    required Map<String, dynamic> lift,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final lifts = await getLifts(companyCode);
    final now = DateTime.now().toIso8601String();
    final id = (lift['id'] ?? '').toString();

    final index = lifts.indexWhere(
        (e) => e['id'].toString() == id);

    if (index >= 0) {
      lifts[index] = {
        ...lifts[index],
        ...lift,
        'updatedAt': now,
      };
    } else {
      lifts.add({
        ...lift,
        'id': DateTime.now()
            .microsecondsSinceEpoch
            .toString(),
        'companyCode': companyCode,
        'createdAt': now,
        'updatedAt': now,
      });
    }

    await prefs.setString(
        _key(companyCode), jsonEncode(lifts));
  }

  Future<void> deleteLift({
    required String companyCode,
    required String liftId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final lifts = await getLifts(companyCode);

    lifts.removeWhere(
        (e) => e['id'].toString() == liftId);

    await prefs.setString(
        _key(companyCode), jsonEncode(lifts));
  }
}
