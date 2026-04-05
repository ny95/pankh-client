import 'package:enough_mail/enough_mail.dart';
import 'package:flutter/foundation.dart';

import '../utils/email_servers.dart';

class ImapPageResult {
  final List<MimeMessage> messages;
  final int mailboxMessages;

  const ImapPageResult({
    required this.messages,
    required this.mailboxMessages,
  });
}

class ImapService {
  EmailServerInfo _resolveServer(
    String email, {
    String? imapHost,
    int? imapPort,
    bool? imapSecure,
  }) {
    final base = serverInfoFromEmail(email);
    return EmailServerInfo(
      imapHost: imapHost ?? base.imapHost,
      imapPort: imapPort ?? base.imapPort,
      imapSecure: imapSecure ?? base.imapSecure,
      smtpHost: base.smtpHost,
      smtpPort: base.smtpPort,
      smtpSecure: base.smtpSecure,
    );
  }


  Future<void> _authenticate(
    ImapClient client, {
    required String email,
    required String password,
    String? oauthAccessToken,
  }) async {
    if (oauthAccessToken != null && oauthAccessToken.isNotEmpty) {
      await client.authenticateWithOAuth2(email, oauthAccessToken);
      return;
    }
    await client.login(email, password);
  }

  Future<bool> appendDraft({
    required String email,
    required String password,
    String? oauthAccessToken,
    String? imapHost,
    int? imapPort,
    bool? imapSecure,
    required String mailboxPath,
    required String from,
    required String to,
    required String cc,
    required String bcc,
    required String subject,
    required String body,
    required String messageId,
  }) async {
    if (email.isEmpty || (password.isEmpty && (oauthAccessToken == null || oauthAccessToken.isEmpty))) return false;
    final serverInfo = _resolveServer(
      email,
      imapHost: imapHost,
      imapPort: imapPort,
      imapSecure: imapSecure,
    );
    final imapServerHost = serverInfo.imapHost;
    final client = ImapClient(
      isLogEnabled: kDebugMode,
      // onBadCertificate: (certificate) => true,
    );

    var connected = false;
    try {
      if (imapServerHost.isEmpty) return false;
      await client.connectToServer(
        imapServerHost,
        serverInfo.imapPort,
        isSecure: serverInfo.imapSecure,
      );
      connected = true;
      await _authenticate(
        client,
        email: email,
        password: password,
        oauthAccessToken: oauthAccessToken,
      );

      final builder = MessageBuilder()
        ..from = [_safeAddress(from)]
        ..to = _parseAddresses(to)
        ..cc = _parseAddresses(cc)
        ..bcc = _parseAddresses(bcc)
        ..subject = subject
        ..text = body
        ..messageId = messageId
        ..date = DateTime.now();

      final message = builder.buildMimeMessage();
      await client.appendMessage(
        message,
        flags: const ['\\Draft'],
        targetMailboxPath: mailboxPath,
      );
      return true;
    } catch (_) {
      return false;
    } finally {
      if (connected) {
        try {
          await client.logout();
        } catch (_) {}
      }
    }
  }

  Future<bool> testConnection({
    required String email,
    required String password,
    String? oauthAccessToken,
    String? imapHost,
    int? imapPort,
    bool? imapSecure,
  }) async {
    if (email.isEmpty || (password.isEmpty && (oauthAccessToken == null || oauthAccessToken.isEmpty))) return false;
    final serverInfo = _resolveServer(
      email,
      imapHost: imapHost,
      imapPort: imapPort,
      imapSecure: imapSecure,
    );
    final client = ImapClient(
      isLogEnabled: kDebugMode,
      onBadCertificate: (certificate) => true,
    );
    var connected = false;
    try {
      if (serverInfo.imapHost.isEmpty) return false;
      await client.connectToServer(
        serverInfo.imapHost,
        serverInfo.imapPort,
        isSecure: serverInfo.imapSecure,
      );
      connected = true;
      await _authenticate(
        client,
        email: email,
        password: password,
        oauthAccessToken: oauthAccessToken,
      );
      return true;
    } catch (_) {
      return false;
    } finally {
      if (connected) {
        try {
          await client.logout();
        } catch (_) {}
      }
    }
  }

