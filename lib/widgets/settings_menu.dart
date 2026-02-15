import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:projectwebview/widgets/settings/account/account.dart';
import 'package:projectwebview/widgets/settings/composition.dart';
import 'package:projectwebview/widgets/settings/extension.dart';
import 'package:projectwebview/widgets/settings/notification.dart';
import 'package:projectwebview/widgets/settings/security.dart';
import 'package:provider/provider.dart';
import '../utils/image_shade.dart';
import '../providers/theme_provider.dart';
import '../providers/layout_provider.dart';
import '../providers/inbox_type_provider.dart';
import 'blur.dart';

class SettingsMenu extends StatefulWidget {
  final VoidCallback onClose;
  final bool hidden;

  const SettingsMenu({super.key, required this.onClose, required this.hidden});

  @override
  SettingsMenuState createState() => SettingsMenuState();
}

class SettingsMenuState extends State<SettingsMenu> {
  late String selectedReadingPane;
  late String selectedInboxType;
  late String currentBackground;
  bool settingCard = true;
  final List<String> bgImgList = [
    "thumbnail-theme-system.jpg",
    "thumbnail-theme-light.jpg",
    "thumbnail-theme-dark.jpg",
    "thumbnail-theme-mccutcheon.jpg",
    "thumbnail-theme-mccutcheon 2.jpg",
    "thumbnail-theme-mirrographer.jpg",
    "thumbnail-theme-nicolas-poupart.jpg",
    "thumbnail-theme-padrinan.jpg",
    "thumbnail-theme-pixabay.jpg",
    "thumbnail-theme-pixabay 2.jpg",
    "thumbnail-theme-quangnguyenvinh.jpg",
    "thumbnail-theme-therato.jpg",
  ];

  final List<Map<String, dynamic>> readingPanes = [
    {
      "label": "No Split",
      "value": "pane_preview_off",
      "img": "pane_preview_off.png",
    },
    {
      "label": "Right of inbox",
      "value": "pane_preview_right",
      "img": "pane_preview_right.png",
    },
    {
      "label": "Below inbox",
      "value": "pane_preview_bottom",
      "img": "pane_preview_bottom.png",
    },
  ];

  final List<Map<String, dynamic>> inboxTypes = [
    {
      "label": "Default",
      "value": "default",
      "img": "inbox_default.png",
      "customization": true,
    },
    {
      "label": "Important first",
      "value": "important_first",
      "img": "inbox_important_first.png",
      "customization": false,
    },
    {
      "label": "Unread first",
      "value": "unread_first",
      "img": "inbox_unread_first.png",
      "customization": false,
    },
    {
      "label": "Starred first",
      "value": "starred_first",
      "img": "inbox_starred_first.png",
      "customization": false,
    },
    {
      "label": "Priority inbox",
      "value": "priority_inbox",
      "img": "inbox_priority_inbox.png",
      "customization": true,
    },
    {
      "label": "Multiple inboxes",
      "value": "multiple_inboxes",
      "img": "inbox_multiple_inboxes.png",
      "customization": true,
    },
  ];

  @override
  void initState() {
    super.initState();
    final layoutProvider = Provider.of<LayoutProvider>(context, listen: false);
    final inboxTypeProvider = Provider.of<InboxTypeProvider>(
      context,
      listen: false,
    );
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);

