import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'dart:ui' as ui;

import '../providers/theme_provider.dart';

/// Helper function to check if an image is dark.
/// Useful for determining if the text should be light or dark when overlaying on an image.
Future<bool> isImageDark(String imagePath) async {
  final image = await _loadImage(imagePath);
  final brightness = _calculateBrightness(image);
  return brightness <
      0.5; // If brightness is less than 0.5, the image is considered dark.
}

/// Loads an image from the assets.
Future<ui.Image> _loadImage(String imagePath) async {
  final image = AssetImage(imagePath);
  final dynamic imageProvider = image.resolve(ImageConfiguration.empty);
  final imageStream = imageProvider.load(image);
  final completer = Completer<ui.Image>();
  imageStream.addListener(
    ImageStreamListener((info, _) {
      completer.complete(info.image);
    }),
  );
  return completer.future;
}

/// Calculates the brightness of an image.
double _calculateBrightness(ui.Image image) {
  final dynamic byteData = image.toByteData();
  if (byteData == null) {
    return 0.5; // Default to medium brightness if unable to calculate.
  }

  final pixels = byteData.buffer.asUint8List();
  dynamic r = 0, g = 0, b = 0;
  final totalPixels = pixels.length ~/ 4;

  for (int i = 0; i < pixels.length; i += 4) {
    r += pixels[i];
    g += pixels[i + 1];
    b += pixels[i + 2];
  }

  final avgR = r / totalPixels;
  final avgG = g / totalPixels;
  final avgB = b / totalPixels;

  // Calculate brightness using the formula: (0.299 * R + 0.587 * G + 0.114 * B) / 255
  final brightness = (0.299 * avgR + 0.587 * avgG + 0.114 * avgB) / 255;
  return brightness;
}

/// Helper function to format a DateTime object into a readable string.
String formatDate(DateTime dateTime) {
  return "${dateTime.day}/${dateTime.month}/${dateTime.year}";
}

/// Helper function to capitalize the first letter of a string.
String capitalize(String text) {
  if (text.isEmpty) return text;
  return text[0].toUpperCase() + text.substring(1);
}

/// Helper function to check if the current theme is dark.
bool isDarkTheme(BuildContext context) {
  return Theme.of(context).brightness == Brightness.dark;
}

/// Helper function to get a contrasting color based on the background color.
Color getContrastingColor(Color backgroundColor) {
  final brightness = backgroundColor.computeLuminance();
  return brightness > 0.5 ? Colors.black : Colors.white;
}

/// Helper function to truncate a string if it exceeds a certain length.
String truncateText(String text, {int maxLength = 50}) {
  if (text.length <= maxLength) return text;
  return "${text.substring(0, maxLength)}...";
}

/// Helper function to parse a string into a DateTime object.
DateTime? parseDate(String dateString) {
  try {
    return DateTime.parse(dateString);
  } catch (e) {
    return null;
  }
}

/// Helper function to format a duration into a readable string.
String formatDuration(Duration duration) {
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60);
  final seconds = duration.inSeconds.remainder(60);

  return "$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";
}

DecorationImage? getBackgroundDecoration(
  BuildContext context,
  ThemeProvider themeProvider,
) {
  if (themeProvider.bgImg.isEmpty) return null;
  String cKey = 'custom::';
  bool isCustomBg = themeProvider.bgImg.startsWith(cKey);
  if (themeProvider.bgImg.contains("l-theme-light") ||
      themeProvider.bgImg.contains("l-theme-dark")) {
    return null;
  }
  return DecorationImage(
    image:
        isCustomBg
            ? FileImage(File(themeProvider.bgImg.replaceFirst(cKey, '')))
            : AssetImage(
              responsiveBackgroundAsset(context, themeProvider.bgImg),
            ),
    fit: BoxFit.cover,
  );
}

String responsiveBackgroundAsset(BuildContext context, String bgImg) {
  final fileName = bgImg.replaceAll('thumbnail-', '');
  final screenWidth = MediaQuery.sizeOf(context).width;
  final targetWidth = screenWidth * MediaQuery.devicePixelRatioOf(context);
  final bucket =
      targetWidth <= 480
          ? 480
          : targetWidth <= 960
          ? 960
          : targetWidth <= 1440
          ? 1440
          : 1920;

  return 'assets/images/bg/$bucket/$fileName';
}
