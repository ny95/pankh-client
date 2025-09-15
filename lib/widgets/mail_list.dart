import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/common_provider.dart';
import '../providers/layout_provider.dart';
import '../providers/mail_provider.dart';
import 'email_list_item.dart';

class EmailListView extends StatelessWidget {
  final double parentWidth;
  final double parentHeight;

  const EmailListView({
    super.key,
    required this.parentWidth,
    required this.parentHeight,
  });
  // EmailListView.dart
  @override
  Widget build(BuildContext context) {
    final commonProvider = Provider.of<CommonProvider>(context);
    final layoutProvider = Provider.of<LayoutProvider>(context);
    bool panePreviewOff = layoutProvider.layout == "pane_preview_off";
    bool panePreviewRight = layoutProvider.layout == "pane_preview_right";
    bool panePreviewBottom = layoutProvider.layout == "pane_preview_bottom";
    const double splitListWidth = 350;
    const double splitListHeight = 300;

    return Consumer<MailProvider>(
      builder: (context, mailProvider, _) {
        final mails = mailProvider.mails;

        if (mailProvider.isLoading) {
          return const Center(child: Text('Loading emails...'));
        }

        if (mails.isEmpty) {
          return const Center(child: Text('No emails found'));
        }

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height:
              !commonProvider.isMailView
                  ? (panePreviewBottom && !commonProvider.isSmallScreen
                      ? splitListHeight
                      : parentHeight)
                  : (panePreviewBottom && !commonProvider.isSmallScreen
                      ? splitListHeight
                      : (panePreviewRight ? parentHeight : 0)),
          width:
              !commonProvider.isMailView
                  ? (panePreviewRight && !commonProvider.isSmallScreen
                      ? splitListWidth
                      : parentWidth)
                  : (panePreviewRight && !commonProvider.isSmallScreen
                      ? splitListWidth
                      : (panePreviewBottom ? parentWidth : 0)),
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
          child: ListView(
            children:
                mails.map((email) => EmailListItem(message: email)).toList(),
          ),
        );
      },
    );
  }
}
