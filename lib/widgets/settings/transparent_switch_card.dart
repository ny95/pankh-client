import 'package:flutter/material.dart';

class TransparentCard extends StatelessWidget {
  final Widget child;
  
  final bool isEnabled;

  const TransparentCard({super.key, required this.child, this.isEnabled = true});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: isEnabled ? 1.0 : 0.5,
      child: Card(
        color: Colors.transparent,
        shadowColor: Colors.transparent,
        child: child,
      )
    );
  }
}

class TransparentSwitchCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final bool isEnabled;
  final ValueChanged<bool>? onChanged;

  const TransparentSwitchCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.value,
    this.isEnabled = true,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: isEnabled ? 1.0 : 0.5,
      child: Card(
        color: Colors.transparent,
        shadowColor: Colors.transparent,
        child: SwitchListTile(
          title: Text(title),
          subtitle: Text(subtitle),
          value: value,
          onChanged: isEnabled ? onChanged : null,
        ),
      ),
    );
  }
}