  Future<bool> deleteByMessageId({
    required String email,
    required String password,
    String? oauthAccessToken,
    String? imapHost,
    int? imapPort,
    bool? imapSecure,
    required String mailboxPath,
    required String messageId,
  }) async {
    if (email.isEmpty || (password.isEmpty && (oauthAccessToken == null || oauthAccessToken.isEmpty))) return false;
    final serverInfo = _resolveServer(
      email,
      imapHost: imapHost,
      imapPort: imapPort,
      imapSecure: imapSecure,
    );
    final imapServerHost = serverInfo.imapHost;
    final client = ImapClient(
      isLogEnabled: kDebugMode,
      onBadCertificate: (certificate) => true,
    );

    var connected = false;
    try {
      if (imapServerHost.isEmpty) return false;
      await client.connectToServer(
        imapServerHost,
        serverInfo.imapPort,
        isSecure: serverInfo.imapSecure,
      );
      connected = true;
      await _authenticate(
        client,
        email: email,
        password: password,
        oauthAccessToken: oauthAccessToken,
      );
      await client.selectMailboxByPath(mailboxPath);
      final result = await client.searchMessages(
        searchCriteria: 'HEADER Message-ID "$messageId"',
      );
      final sequence = result.matchingSequence;
      if (sequence == null || sequence.isEmpty) return false;
      await client.store(
        sequence,
        const ['\\Deleted'],
        action: StoreAction.add,
        silent: true,
      );
      await client.expunge();
      return true;
    } catch (_) {
      return false;
    } finally {
      if (connected) {
        try {
          await client.logout();
        } catch (_) {}
      }
    }
  }
  Future<ImapPageResult> searchMessages({
    required String email,
    required String password,
    String? oauthAccessToken,
    String? imapHost,
    int? imapPort,
    bool? imapSecure,
    required String searchCriteria,
    String mailboxPath = 'INBOX',
    int pageSize = 20,
  }) async {
    if (email.isEmpty || (password.isEmpty && (oauthAccessToken == null || oauthAccessToken.isEmpty))) {
      return const ImapPageResult(messages: [], mailboxMessages: 0);
    }
    final serverInfo = _resolveServer(
      email,
      imapHost: imapHost,
      imapPort: imapPort,
      imapSecure: imapSecure,
    );
    final imapServerHost = serverInfo.imapHost;
    final client = ImapClient(
      isLogEnabled: kDebugMode,
      onBadCertificate: (certificate) => true,
    );

    var connected = false;
    try {
      if (imapServerHost.isEmpty) {
        return const ImapPageResult(messages: [], mailboxMessages: 0);
      }
      await client.connectToServer(
        imapServerHost,
        serverInfo.imapPort,
        isSecure: serverInfo.imapSecure,
      );
      connected = true;
      await _authenticate(
        client,
        email: email,
        password: password,
        oauthAccessToken: oauthAccessToken,
      );
      final mailbox = await client.selectMailboxByPath(mailboxPath);
      final total = mailbox.messagesExists;
      final result = await client.searchMessages(
        searchCriteria: searchCriteria.isEmpty ? 'ALL' : searchCriteria,
      );
      final sequence = result.matchingSequence;
      if (sequence == null || sequence.isEmpty) {
        return const ImapPageResult(messages: [], mailboxMessages: 0);
      }
      final ids = sequence.toList(total);
      final count = ids.length;
      if (count == 0) {
        return const ImapPageResult(messages: [], mailboxMessages: 0);
      }
      final startIndex = count > pageSize ? count - pageSize : 0;
      final pageIds = ids.sublist(startIndex);
      final fetchResult = await client.fetchMessages(
        MessageSequence.fromIds(pageIds),
        '(FLAGS BODY[])',
      );
      return ImapPageResult(
        messages: fetchResult.messages,
        mailboxMessages: count,
      );
    } on ImapException catch (e) {
      debugPrint('IMAP failed: $e');
      return const ImapPageResult(messages: [], mailboxMessages: 0);
    } on Exception catch (e) {
      debugPrint('IMAP error: $e');
      return const ImapPageResult(messages: [], mailboxMessages: 0);
    } finally {
      if (connected) {
        try {
          await client.logout();
        } catch (_) {}
      }
    }
  }

