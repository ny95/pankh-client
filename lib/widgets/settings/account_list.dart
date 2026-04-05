import 'package:flutter/material.dart';
import 'package:pankh/models/account.dart';

class AccountList extends StatefulWidget {
  final ValueChanged<String> onPressed;
  final List<Account> accounts;
  final String? activeEmail;
  final ValueChanged<Account> onSelectAccount;
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

  List<Account> get _accounts => widget.accounts;

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
      _accounts.length,
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
    if (_accounts.isEmpty) {
      return const Center(child: Text('No account found'));
    }
    return RadioGroup<String>(
      groupValue: widget.activeEmail,
      onChanged: (value) {
        if (value == null) return;
        final account = _accounts.firstWhere((a) => a.email == value);
        widget.onSelectAccount(account);
      },
      child: ListView(
        children: List.generate(
          _accounts.length,
          (index) => _buildEmailTile(_accounts[index], index),
        ),
      ),
    );
  }

  Widget _buildEmailTile(Account account, int index) {
    final email = account.email;
    final isExpanded = _currentExpandedIndex == index;
    final isActive = widget.activeEmail == email;
    final isSecure = account.imapSecure;
    final theme = Theme.of(context);
    final isSmallScreen = MediaQuery.of(context).size.width < 900;

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
            horizontalTitleGap: 0.5,
            leading: RotationTransition(
              turns: _iconTurns[index],
              child: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
            ),
            trailing:
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Tooltip(
                      message:
                          isActive ? 'Active account' : 'Set as active account',
                      child: Radio<String>(
                        value: email,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                    if (!isSecure)
                      Tooltip(
                        message: 'Connection is not secure',
                        child: Icon(
                          Icons.warning_amber_rounded,
                          size: 16,
                          color: Colors.orange.shade700,
                        ),
                      )
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
                        : theme.textTheme.bodySmall?.color,
              ),
            ),
            subtitle: Text(
              isActive ? 'Default account' : 'Tap to view settings',
              style: theme.textTheme.bodySmall,
            ),
            onTap: () {
              _handleTileTap(index);
              if (!isSmallScreen) {
                widget.onPressed('general_setting');
              }
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
                        if (isSmallScreen)
                          _buildMenuButton(
                            title: 'General Settings',
                            onPressed: () => widget.onPressed('general_setting'),
                          ),
                        _buildMenuButton(
                          title: 'Incoming Server Settings',
                          onPressed: () => widget.onPressed('incoming_server_setting'),
                        ),
                        _buildMenuButton(
                          title: 'Outgoing Server Settings',
                          onPressed: () => widget.onPressed('outgoing_server_setting'),
                        ),
                        _buildMenuButton(
                          title: 'Remove Account',
                          onPressed: () => widget.onPressed('general_setting'),
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
}
