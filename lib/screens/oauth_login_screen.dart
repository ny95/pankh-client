import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class OAuthLoginScreen extends StatefulWidget {
  const OAuthLoginScreen({
    super.key,
    required this.authUrl,
    required this.redirectUri,
    required this.title,
  });

  final String authUrl;
  final String redirectUri;
  final String title;

  @override
  State<OAuthLoginScreen> createState() => _OAuthLoginScreenState();
}

class _OAuthLoginScreenState extends State<OAuthLoginScreen> {
  bool _isLoading = true;
  bool _completed = false;

  bool _maybeComplete(Uri? uri) {
    if (_completed || uri == null) {
      return false;
    }
    final value = uri.toString();
    if (!value.startsWith(widget.redirectUri)) {
      return false;
    }
    _completed = true;
    if (mounted) {
      Navigator.of(context).pop(uri);
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Stack(
        children: [
          InAppWebView(
            initialUrlRequest: URLRequest(url: WebUri(widget.authUrl)),
            shouldOverrideUrlLoading: (controller, navigationAction) async {
              if (_maybeComplete(navigationAction.request.url)) {
                return NavigationActionPolicy.CANCEL;
              }
              return NavigationActionPolicy.ALLOW;
            },
            onLoadStart: (controller, url) {
              if (_maybeComplete(url)) {
                return;
              }
              if (mounted) {
                setState(() => _isLoading = true);
              }
            },
            onLoadStop: (controller, url) {
              if (_maybeComplete(url)) {
                return;
              }
              if (mounted) {
                setState(() => _isLoading = false);
              }
            },
            onUpdateVisitedHistory: (controller, url, isReload) {
              _maybeComplete(url);
            },
            onReceivedError: (controller, request, error) async {
              if (_maybeComplete(request.url)) {
                return;
              }
            },
          ),
          if (_isLoading)
            const Center(
              child: SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        ],
      ),
    );
  }
}
