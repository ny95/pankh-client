import 'package:flutter/material.dart';
import 'package:projectwebview/widgets/settings/section.dart';

class CompositionSettingsTab extends StatelessWidget {
  final bool isSmallScreen;

  const CompositionSettingsTab({super.key, required this.isSmallScreen});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.all(16),
      children: [
        SettingsSection(
          title: 'Message Composition',
          children: [
            SwitchSettingsRow(
              title: 'Compose messages in HTML format',
              value: true,
              onChanged: (val) {},
            ),
            SwitchSettingsRow(
              title: 'Automatically quote original message',
              value: false,
              onChanged: (val) {},
            ),
            SettingsRow(
              title: 'Default font',
              trailing: DropdownButton<String>(
                value: 'Arial',
                items:
                    ['Arial', 'Times New Roman', 'Courier New']
                        .map(
                          (font) =>
                              DropdownMenuItem(value: font, child: Text(font)),
                        )
                        .toList(),
                onChanged: (val) {},
              ),
            ),
          ],
        ),
      ],
    );
  }
}
