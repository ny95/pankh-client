import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pankh/widgets/blur.dart';
import 'package:pankh/widgets/open_dialog.dart';
import 'package:pankh/widgets/settings/account/account.dart';
import 'package:provider/provider.dart';

import '../providers/mail_provider.dart';
import '../providers/theme_provider.dart';

class Header extends StatefulWidget {
  final VoidCallback toggleMenu;
  final VoidCallback toggleSetting;
  final VoidCallback onHelp;

  const Header({
    super.key,
    required this.toggleMenu,
    required this.toggleSetting,
    required this.onHelp,
  });

  @override
  HeaderState createState() => HeaderState();
}

class HeaderState extends State<Header> with SingleTickerProviderStateMixin {
  bool filterHidden = false;
  Timer? _searchDebounce;
  bool showSearchFilter = false;
  late SearchController filterController = SearchController();
  
  // Add GlobalKey to get the position of the search bar
  final GlobalKey _searchBarKey = GlobalKey();
  
  // Add overlay entry reference
  OverlayEntry? _overlayEntry;
  
  // Add animation controller
  late AnimationController _animationController;
  final ValueNotifier<bool> _isFullScreenCloseButtonNotifier =
      ValueNotifier<bool>(true);
  late Animation<double> _fadeAnimation;
  
  // Add state for filter form
  String sizeOp = 'greater than';
  String sizeUnit = 'MB';
  String dateWithin = 'Any time';
  DateTime? customDate;
  String selectedFolder = 'All Mail';
  bool hasAttachment = false;
  bool excludeChats = false;
  
  // Dropdown options
  final List<String> sizeOpOptions = ['greater than', 'less than'];
  final List<String> sizeUnitOptions = ['KB', 'MB', 'GB'];
  final List<String> dateWithinOptions = [
    'Any time',
    '1 day',
    '7 days',
    '1 month',
    '1 year',
    'Custom'
  ];
  
  // Text controllers
  final TextEditingController fromCtrl = TextEditingController();
  final TextEditingController toCtrl = TextEditingController();
  final TextEditingController subjectCtrl = TextEditingController();
  final TextEditingController includeCtrl = TextEditingController();
  final TextEditingController excludeCtrl = TextEditingController();
  final TextEditingController sizeCtrl = TextEditingController();

  // Add ScrollController to track scroll position
  final ScrollController _scrollController = ScrollController();
  
  // Track overlay visibility
  bool _isOverlayVisible = false;
  
