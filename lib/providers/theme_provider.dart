import 'package:flutter/material.dart';
import '../services/hive_storage.dart';

class ThemeProvider with ChangeNotifier {
  String _theme = 'system';
  String _bgImg = "";
  bool _bgBlur = false;
  double _bgOpacity = 1.0;

  ThemeProvider() {
    _loadTheme();
  }

  String get theme => _theme;
  String get bgImg => _bgImg;
  bool get bgBlur => _bgBlur;
  double get bgOpacity => _bgOpacity;

  void setTheme({
    required String theme,
    String bgImg = "",
    bool bgBlur = false,
    double bgOpacity = 1.0,
  }) async {
    _theme = theme;
    _bgImg = bgImg;
    _bgBlur = bgBlur;
    _bgOpacity = bgOpacity;
    await HiveStorage.putValue(key: "theme", value: theme);
    await HiveStorage.putValue(key: "bgImg", value: bgImg);
    await HiveStorage.putValue(key: "bgBlur", value: bgBlur);
    await HiveStorage.putValue(key: "bgOpacity", value: bgOpacity);
    notifyListeners();
  }

  void _loadTheme() {
    final savedTheme = HiveStorage.getValue(key: "theme");
    if (savedTheme != null) {
      _theme = savedTheme;
    }

    final savedBg = HiveStorage.getValue(key: "bgImg");
    if (savedBg != null) {
      _bgImg = savedBg;
    }
    final savedBlur = HiveStorage.getValue(key: "bgBlur");
    if (savedBlur != null) {
      _bgBlur = savedBlur;
    }
    final savedOpacity = HiveStorage.getValue(key: "bgOpacity");
    if (savedOpacity != null) {
      _bgOpacity = savedOpacity;
    }
    notifyListeners();
  }
}
