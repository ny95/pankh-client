import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:pankh/widgets/web_pointer_interceptor_stub.dart';
import 'package:provider/provider.dart';
import 'package:flutter_windowmanager/flutter_windowmanager.dart';
import 'package:pankh/widgets/blur.dart';

import '../../providers/settings_provider.dart';

class AppLockGate extends StatefulWidget {
  final Widget child;

  const AppLockGate({super.key, required this.child});

  @override
  State<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends State<AppLockGate>
    with WidgetsBindingObserver {
  final LocalAuthentication _localAuth = LocalAuthentication();

  DateTime? _pausedAt;
  bool _locked = false;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _secureScreen(true);
  }

  Future<void> _secureScreen(bool enable) async {
    try {
      if (enable) {
        await FlutterWindowManager.addFlags(
            FlutterWindowManager.FLAG_SECURE);
      } else {
        await FlutterWindowManager.clearFlags(
            FlutterWindowManager.FLAG_SECURE);
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _secureScreen(false);
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
        return;
      }

      final diff = DateTime.now().difference(_pausedAt!).inMinutes;
      if (diff >= timeout) {
        setState(() => _locked = true);
      }
    }
  }

  Future<void> _unlockWithBiometrics() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final isSupported = await _localAuth.isDeviceSupported();

      if (!canCheck || !isSupported) return;

      final ok = await _localAuth.authenticate(
        localizedReason: 'Unlock the app',
        options: const AuthenticationOptions(
          biometricOnly: false,
        ),
      );

      if (ok && mounted) {
        setState(() => _locked = false);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    if (!settings.appLockEnabled) return widget.child;

    if (!_initialized) {
      _initialized = true;
      if (settings.hasPin) {
        _locked = true;
      }
    }

    return Stack(
      children: [
        widget.child,
        if (_locked)
          Positioned.fill(
            child: AppLockScreen(
              allowBiometric: settings.biometricEnabled,
              onBiometric: _unlockWithBiometrics,
              onUnlock: (pin) {
                if (settings.verifyPin(pin)) {
                  setState(() => _locked = false);
                  return true;
                }
                return false;
              },
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
  final _controller = TextEditingController();

  String _error = '';
  int _attempts = 0;
  DateTime? _blockedUntil;

  @override
  void initState() {
    super.initState();

    if (widget.allowBiometric) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onBiometric();
      });
    }
  }

  void _submit() {
    final now = DateTime.now();

    if (_blockedUntil != null && now.isBefore(_blockedUntil!)) {
      setState(() => _error = 'Too many attempts. Try later.');
      return;
    }

    final pin = _controller.text.trim();

    if (pin.length < 4 || pin.length > 6) {
      setState(() => _error = 'Enter 4-6 digit PIN');
      return;
    }

    final ok = widget.onUnlock(pin);

    if (!ok) {
      _attempts++;
      _controller.clear();

      if (_attempts >= 5) {
        _blockedUntil = now.add(const Duration(seconds: 30));
        _attempts = 0;
      }

      setState(() => _error = 'Incorrect PIN');
    } else {
      _attempts = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return WebPointerInterceptor(
      child: Material(
        color: Colors.black54,
        child: Blur(
          blur: true,
          sigmaX: 2.5,
          sigmaY: 2.5,
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
                    controller: _controller,
                    autofocus: true,
                    keyboardType: TextInputType.number,
                    obscureText: true,
                    onChanged: (_) {
                      if (_error.isNotEmpty) {
                        setState(() => _error = '');
                      }
                    },
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
                  ElevatedButton(
                    onPressed: _submit,
                    child: const Text('Unlock'),
                  ),
                  if (widget.allowBiometric)
                    TextButton(
                      onPressed: widget.onBiometric,
                      child: const Text('Use Biometrics'),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}