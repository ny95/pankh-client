import '../services/hive_storage.dart';

class DraftService {
  static const String _draftsKeyPrefix = 'drafts::';

  static Future<void> saveDraft({
    required String accountKey,
    required Map<String, dynamic> draft,
  }) async {
    final key = '$_draftsKeyPrefix$accountKey';
    final List<dynamic> current =
        HiveStorage.getValue<List>(key: key) ?? [];
    final String? id = draft['id'] as String?;
    if (id == null || id.isEmpty) return;
    final updated =
        current
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
    final index = updated.indexWhere((item) => item['id'] == id);
    if (index >= 0) {
      updated[index] = draft;
    } else {
      updated.insert(0, draft);
    }
    await HiveStorage.putValue(key: key, value: updated);
  }

  static Future<void> deleteDraft({
    required String accountKey,
    required String draftId,
  }) async {
    final key = '$_draftsKeyPrefix$accountKey';
    final List<dynamic> current =
        HiveStorage.getValue<List>(key: key) ?? [];
    final updated =
        current
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .where((item) => item['id'] != draftId)
            .toList();
    await HiveStorage.putValue(key: key, value: updated);
  }
}
