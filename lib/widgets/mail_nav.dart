import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/layout_provider.dart';

class MailNav extends StatefulWidget {
  const MailNav({super.key});

  @override
  _MailNavState createState() => _MailNavState();
}

class _MailNavState extends State<MailNav> {
  Widget toggleIcon({required String layout}) {
    late Widget icon;
    switch (layout) {
      case "pane_preview_off":
        icon = Icon(Icons.reorder_rounded);
        break;

      case "pane_preview_right":
        icon = Icon(Icons.vertical_split_rounded);
        break;

      case "pane_preview_bottom":
        icon = Icon(Icons.horizontal_split_rounded);
        break;

      default:
        icon = Icon(Icons.reorder_rounded); // fallback icon
    }
    return icon;
  }

  @override
  Widget build(BuildContext context) {
    final layoutProvider = Provider.of<LayoutProvider>(context);
    bool panePreviewOff = layoutProvider.layout == "pane_preview_off";
    bool panePreviewRight = layoutProvider.layout == "pane_preview_right";
    bool panePreviewBottom = layoutProvider.layout == "pane_preview_bottom";
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor, width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                margin: EdgeInsets.only(left: 8),
                height: 40,
                width: 30,
                child: Checkbox(value: false, onChanged: (val) {}),
              ),
              IconButton(
                iconSize: 20,
                style: ButtonStyle(
                  padding: WidgetStateProperty.all(
                    EdgeInsets.all(0),
                  ), // Set padding
                  minimumSize: WidgetStateProperty.all(
                    Size(10, 10),
                  ), // Override default constraints
                  tapTargetSize:
                      MaterialTapTargetSize
                          .shrinkWrap, // Remove extra padding around icon
                ),
                onPressed: () {},
                icon: const Icon(Icons.arrow_drop_down_sharp),
              ),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.refresh_sharp),
              ),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.more_vert_rounded),
              ),
            ],
          ),
          Row(
            children: [
              const Text('1-50 of 12033'),
              IconButton(
                iconSize: 20,
                onPressed: () {},
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
              ),
              IconButton(
                iconSize: 20,
                onPressed: () {},
                icon: const Icon(Icons.arrow_forward_ios_rounded),
              ),
              Container(
                margin: EdgeInsets.only(right: 8),
                child: IconButton(
                  onPressed: () {
                    layoutProvider.setLayout(
                      panePreviewOff
                          ? "pane_preview_right"
                          : (panePreviewRight
                              ? "pane_preview_bottom"
                              : "pane_preview_off"),
                    );
                  },
                  icon: toggleIcon(layout: layoutProvider.layout),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
