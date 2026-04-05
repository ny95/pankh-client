import 'dart:async';
import 'dart:math';

import 'package:enough_mail/enough_mail.dart';
import 'package:flutter/foundation.dart';

import '../services/backend_api_service.dart';
import '../services/imap_service.dart';
import '../services/mail_cache.dart';
import '../models/mail_folder.dart';
import 'auth_provider.dart';

class MailProvider with ChangeNotifier {
  MimeMessage? _selectedMail;
  List<MimeMessage> _mails = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _isRefreshing = false;
  int _newMailCount = 0;
  int? _minSequenceId;
  int? _maxSequenceId;
  int _mailboxMessages = 0;
  int? _windowStartSeq;
  int? _windowEndSeq;
  Timer? _pollTimer;
  String? _email;
  String? _password;
  String? _imapHost;
  int? _imapPort;
  bool? _imapSecure;
  final int _pageSize = 20;
  List<MailFolder> _folders = [];
  MailFolder? _selectedFolder;
  _SearchContext _searchContext = _SearchContext.none;
  String _searchQuery = '';
  int _searchTotal = 0;
  String _inboxCategory = 'primary';
  List<MimeMessage> _normalMails = [];
  int _normalMailboxMessages = 0;
  final Set<String> _selectedKeys = {};
  final List<String> _searchHistory = [];
  String _localQuery = '';
  List<MimeMessage> _filteredMails = [];
  MimeMessage? _draftToCompose;
  String? _authMethod;
  String? _oauthProvider;
  String? _serverSessionToken;
  String? _backendNextCursor;
  bool _needsOAuthRelogin = false;
  String? _authError;

  bool get _supportsRemoteMailbox => !kIsWeb;
  bool get _useBackendMailApi =>
      kIsWeb && (_serverSessionToken?.isNotEmpty ?? false);
  bool get _usesOauthImap =>
      !kIsWeb &&
      (_authMethod?.toLowerCase() == 'oauth') &&
      (_oauthProvider?.isNotEmpty ?? false) &&
      (_serverSessionToken?.isNotEmpty ?? false);
  bool get _canUseImap =>
      !_needsOAuthRelogin &&
      _email != null &&
      ((_password?.isNotEmpty ?? false) || _usesOauthImap);
  bool get _canLoadMail => _useBackendMailApi || _canUseImap;

  MimeMessage? get selectedMail => _selectedMail;
  List<MimeMessage> get mails =>
      _localQuery.isNotEmpty ? _filteredMails : _mails;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get isRefreshing => _isRefreshing;
  int get newMailCount => _newMailCount;
  int? get minSequenceId => _minSequenceId;
  int? get maxSequenceId => _maxSequenceId;
  int get mailboxMessages => _mailboxMessages;
  int? get windowStartSeq => _windowStartSeq;
  int? get windowEndSeq => _windowEndSeq;
  List<MailFolder> get folders => List.unmodifiable(_folders);
  MailFolder? get selectedFolder => _selectedFolder;
  bool get isSearchMode => _searchContext != _SearchContext.none;
  String get searchQuery => _searchQuery;
  String get inboxCategory => _inboxCategory;
  bool get isQuerySearch => _searchContext == _SearchContext.query;
  List<String> get searchHistory => List.unmodifiable(_searchHistory);
  bool get isLocalFilterActive => _localQuery.isNotEmpty;
  bool get hasSelection => _selectedKeys.isNotEmpty;
  int get selectedCount => _selectedKeys.length;
  bool get isAllSelected =>
      _mails.isNotEmpty && _selectedKeys.length == _mails.length;
  bool get isPartiallySelected => _selectedKeys.isNotEmpty && !isAllSelected;
  bool get hasAuth => _email != null && ((_password?.isNotEmpty ?? false) || _usesOauthImap || _useBackendMailApi);
  bool get needsOAuthRelogin => _needsOAuthRelogin;
  String? get authError => _authError;

  MimeMessage? takeDraftToCompose() {
    final draft = _draftToCompose;
    _draftToCompose = null;
    return draft;
  }

  void requestOpenDraft(MimeMessage message) {
    _draftToCompose = message;
    notifyListeners();
  }

  int get pageStart {
    if (_searchContext != _SearchContext.none) {
      return _searchTotal == 0 ? 0 : 1;
    }
    if (_windowStartSeq == null || _windowEndSeq == null) return 0;
    return _mailboxMessages - _windowEndSeq! + 1;
  }

  int get pageEnd {
    if (_searchContext != _SearchContext.none) {
      return _searchTotal == 0 ? 0 : min(_pageSize, _searchTotal);
    }
    if (_windowStartSeq == null || _windowEndSeq == null) return 0;
    return _mailboxMessages - _windowStartSeq! + 1;
  }

  int get pageTotal =>
      _searchContext != _SearchContext.none ? _searchTotal : _mailboxMessages;

  void selectMail(MimeMessage mail) {
    _selectedMail = mail;
    notifyListeners();
  }

  bool isSelected(MimeMessage mail) {
    return _selectedKeys.contains(_messageKey(mail));
  }

  void toggleSelection(MimeMessage mail, {bool? selected}) {
    final key = _messageKey(mail);
    final shouldSelect = selected ?? !_selectedKeys.contains(key);
    if (shouldSelect) {
      _selectedKeys.add(key);
    } else {
      _selectedKeys.remove(key);
    }
    notifyListeners();
  }

  void clearSelection() {
    if (_selectedKeys.isEmpty) return;
    _selectedKeys.clear();
    notifyListeners();
  }

  void toggleSelectAll() {
    if (isAllSelected) {
      _selectedKeys.clear();
    } else {
      _selectedKeys
        ..clear()
        ..addAll(_mails.map(_messageKey));
    }
    notifyListeners();
  }

