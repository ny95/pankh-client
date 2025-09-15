import 'package:flutter/material.dart';

class CommonProvider with ChangeNotifier {
  bool _isSmallScreen = false;
  bool _isMailView = false;

  bool get isSmallScreen => _isSmallScreen;
  bool get isMailView => _isMailView;

  void setIsSmallScreen({required bool isSmallScreen}) {
    _isSmallScreen = isSmallScreen;
    notifyListeners();
  }

  void setIsMailView({required bool isMailView}) {
    _isMailView = isMailView;
    notifyListeners();
  }
}
