import 'package:flutter/foundation.dart';

import '../models/account.dart';
import '../services/backend_api_service.dart';
import '../services/hive_storage.dart';
import '../utils/web_url_helper.dart';

class AuthProvider with ChangeNotifier {
  static const _accountsKey = 'auth_accounts';
  static const _activeKey = 'auth_active_email';
  static const _defaultOutgoingKey = 'auth_default_outgoing';

  final List<Account> _accounts = [];
  String? _activeEmail;
  String? _defaultOutgoingEmail;

  List<Account> get accounts => List.unmodifiable(_accounts);
  String? get activeEmail => _activeEmail;
  bool get isLoggedIn => _activeEmail != null;
  Account? get activeAccount =>
      _activeEmail == null
          ? null
          : _accounts.firstWhere(
            (a) => a.email == _activeEmail,
            orElse: () => Account.initialForEmail(email: '', password: ''),
          ).email.isEmpty
          ? null
          : _accounts.firstWhere((a) => a.email == _activeEmail);

  String? get email => activeAccount?.email;
  String? get password => activeAccount?.password;
  String? get defaultOutgoingEmail => _defaultOutgoingEmail;
  Account? get defaultOutgoingAccount =>
      _defaultOutgoingEmail == null
          ? null
          : accountForEmail(_defaultOutgoingEmail!);
  bool get isOAuthAccount =>
      (activeAccount?.oauthProvider?.isNotEmpty ?? false) &&
      (activeAccount?.serverSessionToken?.isNotEmpty ?? false);
  String? get oauthProvider => activeAccount?.oauthProvider;
  String? get serverSessionToken => activeAccount?.serverSessionToken;

  Future<void> initialize() async {
    _load();
    if (kIsWeb) {
      final uri = Uri.base;
      final token = uri.queryParameters['token'];
      final provider = uri.queryParameters['provider'];
      final email = uri.queryParameters['email'];
      if (token != null && provider != null && email != null) {
        await loginWithOAuth(
          email: email,
          provider: provider,
          sessionToken: token,
        );
        clearOAuthCallbackQuery();
      }
    }
  }

  Future<void> login({
    required String email,
    required String password,
    String? displayName,
    String? imapHost,
    int? imapPort,
    bool? imapSecure,
    String? smtpHost,
    int? smtpPort,
    bool? smtpSecure,
    String? authMethod,
    String? smtpAuthMethod,
  }) async {
    final normalizedEmail = email.trim();
    final existingIndex =
        _accounts.indexWhere((a) => a.email == normalizedEmail);
    if (existingIndex >= 0) {
      final existing = _accounts[existingIndex];
      _accounts[existingIndex] = existing.copyWith(
        password: password,
        displayName: (displayName ?? existing.displayName).trim(),
        accountName: normalizedEmail,
        smtpUserName: normalizedEmail,
        imapHost: imapHost ?? existing.imapHost,
        imapPort: imapPort ?? existing.imapPort,
        imapSecure: imapSecure ?? existing.imapSecure,
        smtpHost: smtpHost ?? existing.smtpHost,
        smtpPort: smtpPort ?? existing.smtpPort,
        smtpSecure: smtpSecure ?? existing.smtpSecure,
        authMethod: authMethod ?? 'Normal password',
        smtpAuthMethod: smtpAuthMethod ?? existing.smtpAuthMethod,
        oauthProvider: null,
        serverSessionToken: null,
      );
    } else {
      final base = Account.initialForEmail(
        email: normalizedEmail,
        password: password,
      );
      _accounts.add(
        base.copyWith(
          displayName: (displayName ?? base.displayName).trim(),
          accountName: normalizedEmail,
          smtpUserName: normalizedEmail,
          imapHost: imapHost ?? base.imapHost,
          imapPort: imapPort ?? base.imapPort,
          imapSecure: imapSecure ?? base.imapSecure,
          smtpHost: smtpHost ?? base.smtpHost,
          smtpPort: smtpPort ?? base.smtpPort,
          smtpSecure: smtpSecure ?? base.smtpSecure,
          authMethod: authMethod ?? base.authMethod,
          smtpAuthMethod: smtpAuthMethod ?? base.smtpAuthMethod,
        ),
      );
    }
    _activeEmail = normalizedEmail;
    if (_accounts.length == 1) {
      _defaultOutgoingEmail = normalizedEmail;
    }
    await _persist();
    notifyListeners();
  }

