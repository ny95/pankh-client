import 'package:flutter/material.dart';

import '../models/account.dart';
import '../services/hive_storage.dart';

class AuthProvider with ChangeNotifier {
  static const _accountsKey = 'auth_accounts';
  static const _activeKey = 'auth_active_email';

  final List<Account> _accounts = [];
  String? _activeEmail;

  AuthProvider() {
    _load();
  }

  List<Account> get accounts => List.unmodifiable(_accounts);
  String? get activeEmail => _activeEmail;
  bool get isLoggedIn => _activeEmail != null;
  Account? get activeAccount =>
      _activeEmail == null
          ? null
          : _accounts.firstWhere(
            (a) => a.email == _activeEmail,
            orElse: () => const Account(email: '', password: ''),
          ).email.isEmpty
          ? null
          : _accounts.firstWhere((a) => a.email == _activeEmail);

  String? get email => activeAccount?.email;
  String? get password => activeAccount?.password;

  Future<void> login({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim();
    final existingIndex =
        _accounts.indexWhere((a) => a.email == normalizedEmail);
    if (existingIndex >= 0) {
      _accounts[existingIndex] = Account(
        email: normalizedEmail,
        password: password,
      );
    } else {
      _accounts.add(Account(email: normalizedEmail, password: password));
    }
    _activeEmail = normalizedEmail;
    await _persist();
    notifyListeners();
  }

  Future<void> setActive(String email) async {
    if (_activeEmail == email) return;
    if (_accounts.any((a) => a.email == email)) {
      _activeEmail = email;
      await HiveStorage.putValue(key: _activeKey, value: _activeEmail);
      notifyListeners();
    }
  }

  Future<void> removeAccount(String email) async {
    _accounts.removeWhere((a) => a.email == email);
    if (_activeEmail == email) {
      _activeEmail = _accounts.isNotEmpty ? _accounts.first.email : null;
    }
    await _persist();
    notifyListeners();
  }

  Future<void> logout() async {
    _accounts.clear();
    _activeEmail = null;
    await HiveStorage.deleteKey(key: _accountsKey);
    await HiveStorage.deleteKey(key: _activeKey);
    notifyListeners();
  }

  Future<void> _persist() async {
    final list = _accounts.map((a) => a.toMap()).toList();
    await HiveStorage.putValue(key: _accountsKey, value: list);
    await HiveStorage.putValue(key: _activeKey, value: _activeEmail);
  }

  void _load() {
    final stored = HiveStorage.getValue<List>(key: _accountsKey) ?? [];
    for (final item in stored) {
      final account = Account.fromMap(item);
      if (account != null) {
        _accounts.add(account);
      }
    }
    _activeEmail = HiveStorage.getValue<String>(key: _activeKey);
    if (_activeEmail == null && _accounts.isNotEmpty) {
      _activeEmail = _accounts.first.email;
    }
    notifyListeners();
  }
}
