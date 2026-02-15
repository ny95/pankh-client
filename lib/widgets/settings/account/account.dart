import 'package:flutter/material.dart';
import 'package:projectwebview/providers/auth_provider.dart';
import 'package:projectwebview/widgets/settings/account_list.dart';
import 'package:provider/provider.dart';
import '../../../utils/email_servers.dart';

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
  String serverType = 'IMAP Mail Server';
  String serverName = '';
  String userName = '';
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
  final _addAccountFormKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Widget _serverSetting(String email) {
    final serverInfo = serverInfoFromEmail(email);
    serverName = serverInfo.imapHost;
    userName = email;
    connectionSecurity = serverInfo.imapSecure ? 'SSL/TLS' : 'None';
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
        _buildReadOnlyField('Server Name:', serverName),
        _buildReadOnlyField('User Name:', userName),
        const SizedBox(height: 16),

        // Security Settings Section
        const Text(
          'Security Settings',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        _buildReadOnlyField('Connection security:', connectionSecurity),
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

  Widget _settingByName({required String type, required String email}) {
    switch (type) {
      case "server_setting":
        return _serverSetting(email);
      case "copies_folder":
        return Text(type);
      case "composition_addressing":
        return Text(type);
      case "junk_setting":
        return Text(type);
      case "disk_space":
        return Text(type);
      default:
        return _serverSetting(email);
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
          child: Consumer<AuthProvider>(
            builder: (context, auth, _) {
              final accounts = auth.accounts.map((a) => a.email).toList();
              return AccountList(
                onPressed: _toggleSetting,
                accounts: accounts,
                activeEmail: auth.activeEmail,
                onSelectAccount: (email) {
                  auth.setActive(email);
                },
                onRemoveAccount: (email) {
                  auth.removeAccount(email);
                },
              );
            },
          ),
        ),
        Expanded(
          child: Consumer<AuthProvider>(
            builder: (context, auth, _) {
              final email = auth.email ?? '';
              return SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(30),
                  child: _settingByName(type: currentSetting, email: email),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _showAddAccountDialog(BuildContext context) async {
    _emailController.clear();
    _passwordController.clear();
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Account'),
          content: Form(
            key: _addAccountFormKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Email is required';
                    }
                    if (!value.contains('@')) {
                      return 'Enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password / App Password',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Password is required';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!_addAccountFormKey.currentState!.validate()) return;
                await context.read<AuthProvider>().login(
                      email: _emailController.text,
                      password: _passwordController.text,
                    );
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return widget.isSmallScreen
        ? Scaffold(
          appBar: AppBar(
            title: const Text('Account Settings'),
            centerTitle: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.person_add_alt_1),
                onPressed: () => _showAddAccountDialog(context),
              ),
            ],
          ),
          body: _accountWidget(),
        )
        : Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, top: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => _showAddAccountDialog(context),
                    icon: const Icon(Icons.person_add_alt_1),
                    label: const Text('Add Account'),
                  ),
                ],
              ),
            ),
            Expanded(child: _accountWidget()),
          ],
        );
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
