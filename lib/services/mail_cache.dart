import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:enough_mail/enough_mail.dart';
import 'package:hive/hive.dart';

import 'hive_storage.dart';

class MailCache {
  static const _boxName = 'mailCache';
  static const _messagesKey = 'messages';
  static bool _initialized = false;

  static List<int> _deriveKey(String password) {
    final bytes = utf8.encode(password);
    return sha256.convert(bytes).bytes;
  }

  static Future<Box> _openBox(String password) async {
    await _ensureInit();
    final key = _deriveKey(password);
    return Hive.openBox(
      _boxName,
      encryptionCipher: HiveAesCipher(key),
    );
  }

  static Future<void> _ensureInit() async {
    if (!_initialized) {
      await HiveStorage.init();
      _initialized = true;
    }
  }

  static Future<void> save({
    required String password,
    required List<MimeMessage> messages,
  }) async {
    final box = await _openBox(password);
    final payload =
        messages
            .map(
              (m) => {
                'raw': m.renderMessage(),
                'seq': m.sequenceId,
                'uid': m.uid,
              },
            )
            .toList();
    await box.put(_messagesKey, payload);
  }

  static Future<List<MimeMessage>> load({required String password}) async {
    try {
      final box = await _openBox(password);
      final data = box.get(_messagesKey);
      if (data is! List) return [];
      final messages = <MimeMessage>[];
      for (final item in data) {
        if (item is! Map) continue;
        final raw = item['raw'];
        if (raw is! String) continue;
        final message = MimeMessage.parseFromText(raw);
        message.sequenceId = item['seq'] is int ? item['seq'] as int : null;
        message.uid = item['uid'] is int ? item['uid'] as int : null;
        messages.add(message);
      }
      return messages;
    } catch (_) {
      return [];
    }
  }

  static Future<void> clear() async {
    try {
      if (Hive.isBoxOpen(_boxName)) {
        await Hive.box(_boxName).close();
      }
      await Hive.deleteBoxFromDisk(_boxName);
    } catch (_) {}
  }
}
