import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:provider/provider.dart';

import '../../providers/settings_provider.dart';

class AppLockGate extends StatefulWidget {
  final Widget child;

  const AppLockGate({super.key, required this.child});

  @override
  State<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends State<AppLockGate>
    with WidgetsBindingObserver {
  DateTime? _pausedAt;
  bool _locked = false;
  final _localAuth = LocalAuthentication();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final settings = context.read<SettingsProvider>();
    if (!settings.appLockEnabled) return;
    if (state == AppLifecycleState.paused) {
      _pausedAt = DateTime.now();
    } else if (state == AppLifecycleState.resumed) {
      final timeout = settings.lockTimeoutMinutes;
      if (_pausedAt == null || timeout == 0) {
        setState(() => _locked = true);
      } else {
        final diff = DateTime.now().difference(_pausedAt!).inMinutes;
        if (diff >= timeout) {
          setState(() => _locked = true);
        }
      }
    }
  }

  Future<void> _unlockWithBiometrics() async {
    try {
      final ok = await _localAuth.authenticate(
        localizedReason: 'Unlock the app',
        options: const AuthenticationOptions(biometricOnly: true),
      );
      if (ok && mounted) setState(() => _locked = false);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    if (!settings.appLockEnabled) {
      return widget.child;
    }
    if (!_locked && settings.hasPin) {
      _locked = true;
    }
    return Stack(
      children: [
        widget.child,
        if (_locked)
          Positioned.fill(
            child: AppLockScreen(
              onUnlock: (pin) {
                if (settings.verifyPin(pin)) {
                  setState(() => _locked = false);
                  return true;
                }
                return false;
              },
              allowBiometric: settings.biometricEnabled,
              onBiometric: _unlockWithBiometrics,
            ),
          ),
      ],
    );
  }
}

class AppLockScreen extends StatefulWidget {
  final bool allowBiometric;
  final Future<void> Function() onBiometric;
  final bool Function(String pin) onUnlock;

  const AppLockScreen({
    super.key,
    required this.onUnlock,
    required this.allowBiometric,
    required this.onBiometric,
  });

  @override
  State<AppLockScreen> createState() => _AppLockScreenState();
}

class _AppLockScreenState extends State<AppLockScreen> {
  final _pinController = TextEditingController();
  String _error = '';

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  void _submit() {
    final pin = _pinController.text.trim();
    if (pin.length < 4 || pin.length > 6) {
      setState(() => _error = 'Enter a 4-6 digit PIN.');
      return;
    }
    final ok = widget.onUnlock(pin);
    if (!ok) {
      setState(() => _error = 'Incorrect PIN.');
      _pinController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black54,
      child: Center(
        child: Container(
          width: 320,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'App Locked',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _pinController,
                keyboardType: TextInputType.number,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'PIN',
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (_) => _submit(),
              ),
              if (_error.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    _error,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _submit,
                      child: const Text('Unlock'),
                    ),
                  ),
                ],
              ),
              if (widget.allowBiometric)
                TextButton(
                  onPressed: widget.onBiometric,
                  child: const Text('Unlock with biometrics'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
