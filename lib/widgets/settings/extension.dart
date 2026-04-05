import 'package:flutter/material.dart';

class ExtensionsTab extends StatelessWidget {
  final bool isSmallScreen;

  const ExtensionsTab({super.key, required this.isSmallScreen});

  Widget _extensionWidget() {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        const Text(
          "Installed Extensions",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),

        // Example Extension 1
        Card(
          color: Colors.transparent,
          shadowColor: Colors.transparent,
          child: SwitchListTile(
            title: const Text("Smart Replies"),
            subtitle: const Text("Enable AI-generated quick email responses"),
            value: true,
            onChanged: (val) {},
          ),
        ),

        // Example Extension 2
        Card(
          color: Colors.transparent,
          shadowColor: Colors.transparent,
          child: SwitchListTile(
            title: const Text("Read Receipts"),
            subtitle: const Text("Notify when your sent emails are opened"),
            value: false,
            onChanged: (val) {},
          ),
        ),

        // Example Extension 3
        Card(
          color: Colors.transparent,
          shadowColor: Colors.transparent,
          child: SwitchListTile(
            title: const Text("Email Translator"),
            subtitle: const Text(
              "Auto-translate emails to your preferred language",
            ),
            value: true,
            onChanged: (val) {},
          ),
        ),

        const SizedBox(height: 24),
        const Text(
          "Extension Store",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),

        // Explore extensions
        Card(
          color: Colors.transparent,
          shadowColor: Colors.transparent,
          child: ListTile(
            leading: const Icon(Icons.extension),
            title: const Text("Explore More Extensions"),
            subtitle: const Text("Discover and install new features"),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              // Navigate to extension store
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return _extensionWidget();
  }
}
