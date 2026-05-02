import 'dart:io';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/mail_folder.dart';

class BackendMailPage {
  const BackendMailPage({
    required this.rawMessages,
    required this.total,
    this.nextCursor,
  });

  final List<String> rawMessages;
  final int total;
  final String? nextCursor;
}

class ImapCredentials {
  const ImapCredentials({
    required this.host,
    required this.port,
    required this.secure,
    required this.username,
    required this.password,
  });

  final String host;
  final int port;
  final bool secure;
  final String username;
  final String password;

  Map<String, dynamic> toJson() => {
        'host': host,
        'port': port,
        'secure': secure,
        'username': username,
        'password': password,
      };
}

class EmailServerSettings {
  const EmailServerSettings({
    required this.host,
    required this.port,
    required this.secure,
    required this.authMethod,
    required this.usernamePattern,
  });

  final String host;
  final int port;
  final bool secure;
  final String authMethod;
  final String usernamePattern;

  factory EmailServerSettings.fromJson(Map<String, dynamic> json) {
    return EmailServerSettings(
      host: json['host'] as String? ?? '',
      port: json['port'] as int? ?? 0,
      secure: json['secure'] as bool? ?? true,
      authMethod: json['authMethod'] as String? ?? 'password-cleartext',
      usernamePattern: json['usernamePattern'] as String? ?? '%EMAILADDRESS%',
    );
  }
}

class EmailServerLookupResult {
  const EmailServerLookupResult({
    required this.found,
    required this.domain,
    this.source,
    this.hostedAuthAvailable = false,
    this.hostedAuthProvider,
    this.imap,
    this.smtp,
  });

  final bool found;
  final String domain;
  final String? source;
  final bool hostedAuthAvailable;
  final String? hostedAuthProvider;
  final EmailServerSettings? imap;
  final EmailServerSettings? smtp;

  factory EmailServerLookupResult.fromJson(Map<String, dynamic> json) {
    final config = json['config'];
    final hostedAuth = json['hostedAuth'];
    final configMap = config is Map<String, dynamic> ? config : <String, dynamic>{};
    final hostedAuthMap =
        hostedAuth is Map<String, dynamic> ? hostedAuth : <String, dynamic>{};
    final imap = configMap['imap'];
    final smtp = configMap['smtp'];
    return EmailServerLookupResult(
      found: json['found'] as bool? ?? false,
      domain: json['domain'] as String? ?? '',
      source: json['source'] as String?,
      hostedAuthAvailable: hostedAuthMap['available'] as bool? ?? false,
      hostedAuthProvider: hostedAuthMap['provider'] as String?,
      imap:
          imap is Map<String, dynamic>
              ? EmailServerSettings.fromJson(imap)
              : null,
      smtp:
          smtp is Map<String, dynamic>
              ? EmailServerSettings.fromJson(smtp)
              : null,
    );
  }
}


class UnauthorizedRequestException implements Exception {
  const UnauthorizedRequestException(this.message);

  final String message;

  @override
  String toString() => message;
}

class BackendApiService {
  static const String _defaultBaseUrl = String.fromEnvironment(
    'PANKH_API_BASE_URL',
    defaultValue: 'http://localhost:3000/api',
  );

  static String get baseUrl => _defaultBaseUrl;

  static Future<String> fetchGoogleAuthUrl({required String redirectUri}) async {
    return fetchProviderAuthUrl(
      provider: 'google',
      redirectUri: redirectUri,
    );
  }

  static Future<String> fetchProviderAuthUrl({
    required String provider,
    required String redirectUri,
  }) async {
    final uri = Uri.parse('$baseUrl/auth/$provider').replace(
      queryParameters: {'redirectUri': redirectUri},
    );
    final response = await http.get(uri);
    final json = _decode(response);
    return json['authUrl'] as String;
  }

  static Future<EmailServerLookupResult> lookupEmailConfig({
    required String email,
  }) async {
    final uri = Uri.parse('$baseUrl/auth/email-config/lookup').replace(
      queryParameters: {'email': email},
    );
    final response = await http.get(uri);
    final json = _decode(response) as Map<String, dynamic>;
    return EmailServerLookupResult.fromJson(json);
  }

