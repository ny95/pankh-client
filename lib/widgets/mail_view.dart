import 'package:enough_mail/enough_mail.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:pankh/providers/common_provider.dart';
import 'package:pankh/providers/layout_provider.dart';
import 'package:pankh/providers/mail_provider.dart';
import 'package:pankh/providers/theme_provider.dart';
import 'package:pankh/utils/helpers.dart';
import 'package:pankh/widgets/blur.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class ViewMail extends StatelessWidget {
  const ViewMail({super.key});

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = context.select<CommonProvider, bool>((p) => p.isSmallScreen);
    final bgOpacity = context.select<ThemeProvider, double>((p) => p.bgOpacity);
    final bgBlur = context.select<ThemeProvider, bool>((p) => p.bgBlur);
    final panePreviewOff = context.select<LayoutProvider, bool>((p) => p.layout == "pane_preview_off");
    final selectedMail = context.select<MailProvider, MimeMessage?>((p) => p.selectedMail);
    final selectedFolderName = context.select<MailProvider, String?>((p) => p.selectedFolder?.name);
    final isLoading = context.select<MailProvider, bool>((p) => p.isLoading);
    final isRefreshing = context.select<MailProvider, bool>((p) => p.isRefreshing);
    final mailsEmpty = context.select<MailProvider, bool>((p) => p.mails.isEmpty);
    if (selectedMail == null) {
      if (isLoading || isRefreshing || mailsEmpty) {
        return const Center(
          child: SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        );
      }
      return const Center(child: Text("Select an email"));
    }

    final message = selectedMail;
    final plainText = message.decodeTextPlainPart();
    final htmlText = message.decodeTextHtmlPart();
    final content = htmlText ?? (plainText ?? '').replaceAll('\r\n', '<br>');
    final webViewKey = ValueKey(message.uid ?? message.sequenceId ?? message.hashCode);
    final subject = message.decodeSubject() ?? '(no subject)';
    final from = message.from?.isNotEmpty == true ? message.from!.first : null;
    final fromName =
        from?.personalName?.trim().isNotEmpty == true
            ? from!.personalName!
            : from?.mailboxName ?? 'Unknown sender';
    final fromEmail = from?.email ?? '';
    final date = message.decodeDate();
    final flags = message.flags ?? [];
    final isImportant = flags.any(
      (f) =>
          f.toLowerCase().contains('flagged') ||
          f.toLowerCase().contains('important') ||
          f.toLowerCase().contains('starred'),
    );

    final themeProvider = context.read<ThemeProvider>();
    return Scaffold(
      backgroundColor:
          isSmallScreen
              ? Theme.of(
                context,
              ).canvasColor.withValues(alpha: bgOpacity)
              : Colors.transparent,
      body: Container(
        decoration:
            isSmallScreen
                ? BoxDecoration(
                  image: getBackgroundDecoration(context, themeProvider),
                )
                : BoxDecoration(
                  // borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      spreadRadius: 1,
                      blurRadius: 1,
                      offset: const Offset(0, 0),
                    ),
                  ],
                ),
        clipBehavior: Clip.antiAlias,
        child: Blur(
          blur: bgBlur,
          child: SafeArea(
            child: Column(
              children: [
                if (panePreviewOff || isSmallScreen)
                  Container(
                    color:
                        isSmallScreen
                            ? Theme.of(context).canvasColor.withValues(
                              alpha: bgOpacity,
                            )
                            : null,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8.0,
                      vertical: 8,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          onPressed: () {
                            if (panePreviewOff && !isSmallScreen) {
                              context.read<CommonProvider>().setIsMailView(isMailView: false);
                            }
                            if (isSmallScreen) {
                              Navigator.pop(context);
                            }
                          },
                          icon: const Icon(Icons.arrow_back_rounded),
                        ),
                        Row(
                          children: [
                            IconButton(
                              onPressed: () {},
                              icon: const Icon(Icons.archive_outlined),
                            ),
                            IconButton(
                              onPressed: () {},
                              icon: const Icon(Icons.delete_rounded),
                            ),
                            IconButton(
                              onPressed: () {},
                              icon: const Icon(
                                Icons.mark_email_unread_outlined,
                              ),
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
                                      value: 4,
                                      child: Text(
                                        'Save draft',
                                        style: TextStyle(color: Colors.white70),
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 5,
                                      child: Text(
                                        'Discard',
                                        style: TextStyle(color: Colors.white70),
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 6,
                                      child: Text(
                                        'Settings',
                                        style: TextStyle(color: Colors.white70),
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 7,
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
                              icon: const Icon(Icons.more_vert_rounded),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Theme.of(context).dividerColor),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      LayoutBuilder(
                        builder: (context, constraints) {
                          return SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                minWidth: constraints.maxWidth,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        subject,
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        softWrap: false,
                                      ),
                                      const SizedBox(width: 12),
                                      _labelChip(
                                        label: selectedFolderName,
                                      ),
                                    ],
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: Icon(
                                          isImportant
                                              ? Icons.star
                                              : Icons.star_border,
                                          color:
                                              isImportant ? Colors.amber : null,
                                        ),
                                        onPressed: () {
                                          context.read<MailProvider>().toggleImportant(message);
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.print_outlined),
                                        onPressed: () {},
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.open_in_new),
                                        onPressed: () {},
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          return SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                minWidth: constraints.maxWidth,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const CircleAvatar(
                                        radius: 14,
                                        child: Icon(Icons.person, size: 16),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        fromName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                        softWrap: false,
                                      ),
                                      const SizedBox(width: 6),
                                      if (fromEmail.isNotEmpty)
                                        Text(
                                          '<$fromEmail>',
                                          style: TextStyle(
                                            color:
                                                Theme.of(
                                                  context,
                                                ).textTheme.bodySmall?.color,
                                          ),
                                          softWrap: false,
                                        ),
                                      const SizedBox(width: 12),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      Text(
                                        date != null
                                            ? _formatDateTime(date)
                                            : '',
                                        style: TextStyle(
                                          color:
                                              Theme.of(
                                                context,
                                              ).textTheme.bodySmall?.color,
                                        ),
                                        softWrap: false,
                                      ),
                                      const SizedBox(width: 8),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.more_vert_rounded,
                                        ),
                                        onPressed: () {},
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: InAppWebView(
                    key: webViewKey,
                    initialData: InAppWebViewInitialData(data: content),
                    initialSettings: InAppWebViewSettings(
                      useShouldOverrideUrlLoading: true,
                    ),
                    shouldOverrideUrlLoading: (controller, action) async {
                      final uri = action.request.url;
                      if (uri == null) {
                        return NavigationActionPolicy.ALLOW;
                      }
                      final scheme = uri.scheme.toLowerCase();
                      if (scheme == 'http' ||
                          scheme == 'https' ||
                          scheme == 'mailto') {
                        final ok = await launchUrl(
                          uri,
                          mode: LaunchMode.externalApplication,
                        );
                        return ok
                            ? NavigationActionPolicy.CANCEL
                            : NavigationActionPolicy.ALLOW;
                      }
                      return NavigationActionPolicy.ALLOW;
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _labelChip({String? label}) {
    if (label == null || label.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(label, style: const TextStyle(fontSize: 12)),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final local = dateTime.toLocal();
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
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
    final weekday = weekdays[local.weekday - 1];
    final month = months[local.month - 1];
    final day = local.day;
    final year = local.year;
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$weekday, $day $month $year, $hour:$minute';
  }
}
