import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

import '../services/hive_storage.dart';

class SettingsProvider with ChangeNotifier {
  static const _settingsKey = 'app_settings';

  bool composeHtml = true;
  bool autoQuote = false;
  String defaultFont = 'Arial';

  bool notificationsEnabled = true;
  bool notificationSound = true;
  bool notificationVibrate = false;
  bool notifyPrimary = true;
  bool notifyPromotions = false;
  bool notifySocial = true;
  bool quietHoursEnabled = false;
  int quietStartHour = 22;
  int quietEndHour = 7;

  bool biometricEnabled = false;
  bool appLockEnabled = false;
  int lockTimeoutMinutes = 5;
  String? _pinHash;

  SettingsProvider() {
    _load();
  }

  bool get hasPin => _pinHash != null && _pinHash!.isNotEmpty;

  bool verifyPin(String pin) {
    if (!hasPin) return false;
    return _hashPin(pin) == _pinHash;
  }

  Future<void> setPin(String pin) async {
    _pinHash = _hashPin(pin);
    await _persist();
    notifyListeners();
  }

  Future<void> clearPin() async {
    _pinHash = null;
    await _persist();
    notifyListeners();
  }

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
    };
  }

  void _load() {
    final stored = HiveStorage.getValue<Map>(key: _settingsKey);
    if (stored == null) return;
    composeHtml = stored['composeHtml'] is bool ? stored['composeHtml'] : true;
    autoQuote = stored['autoQuote'] is bool ? stored['autoQuote'] : false;
    defaultFont =
        stored['defaultFont'] is String ? stored['defaultFont'] : 'Arial';
    notificationsEnabled =
        stored['notificationsEnabled'] is bool
            ? stored['notificationsEnabled']
            : true;
    notificationSound =
        stored['notificationSound'] is bool
            ? stored['notificationSound']
            : true;
    notificationVibrate =
        stored['notificationVibrate'] is bool
            ? stored['notificationVibrate']
            : false;
    notifyPrimary =
        stored['notifyPrimary'] is bool ? stored['notifyPrimary'] : true;
    notifyPromotions =
        stored['notifyPromotions'] is bool ? stored['notifyPromotions'] : false;
    notifySocial =
        stored['notifySocial'] is bool ? stored['notifySocial'] : true;
    quietHoursEnabled =
        stored['quietHoursEnabled'] is bool
            ? stored['quietHoursEnabled']
            : false;
    quietStartHour =
        stored['quietStartHour'] is int ? stored['quietStartHour'] : 22;
    quietEndHour =
        stored['quietEndHour'] is int ? stored['quietEndHour'] : 7;
    biometricEnabled =
        stored['biometricEnabled'] is bool ? stored['biometricEnabled'] : false;
    appLockEnabled =
        stored['appLockEnabled'] is bool ? stored['appLockEnabled'] : false;
    lockTimeoutMinutes =
        stored['lockTimeoutMinutes'] is int
            ? stored['lockTimeoutMinutes']
            : 5;
    _pinHash = stored['pinHash'] is String ? stored['pinHash'] : null;
  }

  Future<void> _persist() async {
    await HiveStorage.putValue(key: _settingsKey, value: toMap());
  }

  String _hashPin(String pin) {
    final bytes = utf8.encode(pin);
    return sha256.convert(bytes).toString();
  }
}
