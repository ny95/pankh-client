import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

class Smtp {
  Smtp({required this.username, required this.to, required this.option});

  final String username; // Make username final
  late dynamic to; // Make to final
  final Map<String, dynamic> option; // Use a map for options
  List<String> toList = [];
  List<String> ccList = [];
  List<String> bccList = [];

  Future<String> sendMail() async {
    String password =
        username == 'naveen.y@neosoftmail.com'
            ? 'gMMnqy.J![y2'
            : 'snyklakeunwijhyu';
    final smtpServer = getSmtpServer(username, password);
    List<String> toList = to == '' ? [] : to.split(',');
    List<String> ccList = option['cc'] == '' ? [] : option['cc']?.split(',');
    List<String> bccList = option['bcc'] == '' ? [] : option['bcc']?.split(',');

    final message =
        Message()
          ..from = Address(username, username.split('@')[0])
          ..recipients.addAll(toList);

    if (ccList.isNotEmpty) {
      message.ccRecipients.addAll(ccList);
    }

    if (bccList.isNotEmpty) {
      message.bccRecipients.addAll(bccList);
    }

    message.subject = option['subject'] ?? '';
    message.html = option['body'] ?? '';

    try {
      final sendReport = await send(message, smtpServer);
      print('Message sent: $sendReport');
      return ("Message sent successfully!");
    } on MailerException catch (e) {
      print('Message not sent.');
      for (var p in e.problems) {
        print('Problem: ${p.code}: ${p.msg}');
      }
      return ("Failed to send the message!");
    } catch (e) {
      print('An error occurred: $e');
      return ("Error while sending the message!");
    }
  }

  SmtpServer getSmtpServer(String email, String password) {
    if (email.endsWith('@gmail.com')) {
      return gmail(email, password);
    } else if (email.endsWith('@yahoo.com')) {
      return yahoo(email, password);
    } else if (email.endsWith('@neosoftmail.com')) {
      return SmtpServer(
        'mail.neosoftmail.com',
        username: 'naveen.y@neosoftmail.com',
        password: password,
        port: 587,
        ignoreBadCertificate: true, // or 465 for SSL
      );
    } else if (email.endsWith('@outlook.com') ||
        email.endsWith('@hotmail.com')) {
      return SmtpServer(
        'smtp-mail.outlook.com',
        username: email,
        password: password,
        port: 587,
        ssl: false, // Set to true if using SSL
      );
    } else {
      throw Exception('Unsupported email provider');
    }
  }
}
