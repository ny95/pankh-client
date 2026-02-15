import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:flutter/services.dart' show rootBundle;

Future<bool> isImageDark(String imagePath, fileBytes) async {
  // Load image as byte data
  ByteData data;
  Uint8List bytes;
  if (fileBytes != null) {
    bytes = await fileBytes;
  } else {
    data = await rootBundle.load(imagePath);
    bytes = data.buffer.asUint8List();
  }

  // Decode image using the image package
  img.Image? image = img.decodeImage(bytes);
  if (image == null) return false;

  int totalBrightness = 0;
  int pixelCount = image.width * image.height;

  for (int y = 0; y < image.height; y++) {
    for (int x = 0; x < image.width; x++) {
      // Get pixel color safely
      img.Pixel pixel = image.getPixelSafe(x, y);

      // Extract RGB values properly
      int r = pixel.r.toInt();
      int g = pixel.g.toInt();
      int b = pixel.b.toInt();

      // Calculate brightness using the luminance formula
      int brightness = ((r * 0.299) + (g * 0.587) + (b * 0.114)).round();
      totalBrightness += brightness;
    }
  }

  double avgBrightness = totalBrightness / pixelCount;

  return avgBrightness < 128; // Dark if brightness is below 128
}
