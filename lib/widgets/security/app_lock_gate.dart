import 'dart:ui';

import 'package:flutter/material.dart';
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
  final _focusNode = FocusNode();
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

    /// 👇 Auto focus PIN input (desktop only)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final isDesktop = MediaQuery.of(context).size.width >= 600;
      if (isDesktop) {
        FocusScope.of(context).requestFocus(_focusNode);
      }
    });
  }
    @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
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
  Widget _buildPinInput(bool isDesktop) {
    return GestureDetector(
      onTap: () {
        if (isDesktop) {
          FocusScope.of(context).requestFocus(_focusNode);
        }
      },
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              /// Hidden input (for desktop typing)
              if (isDesktop)
                Opacity(
                  opacity: 0,
                  child: SizedBox(
                    width: 1,
                    height: 1,
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      onChanged: (_) {
                        setState(() {});
                        if (_controller.text.length == 6) _submit();
                      },
                      decoration: const InputDecoration(counterText: ''),
                    ),
                  ),
                ),

              /// Visible UI
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(6, (i) {
                  final isActive = i == _controller.text.length;
                  final isFilled = i < _controller.text.length;

                  return Column(
                    children: [
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        width: isDesktop ? 52 : 44,
                        height: isDesktop ? 52 : 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.08),
                          border: Border.all(
                            color: isActive
                                ? Colors.blueAccent
                                : Colors.transparent,
                            width: 2,
                          ),
                          boxShadow: isActive
                              ? [
                                  BoxShadow(
                                    color: Colors.blueAccent.withOpacity(0.6),
                                    blurRadius: 12,
                                    spreadRadius: 1,
                                  )
                                ]
                              : [],
                        ),
                        alignment: Alignment.center,
                        child: isFilled
                            ? Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Colors.white70,
                                  shape: BoxShape.circle,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(3),
                          color: isFilled || isActive
                              ? Colors.blueAccent
                              : Colors.white.withOpacity(0.2),
                          boxShadow: (isFilled || isActive)
                              ? [
                                  BoxShadow(
                                    color: Colors.blueAccent.withOpacity(0.6),
                                    blurRadius: 8,
                                  )
                                ]
                              : [],
                        ),
                      )
                    ],
                  );
                }),
              ),
            ],
          ),
        ],
      ),
    );
  }
  Widget _buildKeypad() {
    Widget key(String text, {VoidCallback? onTap, Widget? child, bool primary = false}) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.all(8),
          height: 70,
          width: 100,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: primary
                ? const LinearGradient(
                    colors: [Color(0xFF4DA3FF), Color(0xFF0066FF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : LinearGradient(
                    colors: [
                      Colors.white.withOpacity(0.08),
                      Colors.black.withOpacity(0.2)
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.4),
                blurRadius: 12,
                offset: const Offset(4, 6),
              )
            ],
          ),
          alignment: Alignment.center,
          child: child ??
              Text(
                text,
                style: TextStyle(
                  fontSize: 25,
                  color: primary ? Colors.white : Colors.white70,
                ),
              ),
        ),
      );
    }

    void add(String d) {
      if (_controller.text.length >= 6) return;

      setState(() {
        _controller.text += d;
        _error = '';
      });

      if (_controller.text.length == 6) _submit();
    }

    void back() {
      if (_controller.text.isEmpty) return;

      setState(() {
        _controller.text =
            _controller.text.substring(0, _controller.text.length - 1);
      });
    }

    return Column(
      children: [
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          key('1', onTap: () => add('1')),
          key('2', onTap: () => add('2')),
          key('3', onTap: () => add('3')),
        ]),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          key('4', onTap: () => add('4')),
          key('5', onTap: () => add('5')),
          key('6', onTap: () => add('6')),
        ]),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          key('7', onTap: () => add('7')),
          key('8', onTap: () => add('8')),
          key('9', onTap: () => add('9')),
        ]),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          key('', onTap: back, child: const Icon(Icons.backspace, color: Colors.white70)),
          key('0', onTap: () => add('0')),
          key(
            '',
            primary: true,
            onTap: _submit,
            child: const Icon(Icons.lock_open, color: Colors.white),
          ),
        ]),
      ],
    );
  }
  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final isDesktop = !isMobile;

    Widget content = Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(isMobile ? 0 : 24),
        color: Colors.white24
      ),
      clipBehavior: Clip.antiAlias,
      child: Blur(
        blur: true,
        child: Container(
          width: isMobile ? double.infinity : 500,
          height: isMobile ? double.infinity : 380,

          padding: const EdgeInsets.fromLTRB(24, 50, 24, 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(isMobile ? 0 : 24),
            gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(0.08),
                Colors.white.withOpacity(0.02),
              ],  
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              /// 🔒 LOCK ICON
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.08),
                ),
                child: const Icon(Icons.lock, size: 100, color: Colors.white30,),
              ),

              const SizedBox(height: 20),

              /// 🔵 PIN DOTS + GLOW LINE
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  _error.isNotEmpty ? _error :'Enter OTP',
                  style: TextStyle(color: _error.isNotEmpty ? Colors.redAccent : Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.55)),
                ),
              ),

              const SizedBox(height: 10),
              _buildPinInput(isDesktop),
              const SizedBox(height: 10),

              if (isMobile) const SizedBox(height: 40),

              if (isMobile) _buildKeypad(),

              const SizedBox(height: 12),

              if (widget.allowBiometric)
                TextButton(
                  onPressed: widget.onBiometric,
                  child: const Text('Use Biometrics'),
                ),
            ],
          ),
        ),
      ),
    );

    return WebPointerInterceptor(
      child: Material(
        color: Colors.black.withOpacity(0.6),
        child: Center(
          child: isMobile ? content : content,
        ),
      ),
    );
  }
}