  Future<void> loginWithOAuth({
    required String email,
    required String provider,
    required String sessionToken,
    String authMethod = 'OAuth2',
  }) async {
    final normalizedEmail = email.trim();
    final existingIndex =
        _accounts.indexWhere((a) => a.email == normalizedEmail);
    final base = Account.initialForEmail(email: normalizedEmail, password: '');
    final updated = (existingIndex >= 0 ? _accounts[existingIndex] : base).copyWith(
      password: '',
      authMethod: authMethod,
      smtpAuthMethod: authMethod,
      oauthProvider: provider,
      serverSessionToken: sessionToken,
      smtpUserName: normalizedEmail,
    );
    if (existingIndex >= 0) {
      _accounts[existingIndex] = updated;
    } else {
      _accounts.add(updated);
    }
    _activeEmail = normalizedEmail;
    if (_accounts.length == 1 || _defaultOutgoingEmail == null) {
      _defaultOutgoingEmail = normalizedEmail;
    }
    await _persist();
    notifyListeners();
  }

  Future<String?> fetchBrokeredAccessToken() async {
    final token = serverSessionToken;
    final provider = oauthProvider;
    if (token == null || provider == null || provider.isEmpty) {
      return null;
    }
    return BackendApiService.fetchBrokeredAccessToken(
      sessionToken: token,
      provider: provider,
    );
  }

  Account? accountForEmail(String email) {
    return _accounts.firstWhere(
      (a) => a.email == email,
      orElse: () => Account.initialForEmail(email: '', password: ''),
    ).email.isEmpty
        ? null
        : _accounts.firstWhere((a) => a.email == email);
  }

  Future<void> updateAccount(Account updated) async {
    final index = _accounts.indexWhere((a) => a.email == updated.email);
    if (index == -1) return;
    _accounts[index] = updated;
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

  Future<void> setDefaultOutgoing(String email) async {
    if (_defaultOutgoingEmail == email) return;
    if (_accounts.any((a) => a.email == email)) {
      _defaultOutgoingEmail = email;
      await HiveStorage.putValue(
        key: _defaultOutgoingKey,
        value: _defaultOutgoingEmail,
      );
      notifyListeners();
    }
  }

  Future<void> removeAccount(String email) async {
    _accounts.removeWhere((a) => a.email == email);
    if (_activeEmail == email) {
      _activeEmail = _accounts.isNotEmpty ? _accounts.first.email : null;
    }
    if (_defaultOutgoingEmail == email) {
      _defaultOutgoingEmail =
          _accounts.isNotEmpty ? _accounts.first.email : null;
    }
    await _persist();
    notifyListeners();
  }

  Future<void> logout() async {
    _accounts.clear();
    _activeEmail = null;
    _defaultOutgoingEmail = null;
    await HiveStorage.deleteKey(key: _accountsKey);
    await HiveStorage.deleteKey(key: _activeKey);
    await HiveStorage.deleteKey(key: _defaultOutgoingKey);
    notifyListeners();
  }

  Future<void> _persist() async {
    final list = _accounts.map((a) => a.toMap()).toList();
    await HiveStorage.putValue(key: _accountsKey, value: list);
    await HiveStorage.putValue(key: _activeKey, value: _activeEmail);
    await HiveStorage.putValue(
      key: _defaultOutgoingKey,
      value: _defaultOutgoingEmail,
    );
  }

  void _load() {
    final stored = HiveStorage.getValue<List>(key: _accountsKey) ?? [];
    for (final item in stored) {
      final account = Account.fromMap(item);
      if (account != null) {
        final migrated = _migrateAccount(account);
        _accounts.add(migrated);
      }
    }
    _activeEmail = HiveStorage.getValue<String>(key: _activeKey);
    _defaultOutgoingEmail =
        HiveStorage.getValue<String>(key: _defaultOutgoingKey);
    if (_activeEmail == null && _accounts.isNotEmpty) {
      _activeEmail = _accounts.first.email;
    }
    if (_accounts.isNotEmpty) {
      if (_defaultOutgoingEmail == null ||
          !_accounts.any((a) => a.email == _defaultOutgoingEmail)) {
        _defaultOutgoingEmail = _accounts.first.email;
      }
    }
  }

  Account _migrateAccount(Account account) {
    if (account.email.endsWith('@neosoftmail.com')) {
      final updated = account.copyWith(
        imapHost:
            account.imapHost == 'imap.neosoftmail.com'
                ? 'mail.neosoftmail.com'
                : account.imapHost,
        imapPort: account.imapPort == 993 ? 993 : account.imapPort,
        imapSecure: account.imapSecure,
        smtpHost:
            account.smtpHost == 'smtp.neosoftmail.com'
                ? 'mail.neosoftmail.com'
                : account.smtpHost,
        smtpPort: account.smtpPort == 465 ? 465 : account.smtpPort,
        smtpSecure: account.smtpSecure,
      );
      return updated;
    }
    return account;
  }
}
