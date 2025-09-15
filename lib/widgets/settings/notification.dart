import 'package:flutter/material.dart';

class NotificationSettingsTab extends StatelessWidget {
  final bool isSmallScreen;

  const NotificationSettingsTab({super.key, required this.isSmallScreen});
  Widget _notificationWidget() {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        const Text(
          "General Notifications",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),

        // Enable notifications
        Card(
          color: Colors.transparent,
          shadowColor: Colors.transparent,
          child: SwitchListTile(
            title: const Text("Enable Notifications"),
            subtitle: const Text("Turn on or off all notifications"),
            value: true,
            onChanged: (val) {},
          ),
        ),

        // Sound
        Card(
          color: Colors.transparent,
          shadowColor: Colors.transparent,
          child: SwitchListTile(
            title: const Text("Sound"),
            subtitle: const Text("Play a sound for new emails"),
            value: true,
            onChanged: (val) {},
          ),
        ),

        // Vibration
        Card(
          color: Colors.transparent,
          shadowColor: Colors.transparent,
          child: SwitchListTile(
            title: const Text("Vibration"),
            subtitle: const Text("Vibrate when receiving emails"),
            value: false,
            onChanged: (val) {},
          ),
        ),

        const SizedBox(height: 24),
        const Text(
          "Email Categories",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),

        // Primary Inbox
        Card(
          color: Colors.transparent,
          shadowColor: Colors.transparent,
          child: SwitchListTile(
            title: const Text("Primary Inbox"),
            subtitle: const Text("Notify for primary inbox emails"),
            value: true,
            onChanged: (val) {},
          ),
        ),

        // Promotions
        Card(
          color: Colors.transparent,
          shadowColor: Colors.transparent,
          child: SwitchListTile(
            title: const Text("Promotions"),
            subtitle: const Text("Notify for promotional emails"),
            value: false,
            onChanged: (val) {},
          ),
        ),

        // Social
        Card(
          color: Colors.transparent,
          shadowColor: Colors.transparent,
          child: SwitchListTile(
            title: const Text("Social"),
            subtitle: const Text("Notify for emails from social media"),
            value: true,
            onChanged: (val) {},
          ),
        ),

        const SizedBox(height: 24),
        const Text(
          "Quiet Hours",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),

        // Quiet Hours Setting
        Card(
          color: Colors.transparent,
          shadowColor: Colors.transparent,
          child: ListTile(
            leading: const Icon(Icons.nightlight_round),
            title: const Text("Set Quiet Hours"),
            subtitle: const Text("Mute notifications during selected hours"),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              // Navigate to time picker or quiet hours config page
            },
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
            title: const Text('Notification Settings'),
            centerTitle: true,
          ),
          body: _notificationWidget(),
        )
        : _notificationWidget();
  }
}
