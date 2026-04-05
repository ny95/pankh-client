import 'package:flutter/material.dart';
import 'package:pankh/providers/settings_provider.dart';
import 'package:provider/provider.dart';

class NotificationSettingsTab extends StatelessWidget {
  final bool isSmallScreen;

  const NotificationSettingsTab({super.key, required this.isSmallScreen});
  Widget _notificationWidget(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
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
            value: settings.notificationsEnabled,
            onChanged: (val) => settings.update(notificationsEnabled: val),
          ),
        ),

        // Sound
        Card(
          color: Colors.transparent,
          shadowColor: Colors.transparent,
          child: SwitchListTile(
            title: const Text("Sound"),
            subtitle: const Text("Play a sound for new emails"),
            value: settings.notificationSound,
            onChanged:
                settings.notificationsEnabled
                    ? (val) => settings.update(notificationSound: val)
                    : null,
          ),
        ),

        // Vibration
        Card(
          color: Colors.transparent,
          shadowColor: Colors.transparent,
          child: SwitchListTile(
            title: const Text("Vibration"),
            subtitle: const Text("Vibrate when receiving emails"),
            value: settings.notificationVibrate,
            onChanged:
                settings.notificationsEnabled
                    ? (val) => settings.update(notificationVibrate: val)
                    : null,
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
            value: settings.notifyPrimary,
            onChanged:
                settings.notificationsEnabled
                    ? (val) => settings.update(notifyPrimary: val)
                    : null,
          ),
        ),

        // Promotions
        Card(
          color: Colors.transparent,
          shadowColor: Colors.transparent,
          child: SwitchListTile(
            title: const Text("Promotions"),
            subtitle: const Text("Notify for promotional emails"),
            value: settings.notifyPromotions,
            onChanged:
                settings.notificationsEnabled
                    ? (val) => settings.update(notifyPromotions: val)
                    : null,
          ),
        ),

        // Social
        Card(
          color: Colors.transparent,
          shadowColor: Colors.transparent,
          child: SwitchListTile(
            title: const Text("Social"),
            subtitle: const Text("Notify for emails from social media"),
            value: settings.notifySocial,
            onChanged:
                settings.notificationsEnabled
                    ? (val) => settings.update(notifySocial: val)
                    : null,
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
            title: const Text("Quiet Hours"),
            subtitle: Text(
              settings.quietHoursEnabled
                  ? 'Muted from ${_formatHour(settings.quietStartHour)} '
                      'to ${_formatHour(settings.quietEndHour)}'
                  : 'Notifications are not muted',
            ),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              _showQuietHoursDialog(context, settings);
            },
          ),
        ),
      ],
    );
  }

  static String _formatHour(int hour) {
    final h = hour % 24;
    final suffix = h >= 12 ? 'PM' : 'AM';
    final display = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    return '$display $suffix';
  }

  Future<void> _showQuietHoursDialog(
    BuildContext context,
    SettingsProvider settings,
  ) async {
    TimeOfDay start = TimeOfDay(hour: settings.quietStartHour, minute: 0);
    TimeOfDay end = TimeOfDay(hour: settings.quietEndHour, minute: 0);
    bool enabled = settings.quietHoursEnabled;

    await showDialog<void>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Quiet Hours'),
            content: StatefulBuilder(
              builder: (context, setState) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SwitchListTile(
                      title: const Text('Enable Quiet Hours'),
                      value: enabled,
                      onChanged: (val) => setState(() => enabled = val),
                    ),
                    ListTile(
                      title: const Text('Start'),
                      trailing: Text(start.format(context)),
                      onTap: () async {
                        final picked =
                            await showTimePicker(
                              context: context,
                              initialTime: start,
                            );
                        if (picked != null) {
                          setState(() => start = picked);
                        }
                      },
                    ),
                    ListTile(
                      title: const Text('End'),
                      trailing: Text(end.format(context)),
                      onTap: () async {
                        final picked =
                            await showTimePicker(
                              context: context,
                              initialTime: end,
                            );
                        if (picked != null) {
                          setState(() => end = picked);
                        }
                      },
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
                  settings.update(
                    quietHoursEnabled: enabled,
                    quietStartHour: start.hour,
                    quietEndHour: end.hour,
                  );
                  Navigator.pop(context);
                },
                child: const Text('Save'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _notificationWidget(context);
  }
}
