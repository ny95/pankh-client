import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:projectwebview/widgets/blur.dart';
import 'package:projectwebview/widgets/settings/account/account.dart';
import 'package:provider/provider.dart';

import '../providers/theme_provider.dart';

class Header extends StatefulWidget {
  final VoidCallback toggleMenu;
  final VoidCallback toggleSetting;

  const Header({
    super.key,
    required this.toggleMenu,
    required this.toggleSetting,
  });

  @override
  _HeaderState createState() => _HeaderState();
}

class _HeaderState extends State<Header> {
  bool filterHidden = false;

  void _openDialog({required BuildContext context, required Widget widget}) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          insetPadding: EdgeInsets.all(0),
          backgroundColor: Theme.of(context).cardColor,
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.7,
            height: MediaQuery.of(context).size.height * 0.8,
            child: widget,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    var size = MediaQuery.of(context).size;
    bool isSmallScreen = size.width < 800;
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(
            isSmallScreen ? 16 : 16,
            isSmallScreen ? 6 : 16,
            isSmallScreen ? 16 : 0,
            0,
          ),
          child: Row(
            children: [
              if (!isSmallScreen)
                Flexible(
                  flex: 2,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      IconButton(
                        onPressed: widget.toggleMenu,
                        icon: const Icon(Icons.menu),
                      ),
                      const Text(
                        'Wings',
                        style: TextStyle(
                          fontSize: 18,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              Flexible(
                flex: 8,
                child: Container(
                  padding:
                      !isSmallScreen
                          ? const EdgeInsets.only(left: 55.0, right: 150)
                          : null,
                  child: SearchAnchor(
                    viewBackgroundColor: Colors.red,
                    builder: (
                      BuildContext context,
                      SearchController controller,
                    ) {
                      return Container(
                        height: 50,
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(50),
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(context).dividerColor,
                              blurRadius: 0,
                              spreadRadius: 1,
                              offset: const Offset(0, 0),
                            ),
                          ],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Blur(
                          blur: themeProvider.bgBlur,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).cardColor.withOpacity(themeProvider.bgOpacity),
                              borderRadius: BorderRadius.circular(
                                8.0,
                              ), // Optional: round the corners
                            ),
                            child: SearchBar(
                              shadowColor: WidgetStateProperty.all(
                                Colors.transparent,
                              ),
                              backgroundColor: WidgetStateProperty.all(
                                Colors.transparent,
                              ),
                              controller: controller,
                              padding: WidgetStateProperty.all<EdgeInsets>(
                                const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 0,
                                ),
                              ),
                              onTap: () {
                                controller.openView();
                              },
                              onChanged: (_) {
                                controller.openView();
                              },
                              leading: Tooltip(
                                message: 'Toggle Menu',
                                child: IconButton(
                                  onPressed: () {
                                    if (isSmallScreen) {
                                      Scaffold.of(context).openDrawer();
                                    }
                                  },
                                  icon: Icon(
                                    isSmallScreen ? Icons.menu : Icons.search,
                                  ),
                                ),
                              ),
                              trailing: <Widget>[
                                Tooltip(
                                  message: 'Show Profile',
                                  child: IconButton(
                                    onPressed: () => {},
                                    icon: Icon(
                                      isSmallScreen
                                          ? Icons.person
                                          : Icons.tune_rounded,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                    suggestionsBuilder: (
                      BuildContext context,
                      SearchController controller,
                    ) {
                      return List<ListTile>.generate(5, (int index) {
                        final String item = 'item $index';
                        return ListTile(
                          title: Text(item),
                          onTap: () {
                            setState(() {
                              controller.closeView(item);
                            });
                          },
                        );
                      });
                    },
                  ),
                ),
              ),
              if (!isSmallScreen)
                Flexible(
                  flex: 2,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Flexible(
                        child: Container(
                          width: 50,
                          height: 50,
                          margin: const EdgeInsets.only(right: 16),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(50),
                          ),
                          child: IconButton(
                            onPressed: () {},
                            icon: const Icon(Icons.help_outline_rounded),
                          ),
                        ),
                      ),
                      Flexible(
                        child: Container(
                          width: 50,
                          height: 50,
                          margin: const EdgeInsets.only(right: 16),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(50),
                          ),
                          child: IconButton(
                            onPressed: widget.toggleSetting,
                            icon: const Icon(Icons.settings_rounded),
                          ),
                        ),
                      ),
                      Flexible(
                        child: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.white70,
                            borderRadius: BorderRadius.circular(50),
                          ),
                          child: IconButton(
                            onPressed: () {
                              _openDialog(
                                widget: AccountSettingsTab(
                                  isSmallScreen: isSmallScreen,
                                ),
                                context: context,
                              );
                            },
                            icon: const Icon(Icons.person),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        if (isSmallScreen)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 6, 20, 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Label'),
                InkWell(
                  onTap: () {
                    setState(() {
                      filterHidden = !filterHidden;
                    });
                  },
                  borderRadius: BorderRadius.circular(20),
                  child:
                      filterHidden
                          ? const Icon(Icons.filter_list_off_rounded)
                          : const Icon(Icons.filter_list_rounded),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
