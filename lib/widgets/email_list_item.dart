import 'package:enough_mail/enough_mail.dart';
import 'package:flutter/material.dart';
import 'package:pankh/providers/mail_provider.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'mail_view.dart';
import '../screens/compose_email_screen.dart';
import '../providers/common_provider.dart';
import '../providers/layout_provider.dart';

class EmailListItem extends StatefulWidget {
  final MimeMessage message;

  const EmailListItem({super.key, required this.message});

  @override
  State<EmailListItem> createState() => _EmailListItemState();
}

class _EmailListItemState extends State<EmailListItem> {
  bool _hovered = false;

  // Cached per-message values — computed once in initState, updated in didUpdateWidget
  late String _fromDisplay;
  late String _fromEmail;
  late String _subject;
  late String _previewText;
  late String? _listUnsubscribe;
  late bool _hasUnsubscribe;

  @override
  void initState() {
    super.initState();
    _cacheMessageValues();
  }

  @override
  void didUpdateWidget(EmailListItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.message, widget.message)) {
      _cacheMessageValues();
    }
  }

  void _cacheMessageValues() {
    final message = widget.message;

    final rawFrom = message.from?.isNotEmpty == true ? message.from![0] : null;
    final fromText = rawFrom?.toString().replaceAll('"', '').trim() ?? 'Unknown sender';
    _fromDisplay = fromText.contains('<') ? fromText.split('<').first.trim() : fromText;
    _fromEmail = fromText.contains('<')
        ? fromText.split('<').last.replaceAll('>', '').trim()
        : '';

    _subject = message.decodeSubject() ?? '';

    final msgText = message.decodeTextPlainPart();
    if (msgText != null) {
      final buf = StringBuffer();
      for (final line in msgText.split('\r\n')) {
        if (line.startsWith('>')) break;
        buf.write('${line.replaceAll('\n', '')} ');
      }
      final trimmed = buf.toString().trim();
      _previewText = trimmed.isNotEmpty ? trimmed : 'Nothing here';
    } else {
      _previewText = 'Nothing here';
    }

    _listUnsubscribe = message.getHeaderValue('List-Unsubscribe');
    _hasUnsubscribe = _listUnsubscribe != null && _listUnsubscribe!.trim().isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    // Narrow selectors — each item only rebuilds when its own slice changes
    final isSmallScreen = context.select<CommonProvider, bool>((p) => p.isSmallScreen);
    final panePreviewRight = context.select<LayoutProvider, bool>(
      (p) => p.layout == 'pane_preview_right',
    );
    final isSelected = context.select<MailProvider, bool>(
      (p) => p.selectedMail == widget.message,
    );
    final isMultiSelected = context.select<MailProvider, bool>(
      (p) => p.isSelected(widget.message),
    );
    final hasSelection = context.select<MailProvider, bool>((p) => p.hasSelection);
    final selectedFolderName = context.select<MailProvider, String>(
      (p) => p.selectedFolder?.name ?? '',
    );

    // Flags are mutable in-place by the provider, so read fresh each build
    final flags = widget.message.flags ?? const [];
    final isImportant = flags.any((f) {
      final fl = f.toLowerCase();
      return fl.contains('flagged') || fl.contains('important') || fl.contains('starred');
    });
    final isRead = flags.any((f) => f.toLowerCase().contains('seen'));

    final highlightColor = Theme.of(context).colorScheme.primary.withValues(alpha: 0.10);
    final bgColor = isMultiSelected
        ? highlightColor.withValues(alpha: 0.18)
        : isSelected
        ? highlightColor
        : !isRead
        ? Theme.of(context).dividerColor.withValues(alpha: 0.12)
        : Colors.transparent;

    return Material(
      color: Colors.transparent,
      child: MouseRegion(
        onEnter: isSmallScreen ? null : (_) => setState(() => _hovered = true),
        onExit: isSmallScreen ? null : (_) => setState(() => _hovered = false),
        child: InkWell(
          onTap: () {
            final mailProvider = context.read<MailProvider>();
            if (hasSelection) {
              mailProvider.toggleSelection(widget.message);
              return;
            }
            final isDraft = selectedFolderName.toLowerCase().contains('draft');
            mailProvider.selectMail(widget.message);
            if (isDraft) {
              if (isSmallScreen) {
                final msg = widget.message;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ComposeEmail(
                      initialTo: msg.to?.map((a) => a.email).join(', ') ?? '',
                      initialCc: msg.cc?.map((a) => a.email).join(', ') ?? '',
                      initialBcc: msg.bcc?.map((a) => a.email).join(', ') ?? '',
                      initialSubject: msg.decodeSubject() ?? '',
                      initialBody:
                          msg.decodeTextPlainPart() ?? msg.decodeTextHtmlPart() ?? '',
                      initialMessageId: msg.getHeaderValue('Message-ID') ?? '',
                    ),
                  ),
                );
              } else {
                mailProvider.requestOpenDraft(widget.message);
              }
              return;
            }
            if (!isSmallScreen) {
              context.read<CommonProvider>().setIsMailView(isMailView: true);
            } else {
              Navigator.push(context, MaterialPageRoute(builder: (_) => ViewMail()));
            }
          },
          child: Container(
            decoration: BoxDecoration(
              color: bgColor,
              border: !isSmallScreen
                  ? Border(
                      bottom: BorderSide(color: Theme.of(context).dividerColor),
                    )
                  : null,
            ),
            padding: isSmallScreen
                ? const EdgeInsets.fromLTRB(12, 8, 12, 8)
                : const EdgeInsets.fromLTRB(0, 8, 16, 8),
            child: LayoutBuilder(
              builder: (context, outer) {
                if (outer.maxWidth < 80) return const SizedBox(height: 56);

                final baseColor = isRead
                    ? Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.55)
                    : Theme.of(context).textTheme.bodyMedium?.color;

                if (isSmallScreen) {
                  return _SmallLayout(
                    fromDisplay: _fromDisplay,
                    fromEmail: _fromEmail,
                    subject: _subject,
                    previewText: _previewText,
                    isImportant: isImportant,
                    isRead: isRead,
                    baseColor: baseColor,
                    date: widget.message.decodeDate(),
                    onStarTap: () => context.read<MailProvider>().toggleImportant(widget.message),
                  );
                }

                return _DesktopLayout(
                  fromDisplay: _fromDisplay,
                  subject: _subject,
                  previewText: _previewText,
                  isImportant: isImportant,
                  isRead: isRead,
                  baseColor: baseColor,
                  date: widget.message.decodeDate(),
                  panePreviewRight: panePreviewRight,
                  isMultiSelected: isMultiSelected,
                  showHoverActions: _hovered,
                  hasUnsubscribe: _hasUnsubscribe,
                  listUnsubscribe: _listUnsubscribe,
                  message: widget.message,
                  availableWidth: outer.maxWidth,
                  onStarTap: () => context.read<MailProvider>().toggleImportant(widget.message),
                  onCheckboxChanged: (v) => context.read<MailProvider>().toggleSelection(
                    widget.message,
                    selected: v ?? false,
                  ),
                  onShowSnack: (msg) => _showSnack(context, msg),
                  extractUri: _extractUnsubscribeUri,
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  void _showSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Uri? _extractUnsubscribeUri(String raw) {
    for (final match in RegExp(r'<([^>]+)>').allMatches(raw)) {
      final value = match.group(1);
      if (value == null) continue;
      final uri = Uri.tryParse(value.trim());
      if (uri != null &&
          (uri.scheme == 'http' || uri.scheme == 'https' || uri.scheme == 'mailto')) {
        return uri;
      }
    }
    for (final part in raw.split(',').map((s) => s.trim())) {
      final cleaned = part.replaceAll('<', '').replaceAll('>', '');
      final uri = Uri.tryParse(cleaned);
      if (uri != null &&
          (uri.scheme == 'http' || uri.scheme == 'https' || uri.scheme == 'mailto')) {
        return uri;
      }
    }
    return null;
  }
}

// ─── Small-screen layout ───────────────────────────────────────────────────

class _SmallLayout extends StatelessWidget {
  final String fromDisplay;
  final String fromEmail;
  final String subject;
  final String previewText;
  final bool isImportant;
  final bool isRead;
  final Color? baseColor;
  final DateTime? date;
  final VoidCallback onStarTap;

  const _SmallLayout({
    required this.fromDisplay,
    required this.fromEmail,
    required this.subject,
    required this.previewText,
    required this.isImportant,
    required this.isRead,
    required this.baseColor,
    required this.date,
    required this.onStarTap,
  });

  @override
  Widget build(BuildContext context) {
    final boldStyle = TextStyle(
      fontSize: 16,
      fontWeight: isRead ? FontWeight.w400 : FontWeight.w600,
      color: baseColor,
    );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 3, right: 10),
          child: _Avatar(fromDisplay: fromDisplay, fromEmail: fromEmail),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(fromDisplay, overflow: TextOverflow.ellipsis, style: boldStyle),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _formatTimestamp(date),
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11, color: baseColor),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          subject,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: isRead ? FontWeight.w400 : FontWeight.w600,
                            color: baseColor,
                          ),
                        ),
                        Text(
                          previewText,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 13, color: baseColor),
                        ),
                      ],
                    ),
                  ),
                  _StarButton(isImportant: isImportant, onPressed: onStarTap, mobileColors: true),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Desktop layout ────────────────────────────────────────────────────────

