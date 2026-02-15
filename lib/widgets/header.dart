
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:projectwebview/widgets/blur.dart';
import 'package:projectwebview/widgets/settings/account/account.dart';
import 'package:provider/provider.dart';

import '../providers/mail_provider.dart';
import '../providers/theme_provider.dart';

class Header extends StatefulWidget {
  final VoidCallback toggleMenu;
  final VoidCallback toggleSetting;

  const Header({
    super.key,
    required this.toggleMenu,
    required this.toggleSetting,
  });

  @override
  HeaderState createState() => HeaderState();
}

class HeaderState extends State<Header> {
  bool filterHidden = false;
  Timer? _searchDebounce;

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }

  void _openDialog({required BuildContext context, required Widget widget}) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          insetPadding: EdgeInsets.all(0),
          backgroundColor: Theme.of(context).cardColor,
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.7,
            height: MediaQuery.of(context).size.height * 0.8,
            child: widget,
          ),
        );
      },
    );
  }

  Future<void> _openSearchFilterDialog(
    BuildContext context,
    SearchController controller,
    MailProvider mailProvider,
  ) async {
    final fromCtrl = TextEditingController();
    final toCtrl = TextEditingController();
    final subjectCtrl = TextEditingController();
    final includeCtrl = TextEditingController();
    final excludeCtrl = TextEditingController();
    final sizeCtrl = TextEditingController();
    var sizeOp = 'greater than';
    var sizeUnit = 'MB';
    var dateWithin = 'Any time';
    DateTime? customDate;
    var selectedFolder = 'All Mail';
    var hasAttachment = false;
    var excludeChats = false;

    final currentQuery = controller.text.trim();
    if (currentQuery.isNotEmpty) {
      includeCtrl.text = currentQuery;
    }

    String? formatDate(DateTime? date) {
      if (date == null) return null;
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    }

    String buildQuery() {
      final tokens = <String>[];
      if (fromCtrl.text.trim().isNotEmpty) {
        tokens.add('from:${fromCtrl.text.trim()}');
      }
      if (toCtrl.text.trim().isNotEmpty) {
        tokens.add('to:${toCtrl.text.trim()}');
      }
      if (subjectCtrl.text.trim().isNotEmpty) {
        tokens.add('subject:${subjectCtrl.text.trim()}');
      }
      if (includeCtrl.text.trim().isNotEmpty) {
        tokens.add(includeCtrl.text.trim());
      }
      if (excludeCtrl.text.trim().isNotEmpty) {
        tokens.add('-${excludeCtrl.text.trim()}');
      }
      if (sizeCtrl.text.trim().isNotEmpty) {
        final value = double.tryParse(sizeCtrl.text.trim());
        if (value != null) {
          final multiplier =
              sizeUnit == 'KB'
                  ? 1024
                  : sizeUnit == 'MB'
                  ? 1024 * 1024
                  : 1024 * 1024 * 1024;
          final bytes = (value * multiplier).round();
          tokens.add(
            sizeOp == 'greater than' ? 'larger:$bytes' : 'smaller:$bytes',
          );
        }
      }
      if (dateWithin != 'Any time') {
        DateTime since;
        final now = DateTime.now();
        switch (dateWithin) {
          case '1 day':
            since = now.subtract(const Duration(days: 1));
            break;
          case '7 days':
            since = now.subtract(const Duration(days: 7));
            break;
          case '1 month':
            since = DateTime(now.year, now.month - 1, now.day);
            break;
          case '1 year':
            since = DateTime(now.year - 1, now.month, now.day);
            break;
          case 'Custom':
            since = customDate ?? now;
            break;
          default:
            since = now;
        }
        tokens.add('after:${formatDate(since)}');
      }
      if (selectedFolder != 'All Mail') {
        tokens.add('label:$selectedFolder');
      }
      if (hasAttachment) {
        tokens.add('has:attachment');
      }
      if (excludeChats) {
        tokens.add('-label:chats');
      }
      return tokens.join(' ');
    }

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            final folders = mailProvider.folders;
            final folderNames = {
              'All Mail',
              ...folders.map((f) => f.name),
            }.toList();
            return AlertDialog(
              title: const Text('Search options'),
              content: SizedBox(
                width: 680,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _filterRow(
                        label: 'From',
                        child: TextField(controller: fromCtrl),
                      ),
                      _filterRow(
                        label: 'To',
                        child: TextField(controller: toCtrl),
                      ),
                      _filterRow(
                        label: 'Subject',
                        child: TextField(controller: subjectCtrl),
                      ),
                      _filterRow(
                        label: 'Includes the words',
                        child: TextField(controller: includeCtrl),
                      ),
                      _filterRow(
                        label: "Doesn't have",
                        child: TextField(controller: excludeCtrl),
                      ),
                      _filterRow(
                        label: 'Size',
                        child: Row(
                          children: [
                            DropdownButton<String>(
                              value: sizeOp,
                              items: const [
                                DropdownMenuItem(
                                  value: 'greater than',
                                  child: Text('greater than'),
                                ),
                                DropdownMenuItem(
                                  value: 'less than',
                                  child: Text('less than'),
                                ),
                              ],
                              onChanged: (value) {
                                if (value == null) return;
                                setState(() => sizeOp = value);
                              },
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 120,
                              child: TextField(
                                controller: sizeCtrl,
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            const SizedBox(width: 8),
                            DropdownButton<String>(
                              value: sizeUnit,
                              items: const [
                                DropdownMenuItem(
                                  value: 'KB',
                                  child: Text('KB'),
                                ),
                                DropdownMenuItem(
                                  value: 'MB',
                                  child: Text('MB'),
                                ),
                                DropdownMenuItem(
                                  value: 'GB',
                                  child: Text('GB'),
                                ),
                              ],
                              onChanged: (value) {
                                if (value == null) return;
                                setState(() => sizeUnit = value);
                              },
                            ),
                          ],
                        ),
                      ),
                      _filterRow(
                        label: 'Date within',
                        child: Row(
                          children: [
                            DropdownButton<String>(
                              value: dateWithin,
                              items: const [
                                DropdownMenuItem(
                                  value: 'Any time',
                                  child: Text('Any time'),
                                ),
                                DropdownMenuItem(
                                  value: '1 day',
                                  child: Text('1 day'),
                                ),
                                DropdownMenuItem(
                                  value: '7 days',
                                  child: Text('7 days'),
                                ),
                                DropdownMenuItem(
                                  value: '1 month',
                                  child: Text('1 month'),
                                ),
                                DropdownMenuItem(
                                  value: '1 year',
                                  child: Text('1 year'),
                                ),
                                DropdownMenuItem(
                                  value: 'Custom',
                                  child: Text('Custom'),
                                ),
                              ],
                              onChanged: (value) {
                                if (value == null) return;
                                setState(() => dateWithin = value);
                              },
                            ),
                            if (dateWithin == 'Custom')
                              IconButton(
                                icon: const Icon(Icons.calendar_today),
                                onPressed: () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: customDate ?? DateTime.now(),
                                    firstDate: DateTime(2000),
                                    lastDate: DateTime.now(),
                                  );
                                  if (picked != null) {
                                    setState(() => customDate = picked);
                                  }
                                },
                              ),
                          ],
                        ),
                      ),
                      _filterRow(
                        label: 'Search',
                        child: DropdownButton<String>(
                          value: selectedFolder,
                          isExpanded: true,
                          items:
                              folderNames
                                  .map(
                                    (f) => DropdownMenuItem(
                                      value: f,
                                      child: Text(f),
                                    ),
                                  )
                                  .toList(),
                          onChanged: (value) {
                            if (value == null) return;
                            setState(() => selectedFolder = value);
                          },
                        ),
                      ),
                      Row(
                        children: [
                          Checkbox(
                            value: hasAttachment,
                            onChanged: (value) {
                              setState(() => hasAttachment = value ?? false);
                            },
                          ),
                          const Text('Has attachment'),
                          const SizedBox(width: 24),
                          Checkbox(
                            value: excludeChats,
                            onChanged: (value) {
                              setState(() => excludeChats = value ?? false);
                            },
                          ),
                          const Text("Don't include chats"),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final query = buildQuery();
                    controller.text = query;
                    if (query.trim().isEmpty) {
                      mailProvider.clearSearch();
                    } else {
                      mailProvider.search(query);
                    }
                    Navigator.pop(context);
                  },
                  child: const Text('Search'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _filterRow({required String label, required Widget child}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          SizedBox(width: 160, child: Text(label)),
          Expanded(child: child),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final mailProvider = Provider.of<MailProvider>(context, listen: false);
    var size = MediaQuery.of(context).size;
    bool isSmallScreen = size.width < 800;
    return Column(
      children: [
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
                        onPressed: widget.toggleMenu,
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
                flex: 7,
                child: Container(
                  padding:
                      !isSmallScreen
                          ? const EdgeInsets.only(left: 55.0, right: 150)
                          : null,
                  child: SearchAnchor(
                    viewBackgroundColor: Theme.of(context).cardColor,
                    viewOnChanged: (value) {
                      _searchDebounce?.cancel();
                      _searchDebounce = Timer(
                        const Duration(milliseconds: 250),
                        () {
                          if (value.trim().isEmpty) {
                            mailProvider.clearLocalFilter();
                            if (mailProvider.isSearchMode) {
                              mailProvider.clearSearch();
                            }
                          } else {
                            if (mailProvider.isSearchMode) {
                              mailProvider.clearSearch();
                            }
                            mailProvider.applyLocalFilter(value);
                          }
                        },
                      );
                    },
                    viewOnSubmitted: (value) {
                      _searchDebounce?.cancel();
                      if (value.trim().isEmpty) {
                        mailProvider.clearLocalFilter();
                        mailProvider.clearSearch();
                      } else {
                        mailProvider.clearLocalFilter();
                        mailProvider.search(value);
                      }
                    },
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
                        child: Blur(
                          blur: themeProvider.bgBlur,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).cardColor.withValues(
                                alpha: themeProvider.bgOpacity,
                              ),
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            child: SearchBar(
                              shadowColor: WidgetStateProperty.all(
                                Colors.transparent,
                              ),
                              backgroundColor: WidgetStateProperty.all(
                                Colors.transparent,
                              ),
                              controller: controller,
                              padding: WidgetStateProperty.all<EdgeInsets>(
                                const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 0,
                                ),
                              ),
                              onTap: () {
                                controller.openView();
                              },
                              onChanged: (value) {
                                controller.openView();
                                _searchDebounce?.cancel();
                                _searchDebounce = Timer(
                                  const Duration(milliseconds: 250),
                                  () {
                                    if (value.trim().isEmpty) {
                                      mailProvider.clearLocalFilter();
                                      if (mailProvider.isSearchMode) {
                                        mailProvider.clearSearch();
                                      }
                                    } else {
                                      if (mailProvider.isSearchMode) {
                                        mailProvider.clearSearch();
                                      }
                                      mailProvider.applyLocalFilter(value);
                                    }
                                  },
                                );
                              },
                              onSubmitted: (value) {
                                _searchDebounce?.cancel();
                                if (value.trim().isEmpty) {
                                  mailProvider.clearLocalFilter();
                                  mailProvider.clearSearch();
                                } else {
                                  mailProvider.clearLocalFilter();
                                  mailProvider.search(value);
                                }
                              },
                              leading: Tooltip(
                                message: 'Toggle Menu',
                                child: Consumer<MailProvider>(
                                  builder: (context, provider, _) {
                                    final showLoader =
                                        provider.isSearchMode &&
                                        provider.isLoading;
                                    if (showLoader) {
                                      return const SizedBox(
                                        width: 36,
                                        height: 36,
                                        child: Padding(
                                          padding: EdgeInsets.all(8.0),
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        ),
                                      );
                                    }
                                    return IconButton(
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
                                    );
                                  },
                                ),
                              ),
                              trailing: <Widget>[
                                ValueListenableBuilder<TextEditingValue>(
                                  valueListenable: controller,
                                  builder: (context, value, _) {
                                    if (value.text.trim().isEmpty) {
                                      return const SizedBox.shrink();
                                    }
                                    return IconButton(
                                      tooltip: 'Clear search',
                                      onPressed: () {
                                        controller.clear();
                                        mailProvider.clearLocalFilter();
                                        mailProvider.clearSearch();
                                      },
                                      icon: const Icon(Icons.close_rounded),
                                    );
                                  },
                                ),
                                Tooltip(
                                  message:
                                      isSmallScreen
                                          ? 'Show Profile'
                                          : 'Search options',
                                  child: IconButton(
                                    onPressed: () {
                                      if (isSmallScreen) {
                                        _openDialog(
                                          widget: AccountSettingsTab(
                                            isSmallScreen: isSmallScreen,
                                          ),
                                          context: context,
                                        );
                                      } else {
                                        _openSearchFilterDialog(
                                          context,
                                          controller,
                                          mailProvider,
                                        );
                                      }
                                    },
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
                      final query = controller.text.trim().toLowerCase();
                      final history =
                          mailProvider.searchHistory
                              .where(
                                (item) =>
                                    query.isEmpty ||
                                    item.toLowerCase().contains(query),
                              )
                              .toList();

                      if (history.isEmpty) {
                        return const <Widget>[
                          ListTile(
                            title: Text('No recent searches'),
                          ),
                        ];
                      }

                      return history
                          .map(
                            (item) => ListTile(
                              leading: const Icon(Icons.history),
                              title: Text(item),
                              onTap: () {
                                controller.closeView(item);
                                if (item.trim().isEmpty) {
                                  mailProvider.clearSearch();
                                } else {
                                  mailProvider.search(item);
                                }
                              },
                            ),
                          )
                          .toList();
                    },
                  ),
                ),
              ),
              if (!isSmallScreen)
                Flexible(
                  flex: 3,
                  child: Row(
                    mainAxisSize: MainAxisSize.max,
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
                            onPressed: () {},
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
                            onPressed: widget.toggleSetting,
                            icon: const Icon(Icons.settings_rounded),
                          ),
                        ),
                      ),
                      Flexible(
                        child: Container(
                          width: 50,
                          height: 50,
                          margin: EdgeInsets.only(right: 50),
                          decoration: BoxDecoration(
                            color: Colors.white70,
                            borderRadius: BorderRadius.circular(50),
                          ),
                          child: IconButton(
                            onPressed: () {
                              _openDialog(
                                widget: AccountSettingsTab(
                                  isSmallScreen: isSmallScreen,
                                ),
                                context: context,
                              );
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
      ],
    );
  }
}
