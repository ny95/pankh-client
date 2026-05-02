import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pankh/providers/common_provider.dart';
import 'package:pankh/providers/layout_provider.dart';
import 'package:pankh/providers/mail_provider.dart';
import 'package:pankh/widgets/blur.dart';
import 'package:pankh/widgets/header.dart';
import 'package:pankh/widgets/mail_container.dart';
import 'package:pankh/widgets/mail_nav.dart';
import 'package:provider/provider.dart';
import 'compose_email_screen.dart';
import '../providers/theme_provider.dart';
import '../utils/helpers.dart';
import '../widgets/side_menu.dart';
import '../widgets/settings_menu.dart';
import '../widgets/web_pointer_interceptor.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool menu = false;
  bool setting = false;
  bool _composeOpen = false;
  bool _composeMinimized = false;
  bool _composeMaximized = false;
  String _composeSubject = '';
  String _composeStatus = '';
  String? _composeInitialTo;
  String? _composeInitialCc;
  String? _composeInitialBcc;
  String? _composeInitialSubject;
  String? _composeInitialBody;
  String? _composeInitialMessageId;
  Timer? _composeStatusTimer;
  final ComposeEmailController _composeController = ComposeEmailController();
  final int _lastNotifiedCount = 0;
  String? _lastDraftMessageId;
  bool _sizeUpdateScheduled = false;
  final List<String> bgImgList = [
    "thumbnail-theme-system.jpg",
    "thumbnail-theme-light.jpg",
    "thumbnail-theme-dark.jpg",
  ];

  @override
  void dispose() {
    _composeStatusTimer?.cancel();
    super.dispose();
  }

  Future<void> _openHelp(BuildContext context, bool isSmallScreen) async {
    const supportEmail = 'support@pankh.app';
    final faqItems = [
      {
        'q': 'How do I add a new email account?',
        'a': 'Open Settings → Account and use “Add Account”.',
      },
      {
        'q': 'Why am I not receiving new emails?',
        'a': 'Check your IMAP server/port and connection security in Settings.',
      },
      {
        'q': 'How do I change the outgoing server?',
        'a': 'Settings → Account → Outgoing Server Setting.',
      },
      {
        'q': 'Can I enable app lock?',
        'a': 'Go to Settings → Security and enable App Lock.',
      },
      {
        'q': 'How do I change notification behavior?',
        'a': 'Settings → Notifications to toggle categories and quiet hours.',
      },
      {
        'q': 'How do I switch between accounts?',
        'a': 'Open Settings → Account and select a different account.',
      },
      {
        'q': 'How do I edit server settings?',
        'a': 'Go to Settings → Account → Incoming/Outgoing Server.',
      },
      {
        'q': 'What ports should I use for IMAP/SMTP?',
        'a': 'IMAP is typically 993 (SSL). SMTP is typically 465 or 587.',
      },
      {
        'q': 'How do I send an email?',
        'a': 'Tap the Compose button and fill in recipients and subject.',
      },
      {
        'q': 'How do I add attachments?',
        'a': 'In the composer, use the paperclip icon to add files.',
      },
      {
        'q': 'How do I save drafts?',
        'a': 'Drafts are saved automatically while you type.',
      },
      {
        'q': 'How do I search emails?',
        'a': 'Use the search bar at the top of the inbox.',
      },
      {
        'q': 'How do I mark emails as read/unread?',
        'a': 'Select the email and use the read/unread actions.',
      },
      {
        'q': 'How do I delete emails?',
        'a': 'Select emails and use the delete action.',
      },
      {
        'q': 'How do I configure quiet hours?',
        'a': 'Settings → Notifications → Quiet Hours.',
      },
      {
        'q': 'How do I set a signature?',
        'a': 'Settings → Account → General Settings → Signature text.',
      },
      {
        'q': 'Why is my connection marked insecure?',
        'a': 'Your server is configured without SSL/TLS.',
      },
    ];

    Widget content = ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ElevatedButton.icon(
          onPressed: () {
            final subject = 'Support Request';
            final body = 'Describe your issue here...';
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (context) => ComposeEmail(
                      initialTo: supportEmail,
                      initialSubject: subject,
                      initialBody: body,
                    ),
              ),
            );
          },
          icon: const Icon(Icons.support_agent),
          label: const Text('Raise a query'),
        ),
        const SizedBox(height: 20),
        const Text(
          'FAQs',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ...faqItems.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['q']!,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(item['a']!),
              ],
            ),
          ),
        ),
      ],
    );

    if (isSmallScreen) {
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Theme.of(context).cardColor,
        showDragHandle: true,
        builder:
            (context) => WebPointerInterceptor(
              child: SafeArea(
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.9,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Expanded(
                              child: Text(
                                'Help & Feedback',
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ],
                        ),
                      ),
                      Expanded(child: content),
                    ],
                  ),
                ),
              ),
            ),
      );
    } else {
      await showDialog(
        context: context,
        builder:
            (context) => WebPointerInterceptor(
              child: AlertDialog(
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Text(
                        'Help & Feedback',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                content: SizedBox(width: 520, height: 420, child: content),
              ),
            ),
      );
    }
  }

  void _flashComposeStatus(String message) {
    _composeStatusTimer?.cancel();
    setState(() {
      _composeStatus = message;
    });
    _composeStatusTimer = Timer(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() {
        _composeStatus = '';
      });
    });
  }

  Future<bool> _saveDraftIfNeeded({required bool showSnackOnClose}) async {
    final messenger = ScaffoldMessenger.of(context);
    final mailProvider = Provider.of<MailProvider>(context, listen: false);
    if (!_composeController.hasDraftContent) return false;
    final saved = await _composeController.saveDraftNow(forceServer: true);
    if (!saved) return false;
    if (!mounted) return false;
    _flashComposeStatus('Saved in Drafts');
    if (showSnackOnClose) {
      messenger.showSnackBar(const SnackBar(content: Text('Saved to Drafts')));
    }
    final selectedName = mailProvider.selectedFolder?.name.toLowerCase() ?? '';
    if (selectedName.contains('draft')) {
      await mailProvider.refreshLatest();
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final commonProvider = Provider.of<CommonProvider>(context);
    final mailProvider = Provider.of<MailProvider>(context);
    final layoutProvider = Provider.of<LayoutProvider>(context);
    bool panePreviewOff = layoutProvider.layout == "pane_preview_off";

    var size = MediaQuery.of(context).size;
    bool isSmallScreen = size.width < 800;
    final draftToOpen = mailProvider.takeDraftToCompose();
    if (draftToOpen != null && !isSmallScreen) {
      final messageId = draftToOpen.getHeaderValue('Message-ID') ?? '';
      if (_lastDraftMessageId == messageId && _composeOpen) {
        // Already opened this draft in the current session.
      } else {
        _lastDraftMessageId = messageId;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          final to = draftToOpen.to?.map((a) => a.email).join(', ') ?? '';
          final cc = draftToOpen.cc?.map((a) => a.email).join(', ') ?? '';
          final bcc = draftToOpen.bcc?.map((a) => a.email).join(', ') ?? '';
          final subject = draftToOpen.decodeSubject() ?? '';
          final body =
              draftToOpen.decodeTextPlainPart() ??
              draftToOpen.decodeTextHtmlPart() ??
              '';
          setState(() {
            _composeOpen = true;
            _composeMinimized = false;
            _composeMaximized = false;
            _composeSubject = subject;
            _composeStatus = '';
            _composeInitialTo = to;
            _composeInitialCc = cc;
            _composeInitialBcc = bcc;
            _composeInitialSubject = subject;
            _composeInitialBody = body;
            _composeInitialMessageId = messageId;
          });
        });
      }
    }
    if (commonProvider.isSmallScreen != isSmallScreen) {
      if (!_sizeUpdateScheduled) {
        _sizeUpdateScheduled = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _sizeUpdateScheduled = false;
          commonProvider.setIsSmallScreen(isSmallScreen: isSmallScreen);
          if (isSmallScreen && commonProvider.isMailView) {
            commonProvider.setIsMailView(isMailView: false);
          }
        });
      }
    }
    // if (mailProvider.newMailCount > 0 &&
    //     mailProvider.newMailCount != _lastNotifiedCount &&
    //     mounted) {
    //   _lastNotifiedCount = mailProvider.newMailCount;
    //   WidgetsBinding.instance.addPostFrameCallback((_) {
    //     if (!mounted) return;
    //     ScaffoldMessenger.of(context).showSnackBar(
    //       SnackBar(
    //         content: Text(
    //           'You have ${mailProvider.newMailCount} new email(s).',
    //         ),
    //         action: SnackBarAction(
    //           label: 'Refresh',
    //           onPressed: () {
    //             mailProvider.refreshNewer();
    //             mailProvider.clearNewMailCount();
    //           },
    //         ),
    //       ),
    //     );
    //   });
    // }

    return Builder(
      builder:
          (context) => Scaffold(
            key: _scaffoldKey,
            drawer:
                isSmallScreen
                    ? Drawer(
                      child: SideMenuList(
                        width: size.width,
                        height: size.height,
                        closeDrawerOnTap: true,
                        onCompose: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ComposeEmail(),
                            ),
                          );
                        },
                        onOpenSettings: () {
                          _scaffoldKey.currentState?.openEndDrawer();
                        },
                        onOpenHelp: () => _openHelp(context, true),
                      ),
                    )
                    : null,
            endDrawer:
                isSmallScreen
                    ? Drawer(
                      child: SettingsMenu(
                        hidden: false,
                        onClose: () => Navigator.pop(context),
                      ),
                    )
                    : null,
            floatingActionButton:
                isSmallScreen
                    ? FloatingActionButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ComposeEmail(),
                          ),
                        );
                      },
                      child: const Icon(Icons.edit),
                    )
                    : null,
            body: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).canvasColor,
                image: getBackgroundDecoration(context, themeProvider),
              ),
              child: SafeArea(
                child: Stack(
                  children: [
                    Column(
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
                          onHelp: () => _openHelp(context, isSmallScreen),
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
                                    onCompose: () {
                                      setState(() {
                                        _composeOpen = true;
                                        _composeMinimized = false;
                                        _composeSubject = '';
                                        _composeStatus = '';
                                        _composeInitialTo = null;
                                        _composeInitialCc = null;
                                        _composeInitialBcc = null;
                                        _composeInitialSubject = null;
                                        _composeInitialBody = null;
                                        _composeInitialMessageId = null;
                                      });
                                    },
                                    onOpenHelp: () => _openHelp(context, false),
                                  ),
                                ),
                              Expanded(
                                child: Container(
                                  margin: EdgeInsets.all(
                                    isSmallScreen ? 0 : 16,
                                  ),
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
                                  !isSmallScreen) MailNav(),
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
                    if (!isSmallScreen && _composeOpen)
                      _ComposeWindow(
                        size: size,
                        minimized: _composeMinimized,
                        maximized: _composeMaximized,
                        subject: _composeSubject,
                        onClose: () {
                          unawaited(_saveDraftIfNeeded(showSnackOnClose: true));
                          setState(() {
                            _composeOpen = false;
                            _composeMinimized = false;
                            _composeMaximized = false;
                            _composeSubject = '';
                            _composeStatus = '';
                            _composeInitialTo = null;
                            _composeInitialCc = null;
                            _composeInitialBcc = null;
                            _composeInitialSubject = null;
                            _composeInitialBody = null;
                            _composeInitialMessageId = null;
                          });
                        },
                        onMinimize: () {
                          unawaited(
                            _saveDraftIfNeeded(showSnackOnClose: false),
                          );
                          setState(() {
                            _composeMinimized = true;
                          });
                        },
                        onToggleMaximize: () {
                          setState(() {
                            _composeMaximized = !_composeMaximized;
                            _composeMinimized = false;
                          });
                        },
                        onRestore: () {
                          setState(() {
                            _composeMinimized = false;
                          });
                        },
                        onSubjectChanged: (value) {
                          setState(() {
                            _composeSubject = value.trim();
                          });
                        },
                        statusMessage: _composeStatus,
                        controller: _composeController,
                        initialTo: _composeInitialTo,
                        initialCc: _composeInitialCc,
                        initialBcc: _composeInitialBcc,
                        initialSubject: _composeInitialSubject,
                        initialBody: _composeInitialBody,
                        initialMessageId: _composeInitialMessageId,
                      ),
                  ],
                ),
              ),
            ),
          ),
    );
  }
}

