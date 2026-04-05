import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/common_provider.dart';
import '../providers/layout_provider.dart';
import '../providers/mail_provider.dart';
import 'email_list_item.dart';

class EmailListView extends StatefulWidget {
  final double parentWidth;
  final double parentHeight;

  const EmailListView({
    super.key,
    required this.parentWidth,
    required this.parentHeight,
  });

  @override
  State<EmailListView> createState() => EmailListViewState();
}

class EmailListViewState extends State<EmailListView> {
  final ScrollController _scrollController = ScrollController();
  bool _topTriggered = false;
  bool _bottomTriggered = false;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final commonProvider = Provider.of<CommonProvider>(context);
    final layoutProvider = Provider.of<LayoutProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final panePreviewRight = layoutProvider.layout == 'pane_preview_right';
    final panePreviewBottom = layoutProvider.layout == 'pane_preview_bottom';

    return Consumer<MailProvider>(
      builder: (context, mailProvider, _) {
        final mails = mailProvider.mails;

        if (mailProvider.needsOAuthRelogin) {
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Icon(Icons.lock_clock_outlined, size: 36),
                        const SizedBox(height: 12),
                        const Text(
                          'Session expired',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          mailProvider.authError ??
                              'Sign in again to continue loading mail.',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: () async {
                            await authProvider.logout();
                          },
                          child: const Text('Sign in again'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        }

        if ((mailProvider.isLoading ||
                mailProvider.isRefreshing ||
                mailProvider.isLoadingMore) &&
            mails.isEmpty) {
          return const Center(
            child: SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }

        if (mails.isEmpty) {
          return const Center(child: Text('No emails found'));
        }

        final listHeight = widget.parentHeight;
        final listWidth = widget.parentWidth;

        return SizedBox(
          height: listHeight,
          width: listWidth,
          child: Stack(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: listHeight,
                width: listWidth,
                decoration:
                    !commonProvider.isSmallScreen && panePreviewRight
                        ? BoxDecoration(
                            border: Border(
                              right: BorderSide(
                                color:
                                    panePreviewRight
                                        ? Theme.of(context).dividerColor
                                        : Colors.transparent,
                              ),
                              bottom: BorderSide(
                                color:
                                    panePreviewBottom
                                        ? Theme.of(context).dividerColor
                                        : Colors.transparent,
                              ),
                            ),
                          )
                        : null,
                child: NotificationListener<ScrollNotification>(
                  onNotification: (notification) {
                    if (!commonProvider.isSmallScreen) return false;
                    if (notification is OverscrollNotification) {
                      final metrics = notification.metrics;
                      final atTop = metrics.extentBefore == 0;
                      final atBottom = metrics.extentAfter == 0;
                      if (notification.overscroll < 0 &&
                          atTop &&
                          !_topTriggered &&
                          !mailProvider.isRefreshing) {
                        _topTriggered = true;
                        mailProvider.loadNewer();
                      }
                      if (notification.overscroll > 0 &&
                          atBottom &&
                          !_bottomTriggered &&
                          !mailProvider.isLoadingMore) {
                        _bottomTriggered = true;
                        mailProvider.loadOlder();
                      }
                    }
                    if (notification is ScrollUpdateNotification) {
                      final metrics = notification.metrics;
                      if (metrics.pixels <= 0 &&
                          !_topTriggered &&
                          !mailProvider.isRefreshing) {
                        _topTriggered = true;
                        mailProvider.loadNewer();
                      }
                    }
                    if (notification is UserScrollNotification) {
                      final metrics = notification.metrics;
                      final atBottom = metrics.extentAfter == 0;
                      final direction = notification.direction;
                      if (direction == ScrollDirection.forward &&
                          metrics.extentBefore == 0 &&
                          !_topTriggered &&
                          !mailProvider.isRefreshing) {
                        _topTriggered = true;
                        mailProvider.loadNewer();
                      }
                      if (direction == ScrollDirection.reverse &&
                          atBottom &&
                          !_bottomTriggered &&
                          !mailProvider.isLoadingMore) {
                        _bottomTriggered = true;
                        mailProvider.loadOlder();
                      }
                      if (direction == ScrollDirection.idle) {
                        _bottomTriggered = false;
                        _topTriggered = false;
                      }
                    }
                    if (notification is ScrollEndNotification) {
                      final metrics = notification.metrics;
                      final atBottom = metrics.extentAfter == 0;
                      if (atBottom &&
                          !_bottomTriggered &&
                          !mailProvider.isLoadingMore) {
                        _bottomTriggered = true;
                        mailProvider.loadOlder();
                      }
                    }
                    if (notification is ScrollEndNotification ||
                        notification is ScrollUpdateNotification) {
                      if (notification.metrics.extentBefore > 0) {
                        _topTriggered = false;
                      }
                      if (notification.metrics.extentAfter > 0) {
                        _bottomTriggered = false;
                      }
                    }
                    return false;
                  },
                  child: ScrollConfiguration(
                    behavior: const _StretchScrollBehavior(),
                    child: ListView.builder(
                      controller: _scrollController,
                      physics: const BouncingScrollPhysics(
                        parent: AlwaysScrollableScrollPhysics(),
                      ),
                      itemCount: mails.length,
                      itemBuilder: (context, index) {
                        return EmailListItem(message: mails[index]);
                      },
                    ),
                  ),
                ),
              ),
              if (mailProvider.isRefreshing || mailProvider.isLoading)
                const Positioned.fill(
                  child: Center(
                    child: SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ),
              if (mailProvider.isLoadingMore &&
                  !mailProvider.isRefreshing &&
                  !mailProvider.isLoading)
                const Positioned(
                  left: 0,
                  right: 0,
                  bottom: 12,
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _StretchScrollBehavior extends MaterialScrollBehavior {
  const _StretchScrollBehavior();

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return StretchingOverscrollIndicator(
      axisDirection: details.direction,
      child: child,
    );
  }
}
