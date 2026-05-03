import 'package:flutter/material.dart';
import 'package:pankh/models/account.dart';
import 'package:pankh/providers/auth_provider.dart';
import 'package:pankh/services/imap_service.dart';
import 'package:pankh/services/smtp_service.dart';
import 'package:pankh/widgets/settings/account_list.dart';
import 'package:provider/provider.dart';
import '../../../utils/email_servers.dart';

class AccountSettingsTab extends StatelessWidget {
  final void Function(bool) updateFullScreenCloseButton;


  const AccountSettingsTab({super.key, required this.updateFullScreenCloseButton});

  @override
  Widget build(BuildContext context) {
    return ServerSettingsDialog(updateFullScreenCloseButton: updateFullScreenCloseButton,);
  }
}

class ServerSettingsDialog extends StatefulWidget {
  final void Function(bool) updateFullScreenCloseButton;
  const ServerSettingsDialog({super.key, required this.updateFullScreenCloseButton});

  @override
  State<ServerSettingsDialog> createState() => _ServerSettingsDialogState();
}

class _ServerSettingsDialogState extends State<ServerSettingsDialog>
    with SingleTickerProviderStateMixin {
  String currentSetting = 'general_setting';
  String serverType = 'IMAP Mail Server';
  final _addAccountFormKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _serverNameController = TextEditingController();
  final _portController = TextEditingController();
  final _localDirController = TextEditingController();
  String? _editingEmail;
  bool _isTesting = false;
  bool _isAccountMenuClicked = false;
  bool _isTestingOutgoing = false;
  String? _selectedOutgoingEmail;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _serverNameController.dispose();
    _portController.dispose();
    _localDirController.dispose();
    super.dispose();
  }

  void _syncControllers(Account account) {
    if (_editingEmail == account.email &&
        _serverNameController.text == account.imapHost) {
      return;
    }
    _editingEmail = account.email;
    _serverNameController.text = account.imapHost;
    _portController.text = account.imapPort.toString();
    _localDirController.text = account.localDirectory;
  }

  Future<bool> _confirmInsecureConnection(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text('Unsecure connection'),
                content: const Text(
                  'This server does not use SSL/TLS. Your credentials and '
                  'mail data could be exposed. Do you want to continue?',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Continue'),
                  ),
                ],
              ),
        ) ??
        false;
  }

  Future<void> _saveServerName({
    required AuthProvider auth,
    required Account account,
    required String value,
  }) async {
    final raw = value.trim();
    if (raw.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Server name cannot be empty.')),
        );
      }
      _serverNameController.text = account.imapHost;
      return;
    }
    String host = raw;
    int? port;
    if (raw.contains(':')) {
      final parts = raw.split(':');
      if (parts.length == 2 && parts.first.trim().isNotEmpty) {
        host = parts.first.trim();
        port = int.tryParse(parts.last.trim());
      }
    }
    if (host == account.imapHost &&
        (port == null || port == account.imapPort)) {
      return;
    }
    if (port != null && (port <= 0 || port > 65535)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid port in server name.')),
        );
      }
      return;
    }
    await auth.updateAccount(
      account.copyWith(imapHost: host, imapPort: port),
    );
  }

  Future<void> _savePort({
    required AuthProvider auth,
    required Account account,
    required String value,
  }) async {
    final raw = value.trim();
    final parsed = int.tryParse(raw);
    if (parsed == null || parsed <= 0 || parsed > 65535) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enter a valid port (1-65535).')),
        );
      }
      _portController.text = account.imapPort.toString();
      return;
    }
    if (parsed == account.imapPort) return;
    await auth.updateAccount(account.copyWith(imapPort: parsed));
  }

  Future<void> _saveLocalDirectory({
    required AuthProvider auth,
    required Account account,
    required String value,
  }) async {
    await auth.updateAccount(account.copyWith(localDirectory: value.trim()));
  }

  Widget _serverSetting(Account account) {
    _syncControllers(account);
    final userName = account.email;
    final connectionSecurity = account.imapSecure ? 'SSL/TLS' : 'None';
    final isCompact = MediaQuery.sizeOf(context).width < 600;
    final defaultPort = account.imapSecure ? 993 : 143;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionCard(
          title: 'Server Settings',
          children: [
            _buildReadOnlyField('Server Type:', serverType, isCompact),
            _buildServerAndPortRow(
              serverLabel: 'Server Name:',
              serverController: _serverNameController,
              portController: _portController,
              defaultPort: defaultPort,
              isCompact: isCompact,
              onSaveServer:
                  (value) => _saveServerName(
                    auth: context.read<AuthProvider>(),
                    account: account,
                    value: value,
                  ),
              onSavePort:
                  (value) => _savePort(
                    auth: context.read<AuthProvider>(),
                    account: account,
                    value: value,
                  ),
            ),
            _buildReadOnlyField('User Name:', userName, isCompact),
          ],
        ),
        if (!account.imapSecure)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.orange.shade700,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'This account uses an unsecure IMAP connection.',
                    ),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 12),
        _buildSectionCard(
          title: 'Security Settings',
          children: [
            _buildDropdownField(
              'Connection security:',
              connectionSecurity,
              ['SSL/TLS', 'None'],
              (value) async {
                if (value == null) return;
                final auth = context.read<AuthProvider>();
                if (value == 'None') {
                  final ok = await _confirmInsecureConnection(context);
                  if (!ok) return;
                }
                if (!mounted) return;
                await auth.updateAccount(
                  account.copyWith(imapSecure: value == 'SSL/TLS'),
                );
              },
              isCompact,
            ),
            _buildActionRow(
              label: 'Test connection to server',
              isCompact: isCompact,
              onTap: () async {
                if (_isTesting) return;
                final messenger = ScaffoldMessenger.of(context);
                setState(() => _isTesting = true);
                final ok = await ImapService().testConnection(
                  email: account.email,
                  password: account.password,
                  imapHost: account.imapHost,
                  imapPort: account.imapPort,
                  imapSecure: account.imapSecure,
                );
                if (!mounted) return;
                setState(() => _isTesting = false);
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(
                      ok ? 'Connection successful.' : 'Connection failed.',
                    ),
                  ),
                );
              },
              trailing:
                  _isTesting
                      ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : const Icon(Icons.link_rounded, size: 18),
            ),
            _buildDropdownField(
              'Authentication method:',
              account.authMethod,
              _authOptionsFor(account.authMethod),
              (value) {
                if (value == null) return;
                context.read<AuthProvider>().updateAccount(
                  account.copyWith(authMethod: value),
                );
              },
              isCompact,
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildSectionCard(
          title: 'Server Behavior',
          children: [
            _buildCheckboxRow(
              'Check for new messages at startup',
              account.checkAtStartup,
              (value) => context.read<AuthProvider>().updateAccount(
                account.copyWith(checkAtStartup: value ?? false),
              ),
            ),
            _buildIntervalRow(
              label: 'Check for new messages every',
              minutes: account.checkIntervalMinutes,
              enabled: account.checkEvery2Mins,
              isCompact: isCompact,
              onToggle:
                  (value) => context.read<AuthProvider>().updateAccount(
                    account.copyWith(checkEvery2Mins: value ?? false),
                  ),
              onMinutesChanged:
                  (value) => context.read<AuthProvider>().updateAccount(
                    account.copyWith(checkIntervalMinutes: value),
                  ),
            ),
            _buildCheckboxRow(
              'Allow immediate server notifications when new messages arrive',
              account.allowNotifications,
              (value) => context.read<AuthProvider>().updateAccount(
                account.copyWith(allowNotifications: value ?? false),
              ),
            ),
            _buildCheckboxRow(
              'Automatically download new messages',
              account.autoDownload,
              (value) => context.read<AuthProvider>().updateAccount(
                account.copyWith(autoDownload: value ?? false),
              ),
            ),
            _buildCheckboxRow(
              'Fetch headers only',
              account.fetchHeadersOnly,
              (value) => context.read<AuthProvider>().updateAccount(
                account.copyWith(fetchHeadersOnly: value ?? false),
              ),
            ),
            _buildDeleteBehavior(
              account: account,
              isCompact: isCompact,
              onChange: (updated) => context.read<AuthProvider>().updateAccount(
                updated,
              ),
            ),
            _buildCheckboxRow(
              'Leave messages on server',
              account.leaveOnServer,
              (value) => context.read<AuthProvider>().updateAccount(
                account.copyWith(leaveOnServer: value ?? false),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 24.0),
              child: Column(
                children: [
                  _buildCheckboxRow(
                    'For at most 365 days',
                    account.leaveFor365Days,
                    (value) => context.read<AuthProvider>().updateAccount(
                      account.copyWith(leaveFor365Days: value ?? false),
                    ),
                  ),
                  _buildCheckboxRow(
                    'Until I delete them',
                    account.leaveUntilDeleted,
                    (value) => context.read<AuthProvider>().updateAccount(
                      account.copyWith(leaveUntilDeleted: value ?? false),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildSectionCard(
          title: 'Message Storage',
          children: [
            _buildCheckboxRow(
              'Clean up ("Expunge") Inbox on Exit',
              account.expungeOnExit,
              (value) => context.read<AuthProvider>().updateAccount(
                account.copyWith(expungeOnExit: value ?? false),
              ),
            ),
            _buildCheckboxRow(
              'Empty Trash on Exit',
              account.emptyTrashOnExit,
              (value) => context.read<AuthProvider>().updateAccount(
                account.copyWith(emptyTrashOnExit: value ?? false),
              ),
            ),
            _buildDropdownField(
              'Message Store Type:',
              account.messageStoreType,
              ['File per folder (mbox)', 'Single file (mbox)', 'Maildir'],
              (value) {
                if (value == null) return;
                context.read<AuthProvider>().updateAccount(
                  account.copyWith(messageStoreType: value),
                );
              },
              isCompact,
            ),
            _buildDirectoryRow(
              label: 'Local Directory:',
              controller: _localDirController,
              isCompact: isCompact,
              onSave:
                  (value) => _saveLocalDirectory(
                    auth: context.read<AuthProvider>(),
                    account: account,
                    value: value,
                  ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _generalSetting(Account account, AuthProvider auth) {
    final isSmall = MediaQuery.sizeOf(context).width < 700;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15.0),
          child:
              isSmall
                  ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Account Settings - ${account.email}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          TextButton(
                            onPressed:
                                auth.defaultOutgoingEmail == account.email
                                    ? null
                                    : () => auth.setDefaultOutgoing(
                                      account.email,
                                    ),
                            style: ButtonStyle(
                              backgroundColor: WidgetStateProperty.all(
                                const Color.fromARGB(157, 246, 245, 245),
                              ),
                            ),
                            child: const Text('Set as Default'),
                          ),
                          ElevatedButton.icon(
                            onPressed: () => auth.removeAccount(account.email),
                            icon: const Icon(Icons.delete_outline),
                            label: const Text('Delete'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  )
                  : Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Account Settings - ${account.email}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            alignment: WrapAlignment.end,
                            children: [
                              TextButton(
                                onPressed:
                                    auth.defaultOutgoingEmail == account.email
                                        ? null
                                        : () => auth.setDefaultOutgoing(
                                          account.email,
                                        ),
                                style: ButtonStyle(
                                  backgroundColor: WidgetStateProperty.all(
                                    const Color.fromARGB(157, 246, 245, 245),
                                  ),
                                ),
                                child: const Text('Set as Default'),
                              ),
                              ElevatedButton.icon(
                                onPressed: () => auth.removeAccount(account.email),
                                icon: const Icon(Icons.delete_outline),
                                label: const Text('Delete'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
        ),
        const SizedBox(height: 12),
        _buildSectionCard(
          title: 'Account',
          children: [
            _buildEditableField(
              label: 'Account Name:',
              initialValue: account.accountName,
              isCompact: isSmall,
              onSave:
                  (value) => auth.updateAccount(
                    account.copyWith(accountName: value.trim()),
                  ),
            ),
            _buildColorRow(
              label: 'Color:',
              colorHex: account.accountColor,
              onSelect:
                  () => _pickAccountColor(
                    account: account,
                    auth: auth,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildSectionCard(
          title: 'Default Identity',
          children: [
            _buildEditableField(
              label: 'Your Name:',
              initialValue: account.displayName,
              isCompact: isSmall,
              onSave:
                  (value) => auth.updateAccount(
                    account.copyWith(displayName: value.trim()),
                  ),
            ),
            _buildEditableField(
              label: 'Email Address:',
              initialValue: account.email,
              isCompact: isSmall,
              onSave:
                  (value) => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Email address cannot be edited here.'),
                    ),
                  ),
            ),
            _buildEditableField(
              label: 'Reply-to Address:',
              initialValue: account.replyTo,
              isCompact: isSmall,
              onSave:
                  (value) => auth.updateAccount(
                    account.copyWith(replyTo: value.trim()),
                  ),
            ),
            _buildEditableField(
              label: 'Organization:',
              initialValue: account.organization,
              isCompact: isSmall,
              onSave:
                  (value) => auth.updateAccount(
                    account.copyWith(organization: value.trim()),
                  ),
            ),
            _buildCheckboxRow(
              'Use HTML (e.g., <b>bold</b>)',
              account.signatureHtml,
              (value) => auth.updateAccount(
                account.copyWith(signatureHtml: value ?? false),
              ),
            ),
            _buildMultilineField(
              label: 'Signature text:',
              value: account.signatureText,
              isCompact: isSmall,
              onSave:
                  (value) => auth.updateAccount(
                    account.copyWith(signatureText: value),
                  ),
            ),
            _buildCheckboxRow(
              'Attach the signature from a file instead',
              account.signatureFromFile,
              (value) => auth.updateAccount(
                account.copyWith(signatureFromFile: value ?? false),
              ),
            ),
            _buildEditableField(
              label: 'Signature file:',
              initialValue: account.signatureFilePath,
              isCompact: isSmall,
              onSave:
                  (value) => auth.updateAccount(
                    account.copyWith(signatureFilePath: value.trim()),
                  ),
            ),
            _buildCheckboxRow(
              'Attach my vCard to messages',
              account.attachVCard,
              (value) => auth.updateAccount(
                account.copyWith(attachVCard: value ?? false),
              ),
            ),
            _buildEditableField(
              label: 'Reply from filter:',
              initialValue: account.replyFromFilter,
              isCompact: isSmall,
              onSave:
                  (value) => auth.updateAccount(
                    account.copyWith(replyFromFilter: value.trim()),
                  ),
            ),
            _buildOutgoingSelector(account: account, auth: auth),
          ],
        ),
      ],
    );
  }

  Future<void> _showOutgoingServerDialog({
    required AuthProvider auth,
    required Account account,
  }) async {
    final descriptionController = TextEditingController(
      text: account.smtpDescription,
    );
    final hostController = TextEditingController(text: account.smtpHost);
    final portController = TextEditingController(
      text: account.smtpPort.toString(),
    );
    final userController = TextEditingController(text: account.smtpUserName);
    String connectionSecurity = account.smtpSecure ? 'SSL/TLS' : 'None';
    String authMethod = account.smtpAuthMethod;

    try {
    await showDialog<void>(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder: (context, setDialogState) {
              final currentDefaultPort =
                  connectionSecurity == 'SSL/TLS' ? 465 : 587;
              return AlertDialog(
                title: const Text('SMTP Server'),
                content: SizedBox(
                  width: 520,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildDialogField('Description', descriptionController),
                      const SizedBox(height: 12),
                      _buildDialogField('Server Name', hostController),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildDialogField('Port', portController),
                          ),
                          const SizedBox(width: 12),
                          Text('Default: $currentDefaultPort'),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Security and Authentication',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildDialogDropdown(
                        'Connection security',
                        connectionSecurity,
                        ['SSL/TLS', 'None'],
                        (value) {
                          if (value == null) return;
                          setDialogState(() {
                            connectionSecurity = value;
                          });
                        },
                      ),
                      const SizedBox(height: 8),
                      _buildDialogDropdown(
                        'Authentication method',
                        authMethod,
                        _authOptionsFor(authMethod),
                        (value) {
                          if (value == null) return;
                          setDialogState(() {
                            authMethod = value;
                          });
                        },
                      ),
                      const SizedBox(height: 8),
                      _buildDialogField('User Name', userController),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                  final host = hostController.text.trim();
                  int? port = int.tryParse(portController.text.trim());
                  String resolvedHost = host;
                  if (host.contains(':')) {
                    final parts = host.split(':');
                    if (parts.length == 2 && parts.first.trim().isNotEmpty) {
                      resolvedHost = parts.first.trim();
                      port = int.tryParse(parts.last.trim()) ?? port;
                    }
                  }
                  if (resolvedHost.isEmpty ||
                      port == null ||
                      port <= 0 ||
                      port > 65535) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Enter a valid server and port.'),
                      ),
                    );
                    return;
                  }
                  auth.updateAccount(
                    account.copyWith(
                      smtpDescription: descriptionController.text.trim(),
                      smtpHost: resolvedHost,
                      smtpPort: port,
                      smtpSecure: connectionSecurity == 'SSL/TLS',
                      smtpAuthMethod: authMethod,
                      smtpUserName: userController.text.trim(),
                        ),
                      );
                      Navigator.pop(context);
                    },
                    child: const Text('OK'),
                  ),
                ],
              );
            },
          ),
    );
    } finally {
      descriptionController.dispose();
      hostController.dispose();
      portController.dispose();
      userController.dispose();
    }
  }

  Widget _outgoingServerSetting(AuthProvider auth) {
    final accounts = auth.accounts;
    if (accounts.isEmpty) {
      return const Center(child: Text('No account found'));
    }
    final defaultEmail =
        auth.defaultOutgoingEmail ?? accounts.first.email;
    _selectedOutgoingEmail ??= defaultEmail;
    final selected =
        auth.accountForEmail(_selectedOutgoingEmail!) ?? accounts.first;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Outgoing Server Settings',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        const Text(
          'Select a server for outgoing mail, or choose a default server.',
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxWidth < 700;
            final list = Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              child: SizedBox(
                height: 260,
                child: ListView.separated(
                  itemCount: accounts.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final account = accounts[index];
                    final isDefault = account.email == defaultEmail;
                    final isSelected =
                        account.email == _selectedOutgoingEmail;
                    return ListTile(
                      selected: isSelected,
                      title: Text(
                        '${account.email} - ${account.smtpHost}'
                        '${isDefault ? ' (Default)' : ''}',
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () {
                        setState(() {
                          _selectedOutgoingEmail = account.email;
                        });
                      },
                    );
                  },
                ),
              ),
            );
            final buttons = Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ElevatedButton(
                  onPressed: () {
                    _showOutgoingServerDialog(
                      auth: auth,
                      account: selected,
                    );
                  },
                  child: const Text('Add...'),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed:
                      _selectedOutgoingEmail == null
                          ? null
                          : () {
                            _showOutgoingServerDialog(
                              auth: auth,
                              account: selected,
                            );
                          },
                  child: const Text('Edit...'),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed:
                      _selectedOutgoingEmail == null
                          ? null
                          : () async {
                            final ok = await showDialog<bool>(
                              context: context,
                              builder:
                                  (context) => AlertDialog(
                                    title: const Text('Remove server'),
                                    content: const Text(
                                      'Reset outgoing server settings for this account?',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed:
                                            () => Navigator.pop(context, false),
                                        child: const Text('Cancel'),
                                      ),
                                      ElevatedButton(
                                        onPressed:
                                            () => Navigator.pop(context, true),
                                        child: const Text('Remove'),
                                      ),
                                    ],
                                  ),
                            );
                            if (ok != true) return;
                            final defaults = serverInfoFromEmail(selected.email);
                            await auth.updateAccount(
                              selected.copyWith(
                                smtpHost: defaults.smtpHost,
                                smtpPort: defaults.smtpPort,
                                smtpSecure: defaults.smtpSecure,
                                smtpAuthMethod: 'Normal password',
                                smtpDescription:
                                    selected.email.split('@').first,
                                smtpUserName: selected.email,
                              ),
                            );
                          },
                  child: const Text('Remove'),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed:
                      _selectedOutgoingEmail == null ||
                              accounts.length == 1
                          ? null
                          : () {
                            auth.setDefaultOutgoing(selected.email);
                          },
                  child: const Text('Set Default'),
                ),
              ],
            );
            if (isCompact) {
              return Column(
                children: [
                  list,
                  const SizedBox(height: 12),
                  buttons,
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: list),
                const SizedBox(width: 16),
                SizedBox(width: 140, child: buttons),
              ],
            );
          },
        ),
        const SizedBox(height: 20),
        _buildSectionCard(
          title: 'Details of selected server',
          children: [
            _buildReadOnlyField(
              'Description:',
              selected.smtpDescription,
              false,
            ),
            _buildReadOnlyField(
              'Server Type:',
              'SMTP Outgoing Server',
              false,
            ),
            _buildReadOnlyField(
              'Server Name:',
              selected.smtpHost,
              false,
            ),
            _buildReadOnlyField(
              'Port:',
              selected.smtpPort.toString(),
              false,
            ),
            _buildReadOnlyField(
              'User Name:',
              selected.smtpUserName,
              false,
            ),
            _buildReadOnlyField(
              'Authentication method:',
              selected.smtpAuthMethod,
              false,
            ),
            _buildReadOnlyField(
              'Connection Security:',
              selected.smtpSecure ? 'SSL/TLS' : 'None',
              false,
            ),
            _buildActionRow(
              label: 'Test connection to server',
              isCompact: false,
              onTap: () async {
                if (_isTestingOutgoing) return;
                setState(() => _isTestingOutgoing = true);
                final ok =
                    await SmtpService(
                      username: selected.smtpUserName,
                      to: '',
                      option: const {},
                      password: selected.password,
                      smtpHost: selected.smtpHost,
                      smtpPort: selected.smtpPort,
                      smtpSecure: selected.smtpSecure,
                    ).testConnection();
                if (mounted) {
                  setState(() => _isTestingOutgoing = false);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        ok ? 'Connection successful.' : 'Connection failed.',
                      ),
                    ),
                  );
                }
              },
              trailing:
                  _isTestingOutgoing
                      ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : const Icon(Icons.link_rounded, size: 18),
            ),
          ],
        ),
      ],
    );
  }

  Widget _settingByName({
    required String type,
    required Account account,
    required AuthProvider auth,
  }) {
    switch (type) {
      case "general_setting":
        return _generalSetting(account, auth);
      case "incoming_server_setting":
        return _serverSetting(account);
      case "outgoing_server_setting":
        return _outgoingServerSetting(auth);
      default:
        return _serverSetting(account);
    }
  }

  void _toggleSetting(String type) {
    debugPrint('Setting type: $type');
    setState(() {
      _isAccountMenuClicked = true;
      if(_isAccountMenuClicked) {
        widget.updateFullScreenCloseButton(!_isAccountMenuClicked);
      }
      currentSetting = type;
    });
  }

  Widget _accountWidget() {
    final isSmallScreen = MediaQuery.sizeOf(context).width < 900;
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        final accounts = auth.accounts;
        final activeAccount =
            auth.activeAccount ??
            Account.initialForEmail(email: '', password: '');
        final content = SingleChildScrollView(
          child: _settingByName(
            type: currentSetting,
            account: activeAccount,
            auth: auth,
          ),
        );

        final list = AccountList(
          onPressed: _toggleSetting,
          accounts: accounts,
          activeEmail: auth.activeEmail,
          onSelectAccount: (account) async {
            if (!account.imapSecure) {
              final ok = await _confirmInsecureConnection(context);
              if (!ok) return;
            }
            auth.setActive(account.email);
          },
          onRemoveAccount: (email) {
            auth.removeAccount(email);
          },
        );

        if (isSmallScreen) {
          return Stack(
            children: [
              Padding(
                padding: const EdgeInsets.only(top:20.0),
                child: Column(
                  children: [
                    if(_isAccountMenuClicked)
                      Expanded(child: content)
                    else
                      Expanded(child: list),
                  ],
                ),
              ),
              if(_isAccountMenuClicked)
              Positioned(
                top: 6,
                right: 0,
                child: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    setState(() {
                      _isAccountMenuClicked = false;
                    });
                    widget.updateFullScreenCloseButton(!_isAccountMenuClicked);
                  },
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.all(
                      Theme.of(context).cardColor,
                    ),
                  ),
                )
              ),
            ],
          );
        }

        return Row(
          children: [
            Container(
              width: 320,
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: list,
            ),
            const SizedBox(width: 15),
            Expanded(child: content),
          ],
        );
      },
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = MediaQuery.sizeOf(context).width < 900;
        return Column(
                children: [
                  if(!isSmallScreen)
                  Padding(
                    padding: const EdgeInsets.only(left: 180, bottom: 8, top:8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        TextButton.icon(
                          onPressed: () => _showAddAccountDialog(context),
                          icon: const Icon(Icons.person_add_alt_1),
                          label: const Text('Add Account'),
                          style: ButtonStyle(
                            backgroundColor: WidgetStateProperty.all(const Color.fromARGB(157, 246, 245, 245)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(child: _accountWidget()),
                ],
              );
      },
    );
  }

  Widget _buildReadOnlyField(String label, String value, bool isCompact) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child:
          isCompact
              ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              )
              : Row(
                children: [
                  SizedBox(width: 140, child: Text(label)),
                  const SizedBox(width: 8),
                  Text(
                    value,
                    style: const TextStyle(fontWeight: FontWeight.bold),
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
    bool isCompact,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child:
          isCompact
              ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label),
                  const SizedBox(height: 4),
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
              )
              : Row(
                children: [
                  SizedBox(width: 140, child: Text(label)),
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

  Widget _buildDialogField(
    String label,
    TextEditingController controller,
  ) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }

  Widget _buildDialogDropdown(
    String label,
    String value,
    List<String> options,
    ValueChanged<String?> onChanged,
  ) {
    return Row(
      children: [
        SizedBox(width: 160, child: Text(label)),
        const SizedBox(width: 8),
        Expanded(
          child: DropdownButton<String>(
            isExpanded: true,
            value: value,
            items:
                options
                    .map(
                      (opt) => DropdownMenuItem(
                        value: opt,
                        child: Text(opt),
                      ),
                    )
                    .toList(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildMultilineField({
    required String label,
    required String value,
    required bool isCompact,
    required ValueChanged<String> onSave,
  }) {
    return _MultilineField(
      label: label,
      initialValue: value,
      isCompact: isCompact,
      onSave: onSave,
    );
  }

  Widget _buildColorRow({
    required String label,
    required String colorHex,
    required VoidCallback onSelect,
  }) {
    final color = Color(int.parse('0xFF$colorHex'));
    final isCompact = MediaQuery.sizeOf(context).width < 600;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child:
          isCompact
              ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 24,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.black26),
                        ),
                      ),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: onSelect,
                        child: const Text('Change'),
                      ),
                    ],
                  ),
                ],
              )
              : Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 36,
                    height: 24,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.black26),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(onPressed: onSelect, child: const Text('Change')),
                ],
              ),
    );
  }

  Future<void> _pickAccountColor({
    required Account account,
    required AuthProvider auth,
  }) async {
    const palette = <String>[
      '2196F3',
      '4CAF50',
      'FF9800',
      '9C27B0',
      'F44336',
      '00BCD4',
      '3F51B5',
      '795548',
    ];
    await showDialog<void>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Pick a color'),
            content: Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  palette
                      .map(
                        (hex) => GestureDetector(
                          onTap: () {
                            auth.updateAccount(
                              account.copyWith(accountColor: hex),
                            );
                            Navigator.pop(context);
                          },
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: Color(int.parse('0xFF$hex')),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.black26),
                            ),
                          ),
                        ),
                      )
                      .toList(),
            ),
          ),
    );
  }

  Widget _buildOutgoingSelector({
    required Account account,
    required AuthProvider auth,
  }) {
    final defaultLabel =
        auth.defaultOutgoingEmail == null
            ? ''
            : ' (Default)';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(width: 140, child: Text('Outgoing Server:')),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: account.email,
                  items:
                      auth.accounts
                          .map(
                            (a) => DropdownMenuItem(
                              value: a.email,
                              child: Text(
                                '${a.smtpDescription} - ${a.smtpHost}'
                                '${a.email == auth.defaultOutgoingEmail ? defaultLabel : ''}',
                                overflow: TextOverflow.ellipsis
                              ),
                            ),
                          )
                          .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    // Keep per-account selection in default outgoing for now.
                    auth.setDefaultOutgoing(value);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Padding(
            padding: const EdgeInsets.only(left: 148.0),
            child: TextButton(
              onPressed: () => setState(() {
                currentSetting = 'outgoing_server_setting';
              }),
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.all(const Color.fromARGB(157, 246, 245, 245)),
              ),
              child: const Text('Edit outgoing server...'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionRow({
    required String label,
    required bool isCompact,
    required VoidCallback onTap,
    required Widget trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child:
          isCompact
              ? Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: onTap,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(label),
                      ),
                    ),
                  ),
                  trailing,
                ],
              )
              : Row(
                children: [
                  const SizedBox(width: 140),
                  TextButton(onPressed: onTap, child: Text(label)),
                  const Spacer(),
                  trailing,
                ],
              ),
    );
  }

  Widget _buildServerAndPortRow({
    required String serverLabel,
    required TextEditingController serverController,
    required TextEditingController portController,
    required int defaultPort,
    required bool isCompact,
    required ValueChanged<String> onSaveServer,
    required ValueChanged<String> onSavePort,
  }) {
    final portField = SizedBox(
      width: 90,
      child: TextField(
        controller: portController,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          isDense: true,
          border: const OutlineInputBorder(),
          suffixIcon: IconButton(
            icon: const Icon(Icons.save),
            onPressed: () => onSavePort(portController.text),
          ),
        ),
        onSubmitted: onSavePort,
      ),
    );
    final serverField = Expanded(
      child: TextField(
        controller: serverController,
        decoration: InputDecoration(
          isDense: true,
          border: const OutlineInputBorder(),
          suffixIcon: IconButton(
            icon: const Icon(Icons.save),
            onPressed: () => onSaveServer(serverController.text),
          ),
        ),
        onSubmitted: onSaveServer,
      ),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child:
          isCompact
              ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(serverLabel),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      serverField,
                      const SizedBox(width: 8),
                      Text('Port:'),
                      const SizedBox(width: 6),
                      portField,
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('Default: $defaultPort'),
                ],
              )
              : Row(
                children: [
                  SizedBox(width: 140, child: Text(serverLabel)),
                  const SizedBox(width: 8),
                  serverField,
                  const SizedBox(width: 12),
                  Text('Port:'),
                  const SizedBox(width: 6),
                  portField,
                  const SizedBox(width: 12),
                  Text('Default: $defaultPort'),
                ],
              ),
    );
  }

  Widget _buildIntervalRow({
    required String label,
    required int minutes,
    required bool enabled,
    required bool isCompact,
    required ValueChanged<bool?> onToggle,
    required ValueChanged<int> onMinutesChanged,
  }) {
    return _IntervalRow(
      label: label,
      minutes: minutes,
      enabled: enabled,
      isCompact: isCompact,
      onToggle: onToggle,
      onMinutesChanged: onMinutesChanged,
    );
  }

  Widget _buildDeleteBehavior({
    required Account account,
    required bool isCompact,
    required ValueChanged<Account> onChange,
  }) {
    final folders = <String>[
      'Trash',
      'Archive',
      'Spam',
      'Custom',
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: RadioGroup<String>(
        groupValue: account.deleteBehavior,
        onChanged: (value) {
          if (value == null) return;
          onChange(account.copyWith(deleteBehavior: value));
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('When I delete a message:'),
            const SizedBox(height: 6),
            Row(
              children: [
                const Radio<String>(value: 'move'),
                const Text('Move it to this folder:'),
                const SizedBox(width: 8),
                SizedBox(
                  width: isCompact ? 160 : 220,
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: account.deleteMoveFolder,
                    items:
                        folders
                            .map(
                              (f) => DropdownMenuItem(
                                value: f,
                                child: Text(f),
                              ),
                            )
                            .toList(),
                    onChanged:
                        account.deleteBehavior == 'move'
                            ? (value) {
                              if (value == null) return;
                              onChange(account.copyWith(deleteMoveFolder: value));
                            }
                            : null,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                const Radio<String>(value: 'mark'),
                const Text('Just mark it as deleted'),
              ],
            ),
            Row(
              children: [
                const Radio<String>(value: 'remove'),
                const Text('Remove it immediately'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDirectoryRow({
    required String label,
    required TextEditingController controller,
    required bool isCompact,
    required ValueChanged<String> onSave,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child:
          isCompact
              ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label),
                  const SizedBox(height: 4),
                  TextField(
                    controller: controller,
                    decoration: InputDecoration(
                      isDense: true,
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.save),
                        onPressed: () => onSave(controller.text),
                      ),
                    ),
                    onSubmitted: onSave,
                  ),
                ],
              )
              : Row(
                children: [
                  SizedBox(width: 140, child: Text(label)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: controller,
                      decoration: InputDecoration(
                        isDense: true,
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.save),
                          onPressed: () => onSave(controller.text),
                        ),
                      ),
                      onSubmitted: onSave,
                    ),
                  ),
                ],
              ),
    );
  }

  Widget _buildEditableField({
    required String label,
    required String initialValue,
    required bool isCompact,
    required ValueChanged<String> onSave,
  }) {
    return _EditableField(
      label: label,
      initialValue: initialValue,
      isCompact: isCompact,
      onSave: onSave,
    );
  }

  Widget _buildCheckboxRow(
    String label,
    bool value,
    ValueChanged<bool?> onChanged,
  ) {
    return Row(
      children: [
        Checkbox(value: value, onChanged: onChanged),
        Expanded(child: Text(label)),
      ],
    );
  }

  Widget _buildSectionCard({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}
const List<String> _authMethodOptions = [
  'No Authentication',
  'Normal password',
  'Encrypted password',
  'Kerberos / GSSAPI',
  'NTLM',
  'TLS Certificate',
  'OAuth2',
  'Exchange / OAuth2',
];

  List<String> _authOptionsFor(String current) {
    return _authMethodOptions.contains(current)
        ? _authMethodOptions
        : [..._authMethodOptions, current];
  }

class _EditableField extends StatefulWidget {
  final String label;
  final String initialValue;
  final bool isCompact;
  final ValueChanged<String> onSave;

  const _EditableField({
    required this.label,
    required this.initialValue,
    required this.isCompact,
    required this.onSave,
  });

  @override
  State<_EditableField> createState() => _EditableFieldState();
}

class _EditableFieldState extends State<_EditableField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: widget.isCompact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.label),
                const SizedBox(height: 4),
                TextField(
                  controller: _controller,
                  decoration: InputDecoration(
                    isDense: true,
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.save),
                      onPressed: () => widget.onSave(_controller.text),
                    ),
                  ),
                  onSubmitted: widget.onSave,
                ),
              ],
            )
          : Row(
              children: [
                SizedBox(width: 140, child: Text(widget.label)),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      isDense: true,
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.save),
                        onPressed: () => widget.onSave(_controller.text),
                      ),
                    ),
                    onSubmitted: widget.onSave,
                  ),
                ),
              ],
            ),
    );
  }
}