  Future<bool> toggleFlagged({
    required String email,
    required String password,
    String? oauthAccessToken,
    String? imapHost,
    int? imapPort,
    bool? imapSecure,
    required String mailboxPath,
    required MimeMessage message,
    required bool add,
  }) async {
    if (email.isEmpty || (password.isEmpty && (oauthAccessToken == null || oauthAccessToken.isEmpty))) return false;
    final serverInfo = _resolveServer(
      email,
      imapHost: imapHost,
      imapPort: imapPort,
      imapSecure: imapSecure,
    );
    final imapServerHost = serverInfo.imapHost;
    final client = ImapClient(
      isLogEnabled: kDebugMode,
      onBadCertificate: (certificate) => true,
    );

    var connected = false;
    try {
      if (imapServerHost.isEmpty) return false;
      await client.connectToServer(
        imapServerHost,
        serverInfo.imapPort,
        isSecure: serverInfo.imapSecure,
      );
      connected = true;
      await _authenticate(
        client,
        email: email,
        password: password,
        oauthAccessToken: oauthAccessToken,
      );
      await client.selectMailboxByPath(mailboxPath);

      if (message.uid != null) {
        await client.uidStore(
          MessageSequence.fromId(message.uid!, isUid: true),
          const ['\\Flagged'],
          action: add ? StoreAction.add : StoreAction.remove,
          silent: true,
        );
        return true;
      }
      if (message.sequenceId != null) {
        await client.store(
          MessageSequence.fromId(message.sequenceId!),
          const ['\\Flagged'],
          action: add ? StoreAction.add : StoreAction.remove,
          silent: true,
        );
        return true;
      }
      return false;
    } catch (_) {
      return false;
    } finally {
      if (connected) {
        try {
          await client.logout();
        } catch (_) {}
      }
    }
  }

  Future<bool> setFlagged({
    required String email,
    required String password,
    String? oauthAccessToken,
    String? imapHost,
    int? imapPort,
    bool? imapSecure,
    required String mailboxPath,
    required List<MimeMessage> messages,
    required bool add,
  }) async {
    return _storeFlags(
      email: email,
      password: password,
      oauthAccessToken: oauthAccessToken,
      imapHost: imapHost,
      imapPort: imapPort,
      imapSecure: imapSecure,
      mailboxPath: mailboxPath,
      messages: messages,
      flags: const ['\\Flagged'],
      action: add ? StoreAction.add : StoreAction.remove,
    );
  }

  Future<bool> setSeen({
    required String email,
    required String password,
    String? oauthAccessToken,
    String? imapHost,
    int? imapPort,
    bool? imapSecure,
    required String mailboxPath,
    required List<MimeMessage> messages,
    required bool seen,
  }) async {
    return _storeFlags(
      email: email,
      password: password,
      oauthAccessToken: oauthAccessToken,
      imapHost: imapHost,
      imapPort: imapPort,
      imapSecure: imapSecure,
      mailboxPath: mailboxPath,
      messages: messages,
      flags: const ['\\Seen'],
      action: seen ? StoreAction.add : StoreAction.remove,
    );
  }

  Future<bool> moveMessages({
    required String email,
    required String password,
    String? oauthAccessToken,
    String? imapHost,
    int? imapPort,
    bool? imapSecure,
    required String mailboxPath,
    required String targetPath,
    required List<MimeMessage> messages,
  }) async {
    return _copyOrMove(
      email: email,
      password: password,
      oauthAccessToken: oauthAccessToken,
      imapHost: imapHost,
      imapPort: imapPort,
      imapSecure: imapSecure,
      mailboxPath: mailboxPath,
      targetPath: targetPath,
      messages: messages,
      move: true,
    );
  }

  Future<bool> copyMessages({
    required String email,
    required String password,
    String? oauthAccessToken,
    String? imapHost,
    int? imapPort,
    bool? imapSecure,
    required String mailboxPath,
    required String targetPath,
    required List<MimeMessage> messages,
  }) async {
    return _copyOrMove(
      email: email,
      password: password,
      oauthAccessToken: oauthAccessToken,
      imapHost: imapHost,
      imapPort: imapPort,
      imapSecure: imapSecure,
      mailboxPath: mailboxPath,
      targetPath: targetPath,
      messages: messages,
      move: false,
    );
  }

