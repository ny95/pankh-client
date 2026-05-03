import 'package:flutter/material.dart';
import '../services/hive_storage.dart';

class LayoutProvider with ChangeNotifier {
  String _layout = 'pane_preview_off';

  LayoutProvider() {
    _loadLayout();
  }

  String get layout => _layout;

  Future<void> setLayout(String layout) async {
    _layout = layout;
    notifyListeners();
    await HiveStorage.putValue(key: "layout", value: layout);
  }

  void _loadLayout() {
    final savedLayout = HiveStorage.getValue(key: "layout");
    if (savedLayout != null) {
      _layout = savedLayout;
    }
    notifyListeners();
  }
}
