class EmailServerInfo {
  final String imapHost;
  final int imapPort;
  final bool imapSecure;
  final String smtpHost;
  final int smtpPort;
  final bool smtpSecure;

  const EmailServerInfo({
    required this.imapHost,
    required this.imapPort,
    required this.imapSecure,
    required this.smtpHost,
    required this.smtpPort,
    required this.smtpSecure,
  });
}

EmailServerInfo serverInfoFromEmail(String email) {
  final parts = email.split('@');
  final domain = parts.length > 1 ? parts.last.toLowerCase() : '';

  if (domain == 'gmail.com') {
    return const EmailServerInfo(
      imapHost: 'imap.gmail.com',
      imapPort: 993,
      imapSecure: true,
      smtpHost: 'smtp.gmail.com',
      smtpPort: 587,
      smtpSecure: true,
    );
  }

  if (domain == 'yahoo.com') {
    return const EmailServerInfo(
      imapHost: 'imap.mail.yahoo.com',
      imapPort: 993,
      imapSecure: true,
      smtpHost: 'smtp.mail.yahoo.com',
      smtpPort: 587,
      smtpSecure: true,
    );
  }

  if (domain == 'outlook.com' ||
      domain == 'hotmail.com' ||
      domain == 'live.com') {
    return const EmailServerInfo(
      imapHost: 'imap-mail.outlook.com',
      imapPort: 993,
      imapSecure: true,
      smtpHost: 'smtp-mail.outlook.com',
      smtpPort: 587,
      smtpSecure: true,
    );
  }

  if (domain == 'neosoftmail.com') {
    return const EmailServerInfo(
      imapHost: 'mail.neosoftmail.com',
      imapPort: 993,
      imapSecure: true,
      smtpHost: 'mail.neosoftmail.com',
      smtpPort: 465,
      smtpSecure: true,
    );
  }

  if (domain.isEmpty) {
    return const EmailServerInfo(
      imapHost: '',
      imapPort: 993,
      imapSecure: true,
      smtpHost: '',
      smtpPort: 587,
      smtpSecure: true,
    );
  }

  return EmailServerInfo(
    imapHost: 'imap.$domain',
    imapPort: 993,
    imapSecure: true,
    smtpHost: 'smtp.$domain',
    smtpPort: 587,
    smtpSecure: true,
  );
}