  Future<bool> deleteMessages({
    required String email,
    required String password,
    String? oauthAccessToken,
    String? imapHost,
    int? imapPort,
    bool? imapSecure,
    required String mailboxPath,
    required List<MimeMessage> messages,
  }) async {
    if (email.isEmpty || (password.isEmpty && (oauthAccessToken == null || oauthAccessToken.isEmpty))) return false;
    final serverInfo = _resolveServer(
      email,
      imapHost: imapHost,
      imapPort: imapPort,
      imapSecure: imapSecure,
    );
    final imapServerHost = serverInfo.imapHost;
    final client = ImapClient(
      isLogEnabled: kDebugMode,
      onBadCertificate: (certificate) => true,
    );

    var connected = false;
    try {
      if (imapServerHost.isEmpty) return false;
      await client.connectToServer(
        imapServerHost,
        serverInfo.imapPort,
        isSecure: serverInfo.imapSecure,
      );
      connected = true;
      await _authenticate(
        client,
        email: email,
        password: password,
        oauthAccessToken: oauthAccessToken,
      );
      await client.selectMailboxByPath(mailboxPath);

      final usedUid = _allHaveUid(messages);
      final ids = _collectIds(messages, useUid: usedUid);
      if (ids.isEmpty) return false;
      if (usedUid) {
        await client.uidStore(
          MessageSequence.fromIds(ids, isUid: true),
          const ['\\Deleted'],
          action: StoreAction.add,
          silent: true,
        );
        await client.uidExpunge(
          MessageSequence.fromIds(ids, isUid: true),
        );
      } else {
        await client.store(
          MessageSequence.fromIds(ids),
          const ['\\Deleted'],
          action: StoreAction.add,
          silent: true,
        );
        await client.expunge();
      }
      return true;
    } catch (_) {
      return false;
    } finally {
      if (connected) {
        try {
          await client.logout();
        } catch (_) {}
      }
    }
  }

  Future<bool> _storeFlags({
    required String email,
    required String password,
    String? oauthAccessToken,
    String? imapHost,
    int? imapPort,
    bool? imapSecure,
    required String mailboxPath,
    required List<MimeMessage> messages,
    required List<String> flags,
    required StoreAction action,
  }) async {
    if (email.isEmpty || (password.isEmpty && (oauthAccessToken == null || oauthAccessToken.isEmpty))) return false;
    if (messages.isEmpty) return false;
    final serverInfo = _resolveServer(
      email,
      imapHost: imapHost,
      imapPort: imapPort,
      imapSecure: imapSecure,
    );
    final imapServerHost = serverInfo.imapHost;
    final client = ImapClient(
      isLogEnabled: kDebugMode,
      onBadCertificate: (certificate) => true,
    );

    var connected = false;
    try {
      if (imapServerHost.isEmpty) return false;
      await client.connectToServer(
        imapServerHost,
        serverInfo.imapPort,
        isSecure: serverInfo.imapSecure,
      );
      connected = true;
      await _authenticate(
        client,
        email: email,
        password: password,
        oauthAccessToken: oauthAccessToken,
      );
      await client.selectMailboxByPath(mailboxPath);

      final usedUid = _allHaveUid(messages);
      final ids = _collectIds(messages, useUid: usedUid);
      if (ids.isEmpty) return false;
      if (usedUid) {
        await client.uidStore(
          MessageSequence.fromIds(ids, isUid: true),
          flags,
          action: action,
          silent: true,
        );
      } else {
        await client.store(
          MessageSequence.fromIds(ids),
          flags,
          action: action,
          silent: true,
        );
      }
      return true;
    } catch (_) {
      return false;
    } finally {
      if (connected) {
        try {
          await client.logout();
        } catch (_) {}
      }
    }
  }

