import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/layout_provider.dart';
import '../providers/mail_provider.dart';
import '../models/mail_folder.dart';

class MailNav extends StatefulWidget {
  const MailNav({super.key});

  @override
  MailNavState createState() => MailNavState();
}

class MailNavState extends State<MailNav> {
  Widget toggleIcon({required String layout}) {
    late Widget icon;
    switch (layout) {
      case "pane_preview_off":
        icon = Icon(Icons.reorder_rounded);
        break;

      case "pane_preview_right":
        icon = Icon(Icons.vertical_split_rounded);
        break;

      case "pane_preview_bottom":
        icon = Icon(Icons.horizontal_split_rounded);
        break;

      default:
        icon = Icon(Icons.reorder_rounded); // fallback icon
    }
    return icon;
  }

  @override
  Widget build(BuildContext context) {
    final layoutProvider = Provider.of<LayoutProvider>(context);
    final mailProvider = Provider.of<MailProvider>(context);
    bool panePreviewOff = layoutProvider.layout == "pane_preview_off";
    bool panePreviewRight = layoutProvider.layout == "pane_preview_right";
    final hasSelection = mailProvider.hasSelection;
    final isInbox =
        mailProvider.selectedFolder?.name.toLowerCase() == 'inbox' &&
        !mailProvider.isQuerySearch;
    final pageStart = mailProvider.pageStart;
    final pageEnd = mailProvider.pageEnd;
    final pageTotal = mailProvider.pageTotal;
    String pageInfo = '0-0 of 0';
    if (pageTotal > 0) {
      pageInfo = '$pageStart-$pageEnd of $pageTotal';
    }
    void showActionError(String message) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }

    Future<void> runSelectionAction(
      Future<bool> Function() action, {
      String? failureMessage,
    }) async {
      final ok = await action();
      if (!ok && failureMessage != null) {
        showActionError(failureMessage);
      }
    }