  void updateAuth(AuthProvider auth) {
    final nextEmail = auth.email;
    final nextPassword = auth.password;
    final nextAccount = auth.activeAccount;
    final nextImapHost = nextAccount?.imapHost;
    final nextImapPort = nextAccount?.imapPort;
    final nextImapSecure = nextAccount?.imapSecure;
    final nextAuthMethod = nextAccount?.authMethod;
    final nextOauthProvider = nextAccount?.oauthProvider;
    final nextServerSessionToken = nextAccount?.serverSessionToken;
    final changed =
        nextEmail != _email ||
        nextPassword != _password ||
        nextImapHost != _imapHost ||
        nextImapPort != _imapPort ||
        nextImapSecure != _imapSecure ||
        nextAuthMethod != _authMethod ||
        nextOauthProvider != _oauthProvider ||
        nextServerSessionToken != _serverSessionToken;
    _email = nextEmail;
    _password = nextPassword;
    _imapHost = nextImapHost;
    _imapPort = nextImapPort;
    _imapSecure = nextImapSecure;
    _authMethod = nextAuthMethod;
    _oauthProvider = nextOauthProvider;
    _serverSessionToken = nextServerSessionToken;

    if (!auth.isLoggedIn) {
      _mails = [];
      _selectedMail = null;
      _selectedKeys.clear();
      _isLoading = false;
      _newMailCount = 0;
      _minSequenceId = null;
      _maxSequenceId = null;
      _mailboxMessages = 0;
      _windowStartSeq = null;
      _windowEndSeq = null;
      _searchContext = _SearchContext.none;
      _searchQuery = '';
      _searchTotal = 0;
      _inboxCategory = 'primary';
      _searchHistory.clear();
      _localQuery = '';
      _filteredMails = [];
      _backendNextCursor = null;
      _needsOAuthRelogin = false;
      _authError = null;
      _pollTimer?.cancel();
      _imapHost = null;
      _imapPort = null;
      _imapSecure = null;
      _authMethod = null;
      _oauthProvider = null;
      _serverSessionToken = null;
      if (changed) {
        notifyListeners();
      }
      return;
    }

    if (changed) {
      _newMailCount = 0;
      _minSequenceId = null;
      _maxSequenceId = null;
      _mailboxMessages = 0;
      _windowStartSeq = null;
      _windowEndSeq = null;
      _folders = [];
      _selectedFolder = null;
      _searchContext = _SearchContext.none;
      _searchQuery = '';
      _searchTotal = 0;
      _inboxCategory = 'primary';
      _searchHistory.clear();
      _localQuery = '';
      _filteredMails = [];
      _selectedKeys.clear();
      _backendNextCursor = null;
      _needsOAuthRelogin = false;
      _authError = null;
      MailCache.clear();
      _loadFromCache();
      if (_canLoadMail) {
        loadFolders().then((_) => fetchInitial());
      } else {
        _isLoading = false;
        notifyListeners();
      }
    }
    if (_canLoadMail) {
      _startPolling();
    } else {
      _pollTimer?.cancel();
    }
  }


  void _handleExpiredOAuthSession([String? message]) {
    _needsOAuthRelogin = true;
    _authError =
        message ??
        'Your login session expired. Sign in again to continue syncing mail.';
    _isLoading = false;
    _isLoadingMore = false;
    _isRefreshing = false;
    _pollTimer?.cancel();
    notifyListeners();
  }

  void markOAuthSessionExpired([String? message]) {
    _handleExpiredOAuthSession(message);
  }

