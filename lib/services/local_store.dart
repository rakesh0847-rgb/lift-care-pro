
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LocalStore {
  LocalStore._();

  static final LocalStore instance = LocalStore._();

  static const String _recordsKey = 'liftcare_service_records';
  static const String _syncQueueKey = 'liftcare_sync_queue';

  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  List<Map<String, dynamic>> getRecords() {
    final raw = _prefs.getString(_recordsKey);

    if (raw == null) return [];

    try {
      final decoded = jsonDecode(raw) as List;

      return decoded
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveRecord(Map<String, dynamic> record) async {
    final records = getRecords();

    records.add({
      ...record,
      'createdAt': DateTime.now().toIso8601String(),
      'syncStatus': 'pending',
    });

    await _prefs.setString(
      _recordsKey,
      jsonEncode(records),
    );

    await addToSyncQueue(record);
  }

  Future<void> addToSyncQueue(
    Map<String, dynamic> record,
  ) async {
    final raw = _prefs.getString(_syncQueueKey);

    List<dynamic> queue = [];

    if (raw != null) {
      try {
        queue = jsonDecode(raw) as List;
      } catch (_) {
        queue = [];
      }
    }

    queue.add({
      ...record,
      'queuedAt': DateTime.now().toIso8601String(),
    });

    await _prefs.setString(
      _syncQueueKey,
      jsonEncode(queue),
    );
  }

  List<Map<String, dynamic>> getPendingSyncRecords() {
    final raw = _prefs.getString(_syncQueueKey);

    if (raw == null) return [];

    try {
      final decoded = jsonDecode(raw) as List;

      return decoded
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> clearSyncQueue() async {
    await _prefs.setString(_syncQueueKey, '[]');
  }

  Future<void> deleteAllRecords() async {
    await _prefs.remove(_recordsKey);
    await _prefs.remove(_syncQueueKey);
  }
}
