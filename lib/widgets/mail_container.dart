import 'package:flutter/material.dart';
import 'package:pankh/providers/common_provider.dart';
import 'package:pankh/providers/layout_provider.dart';
import 'package:pankh/providers/mail_provider.dart';
import 'package:provider/provider.dart';

import 'mail_view.dart';
import 'mail_list.dart';

class MailListContainer extends StatefulWidget {
  const MailListContainer({super.key});

  @override
  State<MailListContainer> createState() => _MailListContainerState();
}

class _MailListContainerState extends State<MailListContainer> {
  double _splitRatio = 0.3;
  bool _autoSelectScheduled = false;

  void _updateRatio(double delta, double total) {
    if (total <= 0) return;
    setState(() {
      _splitRatio = (_splitRatio + (delta / total)).clamp(0.2, 0.8);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = context.select<CommonProvider, bool>((p) => p.isSmallScreen);
    final isMailView = context.select<CommonProvider, bool>((p) => p.isMailView);
    final layout = context.select<LayoutProvider, String?>((p) => p.layout);
    final (mailSelected, mailsEmpty) = context.select<MailProvider, (bool, bool)>(
      (p) => (p.selectedMail != null, p.mails.isEmpty),
    );
    final bool panePreviewBottom = layout == "pane_preview_bottom";
    final bool panePreviewRight = layout == "pane_preview_right";
    return Container(
      padding: EdgeInsets.symmetric(
        vertical: isSmallScreen ? 8 : 0,
      ),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double parentWidth = constraints.maxWidth;
          final double parentHeight = constraints.maxHeight;
          final bool showPreview =
              !isSmallScreen && (isMailView || panePreviewRight || panePreviewBottom);
          if ((panePreviewRight || panePreviewBottom) &&
              showPreview &&
              !mailSelected &&
              !mailsEmpty &&
              !_autoSelectScheduled) {
            _autoSelectScheduled = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _autoSelectScheduled = false;
              final mp = context.read<MailProvider>();
              if (mp.selectedMail == null && mp.mails.isNotEmpty) {
                mp.selectMail(mp.mails.first);
              }
            });
          }

          if (!showPreview) {
            return EmailListView(
              parentWidth: parentWidth,
              parentHeight: parentHeight,
            );
          }

          if (panePreviewRight) {
            const minViewWidth = 200.0;
            final available = parentWidth - 8;
            final desiredListWidth = available * _splitRatio;
            final maxListWidth = (available - minViewWidth).clamp(0.0, available);
            final listWidth = desiredListWidth.clamp(0.0, maxListWidth);
            return Row(
              children: [
                SizedBox(
                  width: listWidth,
                  height: parentHeight,
                  child: EmailListView(
                    parentWidth: listWidth,
                    parentHeight: parentHeight,
                  ),
                ),
                GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onHorizontalDragUpdate: (details) {
                    _updateRatio(details.delta.dx, parentWidth);
                  },
                  child: MouseRegion(
                    cursor: SystemMouseCursors.resizeColumn,
                    child: Container(
                      width: 8,
                      height: parentHeight,
                      color: Theme.of(context).dividerColor.withValues(
                        alpha: 0.3,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: SizedBox(
                    height: parentHeight,
                    child: const ViewMail(),
                  ),
                ),
              ],
            );
          }

          if (panePreviewBottom) {
            const minViewHeight = 200.0;
            final available = parentHeight - 8;
            final desiredListHeight = available * _splitRatio;
            final maxListHeight =
                (available - minViewHeight).clamp(0.0, available);
            final listHeight = desiredListHeight.clamp(0.0, maxListHeight);
            return Column(
              children: [
                SizedBox(
                  width: parentWidth,
                  height: listHeight,
                  child: EmailListView(
                    parentWidth: parentWidth,
                    parentHeight: listHeight,
                  ),
                ),
                GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onVerticalDragUpdate: (details) {
                    _updateRatio(details.delta.dy, parentHeight);
                  },
                  child: MouseRegion(
                    cursor: SystemMouseCursors.resizeRow,
                    child: Container(
                      width: parentWidth,
                      height: 8,
                      color: Theme.of(context).dividerColor.withValues(
                        alpha: 0.3,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: SizedBox(
                    width: parentWidth,
                    child: const ViewMail(),
                  ),
                ),
              ],
            );
          }

          if (showPreview && isMailView) {
            return const ViewMail();
          }

          return EmailListView(
            parentWidth: parentWidth,
            parentHeight: parentHeight,
          );
        },
      ),
    );
  }
}
