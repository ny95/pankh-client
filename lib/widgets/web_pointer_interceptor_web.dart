import 'dart:ui_web' as ui_web;

import 'package:flutter/widgets.dart';
import 'package:web/web.dart' as web;

class WebPointerInterceptor extends StatefulWidget {
  final Widget child;

  const WebPointerInterceptor({super.key, required this.child});

  @override
  State<WebPointerInterceptor> createState() => _WebPointerInterceptorState();
}

class _WebPointerInterceptorState extends State<WebPointerInterceptor> {
  static int _nextId = 0;

  late final String _viewType;

  @override
  void initState() {
    super.initState();
    _viewType = 'pankh-pointer-interceptor-${_nextId++}';
    ui_web.platformViewRegistry.registerViewFactory(_viewType, (int viewId) {
      return web.HTMLDivElement()
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.backgroundColor = 'transparent'
        ..style.pointerEvents = 'auto';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(child: HtmlElementView(viewType: _viewType)),
        widget.child,
      ],
    );
  }
}
