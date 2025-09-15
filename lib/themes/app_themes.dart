import 'package:flutter/material.dart';

class AppThemes {
  static final ThemeData lightTheme = ThemeData(
    canvasColor: const Color(0xffeef1f6),
    primaryColor: Colors.blue,
    cardColor: Colors.white,
    dividerColor: const Color(0xffefefef),
    colorScheme: const ColorScheme.light(primary: Colors.blue),
  );

  static final ThemeData darkTheme = ThemeData(
    canvasColor: const Color(0xFF000000),
    cardColor: const Color(0xFF191c24),
    primaryColor: Colors.deepPurple,
    dividerColor: const Color(0xFF2B2C2F),
    colorScheme: const ColorScheme.dark(primary: Colors.deepPurple),
  );
}
