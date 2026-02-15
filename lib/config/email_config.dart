class EmailConfig {
  const EmailConfig();

  // IMAP
  static const String imapUser = String.fromEnvironment('IMAP_USER');
  static const String imapPassword = String.fromEnvironment('IMAP_PASSWORD');
  static const String imapDomain = String.fromEnvironment(
    'IMAP_DOMAIN',
    defaultValue: 'gmail.com',
  );
  static const int imapPort = int.fromEnvironment(
    'IMAP_PORT',
    defaultValue: 993,
  );
  static const bool imapSecure = bool.fromEnvironment(
    'IMAP_SECURE',
    defaultValue: true,
  );

  // SMTP
  static const String smtpPassword = String.fromEnvironment('SMTP_PASSWORD');
}
