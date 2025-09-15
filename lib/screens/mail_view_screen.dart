import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class ViewMail extends StatefulWidget {
  const ViewMail({
    super.key,
    required this.message,
    required this.type,
    this.onBack,
  });
  final dynamic message;
  final VoidCallback? onBack;
  final bool type;

  @override
  State<ViewMail> createState() => _ViewMailState();
}

class _ViewMailState extends State<ViewMail> {
  late bool isSmallScreen = false;
  late double width;
  late double height;
  double opacity = 0.3;

  Future<Widget> getMessage() async {
    try {
      final htmlContent =
          await widget.message.decodeTextHtmlPart() ??
          (await widget.message.decodeTextPlainPart()).replaceAll(
            "\r\n",
            "<br>",
          );
      return InAppWebView(
        initialData: InAppWebViewInitialData(data: htmlContent),
      );
    } catch (error) {
      return const Center(child: Text('Nothing Here!'));
    }
  }

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
    height = size.height;
    width = size.width;
    isSmallScreen = width < 800;
    if (widget.message == null) {
      return const Center(child: Text("Failed to render email"));
    }

    return Scaffold(
      backgroundColor:
          isSmallScreen
              ? Theme.of(context).canvasColor.withOpacity(opacity)
              : Colors.transparent,
      body: Container(
        decoration:
            isSmallScreen
                ? const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/images/theme-mccutcheon.jpg'),
                    fit: BoxFit.cover, // Change this as needed
                  ),
                )
                : BoxDecoration(borderRadius: BorderRadius.circular(15)),
        child: SafeArea(
          child: Column(
            children: [
              if (widget.type)
                Container(
                  color:
                      isSmallScreen
                          ? Theme.of(context).canvasColor.withOpacity(opacity)
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
                          if (widget.type) {
                            if (!isSmallScreen) {
                              widget.onBack?.call();
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
                            icon: const Icon(Icons.mark_email_unread_outlined),
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
                child: FutureBuilder<Widget>(
                  future: getMessage(),
                  builder: (
                    BuildContext context,
                    AsyncSnapshot<Widget> snapshot,
                  ) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      // Show a loading indicator while the HTML is loading
                      return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      // Handle error state
                      return Center(child: Text('Error: ${snapshot.error}'));
                    } else if (snapshot.hasData) {
                      // Render the HTML content
                      return snapshot.data!;
                    } else {
                      // Fallback case (shouldn't generally happen)
                      return const Center(child: Text('No data available'));
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
