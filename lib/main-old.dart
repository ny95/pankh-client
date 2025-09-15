import 'dart:ui';
import 'dart:math'; // Import the math library for Random
import 'package:flutter/material.dart';
import 'package:projectwebview/providers/theme_provider.dart';
import 'package:provider/provider.dart'; // Add this import
import './fetchMail.dart';
import './mailView.dart';
import './composeEmail.dart';
import './image-shade.dart';
import './haveStorage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HiveStorage.init();
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(), // Provide the ThemeProvider
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.system;

  @override
  void initState() {
    super.initState();
    _toggleTheme();
    print(ThemeMode.system);
  }

  void _toggleTheme() {
    setState(() {
      if (_themeMode == ThemeMode.system) {
        _themeMode = ThemeMode.light; // Switch to light if currently system
      } else if (_themeMode == ThemeMode.light) {
        _themeMode = ThemeMode.dark; // Switch to dark if currently light
      } else {
        _themeMode = ThemeMode.system; // Switch back to system
      }
    });
  }

  void _setTheme({String type = "system"}) {
    setState(() {
      if (type == "light") {
        _themeMode = ThemeMode.light; // Switch to light if currently system
      } else if (type == "dark") {
        _themeMode = ThemeMode.dark; // Switch to dark if currently light
      } else {
        _themeMode = ThemeMode.system; // Switch back to system
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        canvasColor: const Color(0xffeef1f6),
        primaryColor: Colors.blue,
        cardColor: Colors.white,
        dividerColor: Color(0xffefefef),
        colorScheme: const ColorScheme.light(primary: Colors.blue),
      ),
      darkTheme: ThemeData(
        canvasColor: const Color(0xFF000000),
        cardColor: const Color(0xFF191c24),
        primaryColor: Colors.deepPurple,
        dividerColor: const Color(0xFF2B2C2F),
        colorScheme: const ColorScheme.dark(primary: Colors.deepPurple),
      ),
      themeMode: _themeMode,
      home: MyHomePage(
        title: 'App Tittle',
        toggleTheme: _toggleTheme,
        setTheme: _setTheme,
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({
    super.key,
    required this.title,
    required this.toggleTheme,
    required this.setTheme,
  });
  final VoidCallback toggleTheme;
  final void Function({String type}) setTheme;
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePage();
}

class _MyHomePage extends State<MyHomePage> {
  final Random random = Random();
  bool largeLayoutBySplit = false;
  bool showMessageInFull = false;
  bool isDark = false;
  bool showProfile = true;
  bool menuHidden = true;
  bool settingCard = false;
  bool filterHidden = false;
  bool isBlur = false;
  int activeTab = 0;
  late bool isSmallScreen = false;
  late double width;
  late double height;
  double opacity = 1;
  double splitListWidth = 350;
  dynamic viewMail;
  List mailData = [];
  List<String> bgImgList = [
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
  String currentBackground = '';

  List<Map<String, dynamic>> inboxTypes = [
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
  }

  void _updateMailVewLayout() {
    setState(() {
      showMessageInFull = !showMessageInFull;
    });
  }

  List<Map<String, dynamic>> readingPanes = [
    {
      "label": "No Split",
      "value": "pane_preview_off",
      "img": "pane_preview_off.png",
    },
    {
      "label": "Right of inbox",
      "value": "pane_preview_bottom",
      "img": "pane_preview_bottom.png",
    },
    {
      "label": "Below inbox",
      "value": "pane_preview_right",
      "img": "pane_preview_right.png",
    },
  ];
  String selectedReadingPane = "pane_preview_off";
  List<Widget> setReadingPane() {
    return readingPanes
        .map(
          (pane) => Row(
            children: [
              Expanded(
                child: childWithDelay(
                  controller: !settingCard,
                  delay: Duration(milliseconds: 300),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 6.0, 20.0, 6.0),
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
                                    groupValue: selectedReadingPane,
                                    onChanged: (value) {
                                      setState(() {
                                        selectedReadingPane =
                                            value!; // Update the selected value
                                      });
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
              ),
            ],
          ),
        )
        .toList(); // Convert the iterable to a list
  }

  String selectedInboxType = "default";
  List<Widget> setInboxType() {
    return inboxTypes
        .map(
          (pane) => Row(
            children: [
              Expanded(
                child: childWithDelay(
                  controller: !settingCard,
                  delay: Duration(milliseconds: 300),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8.0, 6.0, 20.0, 6.0),
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
                                        selectedInboxType =
                                            value!; // Update the selected value
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
              ),
            ],
          ),
        )
        .toList(); // Convert the iterable to a list
  }

  void _showDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Dialog Title'),
          content: const Text('This is a simple alert dialog.'),
          backgroundColor: Colors.red,
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showThemeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Theme'),
          content: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: SizedBox(
              width: 850,
              height: 400,
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
                              boxShadow:
                                  !isSmallScreen
                                      ? [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.2),
                                          spreadRadius: 1,
                                          blurRadius: 5,
                                          offset: const Offset(1, 1),
                                        ),
                                      ]
                                      : null,
                              borderRadius: BorderRadius.circular(10),
                              border:
                                  currentBackground == img
                                      ? Border.all(color: Colors.blue, width: 3)
                                      : null,
                              image: DecorationImage(
                                image: AssetImage(
                                  'assets/images/$img',
                                ), // Corrected path
                                fit: BoxFit.cover, // Adjust how the image fits
                              ),
                            ),
                            child:
                                currentBackground == img
                                    ? SizedBox(
                                      width: 80,
                                      height: 60,
                                      child: Center(
                                        child: Icon(
                                          Icons.check,
                                          color: Colors.blue,
                                        ),
                                      ),
                                    )
                                    : null,
                          ),
                        );
                      }).toList(), // Convert the iterable to a list
                ),
              ),
            ),
          ),
          backgroundColor: Theme.of(context).cardColor,
          // actions: <Widget>[
          //   TextButton(
          //     child: const Text('OK'),
          //     onPressed: () {
          //       Navigator.of(context).pop();
          //     },
          //   ),
          // ],
        );
      },
    );
  }

  Widget rowOrCol(option) {
    return option['target'].toLowerCase() == 'row'
        ? Row(
          mainAxisAlignment:
              option['mainAxisAlignment'] ?? MainAxisAlignment.start,
          crossAxisAlignment:
              option['crossAxisAlignment'] ?? CrossAxisAlignment.start,
          mainAxisSize: option['mainAxisSize'] ?? MainAxisSize.max,
          children: option['children'] ?? [],
        )
        : Column(
          mainAxisAlignment:
              option['mainAxisAlignment'] ?? MainAxisAlignment.start,
          crossAxisAlignment:
              option['crossAxisAlignment'] ?? CrossAxisAlignment.start,
          mainAxisSize: option['mainAxisSize'] ?? MainAxisSize.max,
          children: option['children'] ?? [],
        );
  }

  Future<List> fetchEmails() async {
    if (mailData.isEmpty) {
      mailData = await Imap().fetchMails();
    }
    return mailData;
  }

  Color _generateRandomColor() {
    return Color.fromARGB(
      255, // Alpha (opacity)
      96 + random.nextInt(96), // Red (96-191)
      96 + random.nextInt(96), // Green (96-191)
      96 + random.nextInt(96), // Blue (96-191)
    );
  }

  List<Widget> _showEmailList(mimeEmails) {
    final List<Widget> email = [];
    mimeEmails.forEach((message) {
      final String from =
          message.from[0].toString().split('<')[0].replaceAll('"', '').trim() ??
          '';
      final String fromEmail =
          message.from[0].toString().split('<')[0].replaceAll('>', '').trim() ??
          '';
      // print(fromEmail);
      dynamic messageString = message.decodeTextPlainPart();
      String newMessageString = 'Nothing here';
      if (messageString != null) {
        newMessageString = '';
        messageString = messageString.split('\r\n');
        for (final line in messageString) {
          if (line.startsWith('>')) {
            break;
          }
          newMessageString += line.replaceAll('\n', '') + ' ';
        }
      }
      email.add(
        GestureDetector(
          onTap: () {
            if (!isSmallScreen) {
              setState(() {
                viewMail = message;
                if (!largeLayoutBySplit) {
                  showMessageInFull = true;
                } else {
                  showMessageInFull = false;
                }
              });
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ViewMail(message: message, type: true),
                ),
              );
            }
          },
          child: Container(
            decoration:
                !isSmallScreen
                    ? BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: Theme.of(context).dividerColor,
                        ),
                      ),
                    )
                    : null,
            padding: EdgeInsets.fromLTRB(
              isSmallScreen ? 12.0 : 0,
              isSmallScreen ? 2.0 : 4.0,
              isSmallScreen ? 12.0 : 16,
              isSmallScreen ? 2.0 : 4.0,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isSmallScreen)
                  Padding(
                    padding: const EdgeInsets.only(top: 3, right: 10),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(40),
                        color: _generateRandomColor(),
                      ),
                      child:
                          (fromEmail.contains('noreply') ||
                                  fromEmail.contains('no-reply') ||
                                  fromEmail.contains('support'))
                              ? Center(
                                child: Padding(
                                  padding: const EdgeInsets.only(bottom: 2.0),
                                  child: Text(
                                    from[0].toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              )
                              : const Icon(Icons.person, color: Colors.white),
                    ),
                  ),
                if (!isSmallScreen)
                  Container(
                    margin: EdgeInsets.only(
                      left: 8,
                      right: largeLayoutBySplit ? 8 : 0,
                    ),
                    width: 30,
                    height: largeLayoutBySplit ? 30 : 40,
                    child: Checkbox(value: false, onChanged: (value) {}),
                  ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment:
                            isSmallScreen || largeLayoutBySplit
                                ? MainAxisAlignment.spaceBetween
                                : MainAxisAlignment.start,
                        children: [
                          if (!isSmallScreen && !largeLayoutBySplit)
                            Container(
                              width: 150,
                              margin: const EdgeInsets.only(right: 20),
                              child: Row(
                                mainAxisSize: MainAxisSize.max,
                                children: [
                                  Flexible(
                                    flex: 4,
                                    child: SizedBox(
                                      width: 40,
                                      height: 40,
                                      child: IconButton(
                                        onPressed: () {},
                                        icon: const Icon(Icons.star_border),
                                      ),
                                    ),
                                  ),
                                  Flexible(
                                    flex: 8,
                                    child: Text(
                                      from,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          Flexible(
                            flex: 9,
                            child: Text(
                              '${largeLayoutBySplit || isSmallScreen ? from : ''} ${(!isSmallScreen && !largeLayoutBySplit) ? '${message.decodeSubject()} - $newMessageString' : ''}',
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                          if (isSmallScreen || largeLayoutBySplit)
                            Flexible(
                              flex: 3,
                              child: const Text(
                                '12:50 pm',
                                style: TextStyle(fontSize: 11),
                              ),
                            ),
                        ],
                      ),
                      if (isSmallScreen || largeLayoutBySplit)
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    message.decodeSubject(),
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(fontSize: 13.5),
                                  ),
                                  Text(
                                    newMessageString,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(
                              width: 30,
                              height: 30,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Icon(
                                    Icons.star_border,
                                    color: Colors.white70,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
    return email;
  }

  Future<bool> getMenuStatus({
    required bool controller,
    required Duration delay,
  }) async {
    if (controller) {
      await Future.delayed(delay);
      return true;
    } else {
      return false;
    }
  }

  Widget childWithDelay({
    required bool controller,
    required Duration delay,
    required Widget child,
  }) {
    return FutureBuilder<bool>(
      future: getMenuStatus(controller: controller, delay: delay),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox();
        } else if (snapshot.hasData && !snapshot.data!) {
          return child;
        } else {
          return const SizedBox();
        }
      },
    );
  }

  Widget getSideMenuList(Map<String, dynamic> option) {
    return Container(
      height: 50,
      padding: EdgeInsets.symmetric(
        horizontal: (!isSmallScreen) ? 25 : 16,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        border:
            option['border'] == true
                ? Border(
                  bottom: BorderSide(color: Theme.of(context).dividerColor),
                )
                : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (option['icon'] != null)
            Flexible(
              flex: 1,
              child: Icon(
                option['icon'],
                // color: Colors.white70,
              ),
            ),
          childWithDelay(
            controller: isSmallScreen ? false : menuHidden,
            delay: Duration(milliseconds: 300),
            child: Flexible(
              flex: 10,
              child: Padding(
                padding: EdgeInsets.only(
                  left: (option['icon'] == null) ? 0 : 16,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (option['label'] != null)
                      Flexible(
                        flex: 1,
                        child: Text(
                          option['label'],
                          style: TextStyle(
                            fontSize: (option['icon'] == null) ? 12 : 14,
                            height: 1.5, // Optional: adjust line height
                          ),
                          overflow:
                              TextOverflow
                                  .ellipsis, // Optional: handle overflow
                        ),
                      ),
                    if (option['badge'] != null)
                      Flexible(
                        flex: 1,
                        child: Text(
                          option['badge'] ?? '',
                          style: const TextStyle(height: 1.5),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget sideMenuList(mWidth, mHeight) {
    return ListView(
      children: [
        if (!isSmallScreen)
          Container(
            height: 65,
            margin: const EdgeInsets.fromLTRB(16, 16, 8, 8),
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
            child: _setBlur(
              blur: isBlur,
              child: TextButton(
                style: ButtonStyle(
                  shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15.0),
                    ),
                  ),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ComposeEmail(),
                    ),
                  );
                },
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Flexible(child: Icon(Icons.edit, size: 20)),
                      if (!menuHidden) const SizedBox(width: 10),
                      if (!menuHidden)
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
              isSmallScreen ? null : const EdgeInsets.fromLTRB(16, 8, 8, 16),
          width: mWidth,
          height: mHeight,
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
          child: _setBlur(
            blur: isBlur,
            child: ListView(
              scrollDirection: Axis.vertical,
              children: [
                if (isSmallScreen)
                  Row(
                    children: [
                      Flexible(
                        child: Container(
                          width: mWidth,
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
                  getSideMenuList(<String, dynamic>{
                    'width': mWidth,
                    'icon': Icons.all_inbox_rounded,
                    'label': 'All inboxes',
                    'badge': null,
                    'border': true,
                  }),
                getSideMenuList(<String, dynamic>{
                  'width': mWidth,
                  'icon': Icons.inbox,
                  'label': isSmallScreen ? 'Primary' : 'Inbox',
                  'badge': '99+',
                  'border': false,
                }),
                if (isSmallScreen)
                  getSideMenuList(<String, dynamic>{
                    'width': mWidth,
                    'icon': Icons.sell_rounded,
                    'label': 'Promotion',
                    'badge': '20',
                    'border': false,
                  }),
                if (isSmallScreen)
                  getSideMenuList(<String, dynamic>{
                    'width': mWidth,
                    'icon': Icons.group,
                    'label': 'Social',
                    'badge': '85',
                    'border': false,
                  }),
                if (isSmallScreen)
                  getSideMenuList(<String, dynamic>{
                    'width': mWidth,
                    'icon': null,
                    'label': 'All labels',
                    'badge': null,
                    'border': false,
                  }),
                getSideMenuList(<String, dynamic>{
                  'width': mWidth,
                  'icon': Icons.star_border,
                  'label': 'Stared',
                  'badge': '12',
                  'border': false,
                }),
                getSideMenuList(<String, dynamic>{
                  'width': mWidth,
                  'icon': Icons.access_time_rounded,
                  'label': 'Snoozed',
                  'badge': '12',
                  'border': false,
                }),
                getSideMenuList(<String, dynamic>{
                  'width': mWidth,
                  'icon': Icons.label_important_outline_rounded,
                  'label': 'Important',
                  'badge': '5',
                  'border': false,
                }),
                getSideMenuList(<String, dynamic>{
                  'width': mWidth,
                  'icon': Icons.send,
                  'label': 'Sent',
                  'badge': '5',
                  'border': false,
                }),
                getSideMenuList(<String, dynamic>{
                  'width': mWidth,
                  'icon': Icons.schedule_send,
                  'label': 'Scheduled',
                  'badge': '5',
                  'border': false,
                }),
                getSideMenuList(<String, dynamic>{
                  'width': mWidth,
                  'icon': Icons.outbox_rounded,
                  'label': 'Outbox',
                  'badge': '5',
                  'border': false,
                }),
                getSideMenuList(<String, dynamic>{
                  'width': mWidth,
                  'icon': Icons.drafts_outlined,
                  'label': 'Drafts',
                  'badge': '5',
                  'border': false,
                }),
                getSideMenuList(<String, dynamic>{
                  'width': mWidth,
                  'icon': Icons.mail_outline_rounded,
                  'label': 'All mail',
                  'badge': '5',
                  'border': false,
                }),
                getSideMenuList(<String, dynamic>{
                  'width': mWidth,
                  'icon': Icons.report_gmailerrorred_rounded,
                  'label': 'Spam',
                  'badge': '5',
                  'border': false,
                }),
                getSideMenuList(<String, dynamic>{
                  'width': mWidth,
                  'icon': Icons.delete_outline_rounded,
                  'label': 'Bin',
                  'badge': '5',
                  'border': true,
                }),
                getSideMenuList(<String, dynamic>{
                  'width': mWidth,
                  'icon': Icons.settings_rounded,
                  'label': 'Settings',
                  'badge': '5',
                  'border': false,
                }),
                getSideMenuList(<String, dynamic>{
                  'width': mWidth,
                  'icon': Icons.help_outline_outlined,
                  'label': 'Help & Feedback',
                  'badge': '5',
                  'border': true,
                }),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget sideMenu({
    required BuildContext context,
    required double width,
    required double height,
    required bool controller,
    required Widget child,
    double minWidth = 0,
    bool animated = true,
    Duration duration = const Duration(milliseconds: 300),
    bool mouseRegion = false,
    EdgeInsets padding = const EdgeInsets.all(0),
    onEnter,
    onExit,
  }) {
    var size = MediaQuery.of(context).size;
    Widget childWidget =
        mouseRegion
            ? MouseRegion(onEnter: onEnter, onExit: onExit, child: child)
            : child;
    return animated
        ? AnimatedContainer(
          padding: padding,
          width: controller ? width : minWidth,
          duration: duration,
          height: height,
          child: childWidget,
        )
        : Container(
          padding: padding,
          width: controller ? width : minWidth,
          child: childWidget,
        );
  }

  Widget settings(mWidth, mHeight, closeSideMenu) {
    return Container(
      margin: EdgeInsets.fromLTRB(0, 16, 16, 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor.withOpacity(opacity),
        borderRadius: BorderRadius.circular(15),
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
      child: _setBlur(
        blur: isBlur,
        child: ListView(
          children: [
            Container(
              height: 50,
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Theme.of(context).dividerColor),
                ),
              ),
              padding: const EdgeInsets.only(left: 16, right: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    flex: 8,
                    child: Text(
                      'Quick settings',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 16.0),
                    ),
                  ),
                  Flexible(
                    flex: 2,
                    child: IconButton(
                      onPressed: closeSideMenu,
                      icon: Icon(Icons.close, size: 20),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: mWidth,
              height: mHeight,
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: ListView(
                scrollDirection: Axis.vertical,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        flex: 6,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 0, 8),
                          child: Text(
                            'Theme',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 16.0),
                          ),
                        ),
                      ),
                      Flexible(
                        flex: 6,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(0, 0, 8, 8),
                          child: TextButton(
                            onPressed: () => {_showThemeDialog(context)},
                            child: Text(
                              "View All",
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 16.0),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Flexible(
                        child: childWithDelay(
                          controller: !settingCard,
                          delay: Duration(milliseconds: 300),
                          child: Center(
                            child: Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children:
                                  bgImgList.sublist(0, 9).map((img) {
                                    return GestureDetector(
                                      onTap: () async {
                                        await updateTheme(img);
                                      },
                                      child: Container(
                                        width: 80,
                                        height: 60,
                                        decoration: BoxDecoration(
                                          boxShadow:
                                              !isSmallScreen
                                                  ? [
                                                    BoxShadow(
                                                      color: Colors.black
                                                          .withOpacity(0.2),
                                                      spreadRadius: 1,
                                                      blurRadius: 5,
                                                      offset: const Offset(
                                                        1,
                                                        1,
                                                      ),
                                                    ),
                                                  ]
                                                  : null,
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          border:
                                              currentBackground == img
                                                  ? Border.all(
                                                    color: Colors.blue,
                                                    width: 3,
                                                  )
                                                  : null,
                                          image: DecorationImage(
                                            image: AssetImage(
                                              'assets/images/$img',
                                            ), // Corrected path
                                            fit:
                                                BoxFit
                                                    .cover, // Adjust how the image fits
                                          ),
                                        ),
                                        child:
                                            currentBackground == img
                                                ? SizedBox(
                                                  width: 80,
                                                  height: 60,
                                                  child: Center(
                                                    child: Icon(
                                                      Icons.check,
                                                      color: Colors.blue,
                                                    ),
                                                  ),
                                                )
                                                : null,
                                      ),
                                    );
                                  }).toList(), // Convert the iterable to a list
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 0, 8),
                          child: Text(
                            'Reading pane',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 16.0),
                          ),
                        ),
                      ),
                    ],
                  ),
                  ...setReadingPane(),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 0, 8),
                          child: Text(
                            'Inbox type',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 16.0),
                          ),
                        ),
                      ),
                    ],
                  ),
                  ...setInboxType(),
                ],
              ),
            ),
            Container(
              height: 50,
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: Theme.of(context).dividerColor),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ComposeEmail(),
                    ),
                  );
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(flex: 2, child: Icon(Icons.settings, size: 20)),
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
      ),
    );
  }

  Widget _setBlur({
    required bool blur,
    double sigmaX = 50.0,
    double sigmaY = 50.0,
    required Widget child,
  }) {
    return blur
        ? BackdropFilter(
          filter: ImageFilter.blur(sigmaX: sigmaX, sigmaY: sigmaY),
          child: child,
        )
        : child;
  }

  Future<void> updateTheme(String img) async {
    if (!bgImgList.sublist(0, 3).contains(img)) {
      setState(() {
        opacity = 0.7;
        isBlur = true;
        currentBackground = img;
      });
      if (await isImageDark('assets/images/$img')) {
        widget.setTheme(type: "dark");
      } else {
        widget.setTheme(type: "light");
      }
    } else {
      setState(() {
        opacity = 1;
        isBlur = false;
        currentBackground = img;
      });
      widget.setTheme(type: img.split(".")[0].split("-")[2].toLowerCase());
    }
  }

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
    height = size.height;
    width = size.width;
    isSmallScreen = width < 800;
    var brightness =
        MediaQuery.of(context).platformBrightness == Brightness.light
            ? Theme.of(context).brightness
            : MediaQuery.of(context).platformBrightness;

    return Scaffold(
      drawer: isSmallScreen ? Drawer(child: sideMenuList(width, height)) : null,
      body: Container(
        // padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 0 : 16.0),
        decoration: BoxDecoration(
          color: Theme.of(context).canvasColor,
          image:
              currentBackground != "" &&
                      !bgImgList.sublist(0, 3).contains(currentBackground)
                  ? DecorationImage(
                    image: AssetImage(
                      'assets/images/${currentBackground.replaceAll('thumbnail-', "")}',
                    ),
                    fit: BoxFit.cover, // Change this as needed
                  )
                  : null,
        ),
        child: SafeArea(
          child: Column(
            children: <Widget>[
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
                              onPressed: () {
                                setState(() {
                                  menuHidden = !menuHidden;
                                });
                              },
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
                              child: _setBlur(
                                blur: isBlur,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Theme.of(
                                      context,
                                    ).cardColor.withOpacity(opacity),
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
                                    padding:
                                        WidgetStateProperty.all<EdgeInsets>(
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
                                          isSmallScreen
                                              ? Icons.menu
                                              : Icons.search,
                                        ),
                                      ),
                                    ),
                                    trailing: <Widget>[
                                      Tooltip(
                                        message: 'Show Profile',
                                        child: IconButton(
                                          onPressed: () => _showDialog(context),
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
                                  onPressed: widget.toggleTheme,
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
                                  onPressed: () {
                                    setState(() {
                                      settingCard = !settingCard;
                                      if (settingCard) {
                                        menuHidden = true;
                                      }
                                    });
                                  },
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
                                    setState(() {
                                      menuHidden = !menuHidden;
                                    });
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
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!isSmallScreen)
                      sideMenu(
                        width: 300.0,
                        height: (height - 66),
                        context: context,
                        controller: !menuHidden,
                        minWidth: 100,
                        child: sideMenuList(300.0, (height - 179)),
                      ),
                    Expanded(
                      child: Container(
                        margin:
                            isSmallScreen
                                ? EdgeInsets.all(0)
                                : EdgeInsets.fromLTRB(8, 16, 16, 16),
                        decoration: BoxDecoration(
                          borderRadius:
                              isSmallScreen
                                  ? BorderRadius.only(
                                    topLeft: Radius.circular(15),
                                    topRight: Radius.circular(15),
                                  )
                                  : BorderRadius.circular(15),
                          color: Theme.of(
                            context,
                          ).cardColor.withOpacity(opacity),
                          boxShadow:
                              !isSmallScreen
                                  ? [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      spreadRadius: 1,
                                      blurRadius: 5,
                                      offset: const Offset(1, 1),
                                    ),
                                  ]
                                  : null,
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: _setBlur(
                          blur: isBlur,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (!isSmallScreen && !showMessageInFull)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    border: Border(
                                      bottom: BorderSide(
                                        color: Theme.of(context).dividerColor,
                                        width: 1,
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            margin: EdgeInsets.only(left: 8),
                                            height: 40,
                                            width: 30,
                                            child: Checkbox(
                                              value: false,
                                              onChanged: (val) {},
                                            ),
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
                                            icon: const Icon(
                                              Icons.arrow_drop_down_sharp,
                                            ),
                                          ),
                                          IconButton(
                                            onPressed: () {},
                                            icon: const Icon(
                                              Icons.refresh_sharp,
                                            ),
                                          ),
                                          IconButton(
                                            onPressed: () {},
                                            icon: const Icon(
                                              Icons.more_vert_rounded,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          const Text('1-50 of 12033'),
                                          IconButton(
                                            iconSize: 20,
                                            onPressed: () {},
                                            icon: const Icon(
                                              Icons.arrow_back_ios_new_rounded,
                                            ),
                                          ),
                                          IconButton(
                                            iconSize: 20,
                                            onPressed: () {},
                                            icon: const Icon(
                                              Icons.arrow_forward_ios_rounded,
                                            ),
                                          ),
                                          Container(
                                            margin: EdgeInsets.only(right: 8),
                                            child: IconButton(
                                              onPressed: () {
                                                setState(() {
                                                  largeLayoutBySplit =
                                                      !largeLayoutBySplit;
                                                  if (largeLayoutBySplit) {
                                                    settingCard = false;
                                                  }
                                                });
                                              },
                                              isSelected: largeLayoutBySplit,
                                              icon: const Icon(
                                                Icons.reorder_rounded,
                                              ),
                                              selectedIcon: const Icon(
                                                Icons.vertical_split_outlined,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              Expanded(
                                child: LayoutBuilder(
                                  builder: (context, constraints) {
                                    double parentWidth = constraints.maxWidth;
                                    return Row(
                                      children: [
                                        Flexible(
                                          child: AnimatedContainer(
                                            padding: EdgeInsets.symmetric(
                                              vertical: isSmallScreen ? 8 : 0.0,
                                            ),
                                            duration: const Duration(
                                              milliseconds: 300,
                                            ),
                                            width:
                                                !showMessageInFull
                                                    ? (!isSmallScreen &&
                                                            largeLayoutBySplit
                                                        ? splitListWidth
                                                        : parentWidth)
                                                    : 0,
                                            decoration:
                                                !isSmallScreen &&
                                                        largeLayoutBySplit
                                                    ? BoxDecoration(
                                                      border: Border(
                                                        right: BorderSide(
                                                          color:
                                                              Theme.of(
                                                                context,
                                                              ).dividerColor,
                                                        ),
                                                      ),
                                                    )
                                                    : null,
                                            child: FutureBuilder<List>(
                                              future: fetchEmails(),
                                              builder: (context, snapshot) {
                                                switch (snapshot
                                                    .connectionState) {
                                                  case ConnectionState.none:
                                                    return Center(
                                                      child: const Text(
                                                        'Refresh',
                                                      ),
                                                    );
                                                  case ConnectionState.waiting:
                                                    return Center(
                                                      child: const Text(
                                                        'Loading emails...',
                                                      ),
                                                    );
                                                  default:
                                                    if (snapshot.hasError) {
                                                      return Center(
                                                        child: Text(
                                                          'Error: ${snapshot.error}',
                                                        ),
                                                      );
                                                    } else {
                                                      return ListView(
                                                        children:
                                                            _showEmailList(
                                                              snapshot.data ??
                                                                  [],
                                                            ),
                                                      );
                                                    }
                                                }
                                              },
                                            ),
                                          ),
                                        ),
                                        if (!isSmallScreen &&
                                            (showMessageInFull ||
                                                largeLayoutBySplit)) // Only show if conditions are met
                                          AnimatedContainer(
                                            width:
                                                showMessageInFull
                                                    ? parentWidth
                                                    : parentWidth -
                                                        splitListWidth,
                                            height: double.infinity,
                                            clipBehavior: Clip.antiAlias,
                                            duration: const Duration(
                                              milliseconds: 300,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Theme.of(
                                                context,
                                              ).canvasColor.withOpacity(0),
                                              borderRadius: BorderRadius.only(
                                                bottomLeft: Radius.circular(
                                                  largeLayoutBySplit ? 0 : 10,
                                                ),
                                                bottomRight: Radius.circular(
                                                  10,
                                                ),
                                              ),
                                            ),
                                            child: ViewMail(
                                              message: viewMail,
                                              type: showMessageInFull,
                                              onBack: _updateMailVewLayout,
                                            ),
                                          ),
                                      ],
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    sideMenu(
                      width: 300.0,
                      height: (height - 66),
                      context: context,
                      controller: !isSmallScreen && settingCard,
                      child: settings(
                        300.0,
                        (height - 98),
                        () => {
                          setState(() {
                            settingCard = !settingCard;
                          }),
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
      floatingActionButton:
          (isSmallScreen)
              ? FloatingActionButton.extended(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ComposeEmail(),
                    ),
                  );
                },
                tooltip: 'Increment',
                label: const Text('Compose'),
                icon: const Icon(Icons.edit),
                backgroundColor: Theme.of(context).cardColor,
                foregroundColor: Theme.of(context).primaryColor,
              )
              : null,
    );
  }
}