  Future<bool> _copyOrMove({
    required String email,
    required String password,
    String? oauthAccessToken,
    String? imapHost,
    int? imapPort,
    bool? imapSecure,
    required String mailboxPath,
    required String targetPath,
    required List<MimeMessage> messages,
    required bool move,
  }) async {
    if (email.isEmpty || (password.isEmpty && (oauthAccessToken == null || oauthAccessToken.isEmpty))) return false;
    if (messages.isEmpty) return false;
    final serverInfo = _resolveServer(
      email,
      imapHost: imapHost,
      imapPort: imapPort,
      imapSecure: imapSecure,
    );
    final imapServerHost = serverInfo.imapHost;
    final client = ImapClient(
      isLogEnabled: kDebugMode,
      onBadCertificate: (certificate) => true,
    );

    var connected = false;
    try {
      if (imapServerHost.isEmpty) return false;
      await client.connectToServer(
        imapServerHost,
        serverInfo.imapPort,
        isSecure: serverInfo.imapSecure,
      );
      connected = true;
      await _authenticate(
        client,
        email: email,
        password: password,
        oauthAccessToken: oauthAccessToken,
      );
      await client.selectMailboxByPath(mailboxPath);

      final usedUid = _allHaveUid(messages);
      final ids = _collectIds(messages, useUid: usedUid);
      if (ids.isEmpty) return false;
      if (move) {
        try {
          if (usedUid) {
            await client.uidMove(
              MessageSequence.fromIds(ids, isUid: true),
              targetMailboxPath: targetPath,
            );
          } else {
            await client.move(
              MessageSequence.fromIds(ids),
              targetMailboxPath: targetPath,
            );
          }
        } catch (_) {
          // Fallback when MOVE is unsupported.
          if (usedUid) {
            await client.uidCopy(
              MessageSequence.fromIds(ids, isUid: true),
              targetMailboxPath: targetPath,
            );
            await client.uidStore(
              MessageSequence.fromIds(ids, isUid: true),
              const ['\\Deleted'],
              action: StoreAction.add,
              silent: true,
            );
            await client.uidExpunge(
              MessageSequence.fromIds(ids, isUid: true),
            );
          } else {
            await client.copy(
              MessageSequence.fromIds(ids),
              targetMailboxPath: targetPath,
            );
            await client.store(
              MessageSequence.fromIds(ids),
              const ['\\Deleted'],
              action: StoreAction.add,
              silent: true,
            );
            await client.expunge();
          }
        }
      } else {
        if (usedUid) {
          await client.uidCopy(
            MessageSequence.fromIds(ids, isUid: true),
            targetMailboxPath: targetPath,
          );
        } else {
          await client.copy(
            MessageSequence.fromIds(ids),
            targetMailboxPath: targetPath,
          );
        }
      }
      return true;
    } catch (_) {
      return false;
    } finally {
      if (connected) {
        try {
          await client.logout();
        } catch (_) {}
      }
    }
  }

  bool _allHaveUid(List<MimeMessage> messages) {
    return messages.every((m) => m.uid != null);
  }

  MailAddress _safeAddress(String raw) {
    try {
      return MailAddress.parse(raw);
    } catch (_) {
      return MailAddress(null, raw);
    }
  }

  List<MailAddress> _parseAddresses(String raw) {
    if (raw.trim().isEmpty) return <MailAddress>[];
    final parts = raw.split(RegExp(r'[;,]'));
    final parsed = <MailAddress>[];
    for (final part in parts) {
      final value = part.trim();
      if (value.isEmpty) continue;
      try {
        parsed.add(MailAddress.parse(value));
      } catch (_) {
        parsed.add(MailAddress(null, value));
      }
    }
    return parsed;
  }

  List<int> _collectIds(List<MimeMessage> messages, {required bool useUid}) {
    return messages
        .map((m) => useUid ? m.uid : m.sequenceId)
        .whereType<int>()
        .toList();
  }

  Future<List<Mailbox>> listMailboxes({
    required String email,
    required String password,
    String? oauthAccessToken,
    String? imapHost,
    int? imapPort,
    bool? imapSecure,
  }) async {
    if (email.isEmpty || (password.isEmpty && (oauthAccessToken == null || oauthAccessToken.isEmpty))) {
      return [];
    }
    final serverInfo = _resolveServer(
      email,
      imapHost: imapHost,
      imapPort: imapPort,
      imapSecure: imapSecure,
    );
    final imapServerHost = serverInfo.imapHost;
    final client = ImapClient(
      isLogEnabled: kDebugMode,
      onBadCertificate: (certificate) => true,
    );

    var connected = false;
    try {
      if (imapServerHost.isEmpty) return [];
      await client.connectToServer(
        imapServerHost,
        serverInfo.imapPort,
        isSecure: serverInfo.imapSecure,
      );
      connected = true;
      await _authenticate(
        client,
        email: email,
        password: password,
        oauthAccessToken: oauthAccessToken,
      );
      final mailboxes = await client.listMailboxes(recursive: true);
      return mailboxes
          .where((m) => !m.flags.contains(MailboxFlag.noSelect))
          .toList();
    } catch (_) {
      return [];
    } finally {
      if (connected) {
        try {
          await client.logout();
        } catch (_) {}
      }
    }
  }

