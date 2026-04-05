import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';

class HiveStorage {
  static const String _hiveCommonBox = 'commonBox';
  static const List<String> _hiveBoxList = [_hiveCommonBox];
  static bool _initialized = false;

  static Future<void> init() async {
    try {
      if (_initialized) return;
      if (kIsWeb) {
        await Hive.initFlutter();
      } else {
        final directory = await getApplicationDocumentsDirectory();
        if (!await directory.exists()) {
          await directory.create(recursive: true);
        }
        await Hive.initFlutter(directory.path);
      }
      for (final boxName in _hiveBoxList) {
        if (!Hive.isBoxOpen(boxName)) {
          await Hive.openBox(boxName);
        }
      }
      _initialized = true;
    } catch (e) {
      throw Exception('Failed to initialize Hive: $e');
    }
  }

  static Future<void> putValue<T>({
    required String key,
    required T value,
    String boxName = _hiveCommonBox,
  }) async {
    try {
      final box = Hive.box(boxName);
      await box.put(key, value);
    } catch (e) {
      throw Exception('Failed to save value: $e');
    }
  }

  static T? getValue<T>({
    required String key,
    String boxName = _hiveCommonBox,
  }) {
    try {
      final box = Hive.box(boxName);
      return box.get(key);
    } catch (e) {
      throw Exception('Failed to retrieve value: $e');
    }
  }

  static Future<void> deleteKey({
    required String key,
    String boxName = _hiveCommonBox,
  }) async {
    try {
      final box = Hive.box(boxName);
      await box.delete(key);
    } catch (e) {
      throw Exception('Failed to delete key: $e');
    }
  }

  static Future<void> clearBox({String boxName = ''}) async {
    try {
      if (boxName.isNotEmpty) {
        final box = Hive.box(boxName);
        await box.clear();
      } else {
        for (final boxName in _hiveBoxList) {
          final box = Hive.box(boxName);
          await box.clear();
        }
      }
    } catch (e) {
      throw Exception('Failed to clear box: $e');
    }
  }

  static Future<void> close() async {
    try {
      await Hive.close();
      _initialized = false;
    } catch (e) {
      throw Exception('Failed to close Hive: $e');
    }
  }
}
