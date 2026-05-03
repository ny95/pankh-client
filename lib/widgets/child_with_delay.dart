import 'package:flutter/material.dart';

class ChildWithDelay extends StatefulWidget {
  final bool controller;
  final Duration delay;
  final Widget child;

  const ChildWithDelay({
    super.key,
    required this.controller,
    required this.delay,
    required this.child,
  });

  @override
  State<ChildWithDelay> createState() => _ChildWithDelayState();
}

class _ChildWithDelayState extends State<ChildWithDelay> {
  late Future<bool> _future;

  @override
  void initState() {
    super.initState();
    _future = _resolve();
  }

  @override
  void didUpdateWidget(ChildWithDelay old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller || old.delay != widget.delay) {
      _future = _resolve();
    }
  }

  Future<bool> _resolve() async {
    if (widget.controller) {
      await Future.delayed(widget.delay);
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox();
        }
        return (snapshot.hasData && !snapshot.data!) ? widget.child : const SizedBox();
      },
    );
  }
}
