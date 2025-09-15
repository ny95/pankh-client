import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/theme_provider.dart';
import 'blur.dart';

class SideMenu extends StatelessWidget {
  final double width;
  final double height;
  final bool controller;
  final Widget child;
  final double minWidth;
  final bool animated;
  final Duration duration;
  final bool mouseRegion;
  final EdgeInsets padding;
  final onEnter;
  final onExit;
  const SideMenu({
    super.key,
    required this.width,
    required this.height,
    required this.controller,
    required this.child,
    this.minWidth = 0,
    this.animated = true,
    this.duration = const Duration(milliseconds: 300),
    this.mouseRegion = false,
    this.padding = const EdgeInsets.all(0),
    this.onEnter,
    this.onExit,
  });
  childWithMouseAction() {
    return mouseRegion
        ? MouseRegion(onEnter: onEnter, onExit: onExit, child: child)
        : child;
  }

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
    return animated
        ? AnimatedContainer(
          padding: padding,
          width: controller ? width : minWidth,
          duration: duration,
          height: height,
          child: childWithMouseAction(),
        )
        : Container(
          padding: padding,
          width: controller ? width : minWidth,
          child: childWithMouseAction(),
        );
  }
}

class SideMenuList extends StatelessWidget {
  SideMenuList({
    super.key,
    required this.width,
    required this.height,
    this.hidden = false,
  });

  final dynamic width;

  final dynamic height;
  late bool isSmallScreen;
  late BuildContext _context;

  bool hidden;
  Widget getSideMenuList({
    required width,
    dynamic icon,
    dynamic label,
    dynamic badge,
    bool? border = false,
  }) {
    return Container(
      height: 50,
      padding: EdgeInsets.symmetric(
        horizontal: (!isSmallScreen) ? 25 : 16,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        border:
            border == true
                ? Border(
                  bottom: BorderSide(color: Theme.of(_context).dividerColor),
                )
                : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (icon != null)
            Flexible(
              flex: 1,
              child: Icon(
                icon as IconData?,
                // color: Colors.white70,
              ),
            ),
          Flexible(
            flex: 10,
            child: Padding(
              padding: EdgeInsets.only(left: (icon == null) ? 0 : 16),
              child: Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (label != null)
                    Flexible(
                      flex: 1,
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: (icon == null) ? 12 : 14,
                          height: 1.5, // Optional: adjust line height
                        ),
                        overflow:
                            TextOverflow.ellipsis, // Optional: handle overflow
                      ),
                    ),
                  if (badge != null && !hidden)
                    Flexible(
                      flex: 1,
                      child: Text(
                        badge ?? '',
                        style: const TextStyle(height: 1.5),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    _context = context;
    double opacity = 1;
    var size = MediaQuery.of(context).size;
    isSmallScreen = size.width < 800;
    return ListView(
      children: [
        if (!isSmallScreen)
          Container(
            height: 65,
            margin: const EdgeInsets.fromLTRB(16, 16, 0, 16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor.withOpacity(opacity),
              borderRadius: BorderRadius.circular(15.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 5,
                  offset: const Offset(1, 1),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Blur(
              blur: themeProvider.bgBlur,
              child: TextButton(
                style: ButtonStyle(
                  shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15.0),
                    ),
                  ),
                ),
                onPressed: () {
                  // Navigator.push(
                  //   context,
                  //   MaterialPageRoute(
                  //     builder: (context) => const ComposeEmail(),
                  //   ),
                  // );
                },
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Flexible(child: Icon(Icons.edit, size: 20)),
                      if (!hidden) const SizedBox(width: 10),
                      if (!hidden)
                        const Flexible(
                          child: Text(
                            'Compose',
                            style: TextStyle(fontSize: 20.0),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        Container(
          margin:
              isSmallScreen ? null : const EdgeInsets.fromLTRB(16, 0, 0, 16),
          width: width,
          height: height,
          padding: EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(!isSmallScreen ? 15.0 : 0.0),
            // color: const Color(0xFF232b23),
            color: Theme.of(context).cardColor.withOpacity(opacity),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                spreadRadius: 1,
                blurRadius: 5,
                offset: const Offset(1, 1),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Blur(
            blur: themeProvider.bgBlur,
            child: ListView(
              scrollDirection: Axis.vertical,
              children: [
                if (isSmallScreen)
                  Row(
                    children: [
                      Flexible(
                        child: Container(
                          width: width,
                          height: 50,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 15,
                          ),
                          decoration: const BoxDecoration(
                            border: Border(
                              bottom: BorderSide(color: Colors.white30),
                            ),
                          ),
                          child: const Text('Wings'),
                        ),
                      ),
                    ],
                  ),
                if (isSmallScreen)
                  getSideMenuList(
                    width: width,
                    icon: Icons.all_inbox_rounded,
                    label: "All inboxes",
                  ),
                getSideMenuList(
                  width: width,
                  icon: Icons.inbox,
                  label: isSmallScreen ? 'Primary' : 'Inbox',
                  badge: '99+',
                ),
                if (isSmallScreen)
                  getSideMenuList(
                    width: width,
                    icon: Icons.sell_rounded,
                    label: 'Promotion',
                    badge: '20',
                  ),
                if (isSmallScreen)
                  getSideMenuList(
                    width: width,
                    icon: Icons.group,
                    label: 'Social',
                    badge: '85',
                  ),
                if (isSmallScreen)
                  getSideMenuList(width: width, label: 'All labels'),
                getSideMenuList(
                  width: width,
                  icon: Icons.star_border,
                  label: 'Stared',
                  badge: '12',
                ),
                getSideMenuList(
                  width: width,
                  icon: Icons.access_time_rounded,
                  label: 'Snoozed',
                  badge: '12',
                ),
                getSideMenuList(
                  width: width,
                  icon: Icons.label_important_outline_rounded,
                  label: 'Important',
                  badge: '5',
                ),
                getSideMenuList(
                  width: width,
                  icon: Icons.send,
                  label: 'Sent',
                  badge: '5',
                ),
                getSideMenuList(
                  width: width,
                  icon: Icons.schedule_send,
                  label: 'Scheduled',
                  badge: '5',
                ),
                getSideMenuList(
                  width: width,
                  icon: Icons.outbox_rounded,
                  label: 'Outbox',
                  badge: '5',
                ),
                getSideMenuList(
                  width: width,
                  icon: Icons.drafts_outlined,
                  label: 'Drafts',
                  badge: '5',
                ),
                getSideMenuList(
                  width: width,
                  icon: Icons.mail_outline_rounded,
                  label: 'All mail',
                  badge: '5',
                ),
                getSideMenuList(
                  width: width,
                  icon: Icons.report_gmailerrorred_rounded,
                  label: 'Spam',
                  badge: '5',
                ),
                getSideMenuList(
                  width: width,
                  icon: Icons.delete_outline_rounded,
                  label: 'Bin',
                  badge: '5',
                  border: true,
                ),
                getSideMenuList(
                  width: width,
                  icon: Icons.settings_rounded,
                  label: 'Settings',
                  badge: '5',
                ),
                getSideMenuList(
                  width: width,
                  icon: Icons.help_outline_outlined,
                  label: 'Help & Feedback',
                  badge: '5',
                  border: true,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
