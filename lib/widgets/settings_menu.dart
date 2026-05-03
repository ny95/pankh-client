import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:pankh/widgets/open_dialog.dart';
import 'package:pankh/widgets/settings/account/account.dart';
import 'package:pankh/widgets/settings/composition.dart';
import 'package:pankh/widgets/settings/extension.dart';
import 'package:pankh/widgets/settings/notification.dart';
import 'package:pankh/widgets/settings/security.dart';
import 'package:provider/provider.dart';
import '../utils/image_shade.dart';
import '../utils/helpers.dart' hide isImageDark;
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
  late String currentBackground;
  late final List<String> _bgImgFirst9;
  bool settingCard = true;
  final ValueNotifier<bool> _isFullScreenCloseButtonNotifier =
      ValueNotifier<bool>(true);
  final Map<String, bool> _darkCache = {};

  final List<String> bgImgList = [
    "thumbnail-theme-system.jpg",
    "thumbnail-theme-light.jpg",
    "thumbnail-theme-dark.jpg",
    "thumbnail-theme-mccutcheon.jpg",
    "thumbnail-theme-mccutcheon-2.jpg",
    "thumbnail-theme-mirrographer.jpg",
    "thumbnail-theme-nicolas-poupart.jpg",
    "thumbnail-theme-padrinan.jpg",
    "thumbnail-theme-pixabay.jpg",
    "thumbnail-theme-pixabay-2.jpg",
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
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);

    selectedReadingPane = layoutProvider.layout;
    currentBackground = themeProvider.theme;
    _bgImgFirst9 = bgImgList.sublist(0, 9);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _precacheAll();
    });
  }

  void _precacheAll() {
    for (final img in bgImgList.sublist(3)) {
      if (!_darkCache.containsKey(img)) {
        isImageDark('assets/images/$img', null).then((isDark) {
          if (mounted) _darkCache[img] = isDark;
        });
      }
      precacheImage(AssetImage('assets/images/bg/${_bucket()}/${img.replaceAll('thumbnail-', '')}'), context);
    }
  }

  int _bucket() {
    final w = MediaQuery.sizeOf(context).width * MediaQuery.devicePixelRatioOf(context);
    return w <= 480 ? 480 : w <= 960 ? 960 : w <= 1440 ? 1440 : 1920;
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
    CustomDialog.show(
      context: context,
      child: Column(
        children: [
          Row(
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
                  const SizedBox(width: 50, height: 50),
                ],
              ),
            ],
          ),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: Center(
                child: Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: bgImgList.map((img) =>
                    _ThumbItem(
                      img: img,
                      width: 230,
                      height: 130,
                      onTap: () => updateTheme(img),
                      iconSize: 50,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          spreadRadius: 1,
                          blurRadius: 5,
                          offset: const Offset(1, 1),
                        ),
                      ],
                    ),
                  ).toList(),
                ),
              ),
            ),
          ),
        ],
      )
    );
  }

  Widget getAllSettingsTabs(
    BuildContext context,
    themeProvider,
    isSmallScreen,
  ) {
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        // No appBar here
        body: Column(
          children: [
            Padding(
              padding: isSmallScreen ? const EdgeInsets.only(right: 80) : EdgeInsets.all(0),
              child: TabBar(
                tabAlignment: TabAlignment.center,
                isScrollable: true,
                dividerColor: Colors.black12,
                tabs: [
                  const Tab(icon: Icon(Icons.account_circle), text: 'Account'),
                  const Tab(icon: Icon(Icons.mail), text: 'Composition'),
                  const Tab(icon: Icon(Icons.notifications), text: 'Notifications'),
                  const Tab(icon: Icon(Icons.security), text: 'Security'),
                  const Tab(icon: Icon(Icons.extension), text: 'Extensions'),
                ],
              ),
            ),
            Expanded( 
              child: TabBarView(
                children: [
                  AccountSettingsTab(updateFullScreenCloseButton: updateFullScreenCloseButton,),
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
    );
  }

  Future<void> updateTheme(String img) async {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    bool shadeCheck = !bgImgList.sublist(0, 3).contains(img);
    if (shadeCheck) {
      // Run dark-check and background preload in parallel to minimise delay
      final darkFuture = _darkCache.containsKey(img)
          ? Future.value(_darkCache[img]!)
          : isImageDark('assets/images/$img', null);
      final bgPath = responsiveBackgroundAsset(context, img);
      final precacheFuture = precacheImage(AssetImage(bgPath), context);

      final isDark = await darkFuture;
      _darkCache[img] = isDark;
      await precacheFuture;

      if (!mounted) return;
      themeProvider.setTheme(
        theme: isDark ? "dark" : "light",
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

  Widget setReadingPane({
    required LayoutProvider layoutProvider,
    required bool isCompact,
  }) {
    return RadioGroup<String>(
      groupValue: layoutProvider.layout,
      onChanged: (value) {
        if (value == null) return;
        layoutProvider.setLayout(value);
      },
      child: Column(
        children: readingPanes.map((pane) {
          final radio = SizedBox(
            width: 40,
            height: 50,
            child: Center(child: RadioListTile(value: pane['value'])),
          );
          final preview = Container(
            width: 70,
            height: 50,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/images/${pane['img']}"),
                fit: BoxFit.cover,
              ),
            ),
          );
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: isCompact
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            radio,
                            const SizedBox(width: 6),
                            ConstrainedBox(
                              constraints:
                                  const BoxConstraints(maxWidth: 140),
                              child: Text(
                                pane["label"],
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      preview,
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            radio,
                            Expanded(
                              child: Text(
                                pane["label"],
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                      preview,
                    ],
                  ),
          );
        }).toList(),
      ),
    );
  }

  Widget setInboxType({
    required InboxTypeProvider inboxTypeProvider,
    required bool isCompact,
  }) {
    return RadioGroup<String>(
      groupValue: inboxTypeProvider.inboxType,
      onChanged: (value) {
        if (value == null) return;
        inboxTypeProvider.setInboxType(value);
      },
      child: Column(
        children: inboxTypes.map((pane) {
          final labelColumn = Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(pane["label"], overflow: TextOverflow.ellipsis),
              if (pane["customization"] == true)
                GestureDetector(
                  onTap: () {},
                  child: const Text(
                    "Customize",
                    style: TextStyle(color: Colors.blue),
                  ),
                ),
            ],
          );
          final radio = SizedBox(
            width: 40,
            height: 50,
            child: Center(child: RadioListTile(value: pane['value'])),
          );
          final preview = Container(
            width: 70,
            height: 50,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/images/${pane['img']}"),
                fit: BoxFit.cover,
              ),
            ),
          );
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: isCompact
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            radio,
                            const SizedBox(width: 6),
                            ConstrainedBox(
                              constraints:
                                  const BoxConstraints(maxWidth: 140),
                              child: labelColumn,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      preview,
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            radio,
                            Flexible(child: labelColumn),
                          ],
                        ),
                      ),
                      preview,
                    ],
                  ),
          );
        }).toList(),
      ),
    );
  }
  void updateFullScreenCloseButton (bool status) {
    _isFullScreenCloseButtonNotifier.value = status;
  }
  @override
  void dispose() {
    _isFullScreenCloseButtonNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // listen: false — bgImg changes are handled per-item inside _ThumbItem via Selector
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    // Only subscribe to the two values this widget actually renders
    final bgOpacity = context.select<ThemeProvider, double>((p) => p.bgOpacity);
    final bgBlur = context.select<ThemeProvider, bool>((p) => p.bgBlur);
    final layoutProvider = Provider.of<LayoutProvider>(context);
    final inboxTypeProvider = Provider.of<InboxTypeProvider>(context);
    final isSmallScreen = MediaQuery.sizeOf(context).width < 600;


    return Container(
      width: 300,
      margin: isSmallScreen ? null : const EdgeInsets.fromLTRB(0, 16, 16, 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor.withValues(
          alpha: bgOpacity,
        ),
        borderRadius: BorderRadius.only(topLeft: Radius.circular(15), bottomLeft:Radius.circular(15), topRight: isSmallScreen? Radius.zero : Radius.circular(15), bottomRight: isSmallScreen ? Radius.zero : Radius.circular(15) ),
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
                blur: bgBlur,
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
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          if (constraints.maxWidth < 80) {
                            return Align(
                              alignment: Alignment.centerRight,
                              child: IconButton(
                                onPressed:
                                    widget.onClose, // Call the onClose callback
                                icon: const Icon(Icons.close, size: 18),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                  minWidth: 28,
                                  minHeight: 28,
                                ),
                              ),
                            );
                          }
                          if (constraints.maxWidth < 140) {
                            return Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Expanded(
                                  child: Text(
                                    'Quick settings',
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(fontSize: 14),
                                  ),
                                ),
                                IconButton(
                                  onPressed:
                                      widget.onClose, // Call the onClose callback
                                  icon: const Icon(Icons.close, size: 18),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(
                                    minWidth: 32,
                                    minHeight: 32,
                                  ),
                                ),
                              ],
                            );
                          }
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Expanded(
                                child: Text(
                                  'Quick settings',
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 16),
                                ),
                              ),
                              IconButton(
                                onPressed:
                                    widget.onClose, // Call the onClose callback
                                icon: const Icon(Icons.close),
                              ),
                            ],
                          );
                        },
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
                                LayoutBuilder(
                                  builder: (context, constraints) {
                                    final isTight = constraints.maxWidth < 120;
                                    if (isTight) {
                                      return Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Theme',
                                            style: TextStyle(fontSize: 16),
                                          ),
                                          Align(
                                            alignment: Alignment.centerLeft,
                                            child: TextButton(
                                              onPressed:
                                                  () => _showThemeDialog(
                                                    context,
                                                    themeProvider,
                                                  ),
                                              child: const Text('View All'),
                                            ),
                                          ),
                                        ],
                                      );
                                    }
                                    return Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Expanded(
                                          child: Text(
                                            'Theme',
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(fontSize: 16),
                                          ),
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
                                    );
                                  },
                                ),
                                const SizedBox(height: 10),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: _bgImgFirst9.map((img) =>
                                    _ThumbItem(
                                      img: img,
                                      width: 78.65,
                                      height: 60,
                                      onTap: () => updateTheme(img),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Theme.of(context).dividerColor,
                                          blurRadius: 0,
                                          spreadRadius: 1,
                                          offset: const Offset(0, 0),
                                        ),
                                      ],
                                    ),
                                  ).toList(),
                                ),
                                const SizedBox(height: 20),
                                const Text(
                                  'Reading Pane',
                                  style: TextStyle(fontSize: 16),
                                ),
                                LayoutBuilder(
                                  builder: (context, constraints) {
                                    final isCompact =
                                        constraints.maxWidth < 220;
                                    return Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        setReadingPane(
                                          layoutProvider: layoutProvider,
                                          isCompact: isCompact,
                                        ),
                                        const SizedBox(height: 20),
                                        const Text(
                                          'Inbox Type',
                                          style: TextStyle(fontSize: 16),
                                        ),
                                        setInboxType(
                                          inboxTypeProvider: inboxTypeProvider,
                                          isCompact: isCompact,
                                        ),
                                      ],
                                    );
                                  },
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
                        onPressed: () {
                          final scaffold = Scaffold.maybeOf(context);
                          if (scaffold != null &&
                              (scaffold.isEndDrawerOpen ||
                                  scaffold.isDrawerOpen)) {
                            Navigator.of(context).pop();
                          }
                          Future.microtask(
                            () {
                              if (!context.mounted) return;
                              CustomDialog.show(
                                context: context,
                                child: getAllSettingsTabs(
                                  context,
                                  themeProvider,
                                  isSmallScreen,
                                ),
                                isFullScreenCloseButtonListenable:
                                    _isFullScreenCloseButtonNotifier,
                              );
                            },
                          );
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Flexible(
                              flex: 2,
                              child: Icon(Icons.settings, size: 20),
                            ),
                            const Flexible(flex: 2, child: SizedBox(width: 10)),
                            const Flexible(
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

class _ThumbItem extends StatelessWidget {
  final String img;
  final double width;
  final double height;
  final VoidCallback onTap;
  final List<BoxShadow>? boxShadow;
  final double? iconSize;

  const _ThumbItem({
    required this.img,
    required this.width,
    required this.height,
    required this.onTap,
    this.boxShadow,
    this.iconSize,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              image: DecorationImage(
                image: AssetImage('assets/images/$img'),
                fit: BoxFit.cover,
              ),
              boxShadow: boxShadow,
            ),
          ),
          Selector<ThemeProvider, bool>(
            selector: (_, p) => p.bgImg == img,
            builder: (_, isSelected, _) => isSelected
                ? Container(
                    width: width,
                    height: height,
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(7),
                      border: Border.all(color: Colors.blue, width: 3),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.check_rounded,
                        color: Colors.blue,
                        size: iconSize,
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
