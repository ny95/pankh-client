import 'package:flutter/material.dart';
import 'package:projectwebview/providers/common_provider.dart';
import 'package:projectwebview/providers/layout_provider.dart';
import 'package:provider/provider.dart';

import '../mailView.dart';
import 'mail_list.dart';

class MailListContainer extends StatelessWidget {
  const MailListContainer({super.key});

  @override
  Widget build(BuildContext context) {
    final commonProvider = Provider.of<CommonProvider>(context);
    final layoutProvider = Provider.of<LayoutProvider>(context);
    bool panePreviewBottom = layoutProvider.layout == "pane_preview_bottom";
    return Container(
      padding: EdgeInsets.symmetric(
        vertical: commonProvider.isSmallScreen ? 8 : 0,
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

          return Flex(
            direction: panePreviewBottom ? Axis.vertical : Axis.horizontal,
            children: [
              EmailListView(
                parentWidth: parentWidth,
                parentHeight: parentHeight,
              ),
              if (!commonProvider.isSmallScreen && commonProvider.isMailView)
                Expanded(child: ViewMail()),
            ],
          );
        },
      ),
    );
  }
}
