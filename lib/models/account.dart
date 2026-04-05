import '../utils/email_servers.dart';

class Account {
  final String email;
  final String password;
  final String imapHost;
  final int imapPort;
  final bool imapSecure;
  final String smtpHost;
  final int smtpPort;
  final bool smtpSecure;
  final String smtpAuthMethod;
  final String smtpDescription;
  final String smtpUserName;
  final String accountName;
  final String displayName;
  final String replyTo;
  final String organization;
  final bool signatureHtml;
  final String signatureText;
  final bool signatureFromFile;
  final String signatureFilePath;
  final bool attachVCard;
  final String replyFromFilter;
  final String accountColor;
  final String authMethod;
  final bool checkAtStartup;
  final bool checkEvery2Mins;
  final int checkIntervalMinutes;
  final bool allowNotifications;
  final String deleteBehavior;
  final String deleteMoveFolder;
  final bool autoDownload;
  final bool fetchHeadersOnly;
  final bool leaveOnServer;
  final bool leaveFor365Days;
  final bool leaveUntilDeleted;
  final bool expungeOnExit;
  final bool emptyTrashOnExit;
  final String messageStoreType;
  final String localDirectory;
  final String? oauthProvider;
  final String? serverSessionToken;

  const Account({
    required this.email,
    required this.password,
    required this.imapHost,
    required this.imapPort,
    required this.imapSecure,
    required this.smtpHost,
    required this.smtpPort,
    required this.smtpSecure,
    required this.smtpAuthMethod,
    required this.smtpDescription,
    required this.smtpUserName,
    required this.accountName,
    required this.displayName,
    required this.replyTo,
    required this.organization,
    required this.signatureHtml,
    required this.signatureText,
    required this.signatureFromFile,
    required this.signatureFilePath,
    required this.attachVCard,
    required this.replyFromFilter,
    required this.accountColor,
    required this.authMethod,
    required this.checkAtStartup,
    required this.checkEvery2Mins,
    required this.checkIntervalMinutes,
    required this.allowNotifications,
    required this.deleteBehavior,
    required this.deleteMoveFolder,
    required this.autoDownload,
    required this.fetchHeadersOnly,
    required this.leaveOnServer,
    required this.leaveFor365Days,
    required this.leaveUntilDeleted,
    required this.expungeOnExit,
    required this.emptyTrashOnExit,
    required this.messageStoreType,
    required this.localDirectory,
    this.oauthProvider,
    this.serverSessionToken,
  });

  static Account initialForEmail({
    required String email,
    required String password,
  }) {
    final serverInfo = serverInfoFromEmail(email);
    return Account(
      email: email,
      password: password,
      imapHost: serverInfo.imapHost,
      imapPort: serverInfo.imapPort,
      imapSecure: serverInfo.imapSecure,
      smtpHost: serverInfo.smtpHost,
      smtpPort: serverInfo.smtpPort,
      smtpSecure: serverInfo.smtpSecure,
      smtpAuthMethod: 'Normal password',
      smtpDescription: email.split('@').first,
      smtpUserName: email,
      accountName: email,
      displayName: email.split('@').first,
      replyTo: '',
      organization: '',
      signatureHtml: false,
      signatureText: '',
      signatureFromFile: false,
      signatureFilePath: '',
      attachVCard: false,
      replyFromFilter: '',
      accountColor: '2196F3',
      authMethod: 'Normal password',
      checkAtStartup: true,
      checkEvery2Mins: true,
      checkIntervalMinutes: 10,
      allowNotifications: true,
      deleteBehavior: 'move',
      deleteMoveFolder: 'Trash',
      autoDownload: true,
      fetchHeadersOnly: false,
      leaveOnServer: true,
      leaveFor365Days: true,
      leaveUntilDeleted: true,
      expungeOnExit: false,
      emptyTrashOnExit: false,
      messageStoreType: 'File per folder (mbox)',
      localDirectory: '',
      oauthProvider: null,
      serverSessionToken: null,
    );
  }

