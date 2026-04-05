
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:provider/provider.dart';

import '../providers/mail_provider.dart';
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
  final void Function(PointerEnterEvent)? onEnter;
  final void Function(PointerExitEvent)? onExit;
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
  Widget childWithMouseAction() {
    return mouseRegion
        ? MouseRegion(onEnter: onEnter, onExit: onExit, child: child)
        : child;
  }

  @override
  Widget build(BuildContext context) {
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
  const SideMenuList({
    super.key,
    required this.width,
    required this.height,
    this.hidden = false,
    this.onCompose,
    this.onOpenSettings,
    this.onOpenHelp,
    this.closeDrawerOnTap = false,
  });

  final double width;
  final double height;
  final bool hidden;
  final VoidCallback? onCompose;
  final VoidCallback? onOpenSettings;
  final VoidCallback? onOpenHelp;
  final bool closeDrawerOnTap;
  Widget getSideMenuList({
    required BuildContext context,
    required double width,
    required bool isSmallScreen,
    dynamic icon,
    dynamic label,
    dynamic badge,
    bool? border = false,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: () {
        if (closeDrawerOnTap && isSmallScreen) {
          Navigator.of(context).pop();
        }
        onTap?.call();
      },
      child: Container(
        height: 50,
        padding: EdgeInsets.symmetric(
          horizontal: (!isSmallScreen) ? 25 : 16,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          border:
              border == true
                  ? Border(
                    bottom: BorderSide(color: Theme.of(context).dividerColor),
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
                            height: 1.5,
                          ),
                          overflow: TextOverflow.ellipsis,
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
      ),
    );
  }

  IconData _folderIcon(String name) {
    final n = name.toLowerCase();
    if (n.contains('inbox')) return Icons.inbox;
    if (n.contains('sent')) return Icons.send;
    if (n.contains('draft')) return Icons.drafts_outlined;
    if (n.contains('spam') || n.contains('junk')) {
      return Icons.report_gmailerrorred_rounded;
    }
    if (n.contains('trash') || n.contains('bin')) {
      return Icons.delete_outline_rounded;
    }
    if (n.contains('archive') || n.contains('all mail')) {
      return Icons.mail_outline_rounded;
    }
    if (n.contains('star')) return Icons.star_border;
    if (n.contains('important')) return Icons.label_important_outline_rounded;
    return Icons.folder_outlined;
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final mailProvider = Provider.of<MailProvider>(context);
    double opacity = 1;
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 800;
    final folders = mailProvider.folders;
    final selectedFolder = mailProvider.selectedFolder;
    return ListView(
      children: [
        if (!isSmallScreen)
          Container(
            height: 65,
            margin: const EdgeInsets.fromLTRB(16, 16, 0, 16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor.withValues(alpha: opacity),
              borderRadius: BorderRadius.circular(15.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
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
                  onCompose?.call();
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
            color: Theme.of(context).cardColor.withValues(alpha: opacity),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
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
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: 75,
                        width: 90,
                        child: Center(
                          child: Image.asset(
                            'assets/logos/pankh-2d.png',
                            // width: 75,
                            height: 44,
                          ),
                        ),
                      ),
                      Image.asset(
                        'assets/logos/pankh-text.png',
                        // width: 75,
                        height: 25,
                      )
                    ],
                  ),
                if (folders.isNotEmpty)
                  ...folders.map((folder) {
                    final isSelected =
                        selectedFolder?.path == folder.path;
                    return Container(
                      color:
                          isSelected
                              ? Theme.of(context)
                                  .dividerColor
                                  .withValues(alpha: 0.15)
                              : Colors.transparent,
                      child: getSideMenuList(
                        context: context,
                        width: width,
                        isSmallScreen: isSmallScreen,
                        icon: _folderIcon(folder.name),
                        label: folder.name,
                        onTap: () {
                          mailProvider.selectFolder(folder);
                        },
                      ),
                    );
                  }),
                getSideMenuList(
                  context: context,
                  width: width,
                  isSmallScreen: isSmallScreen,
                  icon: Icons.settings_rounded,
                  label: 'Settings',
                  // badge: '5',
                  onTap: onOpenSettings,
                ),
                getSideMenuList(
                  context: context,
                  width: width,
                  isSmallScreen: isSmallScreen,
                  icon: Icons.help_outline_outlined,
                  label: 'Help & Feedback',
                  // badge: '5',
                  border: true,
                  onTap: onOpenHelp,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
