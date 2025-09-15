import 'package:flutter/material.dart';

class ChildWithDelay extends StatelessWidget {
  final bool controller;
  final Duration delay;
  final Widget child;

  const ChildWithDelay({
    super.key,
    required this.controller,
    required this.delay,
    required this.child,
  });

  Future<bool> getMenuStatus({
    required bool controller,
    required Duration delay,
  }) async {
    if (controller) {
      await Future.delayed(delay);
      return true;
    } else {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: getMenuStatus(controller: controller, delay: delay),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox();
        } else if (snapshot.hasData && !snapshot.data!) {
          return child;
        } else {
          return const SizedBox();
        }
      },
    );
  }
}