class _MultilineField extends StatefulWidget {
  final String label;
  final String initialValue;
  final bool isCompact;
  final ValueChanged<String> onSave;

  const _MultilineField({
    required this.label,
    required this.initialValue,
    required this.isCompact,
    required this.onSave,
  });

  @override
  State<_MultilineField> createState() => _MultilineFieldState();
}

class _MultilineFieldState extends State<_MultilineField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: widget.isCompact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.label),
                const SizedBox(height: 4),
                TextField(
                  controller: _controller,
                  minLines: 3,
                  maxLines: 6,
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.save),
                      onPressed: () => widget.onSave(_controller.text),
                    ),
                  ),
                ),
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 140, child: Text(widget.label)),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    minLines: 3,
                    maxLines: 6,
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.save),
                        onPressed: () => widget.onSave(_controller.text),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _IntervalRow extends StatefulWidget {
  final String label;
  final int minutes;
  final bool enabled;
  final bool isCompact;
  final ValueChanged<bool?> onToggle;
  final ValueChanged<int> onMinutesChanged;

  const _IntervalRow({
    required this.label,
    required this.minutes,
    required this.enabled,
    required this.isCompact,
    required this.onToggle,
    required this.onMinutesChanged,
  });

  @override
  State<_IntervalRow> createState() => _IntervalRowState();
}