    Future<void> openMoveToMenu(BuildContext buttonContext) async {
      if (mailProvider.folders.isEmpty) {
        showActionError('No folders available for this account.');
        return;
      }
      final box = buttonContext.findRenderObject() as RenderBox;
      final overlay =
          Overlay.of(buttonContext).context.findRenderObject() as RenderBox;
      final position = RelativeRect.fromRect(
        Rect.fromPoints(
          box.localToGlobal(Offset.zero, ancestor: overlay),
          box.localToGlobal(box.size.bottomRight(Offset.zero), ancestor: overlay),
        ),
        Offset.zero & overlay.size,
      );
      final controller = TextEditingController();
      final selected = await showMenu<MailFolder>(
        context: context,
        position: position,
        items: [
          PopupMenuItem<MailFolder>(
            enabled: false,
            padding: EdgeInsets.zero,
            child: StatefulBuilder(
              builder: (context, setState) {
                bool isMoveAllowed(MailFolder target) {
                  final current = mailProvider.selectedFolder;
                  if (current == null) return true;
                  final sourceName = current.name.toLowerCase();
                  final targetName = target.name.toLowerCase();
                  if (sourceName == 'inbox') {
                    if (targetName.contains('sent') ||
                        targetName.contains('draft')) {
                      return false;
                    }
                  }
                  if (sourceName.contains('sent') ||
                      sourceName.contains('draft')) {
                    if (targetName == 'inbox') {
                      return false;
                    }
                  }
                  return true;
                }

                List<MailFolder> filtered =
                    mailProvider.folders.where((folder) {
                      final current = mailProvider.selectedFolder;
                      if (current == null) return true;
                      return folder.path != current.path &&
                          isMoveAllowed(folder);
                    }).toList();
                void applyFilter(String value) {
                  final query = value.trim().toLowerCase();
                  setState(() {
                    if (query.isEmpty) {
                      filtered =
                          mailProvider.folders.where((folder) {
                            final current = mailProvider.selectedFolder;
                            if (current == null) return true;
                            return folder.path != current.path;
                          }).toList();
                    } else {
                      filtered =
                          mailProvider.folders
                              .where(
                                (f) => f.name.toLowerCase().contains(query),
                              )
                              .where((folder) {
                                final current = mailProvider.selectedFolder;
                                if (current == null) return true;
                                return folder.path != current.path &&
                                    isMoveAllowed(folder);
                              })
                              .toList();
                    }
                  });
                }

                final primary = <MailFolder>[];
                final secondary = <MailFolder>[];
                for (final folder in filtered) {
                  final name = folder.name.toLowerCase();
                  if (name.contains('spam') ||
                      name.contains('junk') ||
                      name.contains('trash') ||
                      name.contains('bin') ||
                      name.contains('deleted')) {
                    secondary.add(folder);
                  } else {
                    primary.add(folder);
                  }
                }

                Widget section(List<MailFolder> items) {
                  return Column(
                    children:
                        items
                            .map(
                              (folder) => ListTile(
                                title: Text(folder.name),
                                dense: true,
                                visualDensity: VisualDensity.compact,
                                onTap: () {
                                  Navigator.of(context).pop(folder);
                                },
                              ),
                            )
                            .toList(),
                  );
                }

                return SizedBox(
                  width: 280,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Move to:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: controller,
                          decoration: const InputDecoration(
                            hintText: 'Search',
                            prefixIcon: Icon(Icons.search),
                          ),
                          onChanged: applyFilter,
                        ),
                        const SizedBox(height: 8),
                        SingleChildScrollView(
                          child: Column(
                            children: [
                              section(primary),
                              if (secondary.isNotEmpty) ...[
                                const Divider(),
                                section(secondary),
                              ],
                              const Divider(),
                              ListTile(
                                title: const Text('Create new'),
                                onTap: () {
                                  Navigator.of(context).pop();
                                  showActionError(
                                    'Create new not implemented.',
                                  );
                                },
                              ),
                              ListTile(
                                title: const Text('Manage labels'),
                                onTap: () {
                                  Navigator.of(context).pop();
                                  showActionError(
                                    'Manage labels not implemented.',
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      );

      if (selected != null) {
        await runSelectionAction(
          () => mailProvider.moveSelectedTo(selected),
          failureMessage: 'Failed to move messages.',
        );
      }
    }

    Future<void> openLabelMenu(BuildContext buttonContext) async {
      if (mailProvider.folders.isEmpty) {
        showActionError('No labels available for this account.');
        return;
      }
      final box = buttonContext.findRenderObject() as RenderBox;
      final overlay =
          Overlay.of(buttonContext).context.findRenderObject() as RenderBox;
      final position = RelativeRect.fromRect(
        Rect.fromPoints(
          box.localToGlobal(Offset.zero, ancestor: overlay),
          box.localToGlobal(box.size.bottomRight(Offset.zero), ancestor: overlay),
        ),
        Offset.zero & overlay.size,
      );
      final controller = TextEditingController();
      final selected = await showMenu<List<MailFolder>>(
        context: context,
        position: position,
        items: [
          PopupMenuItem<List<MailFolder>>(
            enabled: false,
            padding: EdgeInsets.zero,
            child: StatefulBuilder(
              builder: (context, setState) {
                bool isLabelAllowed(MailFolder target) {
                  final current = mailProvider.selectedFolder;
                  if (current == null) return true;
                  final sourceName = current.name.toLowerCase();
                  final targetName = target.name.toLowerCase();
                  if (sourceName == 'inbox') {
                    if (targetName.contains('sent') ||
                        targetName.contains('draft')) {
                      return false;
                    }
                  }
                  if (sourceName.contains('sent') ||
                      sourceName.contains('draft')) {
                    if (targetName == 'inbox') {
                      return false;
                    }
                  }
                  return true;
                }

                List<MailFolder> filtered =
                    mailProvider.folders.where((folder) {
                      final current = mailProvider.selectedFolder;
                      if (current == null) return true;
                      return folder.path != current.path &&
                          isLabelAllowed(folder);
                    }).toList();

                final selectedLabels = <String>{};
                void applyFilter(String value) {
                  final query = value.trim().toLowerCase();
                  setState(() {
                    if (query.isEmpty) {
                      filtered =
                          mailProvider.folders.where((folder) {
                            final current = mailProvider.selectedFolder;
                            if (current == null) return true;
                            return folder.path != current.path &&
                                isLabelAllowed(folder);
                          }).toList();
                    } else {
                      filtered =
                          mailProvider.folders
                              .where(
                                (f) => f.name.toLowerCase().contains(query),
                              )
                              .where((folder) {
                                final current = mailProvider.selectedFolder;
                                if (current == null) return true;
                                return folder.path != current.path &&
                                    isLabelAllowed(folder);
                              })
                              .toList();
                    }
                  });
                }

                return SizedBox(
                  width: 280,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Label as:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: controller,
                          decoration: const InputDecoration(
                            hintText: 'Search',
                            prefixIcon: Icon(Icons.search),
                          ),
                          onChanged: applyFilter,
                        ),
                        const SizedBox(height: 8),
                        SingleChildScrollView(
                          child: Column(
                            children: [
                              ...filtered.map((folder) {
                                final checked =
                                    selectedLabels.contains(folder.path);
                                return CheckboxListTile(
                                  value: checked,
                                  dense: true,
                                  visualDensity: VisualDensity.compact,
                                  title: Text(folder.name),
                                  controlAffinity:
                                      ListTileControlAffinity.leading,
                                  onChanged: (value) {
                                    setState(() {
                                      if (value == true) {
                                        selectedLabels.add(folder.path);
                                      } else {
                                        selectedLabels.remove(folder.path);
                                      }
                                    });
                                  },
                                );
                              }).toList(),
                              const Divider(),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: selectedLabels.isEmpty
                                      ? null
                                      : () {
                                          final chosen =
                                              mailProvider.folders
                                                  .where(
                                                    (f) => selectedLabels
                                                        .contains(f.path),
                                                  )
                                                  .toList();
                                          Navigator.of(context).pop(chosen);
                                        },
                                  child: const Text('Apply'),
                                ),
                              ),
                              ListTile(
                                title: const Text('Create new'),
                                onTap: () {
                                  Navigator.of(context).pop();
                                  showActionError(
                                    'Create new not implemented.',
                                  );
                                },
                              ),
                              ListTile(
                                title: const Text('Manage labels'),
                                onTap: () {
                                  Navigator.of(context).pop();
                                  showActionError(
                                    'Manage labels not implemented.',
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      );

      if (selected != null && selected.isNotEmpty) {
        var okAll = true;
        for (final folder in selected) {
          final ok = await mailProvider.addLabelTo(folder);
          okAll = okAll && ok;
        }
        if (!okAll) {
          showActionError('Failed to apply one or more labels.');
        }
      }
    }

    const double actionButtonExtent = 50;
    Widget actionSlot(Widget child) {
      return SizedBox(
        width: actionButtonExtent,
        height: 36,
        child: Center(child: child),
      );
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Theme.of(context).dividerColor, width: 1),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    margin: EdgeInsets.only(left: 8),
                    height: 40,
                    width: 30,
                    child: Checkbox(
                      tristate: true,
                      value:
                          mailProvider.isAllSelected
                              ? true
                              : (mailProvider.isPartiallySelected
                                  ? null
                                  : false),
                      onChanged: (_) {
                        mailProvider.toggleSelectAll();
                      },
                    ),
                  ),
                  IconButton(
                    iconSize: 20,
                    style: ButtonStyle(
                      padding: WidgetStateProperty.all(
                        EdgeInsets.all(0),
                      ),
                      minimumSize: WidgetStateProperty.all(
                        Size(10, 10),
                      ),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: () {},
                    icon: const Icon(Icons.arrow_drop_down_sharp),
                  ),
                  if (!hasSelection) ...[
                    IconButton(
                      onPressed:
                          mailProvider.isRefreshing || mailProvider.isLoading
                              ? null
                              : () {
                                final provider = Provider.of<MailProvider>(
                                  context,
                                  listen: false,
                                );
                                if (provider.isSearchMode) {
                                  provider.search(provider.searchQuery);
                                } else {
                                  provider.refreshLatest();
                                }
                              },
                      icon: const Icon(Icons.refresh_sharp),
                    ),
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.more_vert_rounded),
                    ),
                  ],
                  if (hasSelection) ...[
                    actionSlot(
                      IconButton(
                        tooltip: 'Archive',
                        onPressed: () {
                          runSelectionAction(
                            mailProvider.archiveSelected,
                            failureMessage:
                                'Archive folder not available for this account.',
                          );
                        },
                        icon: const Icon(Icons.archive_outlined),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ),
                    actionSlot(
                      IconButton(
                        tooltip: 'Report spam',
                        onPressed: () {
                          runSelectionAction(
                            mailProvider.reportSpamSelected,
                            failureMessage:
                                'Spam folder not available for this account.',
                          );
                        },
                        icon: const Icon(Icons.report_gmailerrorred_outlined),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ),
                    actionSlot(
                      IconButton(
                        tooltip: 'Delete',
                        onPressed: () {
                          runSelectionAction(
                            mailProvider.deleteSelected,
                            failureMessage: 'Failed to delete messages.',
                          );
                        },
                        icon: const Icon(Icons.delete_outline),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ),
                    actionSlot(
                      IconButton(
                        tooltip:
                            mailProvider.selectedAllRead
                                ? 'Mark as unread'
                                : 'Mark as read',
                        onPressed: () {
                          runSelectionAction(
                            () => mailProvider.setSelectedRead(
                              !mailProvider.selectedAllRead,
                            ),
                            failureMessage: 'Failed to update read status.',
                          );
                        },
                        icon: Icon(
                          mailProvider.selectedAllRead
                              ? Icons.mark_email_unread_outlined
                              : Icons.mark_email_read_outlined,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ),
                    actionSlot(
                      IconButton(
                        tooltip: 'Snooze',
                        onPressed: () {
                          runSelectionAction(
                            mailProvider.snoozeSelected,
                            failureMessage:
                                'Snooze folder not available for this account.',
                          );
                        },
                        icon: const Icon(Icons.snooze),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ),
                    actionSlot(
                      Builder(
                        builder: (buttonContext) {
                          return IconButton(
                            tooltip: 'Move to',
                            onPressed: () => openMoveToMenu(buttonContext),
                            icon: const Icon(Icons.drive_file_move_outlined),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          );
                        },
                      ),
                    ),
                    actionSlot(
                      Builder(
                        builder: (buttonContext) {
                          return IconButton(
                            tooltip: 'Labels',
                            onPressed: () => openLabelMenu(buttonContext),
                            icon: const Icon(Icons.label_outline),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          );
                        },
                      ),
                    ),
                    actionSlot(
                      PopupMenuButton<int>(
                        tooltip: 'More',
                        onSelected: (value) {
                          if (value == 1) {
                            runSelectionAction(
                              () => mailProvider.setSelectedImportant(true),
                              failureMessage: 'Failed to add star.',
                            );
                          } else if (value == 2) {
                            runSelectionAction(
                              () => mailProvider.setSelectedRead(false),
                              failureMessage: 'Failed to mark unread.',
                            );
                          } else if (value == 3) {
                            runSelectionAction(
                              () => mailProvider.setSelectedImportant(true),
                              failureMessage: 'Failed to mark important.',
                            );
                          } else {
                            showActionError('Not supported yet.');
                          }
                        },
                        itemBuilder:
                            (context) => const [
                              PopupMenuItem(
                                value: 1,
                                child: Text('Add star'),
                              ),
                              PopupMenuItem(
                                value: 2,
                                child: Text('Mark as unread'),
                              ),
                              PopupMenuItem(
                                value: 3,
                                child: Text('Mark as important'),
                              ),
                              PopupMenuItem(
                                value: 4,
                                child: Text('Filter messages like these'),
                              ),
                              PopupMenuItem(
                                value: 5,
                                child: Text('Mute'),
                              ),
                              PopupMenuItem(
                                value: 6,
                                child: Text('Forward as attachment'),
                              ),
                              PopupMenuItem(
                                value: 7,
                                child: Text('Switch to simple toolbar'),
                              ),
                            ],
                        icon: const Icon(Icons.more_vert_rounded),
                      ),
                    ),
                  ],
                ],
              ),
              Row(
                children: [
                  Row(
                    children: [
                      Text(pageInfo),
                      if (mailProvider.isLoadingMore ||
                          mailProvider.isRefreshing ||
                          mailProvider.isLoading)
                        const Padding(
                          padding: EdgeInsets.only(left: 8.0),
                          child: SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                    ],
                  ),
                  IconButton(
                    iconSize: 20,
                    onPressed:
                        mailProvider.isSearchMode ||
                                mailProvider.isRefreshing ||
                                mailProvider.isLoading
                            ? null
                            : () {
                              Provider.of<MailProvider>(
                                context,
                                listen: false,
                              ).loadNewer(replace: true);
                            },
                    icon: const Icon(Icons.arrow_back_ios_new_rounded),
                  ),
                  IconButton(
                    iconSize: 20,
                    onPressed:
                        mailProvider.isSearchMode ||
                                mailProvider.isLoadingMore ||
                                mailProvider.isLoading
                            ? null
                            : () {
                              Provider.of<MailProvider>(
                                context,
                                listen: false,
                              ).loadOlder(replace: true);
                            },
                    icon: const Icon(Icons.arrow_forward_ios_rounded),
                  ),
                  Container(
                    margin: EdgeInsets.only(right: 8),
                    child: IconButton(
                      onPressed: () {
                        layoutProvider.setLayout(
                          panePreviewOff
                              ? "pane_preview_right"
                              : (panePreviewRight
                                  ? "pane_preview_bottom"
                                  : "pane_preview_off"),
                        );
                      },
                      icon: toggleIcon(layout: layoutProvider.layout),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (isInbox)
          Container(
            height: 48,
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).dividerColor,
                ),
              ),
            ),
            child: Row(
              children: [
                _InboxTab(
                  label: 'Primary',
                  icon: Icons.inbox,
                  active: mailProvider.inboxCategory == 'primary',
                  onTap: () {
                    mailProvider.setInboxCategory('primary');
                  },
                ),
                _InboxTab(
                  label: 'Promotions',
                  icon: Icons.sell_rounded,
                  active: mailProvider.inboxCategory == 'promotions',
                  onTap: () {
                    mailProvider.setInboxCategory('promotions');
                  },
                ),
                _InboxTab(
                  label: 'Social',
                  icon: Icons.group_outlined,
                  active: mailProvider.inboxCategory == 'social',
                  onTap: () {
                    mailProvider.setInboxCategory('social');
                  },
                ),
                _InboxTab(
                  label: 'Updates',
                  icon: Icons.info_outline,
                  active: mailProvider.inboxCategory == 'updates',
                  onTap: () {
                    mailProvider.setInboxCategory('updates');
                  },
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _InboxTab extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  const _InboxTab({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        hoverColor: Theme.of(
          context,
        ).colorScheme.primary.withValues(alpha: 0.08),
        splashColor: Theme.of(
          context,
        ).colorScheme.primary.withValues(alpha: 0.12),
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color:
                    active
                        ? Theme.of(context).colorScheme.primary
                        : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color:
                    active
                        ? Theme.of(context).colorScheme.primary
                        : null,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                  color:
                      active
                          ? Theme.of(context).colorScheme.primary
                          : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