class _DesktopLayout extends StatelessWidget {
  final String fromDisplay;
  final String subject;
  final String previewText;
  final bool isImportant;
  final bool isRead;
  final Color? baseColor;
  final DateTime? date;
  final bool panePreviewRight;
  final bool isMultiSelected;
  final bool showHoverActions;
  final bool hasUnsubscribe;
  final String? listUnsubscribe;
  final MimeMessage message;
  final double availableWidth;
  final VoidCallback onStarTap;
  final ValueChanged<bool?> onCheckboxChanged;
  final void Function(String) onShowSnack;
  final Uri? Function(String) extractUri;

  const _DesktopLayout({
    required this.fromDisplay,
    required this.subject,
    required this.previewText,
    required this.isImportant,
    required this.isRead,
    required this.baseColor,
    required this.date,
    required this.panePreviewRight,
    required this.isMultiSelected,
    required this.showHoverActions,
    required this.hasUnsubscribe,
    required this.listUnsubscribe,
    required this.message,
    required this.availableWidth,
    required this.onStarTap,
    required this.onCheckboxChanged,
    required this.onShowSnack,
    required this.extractUri,
  });

  @override
  Widget build(BuildContext context) {
    final boldStyle = TextStyle(
      fontSize: 16,
      fontWeight: isRead ? FontWeight.w400 : FontWeight.w600,
      color: baseColor,
    );
    final timestamp = Text(
      _formatTimestamp(date),
      maxLines: 1,
      softWrap: false,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.right,
      style: TextStyle(fontSize: 11, color: baseColor),
    );
    final starButton = _StarButton(isImportant: isImportant, onPressed: onStarTap);

    // Measure content area (subtract checkbox width ~38px)
    final contentWidth = availableWidth - 38;
    final isRowTight = contentWidth < 140;

    Widget topRowContent;
    if (panePreviewRight) {
      topRowContent = Text(fromDisplay, overflow: TextOverflow.ellipsis, style: boldStyle);
    } else {
      // Full desktop: [star + from (flex 3)] [subject — preview (flex 5)]
      topRowContent = Row(
        children: [
          Flexible(
            flex: 3,
            child: Row(
              children: [
                starButton,
                const SizedBox(width: 6),
                Expanded(
                  child: Text(fromDisplay, overflow: TextOverflow.ellipsis, style: boldStyle),
                ),
              ],
            ),
          ),
          Flexible(
            flex: 5,
            child: Text(
              '$subject - $previewText',
              overflow: TextOverflow.ellipsis,
              style: boldStyle,
            ),
          ),
        ],
      );
    }

    Widget topRow;
    if (isRowTight) {
      topRow = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [topRowContent, const SizedBox(height: 2), timestamp],
      );
    } else {
      final rightWidth = showHoverActions ? (hasUnsubscribe ? 320.0 : 200.0) : 90.0;
      topRow = Row(
        children: [
          Expanded(child: topRowContent),
          const SizedBox(width: 8),
          SizedBox(
            width: rightWidth,
            child: Align(
              alignment: Alignment.centerRight,
              child: showHoverActions
                  ? _HoverActions(
                      message: message,
                      hasUnsubscribe: hasUnsubscribe,
                      listUnsubscribe: listUnsubscribe,
                      onShowSnack: onShowSnack,
                      extractUri: extractUri,
                    )
                  : timestamp,
            ),
          ),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: EdgeInsets.only(left: 8, right: panePreviewRight ? 8 : 0),
          width: 30,
          height: panePreviewRight ? 30 : 40,
          child: Checkbox(value: isMultiSelected, onChanged: onCheckboxChanged),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              topRow,
              if (panePreviewRight)
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            subject,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: isRead ? FontWeight.w400 : FontWeight.w600,
                              color: baseColor,
                            ),
                          ),
                          Text(
                            previewText,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 13, color: baseColor),
                          ),
                        ],
                      ),
                    ),
                    starButton,
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Hover actions row ─────────────────────────────────────────────────────

