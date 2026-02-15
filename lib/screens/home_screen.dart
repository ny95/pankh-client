import 'package:flutter/material.dart';
import 'package:projectwebview/providers/common_provider.dart';
import 'package:projectwebview/providers/layout_provider.dart';
import 'package:projectwebview/providers/mail_provider.dart';
import 'package:projectwebview/widgets/blur.dart';
import 'package:projectwebview/widgets/header.dart';
import 'package:projectwebview/widgets/mail_container.dart';
import 'package:projectwebview/widgets/mail_nav.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../utils/helpers.dart';
import '../widgets/side_menu.dart';
import '../widgets/settings_menu.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  bool menu = false;
  bool setting = false;
  int _lastNotifiedCount = 0;
  final List<String> bgImgList = [
    "thumbnail-theme-system.jpg",
    "thumbnail-theme-light.jpg",
    "thumbnail-theme-dark.jpg",
  ];

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final layoutProvider = Provider.of<LayoutProvider>(context);
    final commonProvider = Provider.of<CommonProvider>(context);
    final mailProvider = Provider.of<MailProvider>(context);
    bool panePreviewOff = layoutProvider.layout == "pane_preview_off";
    var size = MediaQuery.of(context).size;
    bool isSmallScreen = size.width < 800;
    if (commonProvider.isSmallScreen != isSmallScreen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        commonProvider.setIsSmallScreen(isSmallScreen: isSmallScreen);
        if (isSmallScreen && commonProvider.isMailView) {
          commonProvider.setIsMailView(isMailView: false);
        }
      });
    }
    if (mailProvider.newMailCount > 0 &&
        mailProvider.newMailCount != _lastNotifiedCount &&
        mounted) {
      _lastNotifiedCount = mailProvider.newMailCount;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'You have ${mailProvider.newMailCount} new email(s).',
            ),
            action: SnackBarAction(
              label: 'Refresh',
              onPressed: () {
                mailProvider.refreshNewer();
                mailProvider.clearNewMailCount();
              },
            ),
          ),
        );
      });
    }

    return Scaffold(
      drawer:
          isSmallScreen
              ? Drawer(
                child: SideMenuList(width: size.width, height: size.height),
              )
              : null,
      body: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).canvasColor,
          image: getBackgroundDecoration(themeProvider),
        ),
        child: SafeArea(
          child: Column(
            children: <Widget>[
              Header(
                toggleMenu: () {
                  setState(() {
                    menu = !menu;
                  });
                },
                toggleSetting: () {
                  setState(() {
                    setting = !setting;
                  });
                },
              ),
              Expanded(
                child: Row(
                  children: [
                    if (!isSmallScreen)
                      SideMenu(
                        width: 300.0,
                        height: (size.height - 66),
                        controller: menu,
                        minWidth: 92,
                        child: SideMenuList(
                          hidden: !menu,
                          width: 300.0,
                          height: (size.height - 179),
                        ),
                      ),
                    Expanded(
                      child: Container(
                        margin: EdgeInsets.all(isSmallScreen ? 0 : 16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          color: Theme.of(
                            context,
                          ).cardColor.withValues(
                            alpha: themeProvider.bgOpacity,
                          ),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Blur(
                          blur: themeProvider.bgBlur,
                          child: Column(
                            children: [
                              if (!(panePreviewOff &&
                                      commonProvider.isMailView) &&
                                  !isSmallScreen)
                                MailNav(),
                              Expanded(child: MailListContainer()),
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (!isSmallScreen)
                      SideMenu(
                        width: 300.0,
                        height: (size.height - 66),
                        controller: setting,
                        child: SettingsMenu(
                          hidden: !setting,
                          onClose: () {
                            setState(() {
                              setting = !setting;
                            });
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      // floatingActionButton: FloatingActionButton.extended(
      //   onPressed: () {
      //     // Navigate to compose email screen
      //   },
      //   tooltip: 'Compose',
      //   label: const Text('Compose'),
      //   icon: const Icon(Icons.edit),
      // ),
    );
  }
}
