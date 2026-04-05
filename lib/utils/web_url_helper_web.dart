// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter
import 'dart:html' as html;

void clearOAuthCallbackQuery() {
  final cleaned = Uri.base.replace(queryParameters: const {}, fragment: '');
  html.window.history.replaceState(null, html.document.title, cleaned.toString());
}
