import 'package:flutter/material.dart';
import '../services/hive_storage.dart';

class InboxTypeProvider with ChangeNotifier {
  String _inboxType = 'default';

  InboxTypeProvider() {
    _loadInboxType();
  }

  String get inboxType => _inboxType;

  void setInboxType(String inboxType) async {
    _inboxType = inboxType;
    await HiveStorage.putValue(key: "inboxType", value: inboxType);
    notifyListeners();
  }

  void _loadInboxType() {
    final savedInboxType = HiveStorage.getValue(key: "inboxType");
    if (savedInboxType != null) {
      _inboxType = savedInboxType;
    }
    notifyListeners();
  }
}