class _IntervalRowState extends State<_IntervalRow> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.minutes.toString());
  }

  @override
  void didUpdateWidget(_IntervalRow old) {
    super.didUpdateWidget(old);
    if (old.minutes != widget.minutes) {
      _controller.text = widget.minutes.toString();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: widget.isCompact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Checkbox(value: widget.enabled, onChanged: widget.onToggle),
                    Expanded(child: Text(widget.label)),
                  ],
                ),
                Row(
                  children: [
                    const SizedBox(width: 40),
                    SizedBox(
                      width: 80,
                      child: TextField(
                        controller: _controller,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          isDense: true,
                          border: OutlineInputBorder(),
                        ),
                        onSubmitted: (value) {
                          final parsed = int.tryParse(value) ?? widget.minutes;
                          widget.onMinutesChanged(parsed.clamp(1, 120));
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text('minutes'),
                  ],
                ),
              ],
            )
          : Row(
              children: [
                Checkbox(value: widget.enabled, onChanged: widget.onToggle),
                Expanded(child: Text(widget.label)),
                SizedBox(
                  width: 80,
                  child: TextField(
                    controller: _controller,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (value) {
                      final parsed = int.tryParse(value) ?? widget.minutes;
                      widget.onMinutesChanged(parsed.clamp(1, 120));
                    },
                  ),
                ),
                const SizedBox(width: 8),
                const Text('minutes'),
              ],
            ),
    );
  }
}
