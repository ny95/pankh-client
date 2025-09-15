import 'package:enough_mail/enough_mail.dart';

class Imap {
  Imap();

  static const String userName = 'mash.leven@gmail.com';
  static const String password = "laxcemyngqcypgvj ";
  String domain = 'gmail.com';
  int imapServerPort = 993;
  bool isImapServerSecure = true;

  Future<List> fetchMails() async {
    String imapServerHost = 'imap.$domain';
    late dynamic messages;
    final client = ImapClient(
      isLogEnabled: false,
      onBadCertificate: (certificate) {
        // print('Bad certificate detected: ${certificate.subject}');
        return true; // Accept the certificate
      },
    );
    try {
      await client.connectToServer(
        imapServerHost,
        imapServerPort,
        isSecure: true,
      );
      await client.login(userName, password);
      final mailboxes = await client.listMailboxes();
      // print(mailboxes);
      await client.selectInbox();
      // fetch 10 most recent messages:
      final fetchResult = await client.fetchRecentMessages(messageCount: 15);
      // print(fetchResult.messages.length);
      messages = fetchResult.messages;
      messages.forEach(printMessage);
      await client.logout();
      return messages;
    } on ImapException catch (e) {
      return [];
      print('IMAP failed with $e');
    }
  }
}

void printMessage(MimeMessage message) {
  // print('from: ${message.from} -: ${message.mediaType}');
  if (!message.isTextPlainMessage()) {
    // print(' content-type: ${message.mediaType}');
  }
  // else {
  //   final plainText = message.decodeTextPlainPart();
  //   if (plainText != null) {
  //     final lines = plainText.split('\r\n');
  //     for (final line in lines) {
  //       // if (line.startsWith('>')) {
  //       //   // break when quoted text starts
  //       //   break;
  //       // }
  //       print(line);
  //     }
  //   }
  // }
}