  // Add resize listener
  late WidgetsBinding _widgetsBinding;
  late final _ResizeObserver _resizeObserver;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    
    _widgetsBinding = WidgetsBinding.instance;
    _resizeObserver = _ResizeObserver(this);
    _widgetsBinding.addPostFrameCallback((_) {
      _widgetsBinding.addObserver(_resizeObserver);
    });
  }

  @override
  void dispose() {
    _widgetsBinding.removeObserver(_resizeObserver);
    _searchDebounce?.cancel();
    _removeOverlay();
    _isFullScreenCloseButtonNotifier.dispose();
    _animationController.dispose();
    _scrollController.dispose();
    fromCtrl.dispose();
    toCtrl.dispose();
    subjectCtrl.dispose();
    includeCtrl.dispose();
    excludeCtrl.dispose();
    sizeCtrl.dispose();
    super.dispose();
  }

  void _handleSearchChanged(String value, MailProvider mailProvider) {
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
  }

  void _handleSearchSubmitted(String value, MailProvider mailProvider) {
    _searchDebounce?.cancel();
    if (value.trim().isEmpty) {
      mailProvider.clearLocalFilter();
      mailProvider.clearSearch();
    } else {
      mailProvider.clearLocalFilter();
      mailProvider.search(value);
    }
  }

  void _handleResize() {
    if (_isOverlayVisible && mounted) {
      _updateOverlayPosition();
    }
  }

  void _updateOverlayPosition() {
    if (_overlayEntry != null && _isOverlayVisible) {
      _overlayEntry!.markNeedsBuild();
    }
  }

  void _removeOverlay() {
    _isOverlayVisible = false;
    _overlayEntry?.remove();
    _overlayEntry = null;
  }
  void updateFullScreenCloseButton (bool status) {
    _isFullScreenCloseButtonNotifier.value = status;
  }

  void _showFilterOverlay(SearchController controller) {
    // Remove existing overlay if any
    _removeOverlay();
    
    // Set the controller
    filterController = controller;
    
    // Pre-fill include words with current search query
    final currentQuery = controller.text.trim();
    if (currentQuery.isNotEmpty) {
      includeCtrl.text = currentQuery;
    }
    
    _isOverlayVisible = true;
    
    // Create overlay entry
    _overlayEntry = OverlayEntry(
      builder: (context) {
        // Get the render box of the search bar
        final renderBox = _searchBarKey.currentContext?.findRenderObject() as RenderBox?;
        if (renderBox == null) return const SizedBox.shrink();
        
        // Get the position relative to the screen
        final offset = renderBox.localToGlobal(Offset.zero);
        final size = renderBox.size;
        
        // Calculate available space below and above
        final screenHeight = MediaQuery.of(context).size.height;
        final spaceBelow = screenHeight - (offset.dy + size.height);
        final spaceAbove = offset.dy;
        
        // Determine if we should show above or below
        final bool showAbove = spaceBelow < 400 && spaceAbove > spaceBelow;
        
        return Stack(
          children: [
            // Backdrop to capture taps outside
            Positioned.fill(
              child: GestureDetector(
                onTap: () {
                  _removeOverlay();
                  setState(() {
                    showSearchFilter = false;
                  });
                },
                child: Container(
                  color: Colors.transparent,
                ),
              ),
            ),
            // Positioned filter box with animation
            Positioned(
              top: showAbove ? null : (offset.dy - 50) + size.height,
              bottom: showAbove ? screenHeight - offset.dy : null,
              left: offset.dx,
              width: size.width,
              child: Material(
                color: Colors.transparent,
                elevation: 0,
                child: AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _fadeAnimation.value,
                      child: child,
                    );
                  },
                  child: _buildSearchFilterOverlay(
                    context,
                    controller,
                    Provider.of<MailProvider>(context, listen: false),
                    onClose: () {
                      _removeOverlay();
                      setState(() {
                        showSearchFilter = false;
                      });
                    },
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
    
    // Insert the overlay and start animation
    Overlay.of(context).insert(_overlayEntry!);
    _animationController.forward();
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
        final multiplier = sizeUnit == 'KB'
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

  Widget _buildSearchFilterOverlay(
    BuildContext context,
    SearchController controller,
    MailProvider mailProvider, {
    required VoidCallback onClose,
  }) {
    final folders = mailProvider.folders;
    final folderNames = {
      'All Mail',
      ...folders.map((f) => f.name),
    }.toList();

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: Theme.of(context).dividerColor,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.only(left: 16, top:6, right: 6, bottom: 6),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).dividerColor,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Search options',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  onPressed: onClose,
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          LayoutBuilder(
            builder: (context, constraints) {
              return ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.6,
                  maxWidth: constraints.maxWidth,
                ),
                child: RawScrollbar(
                  controller: _scrollController,
                  thumbVisibility: true,
                  thickness: 8,
                  radius: const Radius.circular(8),
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _filterRow(
                          label: 'From',
                          child: TextField(
                            controller: fromCtrl,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                          ),
                        ),
                        _filterRow(
                          label: 'To',
                          child: TextField(
                            controller: toCtrl,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                          ),
                        ),
                        _filterRow(
                          label: 'Subject',
                          child: TextField(
                            controller: subjectCtrl,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                          ),
                        ),
                        _filterRow(
                          label: 'Includes the words',
                          child: TextField(
                            controller: includeCtrl,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                          ),
                        ),
                        _filterRow(
                          label: "Doesn't have",
                          child: TextField(
                            controller: excludeCtrl,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                          ),
                        ),
                        _filterRow(
                          label: 'Size',
                          child: Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: _CustomDropdown<String>(
                                  value: sizeOp,
                                  items: sizeOpOptions,
                                  onChanged: (value) {
                                    if (value != null) {
                                      setState(() => sizeOp = value);
                                    }
                                  },
                                  backgroundColor: Theme.of(context).cardColor,
                                  parentOverlayEntry: _overlayEntry,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 1,
                                child: TextField(
                                  controller: sizeCtrl,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                    isDense: true,
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 8,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 1,
                                child: _CustomDropdown<String>(
                                  value: sizeUnit,
                                  items: sizeUnitOptions,
                                  onChanged: (value) {
                                    if (value != null) {
                                      setState(() => sizeUnit = value);
                                    }
                                  },
                                  backgroundColor: Theme.of(context).cardColor,
                                  parentOverlayEntry: _overlayEntry,
                                ),
                              ),
                            ],
                          ),
                        ),
                        _filterRow(
                          label: 'Date within',
                          child: Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: _CustomDropdown<String>(
                                  value: dateWithin,
                                  items: dateWithinOptions,
                                  onChanged: (value) {
                                    if (value != null) {
                                      setState(() {
                                        dateWithin = value;
                                      });
                                      if (value == 'Custom' && customDate == null) {
                                        setState(() {
                                          customDate = DateTime.now();
                                        });
                                      }
                                    }
                                  },
                                  backgroundColor: Theme.of(context).cardColor,
                                  parentOverlayEntry: _overlayEntry,
                                ),
                              ),
                              if (dateWithin == 'Custom') ...[
                                const SizedBox(width: 8),
                                Expanded(
                                  flex: 3,
                                  child: _CustomDateDropdown(
                                    selectedDate: customDate,
                                    onDateSelected: (date) {
                                      setState(() {
                                        customDate = date;
                                        if (date == null) {
                                          dateWithin = 'Any time';
                                        }
                                      });
                                    },
                                    backgroundColor: Theme.of(context).cardColor,
                                    parentOverlayEntry: _overlayEntry,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        _filterRow(
                          label: 'Search in',
                          child: _CustomDropdown<String>(
                            value: selectedFolder,
                            items: folderNames,
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => selectedFolder = value);
                              }
                            },
                            backgroundColor: Theme.of(context).cardColor,
                            parentOverlayEntry: _overlayEntry,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Row(
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
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: Theme.of(context).dividerColor,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: onClose,
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    final query = buildQuery();
                    controller.text = query;
                    if (query.trim().isEmpty) {
                      mailProvider.clearSearch();
                    } else {
                      mailProvider.search(query);
                    }
                    onClose();
                  },
                  child: const Text('Search'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterRow({required String label, required Widget child}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(width: 12),
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
            isSmallScreen ? 16 : 30,
            isSmallScreen ? 6 : 16,
            isSmallScreen ? 16 : 16,
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
                      SizedBox(width: 40,),
                      Flexible(
                        child: Image.asset(
                          'assets/logos/pankh-2d.png',
                          // width: 75,
                          height: 45,
                        ),
                      )
                      // const Text(  
                      //   'Wings',
                      //   style: TextStyle(
                      //     fontSize: 18,
                      //     fontStyle: FontStyle.italic,
                      //   ),
                      // ),
                    ],
                  ),
                ),
              Flexible(
                flex: 7,
                child: Container(
                  padding: !isSmallScreen
                      ? const EdgeInsets.only(left: 55.0)
                      : null,
                  child: Container(
                    key: _searchBarKey,
                    child: SearchAnchor(
                      viewBackgroundColor: Theme.of(context).cardColor,
                      viewOnChanged: (value) {
                        _handleSearchChanged(value, mailProvider);
                      },
                      viewOnSubmitted: (value) {
                        _handleSearchSubmitted(value, mailProvider);
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
                                color: Theme.of(context).cardColor.withValues(
                                  alpha: themeProvider.bgOpacity,
                                ),
                                borderRadius: BorderRadius.circular(50),
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
                                  _handleSearchChanged(value, mailProvider);
                                },
                                onSubmitted: (value) {
                                  _handleSearchSubmitted(value, mailProvider);
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
                                    message: isSmallScreen
                                        ? 'Show Profile'
                                        : 'Search options',
                                    child: IconButton(
                                      onPressed: () {
                                        if (isSmallScreen) {
                                          CustomDialog.show(
                                            child: AccountSettingsTab(updateFullScreenCloseButton: updateFullScreenCloseButton,),
                                            context: context,
                                            isFullScreenCloseButtonListenable:
                                                _isFullScreenCloseButtonNotifier,
                                          );
                                        } else {
                                          setState(() {
                                            showSearchFilter = !showSearchFilter;
                                          });
                                          
                                          if (showSearchFilter) {
                                            _showFilterOverlay(controller);
                                          } else {
                                            _removeOverlay();
                                          }
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
                        final history = mailProvider.searchHistory
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
              ),
              if (!isSmallScreen)
                Flexible(
                  flex: 3,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      alignment: WrapAlignment.end,
                      children: [
                        SizedBox(
                          width: 50,
                          height: 50,
                          child: IconButton(
                            onPressed: widget.onHelp,
                            icon: const Icon(Icons.help_outline_rounded),
                          ),
                        ),
                        SizedBox(
                          width: 50,
                          height: 50,
                          child: IconButton(
                            onPressed: widget.toggleSetting,
                            icon: const Icon(Icons.settings_rounded),
                          ),
                        ),
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.white70,
                            borderRadius: BorderRadius.circular(50),
                          ),
                          child: IconButton(
                            onPressed: () {
                              CustomDialog.show(
                                child: AccountSettingsTab(updateFullScreenCloseButton: (p0)=>{},),
                                context: context,
                              );
                            },
                            icon: const Icon(Icons.person),
                          ),
                        ),
                      ],
                    ),
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
                  child: filterHidden
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

// Observer for resize events
class _ResizeObserver with WidgetsBindingObserver {
  final HeaderState _state;
  
  _ResizeObserver(this._state);
  
  @override
  void didChangeMetrics() {
    _state._handleResize();
  }
}

// Custom dropdown that updates position with its opener
class _CustomDropdown<T> extends StatefulWidget {
  final T value;
  final List<T> items;
  final ValueChanged<T?>? onChanged;
  final Color backgroundColor;
  final OverlayEntry? parentOverlayEntry;

  const _CustomDropdown({
    super.key,
    required this.value,
    required this.items,
    this.onChanged,
    required this.backgroundColor,
    this.parentOverlayEntry,
  });

  @override
  _CustomDropdownState<T> createState() => _CustomDropdownState<T>();
}

class _CustomDropdownState<T> extends State<_CustomDropdown<T>> {
  OverlayEntry? _overlayEntry;
  final GlobalKey _dropdownKey = GlobalKey();
  bool _isOpen = false;

  void _updateParentOverlay() {
    if (widget.parentOverlayEntry != null) {
      widget.parentOverlayEntry!.markNeedsBuild();
    }
  }

  void _toggleDropdown() {
    if (_isOpen) {
      _closeDropdown();
    } else {
      _openDropdown();
    }
  }

  void _openDropdown() {
    if (widget.onChanged == null) return;
    
    final renderBox = _dropdownKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    
    _overlayEntry = OverlayEntry(
      builder: (context) {
        // Recalculate position on every build
        final currentRenderBox = _dropdownKey.currentContext?.findRenderObject() as RenderBox?;
        if (currentRenderBox == null) return const SizedBox.shrink();
        
        final currentOffset = currentRenderBox.localToGlobal(Offset.zero);
        final currentSize = currentRenderBox.size;
        
        // Get screen dimensions
        final screenHeight = MediaQuery.of(context).size.height;
        final screenWidth = MediaQuery.of(context).size.width;
        
        // Calculate available space
        final spaceBelow = screenHeight - (currentOffset.dy + currentSize.height);
        final spaceAbove = currentOffset.dy;
        
        // Determine if dropdown should open above or below
        final bool openAbove = spaceBelow < 200 && spaceAbove > spaceBelow;
        
        // Calculate dropdown width
        final double dropdownWidth = currentSize.width;
        
        // Ensure dropdown doesn't go off screen horizontally
        final double rightOverflow = (currentOffset.dx + dropdownWidth) - screenWidth;
        final double adjustedLeft = rightOverflow > 0 ? currentOffset.dx - rightOverflow : currentOffset.dx;
        
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                onTap: _closeDropdown,
                child: Container(color: Colors.transparent),
              ),
            ),
            Positioned(
              top: openAbove ? null : currentOffset.dy + currentSize.height,
              bottom: openAbove ? screenHeight - currentOffset.dy : null,
              left: adjustedLeft,
              width: dropdownWidth,
              child: Material(
                elevation: 8,
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 200),
                  decoration: BoxDecoration(
                    color: widget.backgroundColor,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: widget.items.length,
                    itemBuilder: (context, index) {
                      final item = widget.items[index];
                      final isSelected = item == widget.value;
                      return InkWell(
                        onTap: () {
                          widget.onChanged?.call(item);
                          _closeDropdown();
                          _updateParentOverlay();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          color: isSelected ? Colors.grey.shade200 : null,
                          child: Text(item.toString()),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
    
    setState(() => _isOpen = true);
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _closeDropdown({bool skipState = false}) {
    _overlayEntry?.remove();
    _overlayEntry = null;
    if (!skipState && mounted) {
      setState(() => _isOpen = false);
      _updateParentOverlay();
    }
  }

  @override
  void dispose() {
    _closeDropdown(skipState: true);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: _dropdownKey,
      onTap: _toggleDropdown,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: widget.backgroundColor,
          border: Border.all(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                widget.value.toString(),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(_isOpen ? Icons.arrow_drop_up : Icons.arrow_drop_down),
          ],
        ),
      ),
    );
  }
}

// Custom date dropdown with full calendar
class _CustomDateDropdown extends StatefulWidget {
  final DateTime? selectedDate;
  final ValueChanged<DateTime?> onDateSelected;
  final Color backgroundColor;
  final OverlayEntry? parentOverlayEntry;

  const _CustomDateDropdown({
    required this.selectedDate,
    required this.onDateSelected,
    required this.backgroundColor,
    this.parentOverlayEntry,
  });

  @override
  _CustomDateDropdownState createState() => _CustomDateDropdownState();
}

class _CustomDateDropdownState extends State<_CustomDateDropdown> {
  OverlayEntry? _overlayEntry;
  final GlobalKey _dropdownKey = GlobalKey();
  bool _isOpen = false;
  DateTime _currentMonth = DateTime.now();
  DateTime? _selectedDate;
  
  final List<String> weekDays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.selectedDate;
    if (_selectedDate != null) {
      _currentMonth = DateTime(_selectedDate!.year, _selectedDate!.month);
    }
  }

  @override
  void didUpdateWidget(_CustomDateDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedDate != oldWidget.selectedDate) {
      setState(() {
        _selectedDate = widget.selectedDate;
        if (_selectedDate != null) {
          _currentMonth = DateTime(_selectedDate!.year, _selectedDate!.month);
        }
      });
    }
  }

  void _updateParentOverlay() {
    if (widget.parentOverlayEntry != null) {
      widget.parentOverlayEntry!.markNeedsBuild();
    }
  }

  void _toggleDropdown() {
    if (_isOpen) {
      _closeDropdown();
    } else {
      _openDropdown();
    }
  }

  void _openDropdown() {
    final renderBox = _dropdownKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    
    _overlayEntry = OverlayEntry(
      builder: (context) {
        final currentRenderBox = _dropdownKey.currentContext?.findRenderObject() as RenderBox?;
        if (currentRenderBox == null) return const SizedBox.shrink();
        
        final currentOffset = currentRenderBox.localToGlobal(Offset.zero);
        final currentSize = currentRenderBox.size;
        
        // Get screen dimensions
        final screenHeight = MediaQuery.of(context).size.height;
        final screenWidth = MediaQuery.of(context).size.width;
        
        // Calculate available space
        final spaceBelow = screenHeight - (currentOffset.dy + currentSize.height);
        final spaceAbove = currentOffset.dy;
        
        // Determine if dropdown should open above or below
        final bool openAbove = spaceBelow < 400 && spaceAbove > spaceBelow;
        
        // Calculate dropdown width
        final double dropdownWidth = 300;
        
        // Ensure dropdown doesn't go off screen horizontally
        final double rightOverflow = (currentOffset.dx + dropdownWidth) - screenWidth;
        final double adjustedLeft = rightOverflow > 0 ? currentOffset.dx - rightOverflow : currentOffset.dx;
        
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                onTap: _closeDropdown,
                child: Container(color: Colors.transparent),
              ),
            ),
            Positioned(
              top: openAbove ? null : currentOffset.dy + currentSize.height,
              bottom: openAbove ? screenHeight - currentOffset.dy : null,
              left: adjustedLeft,
              width: dropdownWidth,
              child: Material(
                elevation: 8,
                child: Container(
                  width: dropdownWidth,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: widget.backgroundColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Month and Year header with navigation
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.chevron_left),
                            onPressed: () {
                              setState(() {
                                _currentMonth = DateTime(
                                  _currentMonth.year,
                                  _currentMonth.month - 1,
                                );
                              });
                              _overlayEntry?.markNeedsBuild();
                            },
                          ),
                          Text(
                            '${_monthName(_currentMonth.month)} ${_currentMonth.year}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.chevron_right),
                            onPressed: () {
                              setState(() {
                                _currentMonth = DateTime(
                                  _currentMonth.year,
                                  _currentMonth.month + 1,
                                );
                              });
                              _overlayEntry?.markNeedsBuild();
                            },
                          ),
                        ],
                      ),
                      
                      // Weekday headers
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: weekDays.map((day) => 
                            Container(
                              width: 32,
                              alignment: Alignment.center,
                              child: Text(
                                day,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ).toList(),
                        ),
                      ),
                      
                      // Calendar days grid
                      _buildCalendarGrid(),
                      
                      const Divider(height: 16),
                      
                      // Action buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () {
                              widget.onDateSelected(null);
                              _closeDropdown();
                              _updateParentOverlay();
                            },
                            child: const Text('Clear'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () {
                              if (_selectedDate != null) {
                                widget.onDateSelected(_selectedDate);
                              }
                              _closeDropdown();
                              _updateParentOverlay();
                            },
                            child: const Text('Select'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
    
    setState(() => _isOpen = true);
    Overlay.of(context).insert(_overlayEntry!);
  }

  Widget _buildCalendarGrid() {
    // Get first day of month
    final firstDay = DateTime(_currentMonth.year, _currentMonth.month, 1);
    int startingWeekday = firstDay.weekday - 1; // Convert to Monday=0
    if (startingWeekday < 0) startingWeekday = 6;
    
    // Get number of days in month
    final lastDay = DateTime(_currentMonth.year, _currentMonth.month + 1, 0);
    final daysInMonth = lastDay.day;
    
    // Calculate total cells needed (6 weeks)
    final totalCells = 42;
    
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 1,
      ),
      itemCount: totalCells,
      padding: EdgeInsets.zero,
      itemBuilder: (context, index) {
        final dayNumber = index - startingWeekday + 1;
        final isInMonth = dayNumber >= 1 && dayNumber <= daysInMonth;
        
        if (!isInMonth) {
          return Container();
        }
        
        final date = DateTime(_currentMonth.year, _currentMonth.month, dayNumber);
        final isSelected = _selectedDate != null &&
            _selectedDate!.year == date.year &&
            _selectedDate!.month == date.month &&
            _selectedDate!.day == date.day;
        final isToday = _isSameDay(date, DateTime.now());
        
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedDate = date;
            });
            _overlayEntry?.markNeedsBuild();
          },
          child: Container(
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected 
                  ? Theme.of(context).primaryColor
                  : isToday
                      ? Theme.of(context).primaryColor.withValues(alpha: 0.2)
                      : null,
            ),
            child: Center(
              child: Text(
                dayNumber.toString(),
                style: TextStyle(
                  color: isSelected ? Colors.white : null,
                  fontWeight: isToday ? FontWeight.bold : null,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _monthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }

  void _closeDropdown({bool skipState = false}) {
    _overlayEntry?.remove();
    _overlayEntry = null;
    if (!skipState && mounted) {
      setState(() => _isOpen = false);
    }
  }

  @override
  void dispose() {
    _closeDropdown(skipState: true);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: _dropdownKey,
      onTap: _toggleDropdown,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: widget.backgroundColor,
          border: Border.all(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                widget.selectedDate != null
                    ? '${widget.selectedDate!.year}-${widget.selectedDate!.month.toString().padLeft(2, '0')}-${widget.selectedDate!.day.toString().padLeft(2, '0')}'
                    : 'Select date',
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(_isOpen ? Icons.arrow_drop_up : Icons.arrow_drop_down),
          ],
        ),
      ),
    );
  }
}
