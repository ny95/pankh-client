import 'package:enough_mail/enough_mail.dart';
import 'package:flutter/material.dart';
import 'package:projectwebview/providers/mail_provider.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'mail_view.dart';
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

  Color _generateRandomColor() {
    return Colors.black38;
    // return Color.fromARGB(
    //   255, // Alpha (opacity)
    //   96 + random.nextInt(96), // Red (96-191)
    //   96 + random.nextInt(96), // Green (96-191)
    //   96 + random.nextInt(96), // Blue (96-191)
    // );
  }

  @override
  Widget build(BuildContext context) {
    final commonProvider = Provider.of<CommonProvider>(context);
    final layoutProvider = Provider.of<LayoutProvider>(context);
    final mailProvider = Provider.of<MailProvider>(context);
    bool panePreviewRight = layoutProvider.layout == "pane_preview_right";

    final message = widget.message;
    final rawFrom = message.from?.isNotEmpty == true ? message.from![0] : null;
    final fromText =
        rawFrom?.toString().replaceAll('"', '').trim() ?? 'Unknown sender';
    final from =
        fromText.contains('<')
            ? fromText.split('<').first.trim()
            : fromText;
    final fromEmail =
        fromText.contains('<')
            ? fromText.split('<').last.replaceAll('>', '').trim()
            : '';
    // print(fromEmail);
    final subject = message.decodeSubject() ?? '';
    final date = message.decodeDate();
    final messageString = message.decodeTextPlainPart();
    String newMessageString = 'Nothing here';
    if (messageString != null) {
      final buffer = StringBuffer();
      final lines = messageString.split('\r\n');
      for (final line in lines) {
        if (line.startsWith('>')) {
          break;
        }
        buffer.write('${line.replaceAll('\n', '')} ');
      }
      newMessageString = buffer.toString().trim();
    }
    final flags = message.flags ?? [];
    final isImportant = flags.any(
      (flag) =>
          flag.toLowerCase().contains('flagged') ||
          flag.toLowerCase().contains('important') ||
          flag.toLowerCase().contains('starred'),
    );
    final isRead = flags.any((flag) => flag.toLowerCase().contains('seen'));
    final isSelected = mailProvider.selectedMail == message;
    final isMultiSelected = mailProvider.isSelected(message);
    final showHoverActions = !commonProvider.isSmallScreen && _hovered;
    final listUnsubscribe = message.getHeaderValue('List-Unsubscribe');
    final hasUnsubscribe =
        listUnsubscribe != null && listUnsubscribe.trim().isNotEmpty;
    final baseColor =
        isRead
            ? Theme.of(context).textTheme.bodyMedium?.color?.withValues(
              alpha: 0.55,
            )
            : Theme.of(context).textTheme.bodyMedium?.color;
    final highlightColor = Theme.of(context)
        .colorScheme
        .primary
        .withValues(alpha: 0.10);

    return Material(
      color: Colors.transparent,
      child: MouseRegion(
        onEnter: (_) {
          if (!commonProvider.isSmallScreen) {
            setState(() => _hovered = true);
          }
        },
        onExit: (_) {
          if (!commonProvider.isSmallScreen) {
            setState(() => _hovered = false);
          }
        },
        child: InkWell(
          onTap: () {
            if (mailProvider.hasSelection) {
              mailProvider.toggleSelection(message);
              return;
            }
            mailProvider.selectMail(message);
            if (!commonProvider.isSmallScreen) {
              commonProvider.setIsMailView(isMailView: true);
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ViewMail()),
              );
            }
          },
          child: Container(
            decoration:
                !commonProvider.isSmallScreen
                    ? BoxDecoration(
                      color:
                          isMultiSelected
                              ? highlightColor.withValues(alpha: 0.18)
                              : isSelected
                              ? highlightColor
                              : (!isRead
                                  ? Theme.of(context)
                                      .dividerColor
                                      .withValues(alpha: 0.12)
                                  : Colors.transparent),
                      border: Border(
                        bottom: BorderSide(
                          color: Theme.of(context).dividerColor,
                        ),
                      ),
                    )
                    : BoxDecoration(
                      color:
                          isMultiSelected
                              ? highlightColor.withValues(alpha: 0.18)
                              : isSelected
                              ? highlightColor
                              : (!isRead
                                  ? Theme.of(context)
                                      .dividerColor
                                      .withValues(alpha: 0.12)
                                  : Colors.transparent),
                    ),
            padding:
                commonProvider.isSmallScreen
                    ? EdgeInsets.fromLTRB(12.0, 2.0, 12.0, 2.0)
                    : EdgeInsets.fromLTRB(0, 4.0, 16, 4.0),
            child: LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 80) {
                return const SizedBox(height: 56);
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (commonProvider.isSmallScreen)
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
                                      from.isNotEmpty
                                          ? from[0].toUpperCase()
                                          : '?',
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
                  if (!commonProvider.isSmallScreen)
                    Container(
                      margin: EdgeInsets.only(
                        left: 8,
                        right: panePreviewRight ? 8 : 0,
                      ),
                      width: 30,
                      height: panePreviewRight ? 30 : 40,
                      child: Checkbox(
                        value: isMultiSelected,
                        onChanged: (value) {
                          mailProvider.toggleSelection(
                            message,
                            selected: value ?? false,
                          );
                        },
                      ),
                    ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  if (!commonProvider.isSmallScreen &&
                                      !panePreviewRight)
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
                                                onPressed: () {
                                                  mailProvider.toggleImportant(
                                                    message,
                                                  );
                                                },
                                                padding: EdgeInsets.zero,
                                                constraints:
                                                    const BoxConstraints(
                                                      minWidth: 24,
                                                      minHeight: 24,
                                                    ),
                                                icon: Icon(
                                                  isImportant
                                                      ? Icons.star_sharp
                                                      : Icons.star_border,
                                                  color:
                                                      isImportant
                                                          ? Colors.amber
                                                          : null,
                                                ),
                                              ),
                                            ),
                                          ),
                                          Flexible(
                                            flex: 8,
                                            child: Text(
                                              from,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight:
                                                    isRead
                                                        ? FontWeight.w400
                                                        : FontWeight.w600,
                                                color: baseColor,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  Flexible(
                                    child: Text(
                                      '${panePreviewRight || commonProvider.isSmallScreen ? from : ''} ${(!commonProvider.isSmallScreen && !panePreviewRight) ? '$subject - $newMessageString' : ''}',
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight:
                                            isRead
                                                ? FontWeight.w400
                                                : FontWeight.w600,
                                        color: baseColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (!showHoverActions)
                              SizedBox(
                                width: 90,
                                child: Align(
                                  alignment: Alignment.centerRight,
                                  child: Text(
                                    _formatListTimestamp(date),
                                    maxLines: 1,
                                    softWrap: false,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.right,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: baseColor,
                                    ),
                                  ),
                                ),
                              )
                            else
                              SizedBox(
                                width: hasUnsubscribe ? 320 : 200,
                                child: Align(
                                  alignment: Alignment.centerRight,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (hasUnsubscribe)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            right: 8,
                                          ),
                                          child: ActionChip(
                                            label: const Text(
                                              'Unsubscribe',
                                              style: TextStyle(fontSize: 11),
                                            ),
                                            materialTapTargetSize:
                                                MaterialTapTargetSize.shrinkWrap,
                                            padding:
                                                const EdgeInsets.symmetric(
                                                  horizontal: 6,
                                                  vertical: 0,
                                                ),
                                            visualDensity:
                                                VisualDensity.compact,
                                            onPressed: () async {
                                              final uri =
                                                  _extractUnsubscribeUri(
                                                    listUnsubscribe!,
                                                  );
                                              if (uri == null) {
                                                _showSnack(
                                                  context,
                                                  'No unsubscribe link found.',
                                                );
                                                return;
                                              }
                                              final ok = await launchUrl(
                                                uri,
                                                mode: LaunchMode
                                                    .externalApplication,
                                              );
                                              if (!ok) {
                                                _showSnack(
                                                  context,
                                                  'Failed to open unsubscribe link.',
                                                );
                                              }
                                            },
                                          ),
                                        ),
                                      _HoverIcon(
                                        icon: Icons.archive_outlined,
                                        tooltip: 'Archive',
                                        onPressed: () async {
                                          final ok =
                                              await mailProvider.archiveMessage(
                                                message,
                                              );
                                          if (!ok) {
                                            _showSnack(
                                              context,
                                              'Archive not available.',
                                            );
                                          }
                                        },
                                      ),
                                      _HoverIcon(
                                        icon: Icons.delete_outline,
                                        tooltip: 'Delete',
                                        onPressed: () async {
                                          final ok =
                                              await mailProvider.deleteMessage(
                                                message,
                                              );
                                          if (!ok) {
                                            _showSnack(
                                              context,
                                              'Failed to delete.',
                                            );
                                          }
                                        },
                                      ),
                                      _HoverIcon(
                                        icon: Icons.mark_email_unread_outlined,
                                        tooltip: 'Mark as unread',
                                        onPressed: () async {
                                          final ok =
                                              await mailProvider.setMessageRead(
                                                message,
                                                false,
                                              );
                                          if (!ok) {
                                            _showSnack(
                                              context,
                                              'Failed to mark unread.',
                                            );
                                          }
                                        },
                                      ),
                                      _HoverIcon(
                                        icon: Icons.snooze_outlined,
                                        tooltip: 'Snooze',
                                        onPressed: () async {
                                          final ok =
                                              await mailProvider.snoozeMessage(
                                                message,
                                              );
                                          if (!ok) {
                                            _showSnack(
                                              context,
                                              'Snooze not available.',
                                            );
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                        if (commonProvider.isSmallScreen || panePreviewRight)
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
                                        fontWeight:
                                            isRead
                                                ? FontWeight.w400
                                                : FontWeight.w600,
                                        color: baseColor,
                                      ),
                                    ),
                                    Text(
                                      newMessageString,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: baseColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(
                                width: 30,
                                height: 30,
                                child: IconButton(
                                  onPressed: () {
                                    mailProvider.toggleImportant(message);
                                  },
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(
                                    minWidth: 24,
                                    minHeight: 24,
                                  ),
                                  icon: Icon(
                                    isImportant
                                        ? Icons.star_sharp
                                        : Icons.star_border,
                                    color:
                                        isImportant
                                            ? Colors.amber
                                            : Colors.white70,
                                  ),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    ),
  );
  }

  String _formatListTimestamp(DateTime? date) {
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
    if (diffDays == 1) {
      return 'Yesterday';
    }
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    if (local.year != now.year) {
      return '${local.day} ${months[local.month - 1]} ${local.year}';
    }
    return '${local.day} ${months[local.month - 1]}';
  }

  void _showSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Uri? _extractUnsubscribeUri(String raw) {
    final matches = RegExp(r'<([^>]+)>').allMatches(raw);
    for (final match in matches) {
      final value = match.group(1);
      if (value == null) continue;
      final uri = Uri.tryParse(value.trim());
      if (uri != null &&
          (uri.scheme == 'http' ||
              uri.scheme == 'https' ||
              uri.scheme == 'mailto')) {
        return uri;
      }
    }
    final fallback = raw.split(',').map((s) => s.trim());
    for (final part in fallback) {
      final cleaned = part.replaceAll('<', '').replaceAll('>', '');
      final uri = Uri.tryParse(cleaned);
      if (uri != null &&
          (uri.scheme == 'http' ||
              uri.scheme == 'https' ||
              uri.scheme == 'mailto')) {
        return uri;
      }
    }
    return null;
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