  Account copyWith({
    String? email,
    String? password,
    String? imapHost,
    int? imapPort,
    bool? imapSecure,
    String? smtpHost,
    int? smtpPort,
    bool? smtpSecure,
    String? smtpAuthMethod,
    String? smtpDescription,
    String? smtpUserName,
    String? accountName,
    String? displayName,
    String? replyTo,
    String? organization,
    bool? signatureHtml,
    String? signatureText,
    bool? signatureFromFile,
    String? signatureFilePath,
    bool? attachVCard,
    String? replyFromFilter,
    String? accountColor,
    String? authMethod,
    bool? checkAtStartup,
    bool? checkEvery2Mins,
    int? checkIntervalMinutes,
    bool? allowNotifications,
    String? deleteBehavior,
    String? deleteMoveFolder,
    bool? autoDownload,
    bool? fetchHeadersOnly,
    bool? leaveOnServer,
    bool? leaveFor365Days,
    bool? leaveUntilDeleted,
    bool? expungeOnExit,
    bool? emptyTrashOnExit,
    String? messageStoreType,
    String? localDirectory,
    String? oauthProvider,
    String? serverSessionToken,
  }) {
    return Account(
      email: email ?? this.email,
      password: password ?? this.password,
      imapHost: imapHost ?? this.imapHost,
      imapPort: imapPort ?? this.imapPort,
      imapSecure: imapSecure ?? this.imapSecure,
      smtpHost: smtpHost ?? this.smtpHost,
      smtpPort: smtpPort ?? this.smtpPort,
      smtpSecure: smtpSecure ?? this.smtpSecure,
      smtpAuthMethod: smtpAuthMethod ?? this.smtpAuthMethod,
      smtpDescription: smtpDescription ?? this.smtpDescription,
      smtpUserName: smtpUserName ?? this.smtpUserName,
      accountName: accountName ?? this.accountName,
      displayName: displayName ?? this.displayName,
      replyTo: replyTo ?? this.replyTo,
      organization: organization ?? this.organization,
      signatureHtml: signatureHtml ?? this.signatureHtml,
      signatureText: signatureText ?? this.signatureText,
      signatureFromFile: signatureFromFile ?? this.signatureFromFile,
      signatureFilePath: signatureFilePath ?? this.signatureFilePath,
      attachVCard: attachVCard ?? this.attachVCard,
      replyFromFilter: replyFromFilter ?? this.replyFromFilter,
      accountColor: accountColor ?? this.accountColor,
      authMethod: authMethod ?? this.authMethod,
      checkAtStartup: checkAtStartup ?? this.checkAtStartup,
      checkEvery2Mins: checkEvery2Mins ?? this.checkEvery2Mins,
      checkIntervalMinutes: checkIntervalMinutes ?? this.checkIntervalMinutes,
      allowNotifications: allowNotifications ?? this.allowNotifications,
      deleteBehavior: deleteBehavior ?? this.deleteBehavior,
      deleteMoveFolder: deleteMoveFolder ?? this.deleteMoveFolder,
      autoDownload: autoDownload ?? this.autoDownload,
      fetchHeadersOnly: fetchHeadersOnly ?? this.fetchHeadersOnly,
      leaveOnServer: leaveOnServer ?? this.leaveOnServer,
      leaveFor365Days: leaveFor365Days ?? this.leaveFor365Days,
      leaveUntilDeleted: leaveUntilDeleted ?? this.leaveUntilDeleted,
      expungeOnExit: expungeOnExit ?? this.expungeOnExit,
      emptyTrashOnExit: emptyTrashOnExit ?? this.emptyTrashOnExit,
      messageStoreType: messageStoreType ?? this.messageStoreType,
      localDirectory: localDirectory ?? this.localDirectory,
      oauthProvider: oauthProvider ?? this.oauthProvider,
      serverSessionToken: serverSessionToken ?? this.serverSessionToken,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'password': password,
      'imapHost': imapHost,
      'imapPort': imapPort,
      'imapSecure': imapSecure,
      'smtpHost': smtpHost,
      'smtpPort': smtpPort,
      'smtpSecure': smtpSecure,
      'smtpAuthMethod': smtpAuthMethod,
      'smtpDescription': smtpDescription,
      'smtpUserName': smtpUserName,
      'accountName': accountName,
      'displayName': displayName,
      'replyTo': replyTo,
      'organization': organization,
      'signatureHtml': signatureHtml,
      'signatureText': signatureText,
      'signatureFromFile': signatureFromFile,
      'signatureFilePath': signatureFilePath,
      'attachVCard': attachVCard,
      'replyFromFilter': replyFromFilter,
      'accountColor': accountColor,
      'authMethod': authMethod,
      'checkAtStartup': checkAtStartup,
      'checkEvery2Mins': checkEvery2Mins,
      'checkIntervalMinutes': checkIntervalMinutes,
      'allowNotifications': allowNotifications,
      'deleteBehavior': deleteBehavior,
      'deleteMoveFolder': deleteMoveFolder,
      'autoDownload': autoDownload,
      'fetchHeadersOnly': fetchHeadersOnly,
      'leaveOnServer': leaveOnServer,
      'leaveFor365Days': leaveFor365Days,
      'leaveUntilDeleted': leaveUntilDeleted,
      'expungeOnExit': expungeOnExit,
      'emptyTrashOnExit': emptyTrashOnExit,
      'messageStoreType': messageStoreType,
      'localDirectory': localDirectory,
      'oauthProvider': oauthProvider,
      'serverSessionToken': serverSessionToken,
    };
  }

