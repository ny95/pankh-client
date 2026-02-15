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
  Future<ImapPageResult> searchMessages({
    required String email,
    required String password,
    required String searchCriteria,
    String mailboxPath = 'INBOX',
    int pageSize = 20,
  }) async {
    if (email.isEmpty || password.isEmpty) {
      return const ImapPageResult(messages: [], mailboxMessages: 0);
    }
    final serverInfo = serverInfoFromEmail(email);
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
      await client.login(email, password);
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
    required String mailboxPath,
    required MimeMessage message,
    required bool add,
  }) async {
    if (email.isEmpty || password.isEmpty) return false;
    final serverInfo = serverInfoFromEmail(email);
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
      await client.login(email, password);
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
    required String mailboxPath,
    required List<MimeMessage> messages,
    required bool add,
  }) async {
    return _storeFlags(
      email: email,
      password: password,
      mailboxPath: mailboxPath,
      messages: messages,
      flags: const ['\\Flagged'],
      action: add ? StoreAction.add : StoreAction.remove,
    );
  }

  Future<bool> setSeen({
    required String email,
    required String password,
    required String mailboxPath,
    required List<MimeMessage> messages,
    required bool seen,
  }) async {
    return _storeFlags(
      email: email,
      password: password,
      mailboxPath: mailboxPath,
      messages: messages,
      flags: const ['\\Seen'],
      action: seen ? StoreAction.add : StoreAction.remove,
    );
  }

  Future<bool> moveMessages({
    required String email,
    required String password,
    required String mailboxPath,
    required String targetPath,
    required List<MimeMessage> messages,
  }) async {
    return _copyOrMove(
      email: email,
      password: password,
      mailboxPath: mailboxPath,
      targetPath: targetPath,
      messages: messages,
      move: true,
    );
  }

  Future<bool> copyMessages({
    required String email,
    required String password,
    required String mailboxPath,
    required String targetPath,
    required List<MimeMessage> messages,
  }) async {
    return _copyOrMove(
      email: email,
      password: password,
      mailboxPath: mailboxPath,
      targetPath: targetPath,
      messages: messages,
      move: false,
    );
  }

  Future<bool> deleteMessages({
    required String email,
    required String password,
    required String mailboxPath,
    required List<MimeMessage> messages,
  }) async {
    if (email.isEmpty || password.isEmpty) return false;
    final serverInfo = serverInfoFromEmail(email);
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
      await client.login(email, password);
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
    required String mailboxPath,
    required List<MimeMessage> messages,
    required List<String> flags,
    required StoreAction action,
  }) async {
    if (email.isEmpty || password.isEmpty) return false;
    if (messages.isEmpty) return false;
    final serverInfo = serverInfoFromEmail(email);
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
      await client.login(email, password);
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
    required String mailboxPath,
    required String targetPath,
    required List<MimeMessage> messages,
    required bool move,
  }) async {
    if (email.isEmpty || password.isEmpty) return false;
    if (messages.isEmpty) return false;
    final serverInfo = serverInfoFromEmail(email);
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
      await client.login(email, password);
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

  List<int> _collectIds(List<MimeMessage> messages, {required bool useUid}) {
    return messages
        .map((m) => useUid ? m.uid : m.sequenceId)
        .whereType<int>()
        .toList();
  }

  Future<List<Mailbox>> listMailboxes({
    required String email,
    required String password,
  }) async {
    if (email.isEmpty || password.isEmpty) {
      return [];
    }
    final serverInfo = serverInfoFromEmail(email);
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
      await client.login(email, password);
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
    int pageSize = 20,
    String mailboxPath = 'INBOX',
  }) async {
    return _fetchRange(
      email: email,
      password: password,
      rangeEnd: null,
      pageSize: pageSize,
      mailboxPath: mailboxPath,
    );
  }

  Future<ImapPageResult> fetchOlder({
    required String email,
    required String password,
    required int rangeEnd,
    int pageSize = 20,
    String mailboxPath = 'INBOX',
  }) async {
    return _fetchRange(
      email: email,
      password: password,
      rangeEnd: rangeEnd,
      pageSize: pageSize,
      mailboxPath: mailboxPath,
    );
  }

  Future<ImapPageResult> fetchNewer({
    required String email,
    required String password,
    required int rangeStart,
    String mailboxPath = 'INBOX',
  }) async {
    return _fetchRange(
      email: email,
      password: password,
      rangeStart: rangeStart,
      mailboxPath: mailboxPath,
    );
  }

  Future<ImapPageResult> _fetchRange({
    required String email,
    required String password,
    int? rangeStart,
    int? rangeEnd,
    int pageSize = 20,
    String mailboxPath = 'INBOX',
  }) async {
    if (email.isEmpty || password.isEmpty) {
      debugPrint('IMAP credentials missing.');
      return const ImapPageResult(messages: [], mailboxMessages: 0);
    }

    final serverInfo = serverInfoFromEmail(email);
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
      await client.login(email, password);
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
