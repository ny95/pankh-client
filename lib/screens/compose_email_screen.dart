import 'dart:async';

import 'package:flutter/material.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:provider/provider.dart';
import '../services/backend_api_service.dart';
import '../services/draft_service.dart';
import '../providers/auth_provider.dart';
import '../providers/mail_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/web_pointer_interceptor.dart';

class ComposeEmailController {
  Future<bool> Function({bool forceServer})? _saveDraft;
  bool Function()? _hasContent;

  bool get hasDraftContent => _hasContent?.call() ?? false;

  Future<bool> saveDraftNow({bool forceServer = false}) async {
    if (_saveDraft == null) return false;
    return _saveDraft!.call(forceServer: forceServer);
  }

  void _bind({
    required Future<bool> Function({bool forceServer}) saveDraft,
    required bool Function() hasContent,
  }) {
    _saveDraft = saveDraft;
    _hasContent = hasContent;
  }

  void _unbind() {
    _saveDraft = null;
    _hasContent = null;
  }
}

class ComposeEmail extends StatefulWidget {
  final bool embedded;
  final ValueChanged<String>? onSubjectChanged;
  final ComposeEmailController? controller;
  final String? initialTo;
  final String? initialCc;
  final String? initialBcc;
  final String? initialSubject;
  final String? initialBody;
  final String? initialMessageId;
  const ComposeEmail({
    super.key,
    this.embedded = false,
    this.onSubjectChanged,
    this.controller,
    this.initialTo,
    this.initialCc,
    this.initialBcc,
    this.initialSubject,
    this.initialBody,
    this.initialMessageId,
  });
  @override
  State<ComposeEmail> createState() => _ComposeEmail();
}

class _ComposeEmail extends State<ComposeEmail> {
  late bool showCc = false;
  late bool showBcc = false;
  late bool isSmallScreen = false;
  late double width;
  late double height;
  String? username;
  late String to = '';
  final Map<String, dynamic> option = {
    'cc': '',
    'bcc': '',
  }; // Use a map for options
  String? selectedValue;
  Map<String, dynamic> alertMessage = {};
  bool _isLoading = false;
  bool _showFormatBar = false;
  late final quill.QuillController _quillController;
  final FocusNode _editorFocus = FocusNode();
  final FocusNode _quillFocusNode = FocusNode();
  final ScrollController _quillScrollController = ScrollController();
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _toController = TextEditingController();
  final TextEditingController _ccController = TextEditingController();
  final TextEditingController _bccController = TextEditingController();
  Timer? _draftDebounce;
  late final String _draftId;
  late final String _draftMessageId;
  DateTime? _lastServerDraftSave;
  final List<String> _attachments = [];
  String? _lastDraftFingerprint;

