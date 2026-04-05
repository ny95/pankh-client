import 'package:flutter/material.dart';
import 'package:pankh/providers/settings_provider.dart';
import 'package:pankh/widgets/settings/section.dart';
import 'package:provider/provider.dart';

class CompositionSettingsTab extends StatelessWidget {
  final bool isSmallScreen;

  const CompositionSettingsTab({super.key, required this.isSmallScreen});

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SettingsSection(
              title: 'Message Composition',
              children: [
                SwitchSettingsRow(
                  title: 'Compose messages in HTML format',
                  value: settings.composeHtml,
                  onChanged:
                      (val) => settings.update(composeHtml: val),
                ),
                SwitchSettingsRow(
                  title: 'Automatically quote original message',
                  value: settings.autoQuote,
                  onChanged:
                      (val) => settings.update(autoQuote: val),
                ),
                SettingsRow(
                  title: 'Default font',
                  trailing: DropdownButton<String>(
                    value: settings.defaultFont,
                    isExpanded: true,
                    items:
                        ['Arial', 'Times New Roman', 'Courier New', 'Georgia']
                            .map(
                              (font) => DropdownMenuItem(
                                value: font,
                                child: Text(
                                  font,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                            .toList(),
                    onChanged:
                        (val) {
                          if (val == null) return;
                          settings.update(defaultFont: val);
                        },
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