  Future<T?> _guardBackendSession<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on UnauthorizedRequestException {
      _handleExpiredOAuthSession();
      return null;
    }
  }

  Future<String?> _resolveImapAccessToken() async {
    if (!_usesOauthImap || _serverSessionToken == null || _oauthProvider == null) {
      return null;
    }
    try {
      final token = await BackendApiService.fetchBrokeredAccessToken(
        sessionToken: _serverSessionToken!,
        provider: _oauthProvider!,
      );
      _needsOAuthRelogin = false;
      _authError = null;
      return token;
    } on UnauthorizedRequestException {
      _handleExpiredOAuthSession();
      return null;
    }
  }

  List<MimeMessage> _parseBackendMessages(List<String> raws) {
    final messages = <MimeMessage>[];
    for (final raw in raws) {
      try {
        messages.add(MimeMessage.parseFromText(raw));
      } catch (_) {}
    }
    return messages;
  }

  void _setBackendWindow() {
    _windowStartSeq = _mails.isEmpty ? null : 1;
    _windowEndSeq = _mails.isEmpty ? null : _mails.length;
  }

  Future<void> _fetchBackendMessages({required bool refresh}) async {
    if (_serverSessionToken == null) {
      _isLoading = false;
      _isRefreshing = false;
      notifyListeners();
      return;
    }
    final page = await _guardBackendSession(
      () => BackendApiService.fetchMessages(
        sessionToken: _serverSessionToken!,
        folderPath: _selectedFolder?.path,
        pageSize: _pageSize,
      ),
    );
    if (page == null) {
      return;
    }
    final previousKeys = _mails.map(_messageKey).toSet();
    _backendNextCursor = page.nextCursor;
    _mailboxMessages = page.total;
    _mails = _mergeAndSort(_parseBackendMessages(page.rawMessages), replace: true);
    _rebuildLocalFilter();
    _updateSequenceRange();
    _setBackendWindow();
    _syncSelectionAfterReplace();
    if (refresh) {
      _newMailCount = _mails.where((mail) => !previousKeys.contains(_messageKey(mail))).length;
    }
  }

  Future<void> fetchInitial() async {
    if (!_canLoadMail) {
      _isLoading = false;
      notifyListeners();
      return;
    }
    if (_email == null) {
      _mails = [];
      _isLoading = false;
      notifyListeners();
      return;
    }
    _isLoading = true;
    _selectedKeys.clear();
    notifyListeners();
    if (_useBackendMailApi) {
      await _fetchBackendMessages(refresh: false);
    } else {
      final oauthAccessToken = await _resolveImapAccessToken();
      final secret = _password ?? '';
      if (secret.isEmpty && (oauthAccessToken == null || oauthAccessToken.isEmpty)) {
        _mails = [];
        _isLoading = false;
        notifyListeners();
        return;
      }
      final result = await ImapService().fetchLatest(
        email: _email!,
        password: secret,
        oauthAccessToken: oauthAccessToken,
        imapHost: _imapHost,
        imapPort: _imapPort,
        imapSecure: _imapSecure,
        pageSize: _pageSize,
        mailboxPath: _selectedFolder?.path ?? 'INBOX',
      );
      _mailboxMessages = result.mailboxMessages;
      _mails = _mergeAndSort(result.messages, replace: true);
      _rebuildLocalFilter();
      _updateSequenceRange();
      _setWindowFromCurrent();
      _syncSelectionAfterReplace();
    }
    if (_searchContext == _SearchContext.none) {
      await _saveCache();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> refreshLatest() async {
    if (!_canLoadMail || _email == null) return;
    if (_isRefreshing) return;
    if (_searchContext == _SearchContext.query) {
      await search(_searchQuery);
      return;
    }
    if (_searchContext == _SearchContext.category) {
      await setInboxCategory(_inboxCategory);
      return;
    }
    _isRefreshing = true;
    _selectedKeys.clear();
    notifyListeners();
    if (_useBackendMailApi) {
      await _fetchBackendMessages(refresh: true);
    } else {
      final oauthAccessToken = await _resolveImapAccessToken();
      final secret = _password ?? '';
      if (secret.isEmpty && (oauthAccessToken == null || oauthAccessToken.isEmpty)) {
        _isRefreshing = false;
        notifyListeners();
        return;
      }
      final result = await ImapService().fetchLatest(
        email: _email!,
        password: secret,
        oauthAccessToken: oauthAccessToken,
        imapHost: _imapHost,
        imapPort: _imapPort,
        imapSecure: _imapSecure,
        pageSize: _pageSize,
        mailboxPath: _selectedFolder?.path ?? 'INBOX',
      );
      _mailboxMessages = result.mailboxMessages;
      _mails = _mergeAndSort(result.messages, replace: true);
      _rebuildLocalFilter();
      _updateSequenceRange();
      _setWindowFromCurrent();
      _syncSelectionAfterReplace();
    }
    if (_searchContext == _SearchContext.none) {
      await _saveCache();
    }
    _isRefreshing = false;
    notifyListeners();
  }

  Future<void> loadOlder({bool replace = false}) async {
    if (!_canLoadMail || _email == null) return;
    if (_isLoadingMore) return;
    if (_useBackendMailApi) {
      if (_serverSessionToken == null || _backendNextCursor == null) return;
      _isLoadingMore = true;
      notifyListeners();
      final page = await _guardBackendSession(
        () => BackendApiService.fetchMessages(
          sessionToken: _serverSessionToken!,
          folderPath: _selectedFolder?.path,
          pageSize: _pageSize,
          cursor: _backendNextCursor,
        ),
      );
      if (page == null) {
        return;
      }
      _backendNextCursor = page.nextCursor;
      _mailboxMessages = page.total;
      _mails = _mergeAndSort(_parseBackendMessages(page.rawMessages), replace: false);
      _rebuildLocalFilter();
      _updateSequenceRange();
      _setBackendWindow();
      _syncSelectionAfterReplace();
      if (_searchContext == _SearchContext.none) {
        await _saveCache();
      }
      _isLoadingMore = false;
      notifyListeners();
      return;
    }
    final secret = _password ?? '';
    final oauthAccessToken = await _resolveImapAccessToken();
    if (secret.isEmpty && (oauthAccessToken == null || oauthAccessToken.isEmpty)) return;
    final anchor = replace ? _windowStartSeq : _minSequenceId;
    if (anchor == null || anchor <= 1) return;

    _isLoadingMore = true;
    notifyListeners();
    final result = await ImapService().fetchOlder(
      email: _email!,
      password: secret,
      oauthAccessToken: oauthAccessToken,
      imapHost: _imapHost,
      imapPort: _imapPort,
      imapSecure: _imapSecure,
      rangeEnd: anchor - 1,
      pageSize: _pageSize,
      mailboxPath: _selectedFolder?.path ?? 'INBOX',
    );
    _mailboxMessages = result.mailboxMessages;
    _mails = _mergeAndSort(result.messages, replace: replace);
    _rebuildLocalFilter();
    _updateSequenceRange();
    if (replace) {
      _setWindowFromCurrent();
      _syncSelectionAfterReplace();
    }
    if (_searchContext == _SearchContext.none) {
      await _saveCache();
    }
    _isLoadingMore = false;
    notifyListeners();
  }

  Future<void> loadNewer({bool replace = false}) async {
    if (!_canLoadMail || _email == null) return;
    if (_isRefreshing) return;
    if (_useBackendMailApi) {
      _isRefreshing = true;
      notifyListeners();
      await _fetchBackendMessages(refresh: true);
      if (_searchContext == _SearchContext.none) {
        await _saveCache();
      }
      _isRefreshing = false;
      notifyListeners();
      return;
    }
    final secret = _password ?? '';
    final oauthAccessToken = await _resolveImapAccessToken();
    if (secret.isEmpty && (oauthAccessToken == null || oauthAccessToken.isEmpty)) return;
    final anchor = replace ? _windowEndSeq : _maxSequenceId;
    if (anchor == null) return;

    _isRefreshing = true;
    notifyListeners();
    final result = await ImapService().fetchNewer(
      email: _email!,
      password: secret,
      oauthAccessToken: oauthAccessToken,
      imapHost: _imapHost,
      imapPort: _imapPort,
      imapSecure: _imapSecure,
      rangeStart: anchor + 1,
      mailboxPath: _selectedFolder?.path ?? 'INBOX',
    );
    _mailboxMessages = result.mailboxMessages;
    if (result.messages.isNotEmpty) {
      _mails = _mergeAndSort(result.messages, replace: replace);
      _rebuildLocalFilter();
      _updateSequenceRange();
      if (replace) {
        _setWindowFromCurrent();
        _syncSelectionAfterReplace();
      }
      _newMailCount += result.messages.length;
      if (_searchContext == _SearchContext.none) {
        await _saveCache();
      }
    }
    _isRefreshing = false;
    notifyListeners();
  }

  Future<void> refreshNewer() async {
    _newMailCount = 0;
    await loadNewer();
  }

  void clearNewMailCount() {
    if (_newMailCount == 0) return;
    _newMailCount = 0;
    notifyListeners();
  }

  void _updateSequenceRange() {
    final seqs = _mails
        .map((m) => m.sequenceId ?? 0)
        .where((v) => v > 0)
        .toList();
    if (seqs.isEmpty) {
      _minSequenceId = null;
      _maxSequenceId = null;
      return;
    }
    seqs.sort();
    _minSequenceId = seqs.first;
    _maxSequenceId = seqs.last;
  }

  void _setWindowFromCurrent() {
    _windowStartSeq = _minSequenceId;
    _windowEndSeq = _maxSequenceId;
  }

  void _syncSelectionAfterReplace() {
    if (_selectedMail == null) {
      if (_mails.isNotEmpty) {
        _selectedMail = _mails.first;
      }
      _pruneSelection();
      return;
    }
    final key = _messageKey(_selectedMail!);
    final match = _mails.firstWhere(
      (m) => _messageKey(m) == key,
      orElse: () => _mails.isNotEmpty ? _mails.first : _selectedMail!,
    );
    _selectedMail = match;
    _pruneSelection();
  }

  void _pruneSelection() {
    if (_selectedKeys.isEmpty) return;
    final valid = _mails.map(_messageKey).toSet();
    _selectedKeys.removeWhere((key) => !valid.contains(key));
  }

  Future<void> loadFolders() async {
    if (!_canLoadMail) {
      _folders = [];
      _selectedFolder = null;
      notifyListeners();
      return;
    }
    if (_email == null) return;
    List<MailFolder> folders;
    if (_useBackendMailApi) {
      final fetchedFolders = await _guardBackendSession(
        () => BackendApiService.fetchFolders(
          sessionToken: _serverSessionToken!,
        ),
      );
      if (fetchedFolders == null) {
        return;
      }
      folders = fetchedFolders;
    } else {
      final secret = _password ?? '';
      final oauthAccessToken = await _resolveImapAccessToken();
      if (secret.isEmpty && (oauthAccessToken == null || oauthAccessToken.isEmpty)) return;
      final mailboxes = await ImapService().listMailboxes(
        email: _email!,
        password: secret,
        oauthAccessToken: oauthAccessToken,
        imapHost: _imapHost,
        imapPort: _imapPort,
        imapSecure: _imapSecure,
      );
      folders =
          mailboxes
              .map((m) => MailFolder(name: m.name, path: m.path))
              .toList();
    }
    folders.sort((a, b) {
      int rank(MailFolder f) {
        final n = f.name.toLowerCase();
        if (n == 'inbox') return 0;
        if (n.contains('sent')) return 1;
        if (n.contains('draft')) return 2;
        if (n.contains('spam') || n.contains('junk')) return 3;
        if (n.contains('trash') || n.contains('bin')) return 4;
        if (n.contains('all mail') || n.contains('archive')) return 5;
        return 10;
      }

      final ra = rank(a);
      final rb = rank(b);
      if (ra != rb) return ra.compareTo(rb);
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    _folders = folders;
    if (_folders.isNotEmpty) {
      _selectedFolder ??= _folders.firstWhere(
        (f) => f.name.toLowerCase() == 'inbox',
        orElse: () => _folders.first,
      );
    }
    notifyListeners();
  }

  Future<void> selectFolder(MailFolder folder) async {
    _selectedFolder = folder;
    _mails = [];
    _selectedMail = null;
    _localQuery = '';
    _filteredMails = [];
    _selectedKeys.clear();
    _minSequenceId = null;
    _maxSequenceId = null;
    _windowStartSeq = null;
    _windowEndSeq = null;
    _newMailCount = 0;
    _mailboxMessages = 0;
    _searchContext = _SearchContext.none;
    _searchQuery = '';
    _searchTotal = 0;
    _inboxCategory = 'primary';
    MailCache.clear();
    notifyListeners();
    await fetchInitial();
  }

  Future<void> toggleImportant(MimeMessage message) async {
    if (_email == null) return;
    final secret = _password ?? '';
    final oauthAccessToken = await _resolveImapAccessToken();
    if (secret.isEmpty && (oauthAccessToken == null || oauthAccessToken.isEmpty)) return;
    final flags = message.flags ?? <String>[];
    final isFlagged =
        flags.any((f) => f.toLowerCase().contains('flagged')) ||
        flags.any((f) => f.toLowerCase().contains('important'));
    final add = !isFlagged;
    final ok = await ImapService().toggleFlagged(
      email: _email!,
      password: secret,
      oauthAccessToken: oauthAccessToken,
      imapHost: _imapHost,
      imapPort: _imapPort,
      imapSecure: _imapSecure,
      mailboxPath: _selectedFolder?.path ?? 'INBOX',
      message: message,
      add: add,
    );
    if (!ok) return;
    final newFlags = List<String>.from(flags);
    if (add) {
      if (!newFlags.any((f) => f.toLowerCase().contains('flagged'))) {
        newFlags.add('\\Flagged');
      }
    } else {
      newFlags.removeWhere((f) => f.toLowerCase().contains('flagged'));
      newFlags.removeWhere((f) => f.toLowerCase().contains('important'));
    }
    final idx = _mails.indexWhere((m) => _messageKey(m) == _messageKey(message));
    if (idx >= 0) {
      _mails[idx].flags = newFlags;
    }
    if (_selectedMail != null &&
        _messageKey(_selectedMail!) == _messageKey(message)) {
      _selectedMail!.flags = newFlags;
    }
    notifyListeners();
  }

  List<MimeMessage> _selectedMessages() {
    if (_selectedKeys.isEmpty) return [];
    return _mails.where((m) => _selectedKeys.contains(_messageKey(m))).toList();
  }

  bool get selectedAllRead {
    final selected = _selectedMessages();
    if (selected.isEmpty) return false;
    return selected.every(
      (m) =>
          (m.flags ?? [])
              .any((flag) => flag.toLowerCase().contains('seen')),
    );
  }

  Future<bool> setSelectedRead(bool read) async {
    if (_email == null) return false;
    final selected = _selectedMessages();
    if (selected.isEmpty) return false;
    final secret = _password ?? '';
    final oauthAccessToken = await _resolveImapAccessToken();
    if (secret.isEmpty && (oauthAccessToken == null || oauthAccessToken.isEmpty)) {
      return false;
    }
    final ok = await ImapService().setSeen(
      email: _email!,
      password: secret,
      oauthAccessToken: oauthAccessToken,
      imapHost: _imapHost,
      imapPort: _imapPort,
      imapSecure: _imapSecure,
      mailboxPath: _selectedFolder?.path ?? 'INBOX',
      messages: selected,
      seen: read,
    );
    if (!ok) return false;
    for (final msg in selected) {
      final flags = List<String>.from(msg.flags ?? []);
      if (read) {
        if (!flags.any((f) => f.toLowerCase().contains('seen'))) {
          flags.add('\\Seen');
        }
      } else {
        flags.removeWhere((f) => f.toLowerCase().contains('seen'));
      }
      msg.flags = flags;
    }
    notifyListeners();
    return true;
  }

  Future<bool> setSelectedImportant(bool add) async {
    if (_email == null || _password == null) return false;
    final selected = _selectedMessages();
    if (selected.isEmpty) return false;
    final ok = await ImapService().setFlagged(
      email: _email!,
      password: _password!,
      imapHost: _imapHost,
      imapPort: _imapPort,
      imapSecure: _imapSecure,
      mailboxPath: _selectedFolder?.path ?? 'INBOX',
      messages: selected,
      add: add,
    );
    if (!ok) return false;
    for (final msg in selected) {
      final flags = List<String>.from(msg.flags ?? []);
      if (add) {
        if (!flags.any((f) => f.toLowerCase().contains('flagged'))) {
          flags.add('\\Flagged');
        }
      } else {
        flags.removeWhere((f) => f.toLowerCase().contains('flagged'));
        flags.removeWhere((f) => f.toLowerCase().contains('important'));
      }
      msg.flags = flags;
    }
    notifyListeners();
    return true;
  }

  Future<bool> deleteSelected() async {
    if (_email == null || _password == null) return false;
    final selected = _selectedMessages();
    if (selected.isEmpty) return false;
    final trash = _findFolderByHints(['trash', 'bin', 'deleted']);
    bool ok;
    if (trash != null) {
      ok = await ImapService().moveMessages(
        email: _email!,
        password: _password!,
        imapHost: _imapHost,
        imapPort: _imapPort,
        imapSecure: _imapSecure,
        mailboxPath: _selectedFolder?.path ?? 'INBOX',
        targetPath: trash.path,
        messages: selected,
      );
    } else {
      ok = await ImapService().deleteMessages(
        email: _email!,
        password: _password!,
        imapHost: _imapHost,
        imapPort: _imapPort,
        imapSecure: _imapSecure,
        mailboxPath: _selectedFolder?.path ?? 'INBOX',
        messages: selected,
      );
    }
    if (!ok) return false;
    _removeSelectedFromList();
    return true;
  }

  Future<bool> archiveMessage(MimeMessage message) async {
    final archive = _findFolderByHints(['all mail', 'archive']);
    if (archive == null) return false;
    return _moveSingleMessage(message, archive);
  }

  Future<bool> snoozeMessage(MimeMessage message) async {
    final snoozed = _findFolderByHints(['snoozed', 'snooze']);
    if (snoozed == null) return false;
    return _moveSingleMessage(message, snoozed);
  }

  Future<bool> deleteMessage(MimeMessage message) async {
    if (_email == null || _password == null) return false;
    final trash = _findFolderByHints(['trash', 'bin', 'deleted']);
    bool ok;
    if (trash != null) {
      ok = await ImapService().moveMessages(
        email: _email!,
        password: _password!,
        imapHost: _imapHost,
        imapPort: _imapPort,
        imapSecure: _imapSecure,
        mailboxPath: _selectedFolder?.path ?? 'INBOX',
        targetPath: trash.path,
        messages: [message],
      );
    } else {
      ok = await ImapService().deleteMessages(
        email: _email!,
        password: _password!,
        imapHost: _imapHost,
        imapPort: _imapPort,
        imapSecure: _imapSecure,
        mailboxPath: _selectedFolder?.path ?? 'INBOX',
        messages: [message],
      );
    }
    if (!ok) return false;
    _removeMessagesFromList([message]);
    return true;
  }

  Future<bool> setMessageRead(MimeMessage message, bool read) async {
    if (_email == null || _password == null) return false;
    final ok = await ImapService().setSeen(
      email: _email!,
      password: _password!,
      imapHost: _imapHost,
      imapPort: _imapPort,
      imapSecure: _imapSecure,
      mailboxPath: _selectedFolder?.path ?? 'INBOX',
      messages: [message],
      seen: read,
    );
    if (!ok) return false;
    final flags = List<String>.from(message.flags ?? []);
    if (read) {
      if (!flags.any((f) => f.toLowerCase().contains('seen'))) {
        flags.add('\\Seen');
      }
    } else {
      flags.removeWhere((f) => f.toLowerCase().contains('seen'));
    }
    message.flags = flags;
    notifyListeners();
    return true;
  }

  Future<bool> _moveSingleMessage(
    MimeMessage message,
    MailFolder target,
  ) async {
    if (_email == null || _password == null) return false;
    if (!_isMoveAllowed(_selectedFolder, target)) return false;
    final ok = await ImapService().moveMessages(
      email: _email!,
      password: _password!,
      imapHost: _imapHost,
      imapPort: _imapPort,
      imapSecure: _imapSecure,
      mailboxPath: _selectedFolder?.path ?? 'INBOX',
      targetPath: target.path,
      messages: [message],
    );
    if (!ok) return false;
    _removeMessagesFromList([message]);
    return true;
  }

  Future<bool> archiveSelected() async {
    final archive = _findFolderByHints(['all mail', 'archive']);
    if (archive == null) return false;
    return moveSelectedTo(archive);
  }

  Future<bool> reportSpamSelected() async {
    final spam = _findFolderByHints(['spam', 'junk']);
    if (spam == null) return false;
    return moveSelectedTo(spam);
  }

  Future<bool> snoozeSelected() async {
    final snoozed = _findFolderByHints(['snoozed', 'snooze']);
    if (snoozed == null) return false;
    return moveSelectedTo(snoozed);
  }

  Future<bool> moveSelectedTo(MailFolder folder) async {
    if (_email == null || _password == null) return false;
    if (!_isMoveAllowed(_selectedFolder, folder)) return false;
    final selected = _selectedMessages();
    if (selected.isEmpty) return false;
    final ok = await ImapService().moveMessages(
      email: _email!,
      password: _password!,
      imapHost: _imapHost,
      imapPort: _imapPort,
      imapSecure: _imapSecure,
      mailboxPath: _selectedFolder?.path ?? 'INBOX',
      targetPath: folder.path,
      messages: selected,
    );
    if (!ok) return false;
    _removeSelectedFromList();
    return true;
  }

  bool _isMoveAllowed(MailFolder? source, MailFolder target) {
    if (source == null) return true;
    final sourceName = source.name.toLowerCase();
    final targetName = target.name.toLowerCase();
    if (sourceName == 'inbox') {
      if (targetName.contains('sent') || targetName.contains('draft')) {
        return false;
      }
    }
    if (sourceName.contains('sent') || sourceName.contains('draft')) {
      if (targetName == 'inbox') {
        return false;
      }
    }
    return true;
  }

  Future<bool> addLabelTo(MailFolder folder) async {
    if (_email == null || _password == null) return false;
    final selected = _selectedMessages();
    if (selected.isEmpty) return false;
    final ok = await ImapService().copyMessages(
      email: _email!,
      password: _password!,
      imapHost: _imapHost,
      imapPort: _imapPort,
      imapSecure: _imapSecure,
      mailboxPath: _selectedFolder?.path ?? 'INBOX',
      targetPath: folder.path,
      messages: selected,
    );
    if (!ok) return false;
    return true;
  }

  void _removeSelectedFromList() {
    if (_selectedKeys.isEmpty) return;
    _mails.removeWhere((m) => _selectedKeys.contains(_messageKey(m)));
    _selectedKeys.clear();
    _updateSequenceRange();
    _setWindowFromCurrent();
    _rebuildLocalFilter();
    if (_mails.isNotEmpty && _selectedMail != null) {
      if (!_mails.any((m) => _messageKey(m) == _messageKey(_selectedMail!))) {
        _selectedMail = _mails.first;
      }
    }
    notifyListeners();
  }

  void _removeMessagesFromList(List<MimeMessage> messages) {
    final removeKeys = messages.map(_messageKey).toSet();
    if (removeKeys.isEmpty) return;
    _mails.removeWhere((m) => removeKeys.contains(_messageKey(m)));
    _selectedKeys.removeWhere((key) => removeKeys.contains(key));
    if (_selectedMail != null &&
        removeKeys.contains(_messageKey(_selectedMail!))) {
      _selectedMail = _mails.isNotEmpty ? _mails.first : null;
    }
    _updateSequenceRange();
    _setWindowFromCurrent();
    _rebuildLocalFilter();
    notifyListeners();
  }

  MailFolder? _findFolderByHints(List<String> hints) {
    for (final hint in hints) {
      final match = _folders.firstWhere(
        (f) => f.name.toLowerCase().contains(hint),
        orElse: () => MailFolder(name: '', path: ''),
      );
      if (match.path.isNotEmpty) return match;
    }
    return null;
  }

  MailFolder? _draftFolder() {
    return _findFolderByHints(['draft']);
  }

  Future<bool> saveDraftToServer({
    required String messageId,
    required String to,
    required String cc,
    required String bcc,
    required String subject,
    required String body,
  }) async {
    if (_email == null || _password == null) return false;
    final draftFolder = _draftFolder();
    if (draftFolder == null) return false;
    await ImapService().deleteByMessageId(
      email: _email!,
      password: _password!,
      imapHost: _imapHost,
      imapPort: _imapPort,
      imapSecure: _imapSecure,
      mailboxPath: draftFolder.path,
      messageId: messageId,
    );
    return ImapService().appendDraft(
      email: _email!,
      password: _password!,
      imapHost: _imapHost,
      imapPort: _imapPort,
      imapSecure: _imapSecure,
      mailboxPath: draftFolder.path,
      from: _email!,
      to: to,
      cc: cc,
      bcc: bcc,
      subject: subject,
      body: body,
      messageId: messageId,
    );
  }

  Future<bool> deleteDraftFromServer(String messageId) async {
    if (_email == null || _password == null) return false;
    final draftFolder = _draftFolder();
    if (draftFolder == null) return false;
    return ImapService().deleteByMessageId(
      email: _email!,
      password: _password!,
      imapHost: _imapHost,
      imapPort: _imapPort,
      imapSecure: _imapSecure,
      mailboxPath: draftFolder.path,
      messageId: messageId,
    );
  }

  Future<void> search(String query) async {
    final trimmed = query.trim();
    if (_useBackendMailApi) {
      if (trimmed.isEmpty) {
        clearLocalFilter();
      } else {
        applyLocalFilter(trimmed);
      }
      return;
    }
    if (!_supportsRemoteMailbox) return;
    if (trimmed.isEmpty) {
      await clearSearch();
      return;
    }
    _localQuery = '';
    _filteredMails = [];
    _addSearchHistory(trimmed);
    if (_email == null) return;
    final secret = _password ?? '';
    final oauthAccessToken = await _resolveImapAccessToken();
    if (secret.isEmpty && (oauthAccessToken == null || oauthAccessToken.isEmpty)) return;
    _searchContext = _SearchContext.query;
    _searchQuery = trimmed;
    _isLoading = true;
    notifyListeners();

    if (_normalMails.isEmpty) {
      _normalMails = List<MimeMessage>.from(_mails);
      _normalMailboxMessages = _mailboxMessages;
    }

    final parsed = _parseSearchQuery(trimmed);
    final result = await ImapService().searchMessages(
      email: _email!,
      password: _password!,
      imapHost: _imapHost,
      imapPort: _imapPort,
      imapSecure: _imapSecure,
      searchCriteria: parsed.criteria,
      mailboxPath: parsed.mailboxPath ?? _selectedFolder?.path ?? 'INBOX',
      pageSize: _pageSize,
    );
    _searchTotal = result.mailboxMessages;
    _mailboxMessages = result.mailboxMessages;
    _mails = _mergeAndSort(result.messages, replace: true);
    _windowStartSeq = 1;
    _windowEndSeq = min(_pageSize, _searchTotal);
    _syncSelectionAfterReplace();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> clearSearch() async {
    if (_searchContext != _SearchContext.query) return;
    _searchContext = _SearchContext.none;
    _searchQuery = '';
    _searchTotal = 0;
    if (_normalMails.isNotEmpty) {
      _mails = List<MimeMessage>.from(_normalMails);
      _normalMails = [];
      _mailboxMessages = _normalMailboxMessages;
      _updateSequenceRange();
      _setWindowFromCurrent();
      _syncSelectionAfterReplace();
    } else {
      await fetchInitial();
    }
    notifyListeners();
  }

  void applyLocalFilter(String query) {
    final trimmed = query.trim();
    _localQuery = trimmed;
    if (trimmed.isEmpty) {
      _filteredMails = [];
      notifyListeners();
      return;
    }
    _filteredMails =
        _mails.where((m) => _matchesLocalQuery(m, trimmed)).toList();
    notifyListeners();
  }

  void clearLocalFilter() {
    if (_localQuery.isEmpty) return;
    _localQuery = '';
    _filteredMails = [];
    notifyListeners();
  }

  void _rebuildLocalFilter() {
    if (_localQuery.isEmpty) return;
    _filteredMails =
        _mails.where((m) => _matchesLocalQuery(m, _localQuery)).toList();
  }

  bool _matchesLocalQuery(MimeMessage message, String query) {
    final q = query.toLowerCase();
    final subject = (message.decodeSubject() ?? '').toLowerCase();
    if (subject.contains(q)) return true;
    final from = message.from?.map((f) => f.toString()).join(' ') ?? '';
    if (from.toLowerCase().contains(q)) return true;
    final to = message.to?.map((t) => t.toString()).join(' ') ?? '';
    if (to.toLowerCase().contains(q)) return true;
    final text = message.decodeTextPlainPart() ?? '';
    if (text.toLowerCase().contains(q)) return true;
    return false;
  }

  void _addSearchHistory(String query) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;
    _searchHistory.removeWhere(
      (existing) => existing.toLowerCase() == trimmed.toLowerCase(),
    );
    _searchHistory.insert(0, trimmed);
    if (_searchHistory.length > 12) {
      _searchHistory.removeRange(12, _searchHistory.length);
    }
    notifyListeners();
  }

  Future<void> setInboxCategory(String category) async {
    if (_useBackendMailApi) return;
    if (!_supportsRemoteMailbox) return;
    if (_selectedFolder == null ||
        _selectedFolder!.name.toLowerCase() != 'inbox') {
      return;
    }
    if (_inboxCategory == category && _searchContext != _SearchContext.none) {
      return;
    }
    _inboxCategory = category;
    if (category == 'primary') {
      _searchContext = _SearchContext.none;
      _searchTotal = 0;
      if (_normalMails.isNotEmpty) {
        _mails = List<MimeMessage>.from(_normalMails);
        _normalMails = [];
        _mailboxMessages = _normalMailboxMessages;
        _updateSequenceRange();
        _setWindowFromCurrent();
        _syncSelectionAfterReplace();
        notifyListeners();
        return;
      }
      await fetchInitial();
      return;
    }

    if (_email == null) return;
    final secret = _password ?? '';
    final oauthAccessToken = await _resolveImapAccessToken();
    if (secret.isEmpty && (oauthAccessToken == null || oauthAccessToken.isEmpty)) return;
    _searchContext = _SearchContext.category;
    _isLoading = true;
    notifyListeners();

    if (_normalMails.isEmpty) {
      _normalMails = List<MimeMessage>.from(_mails);
      _normalMailboxMessages = _mailboxMessages;
    }

    final query = 'X-GM-RAW "category:$category"';
    final result = await ImapService().searchMessages(
      email: _email!,
      password: _password!,
      imapHost: _imapHost,
      imapPort: _imapPort,
      imapSecure: _imapSecure,
      searchCriteria: query,
      mailboxPath: 'INBOX',
      pageSize: _pageSize,
    );
    _searchTotal = result.mailboxMessages;
    _mailboxMessages = result.mailboxMessages;
    _mails = _mergeAndSort(result.messages, replace: true);
    _windowStartSeq = 1;
    _windowEndSeq = min(_pageSize, _searchTotal);
    _syncSelectionAfterReplace();
    _isLoading = false;
    notifyListeners();
  }

  _SearchParseResult _parseSearchQuery(String query) {
    final tokens = _tokenizeSearch(query);
    final criteria = <String>[];
    String? mailboxPath;

    for (final token in tokens) {
      final lower = token.toLowerCase();
      if (lower.startsWith('from:')) {
        criteria.add('FROM "${token.substring(5)}"');
      } else if (lower.startsWith('to:')) {
        criteria.add('TO "${token.substring(3)}"');
      } else if (lower.startsWith('subject:')) {
        criteria.add('SUBJECT "${token.substring(8)}"');
      } else if (lower.startsWith('larger:')) {
        final size = int.tryParse(token.substring(7));
        if (size != null) {
          criteria.add('LARGER $size');
        }
      } else if (lower.startsWith('smaller:')) {
        final size = int.tryParse(token.substring(8));
        if (size != null) {
          criteria.add('SMALLER $size');
        }
      } else if (lower.startsWith('has:')) {
        final value = token.substring(4);
        if (value == 'attachment') {
          criteria.add('HEADER Content-Type "multipart"');
        }
      } else if (lower.startsWith('not:')) {
        final value = token.substring(4);
        if (value.isNotEmpty) {
          criteria.add('NOT TEXT "$value"');
        }
      } else if (lower.startsWith('is:')) {
        final value = token.substring(3);
        if (value == 'unread') criteria.add('UNSEEN');
        if (value == 'read') criteria.add('SEEN');
        if (value == 'starred') criteria.add('FLAGGED');
      } else if (lower.startsWith('label:') || lower.startsWith('in:')) {
        final value = token.split(':').last;
        mailboxPath = _matchFolderPath(value);
      } else if (lower.startsWith('before:')) {
        final date = _parseDate(token.substring(7));
        if (date != null) {
          criteria.add('BEFORE ${_formatImapDate(date)}');
        }
      } else if (lower.startsWith('after:') || lower.startsWith('since:')) {
        final value = token.split(':').last;
        final date = _parseDate(value);
        if (date != null) {
          criteria.add('SINCE ${_formatImapDate(date)}');
        }
      } else if (lower.startsWith('on:')) {
        final date = _parseDate(token.substring(3));
        if (date != null) {
          criteria.add('ON ${_formatImapDate(date)}');
        }
      } else if (lower.startsWith('-') && token.length > 1) {
        criteria.add('NOT TEXT "${token.substring(1)}"');
      } else {
        criteria.add('TEXT "$token"');
      }
    }

    return _SearchParseResult(
      criteria: criteria.join(' '),
      mailboxPath: mailboxPath,
    );
  }

  List<String> _tokenizeSearch(String input) {
    final tokens = <String>[];
    final buffer = StringBuffer();
    var inQuotes = false;
    for (final rune in input.runes) {
      final char = String.fromCharCode(rune);
      if (char == '"') {
        inQuotes = !inQuotes;
        continue;
      }
      if (!inQuotes && char.trim().isEmpty) {
        if (buffer.isNotEmpty) {
          tokens.add(buffer.toString());
          buffer.clear();
        }
      } else {
        buffer.write(char);
      }
    }
    if (buffer.isNotEmpty) tokens.add(buffer.toString());
    return tokens;
  }

  String? _matchFolderPath(String name) {
    final n = name.toLowerCase();
    for (final folder in _folders) {
      final label = folder.name.toLowerCase();
      if (label == n || label.contains(n)) {
        return folder.path;
      }
    }
    return null;
  }

  DateTime? _parseDate(String raw) {
    final normalized = raw.replaceAll('/', '-');
    try {
      return DateTime.parse(normalized);
    } catch (_) {
      return null;
    }
  }

  String _formatImapDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final day = date.day.toString().padLeft(2, '0');
    return '$day-${months[date.month - 1]}-${date.year}';
  }

  List<MimeMessage> _mergeAndSort(
    List<MimeMessage> incoming, {
    bool replace = false,
  }) {
    final Map<String, MimeMessage> map = {};
    if (!replace) {
      for (final m in _mails) {
        map[_messageKey(m)] = m;
      }
    }
    for (final m in incoming) {
      map[_messageKey(m)] = m;
    }
    final merged = map.values.toList();
    merged.sort((a, b) {
      final ad = a.decodeDate();
      final bd = b.decodeDate();
      if (ad != null && bd != null) {
        final byDate = bd.compareTo(ad);
        if (byDate != 0) return byDate;
      } else if (ad != null) {
        return -1;
      } else if (bd != null) {
        return 1;
      }
      return (b.sequenceId ?? 0).compareTo(a.sequenceId ?? 0);
    });
    return merged;
  }

  String _messageKey(MimeMessage m) {
    if (m.uid != null) return 'uid:${m.uid}';
    if (m.sequenceId != null) return 'seq:${m.sequenceId}';
    return 'hash:${m.hashCode}';
  }

  Future<void> _saveCache() async {
    if (_password == null) return;
    await MailCache.save(password: _password!, messages: _mails);
  }

  Future<void> _loadFromCache() async {
    if (_password == null) return;
    try {
      final cached = await MailCache.load(password: _password!);
      if (cached.isEmpty) return;
      _mails = _mergeAndSort(cached, replace: true);
      _updateSequenceRange();
      _isLoading = false;
      notifyListeners();
    } catch (_) {}
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(minutes: 2), (_) {
      loadNewer();
    });
  }
}

class _SearchParseResult {
  final String criteria;
  final String? mailboxPath;

  const _SearchParseResult({
    required this.criteria,
    required this.mailboxPath,
  });
}

enum _SearchContext { none, query, category }
