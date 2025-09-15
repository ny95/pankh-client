import 'package:flutter/material.dart';

class AccountList extends StatefulWidget {
  final ValueChanged<String> onPressed;

  const AccountList({super.key, required this.onPressed});

  @override
  _AccountListState createState() => _AccountListState();
}

class _AccountListState extends State<AccountList>
    with TickerProviderStateMixin {
  int? _currentExpandedIndex;
  late List<AnimationController> _animationControllers;
  late List<Animation<double>> _iconTurns;

  final List<String> _accountEmails = const [
    'naveenyadav0820@gmail.com',
    'immavenandthisismyemail001@gmail.com',
    'naveenyadav0820@gmail.com',
    'naveenyadav0820@gmail.com',
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
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
    return ListView(
      children: List.generate(
        _accountEmails.length,
        (index) => _buildEmailTile(_accountEmails[index], index),
      ),
    );
  }

  Widget _buildEmailTile(String email, int index) {
    final isExpanded = _currentExpandedIndex == index;
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
            trailing: IconButton(
              icon: const Icon(Icons.more_vert_rounded, size: 14),
              onPressed: () => _showOptionsMenu(context, email),
            ),
            title: Text(
              email,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                color:
                    isExpanded
                        ? theme.primaryColor
                        : theme.textTheme.bodySmall?.color,
              ),
            ),
            onTap: () => _handleTileTap(index),
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
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
    );
  }
}