  @override
  void initState() {
    super.initState();
    _draftId = DateTime.now().millisecondsSinceEpoch.toString();
    _draftMessageId =
        widget.initialMessageId?.trim().isNotEmpty == true
            ? widget.initialMessageId!.trim()
            : '<draft-$_draftId@local>';
    to = widget.initialTo?.trim() ?? '';
    option['cc'] = widget.initialCc?.trim() ?? '';
    option['bcc'] = widget.initialBcc?.trim() ?? '';
    option['subject'] = widget.initialSubject?.trim() ?? '';
    option['body'] = widget.initialBody?.trim() ?? '';
    final settings = context.read<SettingsProvider>();
    option['isHtml'] = settings.composeHtml;
    _toController.text = to;
    _ccController.text = option['cc'];
    _bccController.text = option['bcc'];
    _subjectController.text = option['subject'];
    final initialBody =
        settings.autoQuote && (option['body'] ?? '').toString().isNotEmpty
            ? _quoteText(option['body'] ?? '')
            : option['body'] ?? '';
    _quillController = quill.QuillController(
      document: quill.Document()..insert(0, initialBody),
      selection: const TextSelection.collapsed(offset: 0),
    );
    // Only schedule the save — body extraction happens lazily inside _saveDraft
    _quillController.addListener(_scheduleDraftSave);
    widget.controller?._bind(
      saveDraft: saveDraftNow,
      hasContent: _hasDraftContent,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onSubjectChanged?.call(option['subject']?.toString() ?? '');
    });
  }

  @override
  void dispose() {
    _draftDebounce?.cancel();
    _editorFocus.dispose();
    _quillController.dispose();
    _subjectController.dispose();
    _toController.dispose();
    _ccController.dispose();
    _bccController.dispose();
    _quillFocusNode.dispose();
    _quillScrollController.dispose();
    widget.controller?._unbind();
    super.dispose();
  }

  String _quoteText(String text) {
    final lines = text.toString().trimRight().split('\n');
    return lines.map((line) => '> $line').join('\n');
  }

  String _toSimpleHtml(String text) {
    final escaped =
        text
            .replaceAll('&', '&amp;')
            .replaceAll('<', '&lt;')
            .replaceAll('>', '&gt;')
            .replaceAll('"', '&quot;')
            .replaceAll("'", '&#39;');
    return '<p>${escaped.replaceAll('\n', '<br>')}</p>';
  }

  Future<void> _sendMail(AuthProvider authProvider) async {
    final mailProvider = Provider.of<MailProvider>(context, listen: false);
    if (to == '' && option['cc'] == '' && option['bcc'] == '') {
      setState(() {
        alertMessage['content'] = 'Add at least one recipient.';
      });
      return;
    }
    if (username == null || username!.isEmpty) {
      setState(() {
        alertMessage['content'] = 'Login required to send email.';
      });
      return;
    }

    final toList = to
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    final ccList = (option['cc'] ?? '')
        .toString()
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    final bccList = (option['bcc'] ?? '')
        .toString()
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    if (toList.isEmpty && ccList.isEmpty && bccList.isEmpty) {
      setState(() {
        alertMessage['content'] = 'Add at least one recipient.';
      });
      return;
    }

    setState(() {
      option['username'] = username;
      _isLoading = true;
    });

    String status;
    try {
      final body = option['body']?.toString() ?? '';
      final isHtml = option['isHtml'] == true;
      if (authProvider.isOAuthAccount &&
          authProvider.serverSessionToken != null &&
          authProvider.oauthProvider != null) {
        await BackendApiService.sendProviderEmail(
          sessionToken: authProvider.serverSessionToken!,
          provider: authProvider.oauthProvider!,
          to: toList,
          cc: ccList,
          bcc: bccList,
          subject: option['subject'] ?? '',
          text: isHtml ? null : body,
          html: isHtml ? body : null,
          attachmentPaths: _attachments,
        );
      } else {
        final account = authProvider.activeAccount;
        final password = authProvider.password;
        if (account == null || password == null || password.isEmpty) {
          throw Exception('SMTP credentials missing.');
        }
        await BackendApiService.sendSmtpEmail(
          host: account.smtpHost,
          port: account.smtpPort,
          secure: account.smtpSecure,
          username: account.smtpUserName,
          password: password,
          from: username!,
          to: toList,
          cc: ccList,
          bcc: bccList,
          subject: option['subject'] ?? '',
          text: isHtml ? null : body,
          html: isHtml ? body : null,
          attachmentPaths: _attachments,
        );
      }
      status = 'Message sent successfully!';
      await _deleteDraft();
    } on UnauthorizedRequestException {
      mailProvider.markOAuthSessionExpired(
        'Your login session expired. Sign in again before sending mail.',
      );
      status = 'Session expired. Sign in again to continue.';
    } catch (_) {
      status = 'Failed to send the message!';
    }

    if (!mounted) return;
    setState(() {
      alertMessage['title'] = status;
      _isLoading = false;
    });
  }

  void _showInfo(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _scheduleDraftSave() {
    _draftDebounce?.cancel();
    _draftDebounce = Timer(const Duration(milliseconds: 500), () async {
      await _saveDraft();
    });
  }

  bool _hasDraftContent() {
    return to.trim().isNotEmpty ||
        (option['cc'] ?? '').toString().trim().isNotEmpty ||
        (option['bcc'] ?? '').toString().trim().isNotEmpty ||
        (option['subject'] ?? '').toString().trim().isNotEmpty ||
        (option['body'] ?? '').toString().trim().isNotEmpty;
  }

  Future<bool> saveDraftNow({bool forceServer = false}) async {
    if (!_hasDraftContent()) return false;
    if (forceServer) {
      _lastServerDraftSave = null;
    }
    await _saveDraft();
    return true;
  }

  Future<void> _saveDraft() async {
    final accountKey = username ?? 'local';
    // Compute body lazily here rather than on every keystroke in the listener
    final settings = context.read<SettingsProvider>();
    final isHtml = settings.composeHtml;
    final plain = _quillController.document.toPlainText().trimRight();
    final body = isHtml ? _toSimpleHtml(plain) : plain;
    option['isHtml'] = isHtml;
    option['body'] = body;

    if ((to.isEmpty) &&
        (option['cc'] ?? '').toString().trim().isEmpty &&
        (option['bcc'] ?? '').toString().trim().isEmpty &&
        (option['subject'] ?? '').toString().trim().isEmpty &&
        body.trim().isEmpty) {
      return;
    }
    final draft = <String, dynamic>{
      'id': _draftId,
      'messageId': _draftMessageId,
      'updatedAt': DateTime.now().toIso8601String(),
      'to': to,
      'cc': option['cc'] ?? '',
      'bcc': option['bcc'] ?? '',
      'subject': option['subject'] ?? '',
      'body': body,
      'attachments': List<String>.from(_attachments),
    };
    final fingerprint = [
      draft['to'],
      draft['cc'],
      draft['bcc'],
      draft['subject'],
      draft['body'],
      (draft['attachments'] as List).join(','),
    ].join('|');
    if (_lastDraftFingerprint == fingerprint) return;
    await DraftService.saveDraft(accountKey: accountKey, draft: draft);
    _lastDraftFingerprint = fingerprint;
    await _saveDraftToServer(draft);
  }

  bool _subjectCallbackScheduled = false;

  @override
  void didUpdateWidget(covariant ComposeEmail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_subjectCallbackScheduled) {
      _subjectCallbackScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _subjectCallbackScheduled = false;
        widget.onSubjectChanged?.call(option['subject']?.toString() ?? '');
      });
    }
  }

  Future<void> _deleteDraft() async {
    final accountKey = username ?? 'local';
    await DraftService.deleteDraft(accountKey: accountKey, draftId: _draftId);
    await _deleteDraftFromServer();
  }

  Future<void> _saveDraftToServer(Map<String, dynamic> draft) async {
    final mailProvider = Provider.of<MailProvider>(context, listen: false);
    if (!mailProvider.hasAuth) return;
    final now = DateTime.now();
    if (_lastServerDraftSave != null &&
        now.difference(_lastServerDraftSave!) <
            const Duration(seconds: 8)) {
      return;
    }
    _lastServerDraftSave = now;
    await mailProvider.saveDraftToServer(
      messageId: _draftMessageId,
      to: draft['to']?.toString() ?? '',
      cc: draft['cc']?.toString() ?? '',
      bcc: draft['bcc']?.toString() ?? '',
      subject: draft['subject']?.toString() ?? '',
      body: draft['body']?.toString() ?? '',
    );
  }

  Future<void> _deleteDraftFromServer() async {
    final mailProvider = Provider.of<MailProvider>(context, listen: false);
    if (!mailProvider.hasAuth) return;
    await mailProvider.deleteDraftFromServer(_draftMessageId);
  }

  Future<void> _pickAttachments() async {
    final files = await openFiles();
    if (files.isEmpty) return;
    setState(() {
      _attachments.addAll(files.map((f) => f.path));
      option['attachments'] = List<String>.from(_attachments);
    });
    _scheduleDraftSave();
  }

  Future<void> _pickPhoto() async {
    const group = XTypeGroup(
      label: 'images',
      extensions: ['png', 'jpg', 'jpeg', 'gif', 'webp'],
    );
    final file = await openFile(acceptedTypeGroups: [group]);
    if (file == null) return;
    setState(() {
      _attachments.add(file.path);
      option['attachments'] = List<String>.from(_attachments);
    });
    _scheduleDraftSave();
  }

  Future<void> _insertLink() async {
    final urlController = TextEditingController();
    final textController = TextEditingController();
    try {
      final selection = await showDialog<Map<String, String>?>(
        context: context,
        builder: (context) => WebPointerInterceptor(
          child: AlertDialog(
            title: const Text('Insert link'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: urlController,
                  decoration: const InputDecoration(labelText: 'URL'),
                ),
                TextField(
                  controller: textController,
                  decoration: const InputDecoration(
                    labelText: 'Text (optional)',
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context, {
                    'url': urlController.text.trim(),
                    'text': textController.text.trim(),
                  });
                },
                child: const Text('Insert'),
              ),
            ],
          ),
        ),
      );
      if (selection == null) return;
      final url = selection['url'] ?? '';
      if (url.isEmpty) return;
      final text = selection['text'] ?? '';
      final current = _quillController.selection;
      final length = current.end - current.start;
      if (length > 0) {
        _quillController.formatSelection(quill.LinkAttribute(url));
      } else {
        final insertText = text.isEmpty ? url : text;
        _quillController.replaceText(
          current.start,
          0,
          insertText,
          TextSelection.collapsed(offset: current.start + insertText.length),
        );
        _quillController.formatText(
          current.start,
          insertText.length,
          quill.LinkAttribute(url),
        );
      }
    } finally {
      urlController.dispose();
      textController.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    height = size.height;
    width = size.width;
    isSmallScreen = width < 800;
    username = context.select<AuthProvider, String?>((p) => p.email);
    final settings = context.watch<SettingsProvider>();
    final allowFormatting = settings.composeHtml;
    final fontFamily = settings.defaultFont;
    final showHeader = !widget.embedded;
    final body = Stack(
      children: [
        Column(
          children: [
            if (showHeader && !isSmallScreen)
              Container(
                padding: const EdgeInsets.fromLTRB(20, 4, 12, 4),
                color: Colors.grey.shade400,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('New mail'),
                    Row(
                      children: [
                        IconButton(
                          onPressed: () {},
                          icon: const Icon(Icons.open_in_full_rounded),
                          iconSize: 16,
                          selectedIcon: const Icon(
                            Icons.close_fullscreen_rounded,
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          iconSize: 16,
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            if (showHeader && isSmallScreen)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8.0,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                        IconButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          icon: const Icon(Icons.arrow_back_rounded),
                        ),
                        Row(
                          children: [
                            IconButton(
                              onPressed: () {
                                showMenu(
                                  context: context,
                                  color: const Color(0xFF232923),
                                  position: const RelativeRect.fromLTRB(
                                    1,
                                    20,
                                    0,
                                    0,
                                  ), // Adjust position as needed
                                  items: [
                                    const PopupMenuItem(
                                      value: 1,
                                      child: Text(
                                        'Attache file',
                                        style: TextStyle(color: Colors.white70),
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 2,
                                      child: Text(
                                        'Insert From Drive',
                                        style: TextStyle(color: Colors.white70),
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 3,
                                      child: Text(
                                        'Insert photo',
                                        style: TextStyle(color: Colors.white70),
                                      ),
                                    ),
                                  ],
                                ).then((value) {
                                  if (value != null) {
                                    debugPrint('Selected: $value');
                                  }
                                });
                              },
                              color: Colors.white70,
                              icon: const Icon(Icons.attachment_rounded),
                            ),
                            IconButton(
                              onPressed: () async {
                                await _sendMail(context.read<AuthProvider>());
                              },
                              color: Colors.white70,
                              icon: const Icon(Icons.send_rounded),
                            ),
                            IconButton(
                              onPressed: () {
                                showMenu(
                                  context: context,
                                  color: const Color(0xFF232923),
                                  position: const RelativeRect.fromLTRB(
                                    1,
                                    20,
                                    0,
                                    0,
                                  ), // Adjust position as needed
                                  items: [
                                    const PopupMenuItem(
                                      value: 1,
                                      child: Text(
                                        'Schedule Send',
                                        style: TextStyle(color: Colors.white70),
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 2,
                                      child: Text(
                                        'Add from Contact',
                                        style: TextStyle(color: Colors.white70),
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 3,
                                      child: Text(
                                        'Confidential mode',
                                        style: TextStyle(color: Colors.white70),
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 3,
                                      child: Text(
                                        'Save draft',
                                        style: TextStyle(color: Colors.white70),
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 3,
                                      child: Text(
                                        'Discard',
                                        style: TextStyle(color: Colors.white70),
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 3,
                                      child: Text(
                                        'Settings',
                                        style: TextStyle(color: Colors.white70),
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 3,
                                      child: Text(
                                        'Help and Feedback',
                                        style: TextStyle(color: Colors.white70),
                                      ),
                                    ),
                                  ],
                                ).then((value) {
                                  if (value != null) {
                                    debugPrint('Selected: $value');
                                  }
                                });
                              },
                              color: Colors.white70,
                              icon: const Icon(Icons.more_vert_rounded),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                if (isSmallScreen)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Colors.grey.shade600),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Text('From'),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Text(
                            username ?? 'Not logged in',
                            style: const TextStyle(color: Colors.white70),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.only(left: 20, right: 12),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.grey.shade600),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Text('To'),
                      const SizedBox(width: 20),
                      Expanded(
                        child: TextField(
                          controller: _toController,
                          onChanged: (value) {
                            to = value;
                            option['to'] = value;
                            _scheduleDraftSave();
                          },
                          onEditingComplete: _scheduleDraftSave,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintStyle: TextStyle(color: Colors.grey),
                          ),
                        ),
                      ),
                      if (!showCc && !showBcc && isSmallScreen)
                        IconButton(
                          onPressed: () {
                            setState(() {
                              showCc = true;
                              showBcc = true;
                            });
                          },
                          icon: const Icon(Icons.keyboard_arrow_down_rounded),
                          color: Colors.grey[700],
                        ),
                      if (!showCc &&
                          !isSmallScreen &&
                          option['cc'].trim() == '')
                        TextButton(
                          onPressed: () {
                            setState(() {
                              showCc = true;
                            });
                          },
                          child: const Text('Cc'),
                        ),
                      if (!showBcc &&
                          !isSmallScreen &&
                          option['bcc'].trim() == '')
                        TextButton(
                          onPressed: () {
                            setState(() {
                              showBcc = true;
                            });
                          },
                          child: const Text('Bcc'),
                        ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    AnimatedContainer(
                      height: (showCc || option['cc'] != '') ? 49 : 0,
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Colors.grey.shade600),
                        ),
                      ),
                      child: Row(
                        children:
                            (showCc || option['cc'] != '')
                                ? [
                                  const Text('CC'),
                                  const SizedBox(width: 20),
                                  Expanded(
                                    child: TextField(
                                      controller: _ccController,
                                      onChanged: (value) {
                                        option['cc'] = value;
                                        _scheduleDraftSave();
                                      },
                                      onEditingComplete: _scheduleDraftSave,
                                      decoration: const InputDecoration(
                                        border: InputBorder.none,
                                        hintStyle: TextStyle(
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ),
                                  ),
                                ]
                                : [],
                      ),
                    ),
                    AnimatedContainer(
                      height: (showBcc || option['bcc'] != '') ? 49 : 0,
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Colors.grey.shade600),
                        ),
                      ),
                      child: Row(
                        children:
                            (showBcc || option['bcc'] != '')
                                ? [
                                  const Text('Bcc'),
                                  const SizedBox(width: 20),
                                  Expanded(
                                    child: TextField(
                                      controller: _bccController,
                                      onChanged: (value) {
                                        option['bcc'] = value;
                                        _scheduleDraftSave();
                                      },
                                      onEditingComplete: _scheduleDraftSave,
                                      decoration: const InputDecoration(
                                        border: InputBorder.none, //
                                        hintStyle: TextStyle(
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ),
                                  ),
                                ]
                                : [],
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.grey.shade600),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _subjectController,
                          onChanged: (value) {
                            option['subject'] = value;
                            _scheduleDraftSave();
                            widget.onSubjectChanged?.call(value);
                          },
                          onTap: () {
                            setState(() {
                              showCc = false;
                              showBcc = false;
                            });
                          },
                          maxLines: null,
                          decoration: const InputDecoration(
                            border: InputBorder.none, //
                            hintText: 'Subject',
                            hintStyle: TextStyle(color: Colors.grey),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isSmallScreen && _showFormatBar && allowFormatting)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: DefaultTextStyle(
                      style: TextStyle(
                        fontFamily: fontFamily,
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                      ),
                      child: quill.QuillSimpleToolbar(
                        controller: _quillController,
                        config: const quill.QuillSimpleToolbarConfig(
                          multiRowsDisplay: false,
                          showCodeBlock: false,
                          showInlineCode: false,
                          showFontFamily: false,
                          showFontSize: false,
                          showSearchButton: false,
                        ),
                      ),
                    ),
                  ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: DefaultTextStyle(
                      style: TextStyle(
                        fontFamily: fontFamily,
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                      ),
                      child: quill.QuillEditor(
                        controller: _quillController,
                        focusNode: _quillFocusNode,
                        scrollController: _quillScrollController,
                        config: const quill.QuillEditorConfig(
                          placeholder: 'Compose email',
                          autoFocus: false,
                        ),
                      ),
                    ),
                  ),
                ),
                if (!isSmallScreen)
                  Container(
                    height: 56,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(color: Colors.grey.shade600),
                      ),
                    ),
                    child: Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: () async {
                            await _sendMail(context.read<AuthProvider>());
                          },
                          icon: const Icon(Icons.send_rounded),
                          label: const Text('Send'),
                        ),
                        const SizedBox(width: 8),
                        _ComposeAction(
                          icon: Icons.format_color_text_outlined,
                          tooltip: 'Formatting',
                          onPressed:
                              allowFormatting
                                  ? () {
                                    setState(() {
                                      _showFormatBar = !_showFormatBar;
                                    });
                                  }
                                  : null,
                        ),
                        _ComposeAction(
                          icon: Icons.attach_file_rounded,
                          tooltip: 'Attach',
                          onPressed: _pickAttachments,
                        ),
                        _ComposeAction(
                          icon: Icons.link_rounded,
                          tooltip: 'Insert link',
                          onPressed: _insertLink,
                        ),
                        _ComposeAction(
                          icon: Icons.emoji_emotions_outlined,
                          tooltip: 'Emoji',
                          onPressed: () => _showInfo('Emoji not implemented.'),
                        ),
                        _ComposeAction(
                          icon: Icons.change_history_outlined,
                          tooltip: 'Drive',
                          onPressed: () => _showInfo('Drive not implemented.'),
                        ),
                        _ComposeAction(
                          icon: Icons.image_outlined,
                          tooltip: 'Insert photo',
                          onPressed: _pickPhoto,
                        ),
                        _ComposeAction(
                          icon: Icons.lock_outline,
                          tooltip: 'Confidential',
                          onPressed: () => _showInfo('Confidential not implemented.'),
                        ),
                        _ComposeAction(
                          icon: Icons.edit_outlined,
                          tooltip: 'Signature',
                          onPressed: () => _showInfo('Signature not implemented.'),
                        ),
                        const Spacer(),
                        _ComposeAction(
                          icon: Icons.more_vert_rounded,
                          tooltip: 'More',
                          onPressed: () => _showInfo('More options not implemented.'),
                        ),
                        _ComposeAction(
                          icon: Icons.delete_outline,
                          tooltip: 'Discard',
                          onPressed: () async {
                            await _deleteDraft();
                            if (!context.mounted) return;
                            Navigator.pop(context);
                          },
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            if (alertMessage.isNotEmpty)
              AlertDialog(
                title: Text(
                  alertMessage['title'] ?? '',
                  style: const TextStyle(color: Colors.white70),
                ),
                content: Text(
                  alertMessage['content'] ?? '',
                  style: const TextStyle(color: Colors.white70),
                ),
                backgroundColor: const Color(0xFF232923),
                actions: [
                  TextButton(
                    onPressed: () {
                      setState(() {
                        alertMessage = {};
                      });
                    },
                    child: const Text(
                      'OK',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                ],
              ),
            if (_isLoading) const Center(child: CircularProgressIndicator()),
          ],
        );
    if (widget.embedded) {
      return body;
    }
    return Scaffold(
      body: SafeArea(child: body),
    );
  }
}

class _ComposeAction extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  const _ComposeAction({
    required this.icon,
    required this.tooltip,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 36,
      height: 36,
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        icon: Icon(icon, size: 20),
      ),
    );
  }
}
