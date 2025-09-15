import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:projectwebview/providers/common_provider.dart';
import 'package:projectwebview/providers/layout_provider.dart';
import 'package:projectwebview/providers/mail_provider.dart';
import 'package:projectwebview/providers/theme_provider.dart';
import 'package:projectwebview/utils/helpers.dart';
import 'package:projectwebview/widgets/blur.dart';
import 'package:provider/provider.dart';

class ViewMail extends StatelessWidget {
  const ViewMail({super.key});

  @override
  Widget build(BuildContext context) {
    final mailProvider = Provider.of<MailProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final commonProvider = Provider.of<CommonProvider>(context);
    final layoutProvider = Provider.of<LayoutProvider>(context);
    bool panePreviewOff = layoutProvider.layout == "pane_preview_off";
    if (mailProvider.selectedMail == null) {
      return const Center(child: Text("Failed to render email"));
    }

    return Scaffold(
      backgroundColor:
          commonProvider.isSmallScreen
              ? Theme.of(
                context,
              ).canvasColor.withOpacity(themeProvider.bgOpacity)
              : Colors.transparent,
      body: Container(
        decoration:
            commonProvider.isSmallScreen
                ? BoxDecoration(image: getBackgroundDecoration(themeProvider))
                : BoxDecoration(
                  // borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      spreadRadius: 1,
                      blurRadius: 1,
                      offset: const Offset(0, 0),
                    ),
                  ],
                ),
        clipBehavior: Clip.antiAlias,
        child: Blur(
          blur: themeProvider.bgBlur,
          child: SafeArea(
            child: Column(
              children: [
                if (panePreviewOff)
                  Container(
                    color:
                        commonProvider.isSmallScreen
                            ? Theme.of(
                              context,
                            ).canvasColor.withOpacity(themeProvider.bgOpacity)
                            : null,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8.0,
                      vertical: 8,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          onPressed: () {
                            if (panePreviewOff) {
                              if (!commonProvider.isSmallScreen) {
                                commonProvider.setIsMailView(isMailView: false);
                              } else {
                                Navigator.pop(context);
                              }
                            }
                          },
                          icon: const Icon(Icons.arrow_back_rounded),
                        ),
                        Row(
                          children: [
                            IconButton(
                              onPressed: () {},
                              icon: const Icon(Icons.archive_outlined),
                            ),
                            IconButton(
                              onPressed: () {},
                              icon: const Icon(Icons.delete_rounded),
                            ),
                            IconButton(
                              onPressed: () {},
                              icon: const Icon(
                                Icons.mark_email_unread_outlined,
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                showMenu(
                                  context: context,
                                  color: const Color(0xFF232923),
                                  position: const RelativeRect.fromLTRB(
                                    1,
                                    20,
                                    0,
                                    0,
                                  ), // Adjust position as needed
                                  items: [
                                    const PopupMenuItem(
                                      value: 1,
                                      child: Text(
                                        'Schedule Send',
                                        style: TextStyle(color: Colors.white70),
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 2,
                                      child: Text(
                                        'Add from Contact',
                                        style: TextStyle(color: Colors.white70),
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 3,
                                      child: Text(
                                        'Confidential mode',
                                        style: TextStyle(color: Colors.white70),
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 4,
                                      child: Text(
                                        'Save draft',
                                        style: TextStyle(color: Colors.white70),
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 5,
                                      child: Text(
                                        'Discard',
                                        style: TextStyle(color: Colors.white70),
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 6,
                                      child: Text(
                                        'Settings',
                                        style: TextStyle(color: Colors.white70),
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 7,
                                      child: Text(
                                        'Help and Feedback',
                                        style: TextStyle(color: Colors.white70),
                                      ),
                                    ),
                                  ],
                                ).then((value) {
                                  if (value != null) {
                                    // Handle the selected option
                                    print('Selected: $value');
                                  }
                                });
                              },
                              icon: const Icon(Icons.more_vert_rounded),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: InAppWebView(
                    initialData: InAppWebViewInitialData(
                      data:
                          mailProvider.selectedMail.decodeTextHtmlPart() ??
                          (mailProvider.selectedMail.decodeTextPlainPart())
                              .replaceAll("\r\n", "<br>"),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