class _HoverActions extends StatelessWidget {
  final MimeMessage message;
  final bool hasUnsubscribe;
  final String? listUnsubscribe;
  final void Function(String) onShowSnack;
  final Uri? Function(String) extractUri;

  const _HoverActions({
    required this.message,
    required this.hasUnsubscribe,
    required this.listUnsubscribe,
    required this.onShowSnack,
    required this.extractUri,
  });

  @override
  Widget build(BuildContext context) {
    final mailProvider = context.read<MailProvider>();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (hasUnsubscribe)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ActionChip(
              label: const Text('Unsubscribe', style: TextStyle(fontSize: 11)),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
              visualDensity: VisualDensity.compact,
              onPressed: () async {
                final uri = extractUri(listUnsubscribe!);
                if (uri == null) {
                  onShowSnack('No unsubscribe link found.');
                  return;
                }
                final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
                if (!context.mounted) return;
                if (!ok) onShowSnack('Failed to open unsubscribe link.');
              },
            ),
          ),
        _HoverIcon(
          icon: Icons.archive_outlined,
          tooltip: 'Archive',
          onPressed: () async {
            final ok = await mailProvider.archiveMessage(message);
            if (!context.mounted) return;
            if (!ok) onShowSnack('Archive not available.');
          },
        ),
        _HoverIcon(
          icon: Icons.delete_outline,
          tooltip: 'Delete',
          onPressed: () async {
            final ok = await mailProvider.deleteMessage(message);
            if (!context.mounted) return;
            if (!ok) onShowSnack('Failed to delete.');
          },
        ),
        _HoverIcon(
          icon: Icons.mark_email_unread_outlined,
          tooltip: 'Mark as unread',
          onPressed: () async {
            final ok = await mailProvider.setMessageRead(message, false);
            if (!context.mounted) return;
            if (!ok) onShowSnack('Failed to mark unread.');
          },
        ),
        _HoverIcon(
          icon: Icons.snooze_outlined,
          tooltip: 'Snooze',
          onPressed: () async {
            final ok = await mailProvider.snoozeMessage(message);
            if (!context.mounted) return;
            if (!ok) onShowSnack('Snooze not available.');
          },
        ),
      ],
    );
  }
}