  static Future<void> cacheEmailConfig({
    required String email,
    required String imapHost,
    required int imapPort,
    required bool imapSecure,
    String? imapAuthMethod,
    String? smtpHost,
    int? smtpPort,
    bool? smtpSecure,
    String? smtpAuthMethod,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/email-config/cache'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'imapHost': imapHost,
        'imapPort': imapPort,
        'imapSecure': imapSecure,
        if ((imapAuthMethod ?? '').isNotEmpty) 'imapAuthMethod': imapAuthMethod,
        if ((smtpHost ?? '').isNotEmpty) 'smtpHost': smtpHost,
        if (smtpPort != null) 'smtpPort': smtpPort,
        if (smtpSecure != null) 'smtpSecure': smtpSecure,
        if ((smtpAuthMethod ?? '').isNotEmpty) 'smtpAuthMethod': smtpAuthMethod,
      }),
    );
    _ensureSuccess(response);
  }

  static Future<String> fetchBrokeredAccessToken({
    required String sessionToken,
    required String provider,
  }) async {
    final response = await http.get(
      Uri.parse('$baseUrl/token/$provider'),
      headers: _authHeaders(sessionToken),
    );
    final json = _decode(response);
    return json['accessToken'] as String;
  }

  static Future<List<MailFolder>> fetchFolders({
    required String sessionToken,
  }) async {
    final response = await http.get(
      Uri.parse('$baseUrl/mail/folders'),
      headers: _authHeaders(sessionToken),
    );
    final json = _decode(response);
    final folders = (json as List)
        .map(
          (item) => MailFolder(
            name: item['name'] as String,
            path: item['path'] as String,
          ),
        )
        .toList();
    return folders;
  }

  static Future<BackendMailPage> fetchMessages({
    required String sessionToken,
    String? folderPath,
    String? cursor,
    int pageSize = 20,
  }) async {
    final query = <String, String>{
      'pageSize': '$pageSize',
    };
    if (folderPath != null && folderPath.isNotEmpty) {
      query['folderPath'] = folderPath;
    }
    if (cursor != null && cursor.isNotEmpty) {
      query['cursor'] = cursor;
    }
    final uri = Uri.parse('$baseUrl/mail/messages').replace(queryParameters: query);
    final response = await http.get(uri, headers: _authHeaders(sessionToken));
    final json = _decode(response);
    final messages = (json['messages'] as List)
        .map((item) => item['raw'] as String)
        .toList();
    return BackendMailPage(
      rawMessages: messages,
      total: json['total'] as int? ?? messages.length,
      nextCursor: json['nextCursor'] as String?,
    );
  }


  static Future<void> sendProviderEmail({
    required String sessionToken,
    required String provider,
    required List<String> to,
    List<String> cc = const [],
    List<String> bcc = const [],
    required String subject,
    String? text,
    String? html,
    List<String> attachmentPaths = const [],
  }) async {
    await http.post(
      Uri.parse('$baseUrl/send-email'),
      headers: {
        ..._authHeaders(sessionToken),
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'provider': provider,
        'to': to,
        'subject': subject,
        if ((text ?? '').isNotEmpty) 'text': text,
        if ((html ?? '').isNotEmpty) 'html': html,
        if (attachmentPaths.isNotEmpty)
          'attachments': await _encodeAttachments(attachmentPaths),
      }),
    ).then(_ensureSuccess);
  }

  static Future<void> sendSmtpEmail({
    required String host,
    required int port,
    required bool secure,
    required String username,
    required String password,
    required String from,
    required List<String> to,
    List<String> cc = const [],
    List<String> bcc = const [],
    required String subject,
    String? text,
    String? html,
    List<String> attachmentPaths = const [],
  }) async {
    await http.post(
      Uri.parse('$baseUrl/send-email/smtp'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'host': host,
        'port': port,
        'secure': secure,
        'username': username,
        'password': password,
        'from': from,
        'to': to,
        if (cc.isNotEmpty) 'cc': cc,
        if (bcc.isNotEmpty) 'bcc': bcc,
        'subject': subject,
        if ((text ?? '').isNotEmpty) 'text': text,
        if ((html ?? '').isNotEmpty) 'html': html,
        if (attachmentPaths.isNotEmpty)
          'attachments': await _encodeAttachments(attachmentPaths),
      }),
    ).then(_ensureSuccess);
  }

  // IMAP proxy — plain-credential endpoints

  static Future<List<MailFolder>> fetchImapFolders({
    required ImapCredentials creds,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/mail/imap/folders'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(creds.toJson()),
    );
    final json = _decode(response) as List;
    return json
        .map(
          (item) => MailFolder(
            name: item['name'] as String,
            path: item['path'] as String,
          ),
        )
        .toList();
  }

  static Future<BackendMailPage> fetchImapMessages({
    required ImapCredentials creds,
    required String mailboxPath,
    int pageSize = 20,
    int? cursorSeq,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/mail/imap/messages'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        ...creds.toJson(),
        'mailboxPath': mailboxPath,
        'pageSize': pageSize,
        if (cursorSeq != null) 'cursorSeq': cursorSeq,
      }),
    );
    final json = _decode(response) as Map<String, dynamic>;
    final messages = (json['messages'] as List).cast<String>();
    return BackendMailPage(
      rawMessages: messages,
      total: json['total'] as int? ?? messages.length,
      nextCursor:
          json['nextCursorSeq'] != null
              ? '${json['nextCursorSeq']}'
              : null,
    );
  }

  static Future<void> setImapSeen({
    required ImapCredentials creds,
    required String mailboxPath,
    required List<int> uids,
    required bool seen,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/mail/imap/seen'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        ...creds.toJson(),
        'mailboxPath': mailboxPath,
        'uids': uids,
        'seen': seen,
      }),
    );
    _ensureSuccess(response);
  }

  static Future<void> setImapFlagged({
    required ImapCredentials creds,
    required String mailboxPath,
    required List<int> uids,
    required bool add,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/mail/imap/flagged'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        ...creds.toJson(),
        'mailboxPath': mailboxPath,
        'uids': uids,
        'add': add,
      }),
    );
    _ensureSuccess(response);
  }

  static Future<void> moveImapMessages({
    required ImapCredentials creds,
    required String mailboxPath,
    required String targetPath,
    required List<int> uids,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/mail/imap/move'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        ...creds.toJson(),
        'mailboxPath': mailboxPath,
        'targetPath': targetPath,
        'uids': uids,
      }),
    );
    _ensureSuccess(response);
  }

  static Future<void> deleteImapMessages({
    required ImapCredentials creds,
    required String mailboxPath,
    required List<int> uids,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/mail/imap/delete'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        ...creds.toJson(),
        'mailboxPath': mailboxPath,
        'uids': uids,
      }),
    );
    _ensureSuccess(response);
  }

  static Future<void> copyImapMessages({
    required ImapCredentials creds,
    required String mailboxPath,
    required String targetPath,
    required List<int> uids,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/mail/imap/copy'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        ...creds.toJson(),
        'mailboxPath': mailboxPath,
        'targetPath': targetPath,
        'uids': uids,
      }),
    );
    _ensureSuccess(response);
  }

  static Future<void> createImapFolder({
    required ImapCredentials creds,
    required String folderName,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/mail/imap/folders/create'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        ...creds.toJson(),
        'folderName': folderName,
      }),
    );
    _ensureSuccess(response);
  }

  static Map<String, String> _authHeaders(String sessionToken) => {
        'Authorization': 'Bearer $sessionToken',
      };

  static Future<List<Map<String, String>>> _encodeAttachments(List<String> attachmentPaths) async {
    final encoded = <Map<String, String>>[];
    if (kIsWeb) return encoded;
    for (final path in attachmentPaths) {
      final file = File(path);
      if (!await file.exists()) continue;
      encoded.add({
        'filename': path.split('/').last,
        'content': base64Encode(await file.readAsBytes()),
      });
    }
    return encoded;
  }

  static void _ensureSuccess(http.Response response) {
    if (response.statusCode >= 400) {
      final body = response.body.isEmpty ? '{}' : response.body;
      throw Exception('Request failed (${response.statusCode}): $body');
    }
  }

  static dynamic _decode(http.Response response) {
    final body = response.body.isEmpty ? '{}' : response.body;
    final decoded = jsonDecode(body);
    if (response.statusCode == 401) {
      throw UnauthorizedRequestException(
        'Request failed (401): $decoded',
      );
    }
    if (response.statusCode >= 400) {
      throw Exception('Request failed (${response.statusCode}): $decoded');
    }
    return decoded;
  }
}
