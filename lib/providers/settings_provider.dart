import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

import '../services/hive_storage.dart';

class SettingsProvider with ChangeNotifier {
  static const _settingsKey = 'app_settings';

  // ================= UI SETTINGS =================
  bool composeHtml = true;
  bool autoQuote = false;
  String defaultFont = 'Arial';

  // ================= NOTIFICATIONS =================
  bool notificationsEnabled = true;
  bool notificationSound = true;
  bool notificationVibrate = false;
  bool notifyPrimary = true;
  bool notifyPromotions = false;
  bool notifySocial = true;
  bool quietHoursEnabled = false;
  int quietStartHour = 22;
  int quietEndHour = 7;

  // ================= SECURITY =================
  bool biometricEnabled = false;
  bool appLockEnabled = false;
  int lockTimeoutMinutes = 5;

  String? _pinHash;
  String? _pinSalt;

  SettingsProvider() {
    _load();
  }

  bool get hasPin => _pinHash != null && _pinHash!.isNotEmpty;

  // ================= PIN LOGIC =================

  bool verifyPin(String pin) {
    if (!hasPin) return false;

    // New salted hash
    if (_pinSalt != null) {
      return _hashPin(pin, _pinSalt!) == _pinHash;
    }

    // 🔁 Backward compatibility (old unsalted pins)
    final legacyHash = _hashPin(pin, '');
    if (legacyHash == _pinHash) {
      // upgrade silently to salted
      setPin(pin);
      return true;
    }

    return false;
  }

  Future<void> setPin(String pin) async {
    final salt = _generateSalt();
    _pinSalt = salt;
    _pinHash = _hashPin(pin, salt);

    await _persist();
    notifyListeners();
  }

  Future<void> clearPin() async {
    _pinHash = null;
    _pinSalt = null;
    await _persist();
    notifyListeners();
  }

  // ================= UPDATE =================

  Future<void> update({
    bool? composeHtml,
    bool? autoQuote,
    String? defaultFont,
    bool? notificationsEnabled,
    bool? notificationSound,
    bool? notificationVibrate,
    bool? notifyPrimary,
    bool? notifyPromotions,
    bool? notifySocial,
    bool? quietHoursEnabled,
    int? quietStartHour,
    int? quietEndHour,
    bool? biometricEnabled,
    bool? appLockEnabled,
    int? lockTimeoutMinutes,
  }) async {
    this.composeHtml = composeHtml ?? this.composeHtml;
    this.autoQuote = autoQuote ?? this.autoQuote;
    this.defaultFont = defaultFont ?? this.defaultFont;
    this.notificationsEnabled =
        notificationsEnabled ?? this.notificationsEnabled;
    this.notificationSound = notificationSound ?? this.notificationSound;
    this.notificationVibrate = notificationVibrate ?? this.notificationVibrate;
    this.notifyPrimary = notifyPrimary ?? this.notifyPrimary;
    this.notifyPromotions = notifyPromotions ?? this.notifyPromotions;
    this.notifySocial = notifySocial ?? this.notifySocial;
    this.quietHoursEnabled = quietHoursEnabled ?? this.quietHoursEnabled;
    this.quietStartHour = quietStartHour ?? this.quietStartHour;
    this.quietEndHour = quietEndHour ?? this.quietEndHour;
    this.biometricEnabled = biometricEnabled ?? this.biometricEnabled;
    this.appLockEnabled = appLockEnabled ?? this.appLockEnabled;
    this.lockTimeoutMinutes = lockTimeoutMinutes ?? this.lockTimeoutMinutes;

    await _persist();
    notifyListeners();
  }

  // ================= STORAGE =================

  Map<String, dynamic> toMap() {
    return {
      'composeHtml': composeHtml,
      'autoQuote': autoQuote,
      'defaultFont': defaultFont,
      'notificationsEnabled': notificationsEnabled,
      'notificationSound': notificationSound,
      'notificationVibrate': notificationVibrate,
      'notifyPrimary': notifyPrimary,
      'notifyPromotions': notifyPromotions,
      'notifySocial': notifySocial,
      'quietHoursEnabled': quietHoursEnabled,
      'quietStartHour': quietStartHour,
      'quietEndHour': quietEndHour,
      'biometricEnabled': biometricEnabled,
      'appLockEnabled': appLockEnabled,
      'lockTimeoutMinutes': lockTimeoutMinutes,
      'pinHash': _pinHash,
      'pinSalt': _pinSalt, // ✅ NEW
    };
  }

  void _load() {
    final stored = HiveStorage.getValue<Map>(key: _settingsKey);
    if (stored == null) return;

    composeHtml = stored['composeHtml'] ?? true;
    autoQuote = stored['autoQuote'] ?? false;
    defaultFont = stored['defaultFont'] ?? 'Arial';

    notificationsEnabled = stored['notificationsEnabled'] ?? true;
    notificationSound = stored['notificationSound'] ?? true;
    notificationVibrate = stored['notificationVibrate'] ?? false;
    notifyPrimary = stored['notifyPrimary'] ?? true;
    notifyPromotions = stored['notifyPromotions'] ?? false;
    notifySocial = stored['notifySocial'] ?? true;

    quietHoursEnabled = stored['quietHoursEnabled'] ?? false;
    quietStartHour = stored['quietStartHour'] ?? 22;
    quietEndHour = stored['quietEndHour'] ?? 7;

    biometricEnabled = stored['biometricEnabled'] ?? false;
    appLockEnabled = stored['appLockEnabled'] ?? false;
    lockTimeoutMinutes = stored['lockTimeoutMinutes'] ?? 5;

    _pinHash = stored['pinHash'];
    _pinSalt = stored['pinSalt']; // ✅ NEW
  }

  Future<void> _persist() async {
    await HiveStorage.putValue(key: _settingsKey, value: toMap());
  }

  // ================= SECURITY HELPERS =================

  String _hashPin(String pin, String salt) {
    final bytes = utf8.encode(pin + salt);
    return sha256.convert(bytes).toString();
  }

  String _generateSalt() {
    final rand = Random.secure();
    final values = List<int>.generate(16, (_) => rand.nextInt(256));
    return base64UrlEncode(values);
  }
}