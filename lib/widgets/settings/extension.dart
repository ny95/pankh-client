import 'package:flutter/material.dart';
import 'package:pankh/widgets/settings/transparent_switch_card.dart';

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
        TransparentSwitchCard(
          title: "Smart Replies",
          subtitle: "Enable AI-generated quick email responses",
          value: true,
          onChanged: (val) {},
        ),

        // Example Extension 2
        TransparentSwitchCard(
          title: "Read Receipts",
          subtitle: "Notify when your sent emails are opened",
          value: false,
          onChanged: (val) {},
        ),

        // Example Extension 3
        TransparentSwitchCard(
          title: "Email Translator",
          subtitle: "Auto-translate emails to your preferred language",
          value: true,
          onChanged: (val) {},
        ),

        const SizedBox(height: 24),
        const Text(
          "Extension Store",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),

        // Explore extensions
        TransparentCard(
          child: ListTile(
            leading: const Icon(Icons.extension),
            title: const Text("Explore More Extensions"),
            subtitle: const Text("Discover and install new features"),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {},
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
