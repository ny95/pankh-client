import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
  // EmailListView.dart
  @override
  State<EmailListView> createState() => EmailListViewState();
}

class EmailListViewState extends State<EmailListView> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final commonProvider = Provider.of<CommonProvider>(context);
    final layoutProvider = Provider.of<LayoutProvider>(context);
    bool panePreviewRight = layoutProvider.layout == "pane_preview_right";
    bool panePreviewBottom = layoutProvider.layout == "pane_preview_bottom";

    return Consumer<MailProvider>(
      builder: (context, mailProvider, _) {
        final mails = mailProvider.mails;

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

        final double listHeight = widget.parentHeight;
        final double listWidth = widget.parentWidth;

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
                    final metrics = notification.metrics;
                    const threshold = 120.0;
                    if (metrics.extentAfter < threshold) {
                      mailProvider.loadOlder();
                    }
                    if (metrics.extentBefore < threshold) {
                      mailProvider.loadNewer();
                    }
                    return false;
                  },
                  child: ListView.builder(
                    controller: _scrollController,
                    itemCount: mails.length + (mailProvider.isLoadingMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index >= mails.length) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Align(
                            alignment: Alignment.center,
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        );
                      }
                      return EmailListItem(message: mails[index]);
                    },
                  ),
                ),
              ),
              if (mailProvider.isRefreshing ||
                  mailProvider.isLoadingMore ||
                  mailProvider.isLoading)
                const Positioned.fill(
                  child: Center(
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
