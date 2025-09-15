import 'package:flutter/material.dart';

class SecuritySettingsTab extends StatelessWidget {
  final bool isSmallScreen;

  const SecuritySettingsTab({super.key, required this.isSmallScreen});

  Widget _securityWidget() {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        const Text(
          "Authentication",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),

        // Biometric Switch
        Card(
          color: Colors.transparent,
          shadowColor: Colors.transparent,
          child: SwitchListTile(
            title: const Text("Enable Biometric Authentication"),
            subtitle: const Text(
              "Use fingerprint or face unlock to access app",
            ),
            value: true, // default (can be controlled with state)
            onChanged: (val) {},
          ),
        ),

        // App Lock Timeout
        Card(
          color: Colors.transparent,
          shadowColor: Colors.transparent,
          child: SwitchListTile(
            title: const Text("Enable App Lock"),
            subtitle: const Text("Automatically lock app after inactivity"),
            value: false,
            onChanged: (val) {},
          ),
        ),

        const SizedBox(height: 24),
        const Text(
          "Security Controls",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),

        // Change PIN
        Card(
          color: Colors.transparent,
          shadowColor: Colors.transparent,
          child: ListTile(
            leading: const Icon(Icons.lock_outline),
            title: const Text("Change PIN"),
            subtitle: const Text("Set or update your 4-digit app PIN"),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {},
          ),
        ),

        // 2FA Setup
        Card(
          color: Colors.transparent,
          shadowColor: Colors.transparent,
          child: ListTile(
            leading: const Icon(Icons.security),
            title: const Text("Setup Two-Factor Authentication"),
            subtitle: const Text("Add extra protection to your account"),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {},
          ),
        ),

        // Encryption Info
        Card(
          color: Colors.transparent,
          shadowColor: Colors.transparent,
          child: ListTile(
            leading: const Icon(Icons.verified_user),
            title: const Text("Encryption Details"),
            subtitle: const Text("View app's data protection status"),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {},
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return isSmallScreen
        ? Scaffold(
          appBar: AppBar(
            title: const Text('Security Settings'),
            centerTitle: true,
          ),
          body: _securityWidget(),
        )
        : _securityWidget();
  }
}
