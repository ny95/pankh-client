import 'package:hive_flutter/hive_flutter.dart';

class HiveStorage {
  static late Box _box;

  // Initialize Hive
  static Future<void> init() async {
    await Hive.initFlutter();
    _box = await Hive.openBox('234uhAsa237812b123r8y13ijA2iuFhFAaFsGbe31');
  }

  // Save data
  static Future<void> saveData(String key, String value) async {
    await _box.put(key, value);
  }

  // Retrieve data
  static String? getData(String key) {
    return _box.get(key);
  }

  // Delete data
  static Future<void> deleteData(String key) async {
    await _box.delete(key);
  }

  // Clear all data
  static Future<void> clearAll() async {
    await _box.clear();
  }

  static putValue({required String key, required String value}) {}
}
