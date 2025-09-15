import 'dart:ui';

import 'package:flutter/material.dart';

class Blur extends StatelessWidget {
  final bool blur;
  final Widget child;
  final double sigmaX;
  final double sigmaY;
  const Blur({
    super.key,
    required this.blur,
    required this.child,
    this.sigmaX = 50.0,
    this.sigmaY = 50.0,
  });

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
