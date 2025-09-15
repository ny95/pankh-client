import 'dart:math';
import 'package:enough_mail/codecs.dart';
import 'package:flutter/material.dart';
import 'package:projectwebview/providers/mail_provider.dart';
import 'package:provider/provider.dart';
import '../mailView.dart';
import '../providers/common_provider.dart';
import '../providers/layout_provider.dart';

class EmailListItem extends StatelessWidget {
  final MimeMessage message;

  const EmailListItem({super.key, required this.message});

  Color _generateRandomColor() {
    return Colors.black38;
    // return Color.fromARGB(
    //   255, // Alpha (opacity)
    //   96 + random.nextInt(96), // Red (96-191)
    //   96 + random.nextInt(96), // Green (96-191)
    //   96 + random.nextInt(96), // Blue (96-191)
    // );
  }

  @override
  Widget build(BuildContext context) {
    final commonProvider = Provider.of<CommonProvider>(context);
    final layoutProvider = Provider.of<LayoutProvider>(context);
    final mailProvider = Provider.of<MailProvider>(context);
    bool panePreviewRight = layoutProvider.layout == "pane_preview_right";

    final String from =
        message.from?[0].toString().split('<')[0].replaceAll('"', '').trim() ??
        '';
    final String fromEmail =
        message.from?[0].toString().split('<')[0].replaceAll('>', '').trim() ??
        '';
    // print(fromEmail);
    dynamic messageString = message.decodeTextPlainPart();
    String newMessageString = 'Nothing here';
    if (messageString != null) {
      newMessageString = '';
      messageString = messageString.split('\r\n');
      for (final line in messageString) {
        if (line.startsWith('>')) {
          break;
        }
        newMessageString += line.replaceAll('\n', '') + ' ';
      }
    }
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          mailProvider.selectMail(message);
          if (!commonProvider.isSmallScreen) {
            commonProvider.setIsMailView(isMailView: true);
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ViewMail()),
            );
          }
        },
        child: Container(
          decoration:
              !commonProvider.isSmallScreen
                  ? BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Theme.of(context).dividerColor),
                    ),
                  )
                  : null,
          padding:
              commonProvider.isSmallScreen
                  ? EdgeInsets.fromLTRB(12.0, 2.0, 12.0, 2.0)
                  : EdgeInsets.fromLTRB(0, 4.0, 16, 4.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (commonProvider.isSmallScreen)
                Padding(
                  padding: const EdgeInsets.only(top: 3, right: 10),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(40),
                      color: _generateRandomColor(),
                    ),
                    child:
                        (fromEmail.contains('noreply') ||
                                fromEmail.contains('no-reply') ||
                                fromEmail.contains('support'))
                            ? Center(
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 2.0),
                                child: Text(
                                  from[0].toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            )
                            : const Icon(Icons.person, color: Colors.white),
                  ),
                ),
              if (!commonProvider.isSmallScreen)
                Container(
                  margin: EdgeInsets.only(
                    left: 8,
                    right: panePreviewRight ? 8 : 0,
                  ),
                  width: 30,
                  height: panePreviewRight ? 30 : 40,
                  child: Checkbox(value: false, onChanged: (value) {}),
                ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment:
                          commonProvider.isSmallScreen || panePreviewRight
                              ? MainAxisAlignment.spaceBetween
                              : MainAxisAlignment.start,
                      children: [
                        if (!commonProvider.isSmallScreen && !panePreviewRight)
                          Container(
                            width: 150,
                            margin: const EdgeInsets.only(right: 20),
                            child: Row(
                              mainAxisSize: MainAxisSize.max,
                              children: [
                                Flexible(
                                  flex: 4,
                                  child: SizedBox(
                                    width: 40,
                                    height: 40,
                                    child: IconButton(
                                      onPressed: () {},
                                      icon: const Icon(Icons.star_border),
                                    ),
                                  ),
                                ),
                                Flexible(
                                  flex: 8,
                                  child: Text(
                                    from,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        Flexible(
                          flex: 9,
                          child: Text(
                            '${panePreviewRight || commonProvider.isSmallScreen ? from : ''} ${(!commonProvider.isSmallScreen && !panePreviewRight) ? '${message.decodeSubject()} - $newMessageString' : ''}',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                        if (commonProvider.isSmallScreen || panePreviewRight)
                          Flexible(
                            flex: 3,
                            child: const Text(
                              '12:50 pm',
                              style: TextStyle(fontSize: 11),
                            ),
                          ),
                      ],
                    ),
                    if (commonProvider.isSmallScreen || panePreviewRight)
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  message.decodeSubject() ?? "",
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 13.5),
                                ),
                                Text(
                                  newMessageString,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(
                            width: 30,
                            height: 30,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Icon(Icons.star_border, color: Colors.white70),
                              ],
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