  Future<ImapPageResult> fetchLatest({
    required String email,
    required String password,
    String? oauthAccessToken,
    String? imapHost,
    int? imapPort,
    bool? imapSecure,
    int pageSize = 20,
    String mailboxPath = 'INBOX',
  }) async {
    return _fetchRange(
      email: email,
      password: password,
      oauthAccessToken: oauthAccessToken,
      imapHost: imapHost,
      imapPort: imapPort,
      imapSecure: imapSecure,
      rangeEnd: null,
      pageSize: pageSize,
      mailboxPath: mailboxPath,
    );
  }

  Future<ImapPageResult> fetchOlder({
    required String email,
    required String password,
    String? oauthAccessToken,
    String? imapHost,
    int? imapPort,
    bool? imapSecure,
    required int rangeEnd,
    int pageSize = 20,
    String mailboxPath = 'INBOX',
  }) async {
    return _fetchRange(
      email: email,
      password: password,
      oauthAccessToken: oauthAccessToken,
      imapHost: imapHost,
      imapPort: imapPort,
      imapSecure: imapSecure,
      rangeEnd: rangeEnd,
      pageSize: pageSize,
      mailboxPath: mailboxPath,
    );
  }

  Future<ImapPageResult> fetchNewer({
    required String email,
    required String password,
    String? oauthAccessToken,
    String? imapHost,
    int? imapPort,
    bool? imapSecure,
    required int rangeStart,
    String mailboxPath = 'INBOX',
  }) async {
    return _fetchRange(
      email: email,
      password: password,
      oauthAccessToken: oauthAccessToken,
      imapHost: imapHost,
      imapPort: imapPort,
      imapSecure: imapSecure,
      rangeStart: rangeStart,
      mailboxPath: mailboxPath,
    );
  }

  Future<ImapPageResult> _fetchRange({
    required String email,
    required String password,
    String? oauthAccessToken,
    String? imapHost,
    int? imapPort,
    bool? imapSecure,
    int? rangeStart,
    int? rangeEnd,
    int pageSize = 20,
    String mailboxPath = 'INBOX',
  }) async {
    if (email.isEmpty || (password.isEmpty && (oauthAccessToken == null || oauthAccessToken.isEmpty))) {
      debugPrint('IMAP credentials missing.');
      return const ImapPageResult(messages: [], mailboxMessages: 0);
    }

    final serverInfo = _resolveServer(
      email,
      imapHost: imapHost,
      imapPort: imapPort,
      imapSecure: imapSecure,
    );
    final imapServerHost = serverInfo.imapHost;
    final client = ImapClient(
      isLogEnabled: kDebugMode,
      onBadCertificate: (certificate) => true,
    );

    var connected = false;
    try {
      if (imapServerHost.isEmpty) {
        return const ImapPageResult(messages: [], mailboxMessages: 0);
      }
      await client.connectToServer(
        imapServerHost,
        serverInfo.imapPort,
        isSecure: serverInfo.imapSecure,
      );
      connected = true;
      await _authenticate(
        client,
        email: email,
        password: password,
        oauthAccessToken: oauthAccessToken,
      );
      final mailbox = await client.selectMailboxByPath(mailboxPath);
      final total = mailbox.messagesExists;
      if (total == 0) {
        return const ImapPageResult(messages: [], mailboxMessages: 0);
      }

      int end;
      if (rangeEnd != null) {
        end = rangeEnd;
      } else {
        end = total;
      }

      int start;
      if (rangeStart != null) {
        start = rangeStart;
      } else {
        start = end - pageSize + 1;
      }

      if (start < 1) start = 1;
      if (end < 1 || start > end) {
        return ImapPageResult(messages: [], mailboxMessages: total);
      }

      final fetchResult = await client.fetchMessages(
        MessageSequence.fromRange(start, end),
        '(FLAGS BODY[])',
      );
      return ImapPageResult(
        messages: fetchResult.messages,
        mailboxMessages: total,
      );
    } on ImapException catch (e) {
      debugPrint('IMAP failed: $e');
      return const ImapPageResult(messages: [], mailboxMessages: 0);
    } on Exception catch (e) {
      debugPrint('IMAP error: $e');
      return const ImapPageResult(messages: [], mailboxMessages: 0);
    } finally {
      if (connected) {
        try {
          await client.logout();
        } catch (_) {}
      }
    }
  }
}