class _ComposeWindow extends StatelessWidget {
  final Size size;
  final bool minimized;
  final bool maximized;
  final String subject;
  final String statusMessage;
  final ComposeEmailController controller;
  final String? initialTo;
  final String? initialCc;
  final String? initialBcc;
  final String? initialSubject;
  final String? initialBody;
  final String? initialMessageId;
  final VoidCallback onClose;
  final VoidCallback onMinimize;
  final VoidCallback onToggleMaximize;
  final VoidCallback onRestore;
  final ValueChanged<String> onSubjectChanged;

  const _ComposeWindow({
    required this.size,
    required this.minimized,
    required this.maximized,
    required this.subject,
    required this.statusMessage,
    required this.controller,
    this.initialTo,
    this.initialCc,
    this.initialBcc,
    this.initialSubject,
    this.initialBody,
    this.initialMessageId,
    required this.onClose,
    required this.onMinimize,
    required this.onToggleMaximize,
    required this.onRestore,
    required this.onSubjectChanged,
  });

  @override
  Widget build(BuildContext context) {
    const margin = 16.0;
    final maxWidth = size.width - (margin * 2);
    final maxHeight = size.height - (margin * 2);
    final normalWidth = maxWidth.clamp(420.0, 720.0);
    final normalHeight = maxHeight.clamp(320.0, 640.0);

    final headerTitle =
        statusMessage.isNotEmpty
            ? statusMessage
            : (subject.isNotEmpty ? subject : 'New Message');
    final headerContent = Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              headerTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          IconButton(
            tooltip: 'Minimize',
            iconSize: 18,
            onPressed: onMinimize,
            icon: const Icon(Icons.remove_rounded),
          ),
          IconButton(
            tooltip: maximized ? 'Restore' : 'Maximize',
            iconSize: 18,
            onPressed: onToggleMaximize,
            icon: Icon(
              maximized
                  ? Icons.close_fullscreen_rounded
                  : Icons.open_in_full_rounded,
            ),
          ),
          IconButton(
            tooltip: 'Close',
            iconSize: 18,
            onPressed: onClose,
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
    );

    final header =
        minimized
            ? InkWell(onTap: onRestore, child: headerContent)
            : headerContent;

    final compose = ComposeEmail(
      key: ValueKey(initialMessageId ?? 'new_message'),
      embedded: true,
      onSubjectChanged: onSubjectChanged,
      controller: controller,
      initialTo: initialTo,
      initialCc: initialCc,
      initialBcc: initialBcc,
      initialSubject: initialSubject,
      initialBody: initialBody,
      initialMessageId: initialMessageId,
    );

    final content = Stack(
      children: [
        Column(children: [header, const Expanded(child: SizedBox.shrink())]),
        Positioned.fill(
          top: 40,
          child: Offstage(offstage: minimized, child: compose),
        ),
      ],
    );

    final window = WebPointerInterceptor(
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: SizedBox(
          width: minimized ? 400 : (maximized ? maxWidth : normalWidth),
          height: minimized ? 60 : (maximized ? maxHeight : normalHeight),
          child: content,
        ),
      ),
    );

    if (maximized) {
      return Positioned(
        left: margin,
        right: margin,
        top: margin,
        bottom: margin,
        child: window,
      );
    }

    return Positioned(right: margin, bottom: margin, child: window);
  }
}
