import 'package:flutter/material.dart';

class AccountList extends StatefulWidget {
  final ValueChanged<String> onPressed;
  final List<String> accounts;
  final String? activeEmail;
  final ValueChanged<String> onSelectAccount;
  final ValueChanged<String> onRemoveAccount;

  const AccountList({
    super.key,
    required this.onPressed,
    required this.accounts,
    required this.activeEmail,
    required this.onSelectAccount,
    required this.onRemoveAccount,
  });

  @override
  AccountListState createState() => AccountListState();
}

class AccountListState extends State<AccountList>
    with TickerProviderStateMixin {
  int? _currentExpandedIndex;
  late List<AnimationController> _animationControllers;
  late List<Animation<double>> _iconTurns;

  List<String> get _accountEmails => widget.accounts;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  @override
  void didUpdateWidget(covariant AccountList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.accounts.length != widget.accounts.length) {
      for (final controller in _animationControllers) {
        controller.dispose();
      }
      _currentExpandedIndex = null;
      _initializeAnimations();
    }
  }

  void _initializeAnimations() {
    _animationControllers = List.generate(
      _accountEmails.length,
      (index) => AnimationController(
        duration: const Duration(milliseconds: 300),
        vsync: this,
      ),
    );

    _iconTurns =
        _animationControllers
            .map(
              (controller) => Tween(begin: 0.0, end: 0.25).animate(controller),
            )
            .toList();
  }

  @override
  void dispose() {
    for (final controller in _animationControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_accountEmails.isEmpty) {
      return const Center(child: Text('No account found'));
    }
    return ListView(
      children: List.generate(
        _accountEmails.length,
        (index) => _buildEmailTile(_accountEmails[index], index),
      ),
    );
  }

  Widget _buildEmailTile(String email, int index) {
    final isExpanded = _currentExpandedIndex == index;
    final isActive = widget.activeEmail == email;
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade300, width: 1.0),
        ),
      ),
      child: Column(
        children: [
          ListTile(
            dense: true,
            leading: RotationTransition(
              turns: _iconTurns[index],
              child: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
            ),
            trailing:
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isActive)
                      const Icon(Icons.check_circle, size: 16),
                    IconButton(
                      icon: const Icon(Icons.more_vert_rounded, size: 14),
                      onPressed: () => _showOptionsMenu(context, email),
                    ),
                  ],
                ),
            title: Text(
              email,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                color:
                    isActive
                        ? theme.primaryColor
                        : (isExpanded
                            ? theme.primaryColor
                            : theme.textTheme.bodySmall?.color),
              ),
            ),
            onTap: () {
              widget.onSelectAccount(email);
              _handleTileTap(index);
            },
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.fastOutSlowIn,
            alignment: Alignment.topCenter,
            child:
                isExpanded
                    ? Column(
                      children: [
                        _buildMenuButton(
                          title: 'Server Setting',
                          onPressed: () => widget.onPressed('server_setting'),
                        ),
                        _buildMenuButton(
                          title: 'Copies & Folder',
                          onPressed: () => widget.onPressed('copies_folder'),
                        ),
                        _buildMenuButton(
                          title: 'Composition & Addressing',
                          onPressed:
                              () => widget.onPressed('composition_addressing'),
                        ),
                        _buildMenuButton(
                          title: 'Junk Setting',
                          onPressed: () => widget.onPressed('junk_setting'),
                        ),
                        _buildMenuButton(
                          title: 'Disk Space',
                          onPressed: () => widget.onPressed('disk_space'),
                        ),
                      ],
                    )
                    : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  void _handleTileTap(int index) {
    setState(() {
      if (_currentExpandedIndex == index) {
        _currentExpandedIndex = null;
        _animationControllers[index].reverse();
      } else {
        if (_currentExpandedIndex != null) {
          _animationControllers[_currentExpandedIndex!].reverse();
        }
        _currentExpandedIndex = index;
        _animationControllers[index].forward();
      }
    });
  }

  Widget _buildMenuButton({
    required String title,
    required VoidCallback onPressed,
  }) {
    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 32),
      title: Text(title, style: const TextStyle(fontSize: 13)),
      onTap: onPressed, // ✅ fixed
    );
  }

  void _showOptionsMenu(BuildContext context, String email) {
    showModalBottomSheet(
      context: context,
      builder:
          (context) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.check_circle_outline, size: 20),
                title: const Text(
                  'Set Active',
                  style: TextStyle(fontSize: 14),
                ),
                onTap: () {
                  widget.onSelectAccount(email);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.edit, size: 20),
                title: const Text(
                  'Edit Account',
                  style: TextStyle(fontSize: 14),
                ),
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                leading: const Icon(Icons.delete, size: 20),
                title: const Text(
                  'Remove Account',
                  style: TextStyle(fontSize: 14),
                ),
                onTap: () {
                  widget.onRemoveAccount(email);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
    );
  }
}
