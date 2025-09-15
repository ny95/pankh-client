import 'dart:ui';
import 'package:flutter/material.dart';

class BackgroundBlur extends StatelessWidget {
  const BackgroundBlur({
    super.key,
    required this.blur,
    this.sigmaX = 50.0,
    this.sigmaY = 50.0,
    required this.child,
  });

  final bool blur;
  final double sigmaX;
  final double sigmaY;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return blur
        ? BackdropFilter(
          filter: ImageFilter.blur(sigmaX: sigmaX, sigmaY: sigmaY),
          child: child,
        )
        : child;
  }
}