    selectedReadingPane = layoutProvider.layout;
    selectedInboxType = inboxTypeProvider.inboxType;
    currentBackground = themeProvider.theme;
  }

  Future<void> _pickImage(BuildContext context) async {
    try {
      final XFile? file = await openFile(
        acceptedTypeGroups: [
          XTypeGroup(
            label: 'Images',
            extensions: ['jpg', 'png', 'jpeg', 'gif'],
          ),
        ],
      );

      if (file != null) {
        if (!context.mounted) return;
        // Update theme provider
        final themeProvider = Provider.of<ThemeProvider>(
          context,
          listen: false,
        );
        themeProvider.setTheme(
          theme:
              await isImageDark(file.path, file.readAsBytes())
                  ? "dark"
                  : "light",
          bgImg: "custom::${file.path}",
          bgBlur: themeProvider.bgBlur,
          bgOpacity: themeProvider.bgOpacity,
        );
      }
    } catch (e) {
      debugPrint("Error picking background image: $e");
      // Show error to user if needed
    }
  }

  void _showThemeDialog(BuildContext context, themeProvider) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          titlePadding: EdgeInsets.fromLTRB(24, 16, 16, 0),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Select Theme'),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextButton(
                    onPressed: () => _pickImage(context),
                    child: Text('My photos'),
                  ),
                  SizedBox(width: 20),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        Navigator.of(context).pop();
                      });
                    },
                    icon: Icon(Icons.close),
                  ),
                ],
              ),
            ],
          ),
          content: SizedBox(
            width: 850,
            height: 420,
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: Center(
                child: Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children:
                      bgImgList.map((img) {
                        return GestureDetector(
                          onTap: () async {
                            await updateTheme(img);
                          },
                          child: Container(
                            width: 200,
                            height: 120,
                            decoration: BoxDecoration(
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  spreadRadius: 1,
                                  blurRadius: 5,
                                  offset: const Offset(1, 1),
                                ),
                              ],
                              borderRadius: BorderRadius.circular(10),
                              border:
                                  themeProvider.bgImg == img
                                      ? Border.all(color: Colors.blue, width: 3)
                                      : null,
                              image: DecorationImage(
                                image: AssetImage('assets/images/$img'),
                                fit: BoxFit.cover,
                              ),
                            ),
                            child:
                                themeProvider.bgImg == img
                                    ? Container(
                                      decoration: BoxDecoration(
                                        color: Colors.black54,
                                        borderRadius: BorderRadius.circular(7),
                                      ),
                                      child: const Center(
                                        child: Icon(
                                          Icons.check_rounded,
                                          size: 50,
                                          color: Colors.blue,
                                        ),
                                      ),
                                    )
                                    : null,
                          ),
                        );
                      }).toList(),
                ),
              ),
            ),
          ),
          backgroundColor: Theme.of(context).cardColor,
        );
      },
    );
  }

  Widget getAllSettingsTabs(
    BuildContext context,
    themeProvider,
    isSmallScreen,
  ) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.7,
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor.withValues(
          alpha: themeProvider.bgOpacity,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Blur(
        blur: themeProvider.bgBlur,
        child: DefaultTabController(
          length: 5,
          child: Scaffold(
            backgroundColor: Colors.transparent,
            // No appBar here
            body: Column(
              children: [
                TabBar(
                  tabAlignment: TabAlignment.center,
                  isScrollable: true,
                  dividerColor: Colors.black12,
                  tabs: [
                    Tab(icon: Icon(Icons.account_circle), text: 'Account'),
                    Tab(icon: Icon(Icons.mail), text: 'Composition'),
                    Tab(icon: Icon(Icons.notifications), text: 'Notifications'),
                    Tab(icon: Icon(Icons.security), text: 'Security'),
                    Tab(icon: Icon(Icons.extension), text: 'Extensions'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      AccountSettingsTab(isSmallScreen: isSmallScreen),
                      CompositionSettingsTab(isSmallScreen: isSmallScreen),
                      NotificationSettingsTab(isSmallScreen: isSmallScreen),
                      SecuritySettingsTab(isSmallScreen: isSmallScreen),
                      ExtensionsTab(isSmallScreen: isSmallScreen),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Object _showAllSettingsDialog(BuildContext context, themeProvider) {
    final isSmallScreen = MediaQuery.of(context).size.width < 600;
    if (isSmallScreen) {
      return Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
        body: getAllSettingsTabs(context, themeProvider, isSmallScreen),
      );
    } else {
      return showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            backgroundColor: Theme.of(context).cardColor,
            content: getAllSettingsTabs(context, themeProvider, isSmallScreen),
          );
        },
      );
    }
  }

  Future<void> updateTheme(String img) async {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    bool shadeCheck = !bgImgList.sublist(0, 3).contains(img);
    if (shadeCheck) {
      themeProvider.setTheme(
        theme: await isImageDark('assets/images/$img', null) ? "dark" : "light",
        bgImg: img,
        bgBlur: true,
        bgOpacity: 0.5,
      );
    } else {
      themeProvider.setTheme(
        theme: img.contains("light") ? "light" : "dark",
        bgImg: img,
        bgBlur: false,
        bgOpacity: 1,
      );
    }
  }

  List<Widget> setReadingPane({required LayoutProvider layoutProvider}) {
    return readingPanes
        .map(
          (pane) => Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 40,
                              height: 50,
                              child: Center(
                                child: RadioListTile(
                                  value: pane['value'],
                                  groupValue: layoutProvider.layout,
                                  onChanged: (value) {
                                    layoutProvider.setLayout(value!);
                                  },
                                ),
                              ),
                            ),
                            Expanded(child: Text(pane["label"])),
                          ],
                        ),
                      ), // Display the label
                      Container(
                        width: 70,
                        height: 50,
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: AssetImage("assets/images/${pane['img']}"),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        )
        .toList(); // Convert the iterable to a list
  }

  List<Widget> setInboxType({required InboxTypeProvider inboxTypeProvider}) {
    return inboxTypes
        .map(
          (pane) => Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            SizedBox(
                              width: 40,
                              height: 50,
                              child: Center(
                                child: RadioListTile(
                                  value: pane['value'],
                                  groupValue: selectedInboxType,
                                  onChanged: (value) {
                                    setState(() {
                                      selectedInboxType = value!;
                                      inboxTypeProvider.setInboxType(value!);
                                    });
                                  },
                                ),
                              ),
                            ),
                            Flexible(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(pane["label"]),
                                  if (pane["customization"])
                                    GestureDetector(
                                      onTap: () {},
                                      child: Text(
                                        "Customize",
                                        style: TextStyle(color: Colors.blue),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ), // Display the label
                      Container(
                        width: 70,
                        height: 50,
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: AssetImage("assets/images/${pane['img']}"),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        )
        .toList(); // Convert the iterable to a list
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final layoutProvider = Provider.of<LayoutProvider>(context);
    final inboxTypeProvider = Provider.of<InboxTypeProvider>(context);

    return Container(
      width: 300,
      margin: const EdgeInsets.fromLTRB(0, 16, 16, 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor.withValues(
          alpha: themeProvider.bgOpacity,
        ),
        borderRadius: BorderRadius.circular(15),
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
      child:
          !widget.hidden
              ? Blur(
                blur: themeProvider.bgBlur,
                child: Column(
                  children: [
                    Container(
                      height: 50,
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: Theme.of(context).dividerColor,
                          ),
                        ),
                      ),
                      padding: const EdgeInsets.only(left: 16, right: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Quick settings',
                            style: TextStyle(fontSize: 16),
                          ),
                          IconButton(
                            onPressed:
                                widget.onClose, // Call the onClose callback
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Theme',
                                      style: TextStyle(fontSize: 16),
                                    ),
                                    TextButton(
                                      onPressed:
                                          () => _showThemeDialog(
                                            context,
                                            themeProvider,
                                          ),
                                      child: const Text('View All'),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children:
                                      bgImgList.sublist(0, 9).map((img) {
                                        return GestureDetector(
                                          onTap: () async {
                                            await updateTheme(img);
                                          },
                                          child: Container(
                                            width: 78.65,
                                            height: 60,
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              border:
                                                  themeProvider.bgImg == img
                                                      ? Border.all(
                                                        color: Colors.blue,
                                                        width: 3,
                                                      )
                                                      : null,
                                              image: DecorationImage(
                                                image: AssetImage(
                                                  'assets/images/$img',
                                                ),
                                                fit: BoxFit.cover,
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color:
                                                      Theme.of(
                                                        context,
                                                      ).dividerColor,
                                                  blurRadius: 0,
                                                  spreadRadius: 1,
                                                  offset: const Offset(0, 0),
                                                ),
                                              ],
                                            ),
                                            child:
                                                themeProvider.bgImg == img
                                                    ? Container(
                                                      decoration: BoxDecoration(
                                                        color: Colors.black54,
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              7,
                                                            ),
                                                      ),
                                                      child: const Center(
                                                        child: Icon(
                                                          Icons.check_rounded,
                                                          color: Colors.blue,
                                                        ),
                                                      ),
                                                    )
                                                    : null,
                                          ),
                                        );
                                      }).toList(),
                                ),
                                const SizedBox(height: 20),
                                const Text(
                                  'Reading Pane',
                                  style: TextStyle(fontSize: 16),
                                ),
                                ...setReadingPane(
                                  layoutProvider: layoutProvider,
                                ),
                                const SizedBox(height: 20),
                                const Text(
                                  'Inbox Type',
                                  style: TextStyle(fontSize: 16),
                                ),
                                ...setInboxType(
                                  inboxTypeProvider: inboxTypeProvider,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      height: 60,
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(
                            color: Theme.of(context).dividerColor,
                          ),
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: ElevatedButton(
                        onPressed:
                            () =>
                                _showAllSettingsDialog(context, themeProvider),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              flex: 2,
                              child: Icon(Icons.settings, size: 20),
                            ),
                            Flexible(flex: 2, child: SizedBox(width: 10)),
                            Flexible(
                              flex: 8,
                              child: Text(
                                'See all settings',
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 16.0),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              )
              : null,
    );
  }
}