// ─── Shared sub-widgets ────────────────────────────────────────────────────

String _formatTimestamp(DateTime? date) {
  if (date == null) return '';
  final local = date.toLocal();
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final target = DateTime(local.year, local.month, local.day);
  final diffDays = today.difference(target).inDays;
  if (diffDays == 0) {
    final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final minute = local.minute.toString().padLeft(2, '0');
    final period = local.hour >= 12 ? 'pm' : 'am';
    return '$hour:$minute $period';
  }
  if (diffDays == 1) return 'Yesterday';
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  if (local.year != now.year) {
    return '${local.day} ${months[local.month - 1]} ${local.year}';
  }
  return '${local.day} ${months[local.month - 1]}';
}

class _Avatar extends StatelessWidget {
  final String fromDisplay;
  final String fromEmail;

  const _Avatar({required this.fromDisplay, required this.fromEmail});

  @override
  Widget build(BuildContext context) {
    final isBot = fromEmail.contains('noreply') ||
        fromEmail.contains('no-reply') ||
        fromEmail.contains('support');
    return Container(
      width: 40,
      height: 40,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.black38,
      ),
      child: isBot
          ? Center(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  fromDisplay.isNotEmpty ? fromDisplay[0].toUpperCase() : '?',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ),
            )
          : const Icon(Icons.person, color: Colors.white),
    );
  }
}

class _StarButton extends StatelessWidget {
  final bool isImportant;
  final bool mobileColors;
  final VoidCallback onPressed;

  const _StarButton({
    required this.isImportant,
    required this.onPressed,
    this.mobileColors = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 32,
      height: 32,
      child: IconButton(
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
        icon: Icon(
          isImportant ? Icons.star_sharp : Icons.star_border,
          size: 20,
          color: isImportant
              ? Colors.amber
              : mobileColors
              ? Colors.white70
              : null,
        ),
      ),
    );
  }
}

class _HoverIcon extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  const _HoverIcon({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 32,
      height: 32,
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
        icon: Icon(icon, size: 18),
      ),
    );
  }
}
