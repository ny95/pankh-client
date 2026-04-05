import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

import '../config/email_config.dart';

class SmtpService {
  SmtpService({
    required this.username,
    required this.to,
    required this.option,
    this.password,
    this.smtpHost,
    this.smtpPort,
    this.smtpSecure,
    this.smtpUserName,
  });

  final String username;
  final String to;
  final Map<String, dynamic> option;
  final String? password;
  final String? smtpHost;
  final int? smtpPort;
  final bool? smtpSecure;
  final String? smtpUserName;

  Future<String> sendMail() async {
    final resolvedPassword = password ?? EmailConfig.smtpPassword;
    if (resolvedPassword.isEmpty) {
      debugPrint('SMTP password missing. Set SMTP_PASSWORD.');
      return 'SMTP credentials missing.';
    }
    final smtpServer = getSmtpServer(username, resolvedPassword);
    final List<String> toList = to.isEmpty ? [] : to.split(',');
    final List<String> ccList =
        option['cc'] == '' ? [] : option['cc']?.split(',') ?? [];
    final List<String> bccList =
        option['bcc'] == '' ? [] : option['bcc']?.split(',') ?? [];

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
    final body = option['body'] ?? '';
    final isHtml = option['isHtml'] == true;
    if (isHtml) {
      message.html = body.toString();
    } else {
      message.text = body.toString();
    }
    final attachments =
        (option['attachments'] as List?)?.cast<String>() ?? const [];
    for (final path in attachments) {
      final file = File(path);
      if (await file.exists()) {
        message.attachments.add(FileAttachment(file));
      }
    }

    try {
      final sendReport = await send(message, smtpServer);
      debugPrint('Message sent: $sendReport');
      return 'Message sent successfully!';
    } on MailerException catch (e) {
      debugPrint('Message not sent.');
      for (final p in e.problems) {
        debugPrint('Problem: ${p.code}: ${p.msg}');
      }
      return 'Failed to send the message!';
    } catch (e) {
      debugPrint('An error occurred: $e');
      return 'Error while sending the message!';
    }
  }

  SmtpServer getSmtpServer(String email, String password) {
    if (smtpHost != null && smtpHost!.isNotEmpty) {
      final port = smtpPort ?? 587;
      final secure = smtpSecure ?? false;
      final authUser = (smtpUserName == null || smtpUserName!.isEmpty)
          ? email
          : smtpUserName!;
      return SmtpServer(
        smtpHost!,
        username: authUser,
        password: password,
        port: port,
        ssl: secure && port == 465,
        ignoreBadCertificate: !secure,
      );
    }
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

  Future<bool> testConnection() async {
    if (smtpHost == null || smtpHost!.isEmpty) return false;
    final port = smtpPort ?? 587;
    try {
      final socket = await Socket.connect(
        smtpHost!,
        port,
        timeout: const Duration(seconds: 5),
      );
      socket.destroy();
      return true;
    } catch (_) {
      return false;
    }
  }
}