  static Account? fromMap(dynamic value) {
    if (value is! Map) return null;
    final email = value['email'];
    final password = value['password'];
    if (email is! String || password is! String) return null;
    final serverInfo = serverInfoFromEmail(email);
    final imapHost =
        value['imapHost'] is String
            ? value['imapHost'] as String
            : serverInfo.imapHost;
    final imapPort =
        value['imapPort'] is int
            ? value['imapPort'] as int
            : serverInfo.imapPort;
    final imapSecure =
        value['imapSecure'] is bool
            ? value['imapSecure'] as bool
            : serverInfo.imapSecure;
    final smtpHost =
        value['smtpHost'] is String
            ? value['smtpHost'] as String
            : serverInfo.smtpHost;
    final smtpPort =
        value['smtpPort'] is int
            ? value['smtpPort'] as int
            : serverInfo.smtpPort;
    final smtpSecure =
        value['smtpSecure'] is bool
            ? value['smtpSecure'] as bool
            : serverInfo.smtpSecure;

    return Account(
      email: email,
      password: password,
      imapHost: imapHost,
      imapPort: imapPort,
      imapSecure: imapSecure,
      smtpHost: smtpHost,
      smtpPort: smtpPort,
      smtpSecure: smtpSecure,
      smtpAuthMethod:
          value['smtpAuthMethod'] is String
              ? value['smtpAuthMethod'] as String
              : 'Normal password',
      smtpDescription:
          value['smtpDescription'] is String
              ? value['smtpDescription'] as String
              : email.split('@').first,
      smtpUserName:
          value['smtpUserName'] is String
              ? value['smtpUserName'] as String
              : email,
      accountName:
          value['accountName'] is String ? value['accountName'] as String : email,
      displayName:
          value['displayName'] is String
              ? value['displayName'] as String
              : email.split('@').first,
      replyTo: value['replyTo'] is String ? value['replyTo'] as String : '',
      organization:
          value['organization'] is String ? value['organization'] as String : '',
      signatureHtml:
          value['signatureHtml'] is bool ? value['signatureHtml'] as bool : false,
      signatureText:
          value['signatureText'] is String ? value['signatureText'] as String : '',
      signatureFromFile:
          value['signatureFromFile'] is bool
              ? value['signatureFromFile'] as bool
              : false,
      signatureFilePath:
          value['signatureFilePath'] is String
              ? value['signatureFilePath'] as String
              : '',
      attachVCard:
          value['attachVCard'] is bool ? value['attachVCard'] as bool : false,
      replyFromFilter:
          value['replyFromFilter'] is String
              ? value['replyFromFilter'] as String
              : '',
      accountColor:
          value['accountColor'] is String
              ? value['accountColor'] as String
              : '2196F3',
      authMethod:
          value['authMethod'] is String
              ? value['authMethod'] as String
              : 'Normal password',
      checkAtStartup:
          value['checkAtStartup'] is bool
              ? value['checkAtStartup'] as bool
              : true,
      checkEvery2Mins:
          value['checkEvery2Mins'] is bool
              ? value['checkEvery2Mins'] as bool
              : true,
      checkIntervalMinutes:
          value['checkIntervalMinutes'] is int
              ? value['checkIntervalMinutes'] as int
              : 10,
      allowNotifications:
          value['allowNotifications'] is bool
              ? value['allowNotifications'] as bool
              : true,
      deleteBehavior:
          value['deleteBehavior'] is String
              ? value['deleteBehavior'] as String
              : 'move',
      deleteMoveFolder:
          value['deleteMoveFolder'] is String
              ? value['deleteMoveFolder'] as String
              : 'Trash',
      autoDownload:
          value['autoDownload'] is bool
              ? value['autoDownload'] as bool
              : true,
      fetchHeadersOnly:
          value['fetchHeadersOnly'] is bool
              ? value['fetchHeadersOnly'] as bool
              : false,
      leaveOnServer:
          value['leaveOnServer'] is bool
              ? value['leaveOnServer'] as bool
              : true,
      leaveFor365Days:
          value['leaveFor365Days'] is bool
              ? value['leaveFor365Days'] as bool
              : true,
      leaveUntilDeleted:
          value['leaveUntilDeleted'] is bool
              ? value['leaveUntilDeleted'] as bool
              : true,
      expungeOnExit:
          value['expungeOnExit'] is bool
              ? value['expungeOnExit'] as bool
              : false,
      emptyTrashOnExit:
          value['emptyTrashOnExit'] is bool
              ? value['emptyTrashOnExit'] as bool
              : false,
      messageStoreType:
          value['messageStoreType'] is String
              ? value['messageStoreType'] as String
              : 'File per folder (mbox)',
      localDirectory:
          value['localDirectory'] is String
              ? value['localDirectory'] as String
              : '',
      oauthProvider:
          value['oauthProvider'] is String
              ? value['oauthProvider'] as String
              : null,
      serverSessionToken:
          value['serverSessionToken'] is String
              ? value['serverSessionToken'] as String
              : null,
    );
  }
}
