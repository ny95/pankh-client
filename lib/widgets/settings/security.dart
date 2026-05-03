import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:pankh/providers/settings_provider.dart';
import 'package:pankh/widgets/settings/transparent_switch_card.dart';
import 'package:provider/provider.dart';

class SecuritySettingsTab extends StatefulWidget {
  final bool isSmallScreen;

  const SecuritySettingsTab({super.key, required this.isSmallScreen});

  @override
  State<SecuritySettingsTab> createState() => _SecuritySettingsTabState();
}

class _SecuritySettingsTabState extends State<SecuritySettingsTab> {
  final _localAuth = LocalAuthentication();
  bool _biometricSupported = false;

  @override
  void initState() {
    super.initState();
    _checkBiometrics();
  }

  Future<void> _checkBiometrics() async {
    try {
      final supported = await _localAuth.isDeviceSupported();
      final canCheck = await _localAuth.canCheckBiometrics;
      if (mounted) {
        setState(() => _biometricSupported = supported && canCheck);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _biometricSupported = false);
      }
    }
  }

  Widget _securityWidget(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        const Text(
          "Authentication",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),

        // Biometric Switch
        if (_biometricSupported)
          TransparentSwitchCard(
            title: "Enable Biometric Authentication",
            subtitle: "Use fingerprint or face unlock to access app",
            value: settings.biometricEnabled,
            onChanged: settings.appLockEnabled
                ? (val) => settings.update(biometricEnabled: val)
                : null,
          ),

        // App Lock Timeout
        Card(
          color: Colors.transparent,
          shadowColor: Colors.transparent,
          child: SwitchListTile(
            title: const Text("Enable App Lock"),
            subtitle: const Text("Automatically lock app after inactivity"),
            value: settings.appLockEnabled,
            onChanged: (val) async {
              if (val) {
                if (!settings.hasPin) {
                  final ok = await _setPinDialog(context, settings);
                  if (!ok) return;
                }
              }
              settings.update(appLockEnabled: val);
            },
          ),
        ),
        TransparentCard(
          child: ListTile(
            leading: const Icon(Icons.timer_outlined),
            title: const Text("App Lock Timeout"),
            subtitle: Text('${settings.lockTimeoutMinutes} minutes'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: settings.appLockEnabled
                ? () => _timeoutDialog(context, settings)
                : null,
          ),
        ),

        const SizedBox(height: 24),
        const Text(
          "Security Controls",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),

        // Change PIN
        TransparentCard(
          child: ListTile(
            leading: const Icon(Icons.lock_outline),
            title: const Text("Change PIN"),
            subtitle: const Text("Set or update your 4-digit app PIN"),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () => _setPinDialog(context, settings),
          ),
        ),

        // 2FA Setup
        TransparentCard(
          child: ListTile(
            leading: const Icon(Icons.security),
            title: const Text("Setup Two-Factor Authentication"),
            subtitle: const Text("Add extra protection to your account"),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('2FA is not configured yet.')),
              );
            },
          ),
        ),

        // Encryption Info
        TransparentCard(
          child: ListTile(
            leading: const Icon(Icons.verified_user),
            title: const Text("Encryption Details"),
            subtitle: const Text("View app's data protection status"),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () => _showEncryptionInfo(context, settings),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return _securityWidget(context);
  }

  Future<bool> _setPinDialog(
    BuildContext context,
    SettingsProvider settings,
  ) async {
    final pinController = TextEditingController();
    final confirmController = TextEditingController();
    bool ok = false;
    try {
    await showDialog<void>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Set PIN'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: pinController,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'PIN (4-6 digits)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: confirmController,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Confirm PIN',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final pin = pinController.text.trim();
                  final confirm = confirmController.text.trim();
                  if (pin.length < 4 ||
                      pin.length > 6 ||
                      pin != confirm) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Invalid PIN.')),
                    );
                    return;
                  }
                  await settings.setPin(pin);
                  if (!context.mounted) return;
                  ok = true;
                  Navigator.pop(context);
                },
                child: const Text('Save'),
              ),
            ],
          ),
    );
    } finally {
      pinController.dispose();
      confirmController.dispose();
    }
    return ok;
  }

  Future<void> _timeoutDialog(
    BuildContext context,
    SettingsProvider settings,
  ) async {
    int minutes = settings.lockTimeoutMinutes;
    await showDialog<void>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('App Lock Timeout'),
            content: StatefulBuilder(
              builder: (context, setState) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Slider(
                      min: 0,
                      max: 30,
                      divisions: 30,
                      value: minutes.toDouble(),
                      label: minutes == 0 ? 'Always' : '$minutes min',
                      onChanged:
                          (val) => setState(() => minutes = val.toInt()),
                    ),
                    Text(
                      minutes == 0
                          ? 'Lock immediately on resume'
                          : '$minutes minutes',
                    ),
                  ],
                );
              },
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  settings.update(lockTimeoutMinutes: minutes);
                  Navigator.pop(context);
                },
                child: const Text('Save'),
              ),
            ],
          ),
    );
  }

  void _showEncryptionInfo(
    BuildContext context,
    SettingsProvider settings,
  ) {
    showDialog<void>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Encryption Details'),
            content: const Text(
              'Mail cache is encrypted with a key derived from your password.\n'
              'App settings are stored locally in Hive.\n'
              'Enable App Lock for device-level protection.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }
}
