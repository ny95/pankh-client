import 'package:enough_mail/enough_mail.dart';
import 'package:flutter/material.dart';

import '../fetchMail.dart';
import '../models/email_model.dart';

class MailProvider with ChangeNotifier {
  dynamic _selectedMail;
  List<MimeMessage> _mails = [];
  bool _isLoading = true;

  dynamic get selectedMail => _selectedMail;
  List get mails => _mails;
  bool get isLoading => _isLoading;

  void selectMail(dynamic mail) {
    _selectedMail = mail;
    notifyListeners();
  }

  MailProvider() {
    fetchMails(); // automatically fetch on creation
  }

  Future<void> fetchMails() async {
    _isLoading = true;
    notifyListeners();
    _mails = await Imap().fetchMails();
    _isLoading = false;
    notifyListeners();
  }
}
