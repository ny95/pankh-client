import 'package:flutter/material.dart';
import 'package:projectwebview/widgets/settings/accountList.dart';

class AccountSettingsTab extends StatelessWidget {
  final bool isSmallScreen;

  const AccountSettingsTab({super.key, required this.isSmallScreen});

  @override
  Widget build(BuildContext context) {
    return ServerSettingsDialog(isSmallScreen: isSmallScreen);
  }
}

class ServerSettingsDialog extends StatefulWidget {
  final bool isSmallScreen;

  const ServerSettingsDialog({super.key, required this.isSmallScreen});

  @override
  State<ServerSettingsDialog> createState() => _ServerSettingsDialogState();
}

class _ServerSettingsDialogState extends State<ServerSettingsDialog>
    with SingleTickerProviderStateMixin {
  String currentSetting = 'server_setting';
  String serverType = 'POP Mail Server';
  String serverName = 'mail.neosoftmail.com';
  String userName = 'naveen.y@neosoftmail.com';
  String connectionSecurity = 'STARTTLS';
  String authMethod = 'Normal password';
  bool checkAtStartup = true;
  bool checkEvery2Mins = true;
  bool autoDownload = true;
  bool fetchHeadersOnly = false;
  bool leaveOnServer = true;
  bool for365Days = true;
  bool untilDeleted = true;
  bool emptyTrashOnExit = false;
  String messageStoreType = 'File per folder (mbox)';

  final TextEditingController _serverNameController = TextEditingController();
  final TextEditingController _userNameController = TextEditingController();
  late AnimationController _animationController;
  late Animation<double> _iconTurns;
  @override
  void initState() {
    super.initState();
    _serverNameController.text = 'mail.neosoftmail.com';
    _userNameController.text = 'naveen.y@neosoftmail.com';
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _iconTurns = Tween<double>(
      begin: 0.0,
      end: 0.25,
    ).animate(_animationController);
  }

  @override
  void dispose() {
    _serverNameController.dispose();
    _userNameController.dispose();
    super.dispose();
  }

  Widget _serverSetting() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Server Information Section
        const Text(
          'Server Settings',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        _buildReadOnlyField('Server Type:', serverType),
        _buildTextField(
          'Server Name:',
          serverName,
          (value) => setState(() => serverName = value),
        ),
        _buildTextField(
          'User Name:',
          userName,
          (value) => setState(() => userName = value),
        ),
        const SizedBox(height: 16),

        // Security Settings Section
        const Text(
          'Security Settings',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        _buildDropdownField(
          'Connection security:',
          connectionSecurity,
          ['STARTTLS', 'SSL/TLS', 'None'],
          (value) => setState(() => connectionSecurity = value!),
        ),
        _buildDropdownField(
          'Authentication method:',
          authMethod,
          ['Normal password', 'OAuth2', 'Kerberos'],
          (value) => setState(() => authMethod = value!),
        ),
        const SizedBox(height: 16),

        // Server Behavior Section
        const Text(
          'Server Settings',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        _buildCheckboxRow(
          'Check for new messages at startup',
          checkAtStartup,
          (value) => setState(() => checkAtStartup = value!),
        ),
        _buildCheckboxRow(
          'Check for new messages every 2 minutes',
          checkEvery2Mins,
          (value) => setState(() => checkEvery2Mins = value!),
        ),
        _buildCheckboxRow(
          'Automatically download new messages',
          autoDownload,
          (value) => setState(() => autoDownload = value!),
        ),
        _buildCheckboxRow(
          'Fetch headers only',
          fetchHeadersOnly,
          (value) => setState(() => fetchHeadersOnly = value!),
        ),
        _buildCheckboxRow(
          'Leave messages on server',
          leaveOnServer,
          (value) => setState(() => leaveOnServer = value!),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 24.0),
          child: Column(
            children: [
              _buildCheckboxRow(
                'For at most 365 days',
                for365Days,
                (value) => setState(() => for365Days = value!),
              ),
              _buildCheckboxRow(
                'Until I delete them',
                untilDeleted,
                (value) => setState(() => untilDeleted = value!),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Message Storage Section
        const Text(
          'Message Storage',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        _buildCheckboxRow(
          'Empty Trash on Exit',
          emptyTrashOnExit,
          (value) => setState(() => emptyTrashOnExit = value!),
        ),
        _buildDropdownField(
          'Message Store Type:',
          messageStoreType,
          ['File per folder (mbox)', 'Single file (mbox)', 'Maildir'],
          (value) => setState(() => messageStoreType = value!),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _settingByName({required String type}) {
    switch (type) {
      case "server_setting":
        return _serverSetting();
      case "copies_folder":
        return Text(type);
      case "composition_addressing":
        return Text(type);
      case "junk_setting":
        return Text(type);
      case "disk_space":
        return Text(type);
      default:
        return _serverSetting();
    }
  }

  void _toggleSetting(String type) {
    debugPrint('Setting type: $type');
    setState(() {
      currentSetting = type;
    });
  }

  Widget _accountWidget() {
    return Row(
      children: [
        Container(
          width: 300,
          decoration: BoxDecoration(
            border: Border(right: BorderSide(color: Colors.black38, width: 1)),
          ),
          child: AccountList(onPressed: _toggleSetting),
        ),
        Expanded(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(30),
              child: _settingByName(type: currentSetting),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return widget.isSmallScreen
        ? Scaffold(
          appBar: AppBar(
            title: const Text('Account Settings'),
            centerTitle: true,
          ),
          body: _accountWidget(),
        )
        : _accountWidget();
  }

  Widget _buildReadOnlyField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          SizedBox(width: 120, child: Text(label)),
          const SizedBox(width: 8),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildTextField(
    String label,
    String initialValue,
    ValueChanged<String> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          SizedBox(width: 120, child: Text(label)),
          const SizedBox(width: 8),
          SizedBox(
            width: 300,
            child: TextFormField(
              initialValue: initialValue,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                isDense: true,
              ),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownField(
    String label,
    String value,
    List<String> options,
    ValueChanged<String?> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          SizedBox(width: 120, child: Text(label)),
          const SizedBox(width: 8),
          DropdownButton<String>(
            value: value,
            items:
                options.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildCheckboxRow(
    String label,
    bool value,
    ValueChanged<bool?> onChanged,
  ) {
    return Row(
      children: [Checkbox(value: value, onChanged: onChanged), Text(label)],
    );
  }
}
