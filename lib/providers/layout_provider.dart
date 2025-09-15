import 'package:flutter/material.dart';
import '../services/hive_storage.dart';

class LayoutProvider with ChangeNotifier {
  String _layout = 'pane_preview_off';

  LayoutProvider() {
    _loadLayout();
  }

  String get layout => _layout;

  void setLayout(String layout) async {
    _layout = layout;
    await HiveStorage.putValue(key: "layout", value: layout);
    notifyListeners();
  }

  void _loadLayout() {
    final savedLayout = HiveStorage.getValue(key: "layout");
    if (savedLayout != null) {
      _layout = savedLayout;
    }
    notifyListeners();
  }
}
