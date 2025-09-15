import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart' as path_provider;

class HiveStorage {
  static const String _hiveCommonBox = 'commonBox';
  static const List<String> _hiveBoxList = [_hiveCommonBox];

  static Future<void> init() async {
    try {
      final appDocumentDirectory =
          await path_provider.getApplicationDocumentsDirectory();
      Hive.init(appDocumentDirectory.path);
      for (final boxName in _hiveBoxList) {
        await Hive.openBox(boxName);
      }
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
    } catch (e) {
      throw Exception('Failed to close Hive: $e');
    }
  }
}
